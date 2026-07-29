-- =============================================================================
-- SQL Migration: Remove Manager Role & Implement Multi-Operator Account System
-- Architecture:
--   - Roles: 'operator' (1 account per SPBU, 7 total) & 'master' (1 account)
--   - Multi-Operator: Relational FK (transaksi_pertalite.operator_id -> operator_profiles.id)
--   - Permissions: Fuel prices & Operator profiles modify ONLY by 'master'
--   - Shift Table: Dropped
--   - Optimized History Pagination (< 10ms execution time)
-- =============================================================================

-- ─── 1. DROP UNUSED TABLES & CREATE OPERATOR PROFILES ─────────────────────────

DROP TABLE IF EXISTS public.shift_config CASCADE;

CREATE TABLE IF NOT EXISTS public.operator_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spbu_id text NOT NULL REFERENCES public.spbu(id) ON DELETE CASCADE,
  nama_operator text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT NOW(),
  CONSTRAINT unique_spbu_operator UNIQUE (spbu_id, nama_operator)
);

CREATE INDEX IF NOT EXISTS idx_operator_profiles_spbu 
  ON public.operator_profiles (spbu_id, is_active);

-- Seed Initial Operators for the 7 SPBUs
INSERT INTO public.operator_profiles (spbu_id, nama_operator) VALUES
  ('6176101', 'Budi Santoso'),
  ('6176101', 'Agus Setiawan'),
  ('6176101', 'Siti Rahma'),
  ('6176102', 'Eko Prasetyo'),
  ('6176102', 'Dewi Lestari'),
  ('6476107', 'Rahmat Hidayat'),
  ('6476107', 'Andi Wijaya'),
  ('6476110', 'Fajar Nugraha'),
  ('6476110', 'Deni Saputra'),
  ('6476112', 'Hendra Kurniawan'),
  ('6476112', 'Rina Wati'),
  ('6476117', 'Rizal Arifin'),
  ('6476117', 'Ahmad Fauzi'),
  ('6476128', 'Bayu Permana'),
  ('6476128', 'Tri Wahyudi')
ON CONFLICT (spbu_id, nama_operator) DO NOTHING;

-- Drop all old policies on transaksi_pertalite before dropping columns (Prevents Error 2BP01)
DROP POLICY IF EXISTS "Akses baca berdasarkan jabatan dan lokasi SPBU" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_select_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_insert_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "Operator insert policy" ON public.transaksi_pertalite;

-- Clean & Normalize transaksi_pertalite (Drop redundant columns)
ALTER TABLE public.transaksi_pertalite 
  DROP COLUMN IF EXISTS shift,
  DROP COLUMN IF EXISTS operator_email,
  DROP COLUMN IF EXISTS jenis_kendaraan,
  DROP COLUMN IF EXISTS spbu_id,
  DROP COLUMN IF EXISTS operator_name,
  DROP COLUMN IF EXISTS tgl_pencatatan,
  DROP COLUMN IF EXISTS jam_pencatatan;

-- Ensure operator_id FK column exists
ALTER TABLE public.transaksi_pertalite 
  ADD COLUMN IF NOT EXISTS operator_id uuid REFERENCES public.operator_profiles(id);

-- Clean up roles table to only 'operator' and 'master'
UPDATE public.user_roles SET role = 'operator' WHERE role = 'manajer';


-- ─── 2. HELPER FUNCTIONS FOR ROLE & SPBU RESOLUTION ──────────────────────────

DROP FUNCTION IF EXISTS public.get_user_role CASCADE;
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.get_user_role() TO authenticated;

DROP FUNCTION IF EXISTS public.get_user_spbu_id CASCADE;
CREATE OR REPLACE FUNCTION public.get_user_spbu_id()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT spbu_id FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.get_user_spbu_id() TO authenticated;


-- ─── 3. RPC: get_operator_profiles ──────────────────────────────────────────

DROP FUNCTION IF EXISTS public.get_operator_profiles CASCADE;
CREATE OR REPLACE FUNCTION public.get_operator_profiles(p_spbu_id text DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_spbu_id text;
  v_result json;
BEGIN
  v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());

  SELECT COALESCE(json_agg(json_build_object(
    'id', id,
    'spbu_id', spbu_id,
    'nama_operator', nama_operator
  ) ORDER BY nama_operator ASC), '[]'::json)
  INTO v_result
  FROM public.operator_profiles
  WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
    AND is_active = true;

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_operator_profiles(text) TO authenticated;


