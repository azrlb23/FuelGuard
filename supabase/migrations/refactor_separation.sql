-- =============================================================================
-- SQL Migration: Refactor Separation of Concerns
-- Moves business logic, data aggregation, and access control to PostgreSQL
-- 
-- Prerequisites:
--   - Table `fuel_prices` exists (spbu_id, fuel_type, price_per_liter)
--   - Table `shift_config` exists (spbu_id, shift_name, start_time, end_time)
--   - Table `user_roles` exists (user_id, role, spbu_id)
--   - Table `transaksi_pertalite` exists
--   - Table `spbu` exists (id, nama, alamat, manajer_id)
--   - Table `activity_logs` exists (user_id, action, details, timestamp)
--   - Table `support_tickets` exists (user_id, ...)
--   - View `team_members` exists (spbu_id, ...)
--   - Function `get_user_role()` already exists in database
-- =============================================================================


-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. HELPER FUNCTION: get_user_spbu_id()
-- ═══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.get_user_spbu_id() CASCADE;

CREATE OR REPLACE FUNCTION public.get_user_spbu_id()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT spbu_id FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_spbu_id() TO authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. RPC: fn_check_plate_status(p_plat, p_jenis, p_spbu_id)
--    Mengecek status kuota pengisian BBM kendaraan hari ini (GLOBAL LINTAS CABANG)
-- ═══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.fn_check_plate_status(text, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.fn_check_plate_status(text, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.fn_check_plate_status(text, text) CASCADE;
DROP FUNCTION IF EXISTS public.fn_check_plate_status(text) CASCADE;

CREATE OR REPLACE FUNCTION public.fn_check_plate_status(
  p_plat text,
  p_jenis text DEFAULT 'Motor',
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
  v_is_motor boolean;
  v_last_trx json := NULL;
  v_last_time text := '';
BEGIN
  -- Resolve spbu_id
  v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());
  
  IF v_spbu_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_spbu');
  END IF;

  v_is_motor := LOWER(p_jenis) = 'motor';

  -- Hitung total HARGA dan LITER secara GLOBAL (lintas cabang SPBU)
  SELECT 
    COALESCE(SUM(liter), 0),
    COALESCE(SUM(harga), 0),
    COUNT(id)
  INTO v_total_liter_today, v_total_harga_today, v_count_today
  FROM public.transaksi_pertalite
  WHERE plat_nomor = UPPER(TRIM(p_plat))
    AND waktu_pencatatan >= date_trunc('day', NOW())
    AND waktu_pencatatan < date_trunc('day', NOW()) + INTERVAL '1 day';

  -- Tentukan apakah sudah melebihi batas nominal Rp 50.000 untuk Motor (1x untuk Mobil)
  IF v_is_motor THEN
    v_has_refueled := v_total_harga_today >= 50000;
    v_remaining_quota := GREATEST(0, 50000 - v_total_harga_today);
  ELSE
    v_has_refueled := v_count_today > 0;
    v_remaining_quota := 0;
  END IF;

  -- Ambil transaksi terakhir lintas cabang
  IF v_count_today > 0 THEN
    SELECT json_build_object(
      'id', id,
      'liter', liter,
      'harga', harga,
      'waktu_pencatatan', waktu_pencatatan,
      'jenis_kendaraan', jenis_kendaraan
    )
    INTO v_last_trx
    FROM public.transaksi_pertalite
    WHERE plat_nomor = UPPER(TRIM(p_plat))
      AND waktu_pencatatan >= date_trunc('day', NOW())
      AND waktu_pencatatan < date_trunc('day', NOW()) + INTERVAL '1 day'
    ORDER BY waktu_pencatatan DESC
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

GRANT EXECUTE ON FUNCTION public.fn_check_plate_status(text, text, text) TO authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. RPC: fn_safe_insert_transaction(p_plat, p_liter, p_jenis, p_shift)
--    Server-side price calculation + atomic quota enforcement (GLOBAL LINTAS CABANG)
-- ═══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.fn_safe_insert_transaction(text, numeric, text, integer) CASCADE;
DROP FUNCTION IF EXISTS public.fn_safe_insert_transaction(text, numeric, text, integer, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.fn_safe_insert_transaction(text, numeric, text) CASCADE;
DROP FUNCTION IF EXISTS public.fn_safe_insert_transaction(text, numeric) CASCADE;

CREATE OR REPLACE FUNCTION public.fn_safe_insert_transaction(
  p_plat text,
  p_liter numeric,
  p_jenis text DEFAULT 'Motor',
  p_shift integer DEFAULT 1
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_spbu_id text;
  v_user_id uuid;
  v_user_email text;
  v_plat_clean text;
  v_harga_per_liter numeric;
  v_total_harga numeric;
  v_total_harga_today numeric;
  v_count_today integer;
  v_is_motor boolean;
  v_new_id bigint;
BEGIN
  v_user_id := auth.uid();
  v_spbu_id := public.get_user_spbu_id();
  v_plat_clean := UPPER(TRIM(p_plat));
  v_is_motor := LOWER(p_jenis) = 'motor';

  IF v_spbu_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_spbu', 'message', 'SPBU tidak ditemukan untuk user ini.');
  END IF;

  -- Validasi input
  IF v_plat_clean = '' OR p_liter <= 0 THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_input', 'message', 'Plat nomor dan liter harus valid.');
  END IF;

  -- Ambil harga per liter dari tabel fuel_prices (server-side, anti-tamper)
  SELECT price_per_liter INTO v_harga_per_liter
  FROM public.fuel_prices
  WHERE spbu_id = v_spbu_id
    AND LOWER(fuel_type) LIKE '%pertalite%'
  ORDER BY updated_at DESC NULLS LAST
  LIMIT 1;

  -- Fallback jika tidak ada data harga
  IF v_harga_per_liter IS NULL OR v_harga_per_liter <= 0 THEN
    v_harga_per_liter := 10000;
  END IF;

  v_total_harga := p_liter * v_harga_per_liter;

  -- ── ATOMIC QUOTA CHECK (Row lock to prevent race condition) ──
  PERFORM id FROM public.transaksi_pertalite
  WHERE plat_nomor = v_plat_clean
    AND waktu_pencatatan >= date_trunc('day', NOW())
    AND waktu_pencatatan < date_trunc('day', NOW()) + INTERVAL '1 day'
  FOR UPDATE;

  -- Hitung total harga transaksi hari ini LINTAS CABANG (secara GLOBAL)
  SELECT 
    COALESCE(SUM(harga), 0),
    COUNT(id)
  INTO v_total_harga_today, v_count_today
  FROM public.transaksi_pertalite
  WHERE plat_nomor = v_plat_clean
    AND waktu_pencatatan >= date_trunc('day', NOW())
    AND waktu_pencatatan < date_trunc('day', NOW()) + INTERVAL '1 day';

  -- Enforce kuota (Motor max Rp 50.000/hari global, Mobil max 1x/hari global)
  IF v_is_motor THEN
    IF (v_total_harga_today + v_total_harga) > 50000 THEN
      RETURN json_build_object(
        'success', false,
        'reason', 'quota_exceeded',
        'message', format('Kuota Motor (Rp 50.000/hari) terlampaui! Pengisian hari ini: Rp %s.', v_total_harga_today)
      );
    END IF;
  ELSE
    IF v_count_today > 0 THEN
      RETURN json_build_object(
        'success', false,
        'reason', 'already_refueled',
        'message', 'Kendaraan Mobil hanya boleh mengisi BBM 1x per hari (lintas cabang)!'
      );
    END IF;
  END IF;

  -- Ambil email user
  SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;

  -- INSERT transaksi
  INSERT INTO public.transaksi_pertalite (
    plat_nomor, liter, harga, jenis_kendaraan, shift,
    operator_id, operator_email, spbu_id, waktu_pencatatan
  ) VALUES (
    v_plat_clean, p_liter, v_total_harga, p_jenis, p_shift,
    v_user_id, v_user_email, v_spbu_id, NOW()
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

GRANT EXECUTE ON FUNCTION public.fn_safe_insert_transaction(text, numeric, text, integer) TO authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. RPC: get_dashboard_summary(p_filter, p_spbu_id)
--    Full aggregation in SQL — replaces all JS .reduce() calls
-- ═══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.get_dashboard_summary() CASCADE;
DROP FUNCTION IF EXISTS public.get_dashboard_summary(text) CASCADE;
DROP FUNCTION IF EXISTS public.get_dashboard_summary(text, text) CASCADE;
DROP FUNCTION IF EXISTS public.get_dashboard_summary(text, uuid) CASCADE;

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
  v_shift_chart json;
  v_vehicle_chart json;
  v_peak_hours json;
  v_loyal_customers json;
  v_trend_7_days json;
  v_revenue_share json;
BEGIN
  v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());

  -- Determine time filter
  IF p_filter = 'today' THEN
    v_start_time := date_trunc('day', NOW());
  ELSIF p_filter = 'weekly' THEN
    v_start_time := NOW() - INTERVAL '7 days';
  ELSIF p_filter = 'monthly' THEN
    v_start_time := NOW() - INTERVAL '30 days';
  ELSE
    v_start_time := '1970-01-01'::timestamp;
  END IF;

  -- ── 1. Stats ──
  SELECT json_build_object(
    'volume', COALESCE(SUM(liter), 0),
    'revenue', COALESCE(SUM(harga), 0),
    'vehicle', COUNT(id),
    'volume_growth', 0,
    'revenue_growth', 0
  ) INTO v_stats
  FROM public.transaksi_pertalite
  WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
    AND waktu_pencatatan >= v_start_time;

  -- ── 2. Live Feed (10 terbaru) ──
  SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) INTO v_feed
  FROM (
    SELECT id, plat_nomor, liter, harga, jenis_kendaraan, waktu_pencatatan, operator_email
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
    ORDER BY waktu_pencatatan DESC
    LIMIT 10
  ) t;

  -- Jika feed kosong dan filter=today, ambil 10 terakhir tanpa filter waktu
  IF (v_feed IS NULL OR v_feed::text = '[]') AND p_filter = 'today' THEN
    SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) INTO v_feed
    FROM (
      SELECT id, plat_nomor, liter, harga, jenis_kendaraan, waktu_pencatatan, operator_email
      FROM public.transaksi_pertalite
      WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      ORDER BY waktu_pencatatan DESC
      LIMIT 10
    ) t;
  END IF;

  -- ── 3. Shift Chart ──
  SELECT COALESCE(json_agg(json_build_object('shift', s.shift_num, 'count', COALESCE(c.cnt, 0))), '[]'::json)
  INTO v_shift_chart
  FROM (VALUES (1), (2), (3)) AS s(shift_num)
  LEFT JOIN (
    SELECT
      CASE
        WHEN EXTRACT(HOUR FROM waktu_pencatatan) >= 6 AND EXTRACT(HOUR FROM waktu_pencatatan) < 14 THEN 1
        WHEN EXTRACT(HOUR FROM waktu_pencatatan) >= 14 AND EXTRACT(HOUR FROM waktu_pencatatan) < 22 THEN 2
        ELSE 3
      END AS shift_num,
      COUNT(*) AS cnt
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
    GROUP BY 1
  ) c ON c.shift_num = s.shift_num;

  -- ── 4. Vehicle Chart ──
  SELECT COALESCE(json_agg(json_build_object('label', jenis_kendaraan, 'count', cnt)), '[]'::json)
  INTO v_vehicle_chart
  FROM (
    SELECT COALESCE(jenis_kendaraan, 'Umum') AS jenis_kendaraan, COUNT(*) AS cnt
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
    GROUP BY jenis_kendaraan
  ) sub;

  -- ── 5. Peak Hours ──
  SELECT COALESCE(json_agg(json_build_object('hour', h, 'count', cnt) ORDER BY h), '[]'::json)
  INTO v_peak_hours
  FROM (
    SELECT EXTRACT(HOUR FROM waktu_pencatatan)::integer AS h, COUNT(*) AS cnt
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
    GROUP BY 1
  ) sub;

  -- ── 6. Loyal Customers (Top 5 by volume) ──
  SELECT COALESCE(json_agg(json_build_object(
    'plat_nomor', plat_nomor,
    'total_trx', total_trx,
    'total_liter', total_liter
  )), '[]'::json)
  INTO v_loyal_customers
  FROM (
    SELECT plat_nomor, COUNT(*) AS total_trx, SUM(liter) AS total_liter
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
      AND plat_nomor IS NOT NULL AND plat_nomor <> ''
    GROUP BY plat_nomor
    ORDER BY total_liter DESC
    LIMIT 5
  ) sub;

  -- ── 7. Trend 7 Hari ──
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
    SELECT waktu_pencatatan::date AS trx_date, SUM(harga) AS total_revenue
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= date_trunc('day', NOW()) - INTERVAL '6 days'
    GROUP BY 1
  ) t ON t.trx_date = days.d;

  -- ── 8. Revenue Share by Vehicle Type ──
  SELECT COALESCE(json_agg(json_build_object('label', jenis_kendaraan, 'total', total_rev)), '[]'::json)
  INTO v_revenue_share
  FROM (
    SELECT COALESCE(jenis_kendaraan, 'Umum') AS jenis_kendaraan, SUM(harga) AS total_rev
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
    GROUP BY jenis_kendaraan
  ) sub;

  -- Build final JSON
  RETURN json_build_object(
    'stats', v_stats,
    'feed', v_feed,
    'shift_chart', v_shift_chart,
    'vehicle_chart', v_vehicle_chart,
    'peak_hours', v_peak_hours,
    'loyal_customers', v_loyal_customers,
    'trend_7_days', v_trend_7_days,
    'ticket_size', '[]'::json,
    'revenue_share', v_revenue_share
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_dashboard_summary(text, text) TO authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. RPC: get_export_transactions(p_start_date, p_end_date, p_spbu_id)
--    Returns all transactions in date range in a single query (replaces looping)
-- ═══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.get_export_transactions(text, text) CASCADE;
DROP FUNCTION IF EXISTS public.get_export_transactions(text, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.get_export_transactions(text, text, uuid) CASCADE;

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
    SELECT id, waktu_pencatatan, jenis_kendaraan, plat_nomor, liter, harga, operator_id
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= (p_start_date || 'T00:00:00')::timestamp
      AND waktu_pencatatan <= (p_end_date || 'T23:59:59')::timestamp
    ORDER BY waktu_pencatatan ASC
  ) t;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_export_transactions(text, text, text) TO authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── 6a. transaksi_pertalite ──
ALTER TABLE public.transaksi_pertalite ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "trx_select_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_insert_policy" ON public.transaksi_pertalite;

CREATE POLICY "trx_select_policy" ON public.transaksi_pertalite
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR spbu_id = public.get_user_spbu_id()
  );

-- Direct INSERT dari Client SDK dilarang untuk Operator (harus lewat RPC fn_safe_insert_transaction)
CREATE POLICY "trx_insert_policy" ON public.transaksi_pertalite
  FOR INSERT WITH CHECK (
    public.get_user_role() = 'master'
  );

-- ── 6b. fuel_prices ──
ALTER TABLE public.fuel_prices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "fuel_prices_select" ON public.fuel_prices;
DROP POLICY IF EXISTS "fuel_prices_modify" ON public.fuel_prices;

CREATE POLICY "fuel_prices_select" ON public.fuel_prices
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "fuel_prices_modify" ON public.fuel_prices
  FOR ALL USING (
    public.get_user_role() IN ('manajer', 'master')
  );

-- ── 6c. shift_config ──
ALTER TABLE public.shift_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "shift_config_select" ON public.shift_config;
DROP POLICY IF EXISTS "shift_config_modify" ON public.shift_config;

CREATE POLICY "shift_config_select" ON public.shift_config
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "shift_config_modify" ON public.shift_config
  FOR ALL USING (
    public.get_user_role() IN ('manajer', 'master')
  );

-- ── 6d. team_members (VIEW — RLS dikontrol via tabel dasar user_roles) ──
-- (Catatan: team_members adalah VIEW, RLS tidak diterapkan langsung pada VIEW)

-- ── 6e. support_tickets ──
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "support_tickets_select" ON public.support_tickets;
DROP POLICY IF EXISTS "support_tickets_insert" ON public.support_tickets;

CREATE POLICY "support_tickets_select" ON public.support_tickets
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR user_id = auth.uid()
  );

CREATE POLICY "support_tickets_insert" ON public.support_tickets
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- ── 6f. user_roles (Proteksi Privilege Escalation) ──
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


-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. AUDIT TRAIL TRIGGER
-- ═══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.fn_audit_transaction() CASCADE;

CREATE OR REPLACE FUNCTION public.fn_audit_transaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.activity_logs (user_email, action, details, timestamp)
  VALUES (
    NEW.operator_email,
    'INSERT_TRANSACTION',
    json_build_object(
      'transaction_id', NEW.id,
      'plat_nomor', NEW.plat_nomor,
      'liter', NEW.liter,
      'harga', NEW.harga,
      'jenis_kendaraan', NEW.jenis_kendaraan,
      'spbu_id', NEW.spbu_id
    )::jsonb,
    NOW()
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_transaction ON public.transaksi_pertalite;

CREATE TRIGGER trg_audit_transaction
  AFTER INSERT ON public.transaksi_pertalite
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_audit_transaction();


-- ═══════════════════════════════════════════════════════════════════════════════
-- 8. PERMISSIONS & SCHEMA REFRESH
-- ═══════════════════════════════════════════════════════════════════════════════
NOTIFY pgrst, 'reload schema';
