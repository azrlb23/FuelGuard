-- =============================================================================
-- SQL Migration: 04_operator_rpcs.sql
-- Description: RPCs for Operator Dashboard (Shared Device / Multi-Operator)
-- Architecture:
--   - operator_id di transaksi_pertalite merujuk ke operator_profiles(id)
--   - SPBU didapat via JOIN: transaksi_pertalite.operator_id -> operator_profiles.spbu_id
--   - fn_safe_insert_transaction mewajibkan p_operator_id dari tabel operator_profiles
-- =============================================================================

-- ─── 1. RPC: fn_check_plate_status ───────────────────────────────────────────
DROP FUNCTION IF EXISTS public.fn_check_plate_status CASCADE;
CREATE OR REPLACE FUNCTION public.fn_check_plate_status(
  p_plat text,
  p_is_ojol boolean DEFAULT false,
  p_spbu_id text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_spbu_id text;
  v_total_liter_today numeric := 0;
  v_total_harga_today numeric := 0;
  v_count_today integer := 0;
  v_has_refueled boolean := false;
  v_remaining_quota numeric := 0;
  v_max_quota numeric := 50000;
  v_last_trx json := NULL;
  v_last_time text := '';
BEGIN
  v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());

  -- Validasi Kode Wilayah Plat Indonesia
  IF NOT EXISTS (
    SELECT 1 FROM public.region_codes 
    WHERE code = split_part(UPPER(TRIM(p_plat)), ' ', 1)
  ) THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'invalid_region',
      'message', 'Kode wilayah plat (' || split_part(UPPER(TRIM(p_plat)), ' ', 1) || ') tidak terdaftar di Indonesia.'
    );
  END IF;

  IF p_is_ojol THEN
    v_max_quota := 100000; -- Motor Ojol Rp 100.000/hari
  ELSE
    v_max_quota := 50000;  -- Motor Non-Ojol Rp 50.000/hari
  END IF;

  -- Count today's transactions for this plate (cross-branch)
  SELECT 
    COALESCE(SUM(liter), 0),
    COALESCE(SUM(harga), 0),
    COUNT(id)
  INTO v_total_liter_today, v_total_harga_today, v_count_today
  FROM public.transaksi_pertalite
  WHERE plat_nomor = UPPER(TRIM(p_plat))
    AND waktu_pencatatan >= date_trunc('day', NOW())
    AND waktu_pencatatan < date_trunc('day', NOW()) + INTERVAL '1 day';

  v_has_refueled := v_total_harga_today >= v_max_quota;
  v_remaining_quota := GREATEST(0, v_max_quota - v_total_harga_today);

  IF v_count_today > 0 THEN
    -- Join via operator_profiles to get spbu_id
    SELECT json_build_object(
      'id', t.id,
      'liter', t.liter,
      'harga', t.harga,
      'waktu_pencatatan', t.waktu_pencatatan,
      'is_ojol', t.is_ojol,
      'spbu_id', op.spbu_id,
      'spbu_nama', COALESCE(s.nama, CONCAT('SPBU #', op.spbu_id))
    )
    INTO v_last_trx
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE t.plat_nomor = UPPER(TRIM(p_plat))
      AND t.waktu_pencatatan >= date_trunc('day', NOW())
      AND t.waktu_pencatatan < date_trunc('day', NOW()) + INTERVAL '1 day'
    ORDER BY t.waktu_pencatatan DESC
    LIMIT 1;

    SELECT to_char(waktu_pencatatan, 'HH24:MI')
    INTO v_last_time
    FROM public.transaksi_pertalite
    WHERE plat_nomor = UPPER(TRIM(p_plat))
      AND waktu_pencatatan >= date_trunc('day', NOW())
    ORDER BY waktu_pencatatan DESC
    LIMIT 1;
  END IF;

  RETURN json_build_object(
    'success', true,
    'hasRefueledToday', v_has_refueled,
    'totalLiterToday', v_total_liter_today,
    'totalHargaToday', v_total_harga_today,
    'remainingQuota', v_remaining_quota,
    'countToday', v_count_today,
    'lastTransaction', v_last_trx,
    'timeFormatted', v_last_time,
    'plat', UPPER(TRIM(p_plat))
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.fn_check_plate_status(text, boolean, text) TO authenticated;


-- ─── 2. RPC: fn_safe_insert_transaction ──────────────────────────────────────
-- p_operator_id wajib dikirim dari frontend (UUID dari operator_profiles, bukan auth.users)
DROP FUNCTION IF EXISTS public.fn_safe_insert_transaction CASCADE;
CREATE OR REPLACE FUNCTION public.fn_safe_insert_transaction(
  p_plat text,
  p_liter numeric,
  p_operator_id uuid,
  p_is_ojol boolean DEFAULT false
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_spbu_id text;
  v_plat_clean text;
  v_harga_per_liter numeric;
  v_total_harga numeric;
  v_total_harga_today numeric;
  v_count_today integer;
  v_max_quota numeric := 50000;
  v_new_id bigint;
BEGIN
  -- Validate Operator (harus ada di operator_profiles)
  IF p_operator_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_operator', 'message', 'Operator ID tidak valid.');
  END IF;

  -- Cari spbu_id dari operator_profiles (bukan user_roles!)
  SELECT spbu_id INTO v_spbu_id FROM public.operator_profiles WHERE id = p_operator_id;
  IF v_spbu_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_spbu', 'message', 'Operator tidak terdaftar pada SPBU manapun.');
  END IF;

  v_plat_clean := UPPER(TRIM(p_plat));
  IF v_plat_clean = '' OR p_liter <= 0 THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_input', 'message', 'Plat nomor dan liter harus valid.');
  END IF;

  -- Validasi Kode Wilayah Plat Indonesia
  IF NOT EXISTS (
    SELECT 1 FROM public.region_codes 
    WHERE code = split_part(v_plat_clean, ' ', 1)
  ) THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'invalid_region',
      'message', 'Kode wilayah plat (' || split_part(v_plat_clean, ' ', 1) || ') tidak terdaftar di Indonesia.'
    );
  END IF;

  IF p_is_ojol THEN
    v_max_quota := 100000;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(v_plat_clean));

  -- Get Price Per Liter from Server
  SELECT price_per_liter INTO v_harga_per_liter
  FROM public.fuel_prices
  WHERE spbu_id = v_spbu_id
    AND LOWER(fuel_type) LIKE '%pertalite%'
  ORDER BY updated_at DESC NULLS LAST
  LIMIT 1;

  IF v_harga_per_liter IS NULL OR v_harga_per_liter <= 0 THEN
    v_harga_per_liter := 10000; -- Default fallback price
  END IF;

  v_total_harga := p_liter * v_harga_per_liter;

  -- Cross-branch Daily Quota Check
  SELECT 
    COALESCE(SUM(harga), 0),
    COUNT(id)
  INTO v_total_harga_today, v_count_today
  FROM public.transaksi_pertalite
  WHERE plat_nomor = v_plat_clean
    AND waktu_pencatatan >= date_trunc('day', NOW())
    AND waktu_pencatatan < date_trunc('day', NOW()) + INTERVAL '1 day';

  IF (v_total_harga_today + v_total_harga) > v_max_quota THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'quota_exceeded',
      'message', format('Kuota Pertalite Motor (%s - Rp %s/hari) terlampaui! Sudah terisi: Rp %s.', 
        CASE WHEN p_is_ojol THEN 'Ojol' ELSE 'Non-Ojol' END, 
        v_max_quota, 
        v_total_harga_today)
    );
  END IF;

  INSERT INTO public.transaksi_pertalite (
    plat_nomor, liter, harga, operator_id, is_ojol, waktu_pencatatan
  ) VALUES (
    v_plat_clean, p_liter, v_total_harga, p_operator_id, p_is_ojol, NOW()
  )
  RETURNING id INTO v_new_id;

  RETURN json_build_object(
    'success', true,
    'transaction_id', v_new_id,
    'harga', v_total_harga,
    'message', 'Transaksi berhasil dicatat.'
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.fn_safe_insert_transaction(text, numeric, uuid, boolean) TO authenticated;


-- ─── 3. RPC: get_dashboard_summary ───────────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_dashboard_summary CASCADE;
CREATE OR REPLACE FUNCTION public.get_dashboard_summary(
  p_filter text DEFAULT 'today',
  p_spbu_id text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_spbu_id text;
  v_start_time timestamp;
  v_stats json;
  v_feed json;
  v_vehicle_chart json;
  v_peak_hours json;
  v_loyal_customers json;
  v_trend_7_days json;
  v_revenue_share json;
BEGIN
  v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());

  IF p_filter = 'today' THEN
    v_start_time := date_trunc('day', NOW());
  ELSIF p_filter = 'weekly' THEN
    v_start_time := NOW() - INTERVAL '7 days';
  ELSIF p_filter = 'monthly' THEN
    v_start_time := NOW() - INTERVAL '30 days';
  ELSE
    v_start_time := '1970-01-01'::timestamp;
  END IF;

  -- 1. Main Stats
  SELECT json_build_object(
    'volume', COALESCE(SUM(t.liter), 0),
    'revenue', COALESCE(SUM(t.harga), 0),
    'vehicle', COUNT(t.id)
  ) INTO v_stats
  FROM public.transaksi_pertalite t
  LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
    AND t.waktu_pencatatan >= v_start_time;

  -- 2. Recent Feed (10 Latest)
  SELECT COALESCE(json_agg(row_to_json(feed_data)), '[]'::json) INTO v_feed
  FROM (
    SELECT 
      t.id, 
      t.plat_nomor, 
      t.liter, 
      t.harga, 
      t.is_ojol,
      t.waktu_pencatatan, 
      op.spbu_id
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      AND t.waktu_pencatatan >= v_start_time
    ORDER BY t.waktu_pencatatan DESC
    LIMIT 10
  ) feed_data;

  -- Fallback Feed if empty today
  IF (v_feed IS NULL OR v_feed::text = '[]') AND p_filter = 'today' THEN
    SELECT COALESCE(json_agg(row_to_json(feed_data)), '[]'::json) INTO v_feed
    FROM (
      SELECT 
        t.id, 
        t.plat_nomor, 
        t.liter, 
        t.harga, 
        t.is_ojol,
        t.waktu_pencatatan, 
        op.spbu_id
      FROM public.transaksi_pertalite t
      LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
      WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      ORDER BY t.waktu_pencatatan DESC
      LIMIT 10
    ) feed_data;
  END IF;

  -- 3. Ojol vs Non-Ojol Chart
  SELECT json_build_array(
    json_build_object('label', 'Ojol', 'count', 
      COALESCE(COUNT(t.id) FILTER (WHERE t.is_ojol = true), 0)),
    json_build_object('label', 'Non-Ojol', 'count', 
      COALESCE(COUNT(t.id) FILTER (WHERE t.is_ojol = false OR t.is_ojol IS NULL), 0))
  ) INTO v_vehicle_chart
  FROM public.transaksi_pertalite t
  LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
    AND t.waktu_pencatatan >= v_start_time;

  -- 4. Peak Hours Distribution
  SELECT COALESCE(json_agg(json_build_object('hour', h, 'count', cnt) ORDER BY h), '[]'::json)
  INTO v_peak_hours
  FROM (
    SELECT EXTRACT(HOUR FROM t.waktu_pencatatan)::integer AS h, COUNT(*) AS cnt
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      AND t.waktu_pencatatan >= v_start_time
    GROUP BY 1
  ) sub;

  -- 5. Top Loyal Vehicles
  SELECT COALESCE(json_agg(json_build_object(
    'plat_nomor', plat_nomor,
    'total_trx', total_trx,
    'total_liter', total_liter
  )), '[]'::json)
  INTO v_loyal_customers
  FROM (
    SELECT t.plat_nomor, COUNT(*) AS total_trx, SUM(t.liter) AS total_liter
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      AND t.waktu_pencatatan >= v_start_time
      AND t.plat_nomor IS NOT NULL AND t.plat_nomor <> ''
    GROUP BY t.plat_nomor
    ORDER BY total_liter DESC
    LIMIT 5
  ) sub;

  -- 6. 7-Day Revenue Trend
  WITH days AS (
    SELECT generate_series(
      date_trunc('day', NOW()) - INTERVAL '6 days',
      date_trunc('day', NOW()),
      INTERVAL '1 day'
    )::date AS d
  )
  SELECT COALESCE(json_agg(json_build_object(
    'label', to_char(days.d, 'Dy DD'),
    'total', COALESCE(trx.total_revenue, 0)
  ) ORDER BY days.d), '[]'::json)
  INTO v_trend_7_days
  FROM days
  LEFT JOIN (
    SELECT t.waktu_pencatatan::date AS trx_date, SUM(t.harga) AS total_revenue
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      AND t.waktu_pencatatan >= date_trunc('day', NOW()) - INTERVAL '6 days'
    GROUP BY 1
  ) trx ON trx.trx_date = days.d;

  -- 7. Revenue Share (Ojol vs Non-Ojol)
  SELECT json_build_array(
    json_build_object('label', 'Ojol', 'total', 
      COALESCE(SUM(t.harga) FILTER (WHERE t.is_ojol = true), 0)),
    json_build_object('label', 'Non-Ojol', 'total', 
      COALESCE(SUM(t.harga) FILTER (WHERE t.is_ojol = false OR t.is_ojol IS NULL), 0))
  ) INTO v_revenue_share
  FROM public.transaksi_pertalite t
  LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
    AND t.waktu_pencatatan >= v_start_time;

  RETURN json_build_object(
    'stats', v_stats,
    'feed', v_feed,
    'vehicle_chart', v_vehicle_chart,
    'peak_hours', v_peak_hours,
    'loyal_customers', v_loyal_customers,
    'trend_7_days', v_trend_7_days,
    'revenue_share', v_revenue_share
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_dashboard_summary(text, text) TO authenticated;


-- ─── 4. RPC: get_export_transactions ─────────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_export_transactions CASCADE;
CREATE OR REPLACE FUNCTION public.get_export_transactions(
  p_start_date text,
  p_end_date text,
  p_spbu_id text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_spbu_id text;
  v_result json;
BEGIN
  v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());

  SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) INTO v_result
  FROM (
    SELECT 
      trx.id, 
      trx.waktu_pencatatan, 
      trx.plat_nomor, 
      trx.liter, 
      trx.harga,
      trx.is_ojol,
      COALESCE(s.nama, CONCAT('SPBU #', op.spbu_id)) AS spbu_nama
    FROM public.transaksi_pertalite trx
    LEFT JOIN public.operator_profiles op ON op.id = trx.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      AND trx.waktu_pencatatan >= (p_start_date || 'T00:00:00')::timestamp
      AND trx.waktu_pencatatan <= (p_end_date || 'T23:59:59')::timestamp
    ORDER BY trx.waktu_pencatatan ASC
  ) t;

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_export_transactions(text, text, text) TO authenticated;

NOTIFY pgrst, 'reload schema';