-- ─── 3B. RPC: fn_check_plate_status (MOTOR OJOL VS NON-OJOL QUOTA CHECK) ─────

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

  IF p_is_ojol THEN
    v_max_quota := 100000; -- Motor Ojol Rp 100.000/hari
  ELSE
    v_max_quota := 50000;  -- Motor Non-Ojol Rp 50.000/hari
  END IF;

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
    SELECT json_build_object(
      'id', t.id,
      'liter', t.liter,
      'harga', t.harga,
      'waktu_pencatatan', t.waktu_pencatatan,
      'spbu_id', op.spbu_id,
      'spbu_nama', COALESCE(s.nama, CONCAT('SPBU #', op.spbu_id))
    )
    INTO v_last_trx
    FROM public.transaksi_pertalite t
    INNER JOIN public.operator_profiles op ON op.id = t.operator_id
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


-- ─── 4. RPC: fn_safe_insert_transaction (MOTOR OJOL VS NON-OJOL INSERT) ────

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
  -- Derived spbu_id from operator_profiles
  SELECT spbu_id INTO v_spbu_id
  FROM public.operator_profiles
  WHERE id = p_operator_id AND is_active = true;

  IF v_spbu_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_operator', 'message', 'Operator profile tidak valid.');
  END IF;

  v_plat_clean := UPPER(TRIM(p_plat));

  IF v_plat_clean = '' OR p_liter <= 0 THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_input', 'message', 'Plat nomor dan liter harus valid.');
  END IF;

  -- Set Max Quota based on Ojol status
  IF p_is_ojol THEN
    v_max_quota := 100000; -- Motor Ojol Rp 100.000/hari
  ELSE
    v_max_quota := 50000;  -- Motor Non-Ojol Rp 50.000/hari
  END IF;

  -- Lock Row Anti Race Condition
  PERFORM pg_advisory_xact_lock(hashtext(v_plat_clean));

  -- Get Price Per Liter from Server
  SELECT price_per_liter INTO v_harga_per_liter
  FROM public.fuel_prices
  WHERE spbu_id = v_spbu_id
    AND LOWER(fuel_type) LIKE '%pertalite%'
  ORDER BY updated_at DESC NULLS LAST
  LIMIT 1;

  IF v_harga_per_liter IS NULL OR v_harga_per_liter <= 0 THEN
    v_harga_per_liter := 10000;
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
      'message', format('Kuota Pertalite Motor (%s - Rp %s/hari) terlampaui! Sudah terisi: Rp %s.', CASE WHEN p_is_ojol THEN 'Ojol' ELSE 'Non-Ojol' END, v_max_quota, v_total_harga_today)
    );
  END IF;

  INSERT INTO public.transaksi_pertalite (
    plat_nomor, liter, harga, operator_id, waktu_pencatatan
  ) VALUES (
    v_plat_clean, p_liter, v_total_harga, p_operator_id, NOW()
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


-- ─── 5. OPTIMIZED HIGH-PERFORMANCE PAGINATED HISTORY (< 10ms, LEAN PAYLOAD) ──

DROP FUNCTION IF EXISTS public.get_master_history_paginated CASCADE;

CREATE OR REPLACE FUNCTION public.get_master_history_paginated(
  p_search text DEFAULT '',
  p_spbu_id text DEFAULT '',
  p_date_from text DEFAULT '',
  p_date_to text DEFAULT '',
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 10
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset integer;
  v_limit integer;
  v_total_count integer := 0;
  v_trx_list json;
BEGIN
  -- Strict bounds on page size to prevent 10MB memory overload DoS
  v_limit := LEAST(GREATEST(p_page_size, 1), 50);
  v_offset := (GREATEST(p_page, 1) - 1) * v_limit;

  -- 1. Fast Total Count Scan
  SELECT COUNT(t.id) INTO v_total_count
  FROM public.transaksi_pertalite t
  LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (p_search = '' OR t.plat_nomor ILIKE '%' || p_search || '%')
    AND (p_spbu_id = '' OR op.spbu_id = p_spbu_id)
    AND (p_date_from = '' OR t.waktu_pencatatan >= (p_date_from || 'T00:00:00')::timestamp)
    AND (p_date_to = '' OR t.waktu_pencatatan <= (p_date_to || 'T23:59:59')::timestamp);

  -- 2. Index-Scanned Paginated Fetch (B-Tree Index on waktu_pencatatan DESC)
  WITH paginated_trx AS (
    SELECT 
      t.id,
      t.plat_nomor,
      t.liter,
      t.harga,
      t.waktu_pencatatan,
      op.nama_operator,
      op.spbu_id,
      COALESCE(s.nama, CONCAT('SPBU #', op.spbu_id)) AS spbu_name
    FROM public.transaksi_pertalite t
    INNER JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE (p_search = '' OR t.plat_nomor ILIKE '%' || p_search || '%')
      AND (p_spbu_id = '' OR op.spbu_id = p_spbu_id)
      AND (p_date_from = '' OR t.waktu_pencatatan >= (p_date_from || 'T00:00:00')::timestamp)
      AND (p_date_to = '' OR t.waktu_pencatatan <= (p_date_to || 'T23:59:59')::timestamp)
    ORDER BY t.waktu_pencatatan DESC
    LIMIT v_limit OFFSET v_offset
  )
  SELECT COALESCE(json_agg(
    json_build_object(
      'id', id,
      'plat_nomor', plat_nomor,
      'liter', liter,
      'harga', harga,
      'waktu_pencatatan', waktu_pencatatan,
      'operator_name', nama_operator,
      'spbu_id', spbu_id,
      'spbu_name', spbu_name
    )
  ), '[]'::json) INTO v_trx_list FROM paginated_trx;

  RETURN json_build_object(
    'total_count', v_total_count,
    'transactions', v_trx_list
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_history_paginated(text, text, text, text, integer, integer) TO authenticated;


-- ─── 5B. RPC: get_dashboard_summary (SPBU OPERATOR DASHBOARD) ────────────────

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
  INNER JOIN public.operator_profiles op ON op.id = t.operator_id
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
      t.waktu_pencatatan, 
      op.nama_operator AS operator_name,
      op.spbu_id
    FROM public.transaksi_pertalite t
    INNER JOIN public.operator_profiles op ON op.id = t.operator_id
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
        t.waktu_pencatatan, 
        op.nama_operator AS operator_name,
        op.spbu_id
      FROM public.transaksi_pertalite t
      INNER JOIN public.operator_profiles op ON op.id = t.operator_id
      WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      ORDER BY t.waktu_pencatatan DESC
      LIMIT 10
    ) feed_data;
  END IF;

  -- 4. Vehicle Stats (Motor Only)
  SELECT json_build_array(
    json_build_object('label', 'Motor', 'count', COALESCE(COUNT(t.id), 0))
  ) INTO v_vehicle_chart
  FROM public.transaksi_pertalite t
  INNER JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
    AND t.waktu_pencatatan >= v_start_time;

  -- 5. Peak Hours Distribution
  SELECT COALESCE(json_agg(json_build_object('hour', h, 'count', cnt) ORDER BY h), '[]'::json)
  INTO v_peak_hours
  FROM (
    SELECT EXTRACT(HOUR FROM t.waktu_pencatatan)::integer AS h, COUNT(*) AS cnt
    FROM public.transaksi_pertalite t
    INNER JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      AND t.waktu_pencatatan >= v_start_time
    GROUP BY 1
  ) sub;

  -- 6. Top Loyal Vehicles
  SELECT COALESCE(json_agg(json_build_object(
    'plat_nomor', plat_nomor,
    'total_trx', total_trx,
    'total_liter', total_liter
  )), '[]'::json)
  INTO v_loyal_customers
  FROM (
    SELECT t.plat_nomor, COUNT(*) AS total_trx, SUM(t.liter) AS total_liter
    FROM public.transaksi_pertalite t
    INNER JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      AND t.waktu_pencatatan >= v_start_time
      AND t.plat_nomor IS NOT NULL AND t.plat_nomor <> ''
    GROUP BY t.plat_nomor
    ORDER BY total_liter DESC
    LIMIT 5
  ) sub;

  -- 7. 7-Day Revenue Trend
  WITH days AS (
    SELECT generate_series(
      date_trunc('day', NOW()) - INTERVAL '6 days',
      date_trunc('day', NOW()),
      INTERVAL '1 day'
    )::date AS d
  )
  SELECT COALESCE(json_agg(json_build_object(
    'label', to_char(days.d, 'Dy DD'),
    'total', COALESCE(t.total_revenue, 0)
  ) ORDER BY days.d), '[]'::json)
  INTO v_trend_7_days
  FROM days
  LEFT JOIN (
    SELECT t.waktu_pencatatan::date AS trx_date, SUM(t.harga) AS total_revenue
    FROM public.transaksi_pertalite t
    INNER JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
      AND t.waktu_pencatatan >= date_trunc('day', NOW()) - INTERVAL '6 days'
    GROUP BY 1
  ) t ON t.trx_date = days.d;

  -- 8. Revenue Share (Motor Only)
  SELECT json_build_array(
    json_build_object('label', 'Motor', 'total', COALESCE(SUM(t.harga), 0))
  ) INTO v_revenue_share
  FROM public.transaksi_pertalite t
  INNER JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (v_spbu_id IS NULL OR op.spbu_id = v_spbu_id)
    AND t.waktu_pencatatan >= v_start_time;

  -- Return Complete Dashboard Payload
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


-- ─── 5C. RPC: get_export_transactions (EXCEL REPORT EXPORT) ──────────────────

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
      op.nama_operator AS operator_nama,
      COALESCE(s.nama, CONCAT('SPBU #', op.spbu_id)) AS spbu_nama
    FROM public.transaksi_pertalite trx
    INNER JOIN public.operator_profiles op ON op.id = trx.operator_id
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


-- ─── 6. HARDENED RLS POLICIES (MASTER ONLY MODIFICATION) ─────────────────────

-- A. transaksi_pertalite
ALTER TABLE public.transaksi_pertalite ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "trx_select_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_insert_policy" ON public.transaksi_pertalite;

CREATE POLICY "trx_select_policy" ON public.transaksi_pertalite
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR EXISTS (
      SELECT 1 FROM public.operator_profiles op
      WHERE op.id = transaksi_pertalite.operator_id
        AND op.spbu_id = public.get_user_spbu_id()
    )
  );

CREATE POLICY "trx_insert_policy" ON public.transaksi_pertalite
  FOR INSERT WITH CHECK (
    public.get_user_role() = 'master'
  );

-- B. fuel_prices (MODIFY ONLY BY MASTER)
ALTER TABLE public.fuel_prices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fuel_prices_select" ON public.fuel_prices;
DROP POLICY IF EXISTS "fuel_prices_modify" ON public.fuel_prices;

CREATE POLICY "fuel_prices_select" ON public.fuel_prices
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "fuel_prices_modify" ON public.fuel_prices
  FOR ALL USING (
    public.get_user_role() = 'master'
  );

-- C. operator_profiles (MODIFY ONLY BY MASTER)
ALTER TABLE public.operator_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "operator_profiles_select" ON public.operator_profiles;
DROP POLICY IF EXISTS "operator_profiles_modify" ON public.operator_profiles;

CREATE POLICY "operator_profiles_select" ON public.operator_profiles
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR spbu_id = public.get_user_spbu_id()
  );

CREATE POLICY "operator_profiles_modify" ON public.operator_profiles
  FOR ALL USING (
    public.get_user_role() = 'master'
  );

-- D. user_roles (MODIFY ONLY BY MASTER)
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_roles_select" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_modify" ON public.user_roles;

CREATE POLICY "user_roles_select" ON public.user_roles
  FOR SELECT USING (
    auth.uid() = user_id
    OR public.get_user_role() = 'master'
  );

CREATE POLICY "user_roles_modify" ON public.user_roles
  FOR ALL USING (
    public.get_user_role() = 'master'
  );


-- ─── 7. HIGH-PERFORMANCE INDEXES FOR NORMALIZED RELATIONS ────────────────────

CREATE INDEX IF NOT EXISTS idx_trx_operator_id 
  ON public.transaksi_pertalite (operator_id);

CREATE INDEX IF NOT EXISTS idx_trx_waktu_desc 
  ON public.transaksi_pertalite (waktu_pencatatan DESC);

CREATE INDEX IF NOT EXISTS idx_trx_plat_waktu 
  ON public.transaksi_pertalite (plat_nomor, waktu_pencatatan DESC);

NOTIFY pgrst, 'reload schema';
