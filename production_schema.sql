-- =============================================================================
-- FULL PRODUCTION SCHEMA - FUELGUARD
-- =============================================================================

-- ─── 1. EXTENSIONS ───────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── 2. CREATE TABLES (IN DEPENDENCY ORDER) ──────────────────────────────────

CREATE TABLE IF NOT EXISTS public.spbu (
  id text NOT NULL,
  nama text,
  alamat text,
  CONSTRAINT spbu_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.region_codes (
  code text NOT NULL,
  region_name text NOT NULL,
  CONSTRAINT region_codes_pkey PRIMARY KEY (code)
);

CREATE TABLE IF NOT EXISTS public.activity_logs (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  timestamp timestamp with time zone NOT NULL DEFAULT now(),
  user_email text,
  action text NOT NULL,
  details jsonb,
  CONSTRAINT activity_logs_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.operator_profiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  spbu_id text NOT NULL,
  nama_operator text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT operator_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT operator_profiles_spbu_id_fkey FOREIGN KEY (spbu_id) REFERENCES public.spbu(id) ON DELETE CASCADE,
  CONSTRAINT unique_spbu_operator UNIQUE (spbu_id, nama_operator)
);

CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id uuid NOT NULL,
  role text NOT NULL,
  spbu_id text,
  CONSTRAINT user_roles_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_roles_spbu_id_fkey FOREIGN KEY (spbu_id) REFERENCES public.spbu(id),
  CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

CREATE TABLE IF NOT EXISTS public.support_tickets (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  user_id uuid NOT NULL,
  kategori text NOT NULL,
  prioritas text NOT NULL,
  subjek text NOT NULL,
  deskripsi text NOT NULL,
  status text DEFAULT 'Open'::text,
  spbu_id text,
  CONSTRAINT support_tickets_pkey PRIMARY KEY (id),
  CONSTRAINT support_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT support_tickets_spbu_id_fkey FOREIGN KEY (spbu_id) REFERENCES public.spbu(id)
);

CREATE TABLE IF NOT EXISTS public.fuel_prices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  fuel_type text NOT NULL,
  price_per_liter numeric NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid,
  spbu_id text,
  CONSTRAINT fuel_prices_pkey PRIMARY KEY (id),
  CONSTRAINT fuel_prices_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id),
  CONSTRAINT fuel_prices_spbu_id_fkey FOREIGN KEY (spbu_id) REFERENCES public.spbu(id)
);

CREATE TABLE IF NOT EXISTS public.transaksi_pertalite (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  plat_nomor text NOT NULL,
  liter numeric NOT NULL,
  harga bigint NOT NULL,
  waktu_pencatatan timestamp with time zone NOT NULL DEFAULT now(),
  operator_id uuid,
  is_ojol boolean DEFAULT false,
  CONSTRAINT transaksi_pertalite_pkey PRIMARY KEY (id),
  CONSTRAINT transaksi_pertalite_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.operator_profiles(id)
);

-- ─── 3. SEED INITIAL DATA ────────────────────────────────────────────────────

INSERT INTO public.region_codes (code, region_name) VALUES
('A', 'Banten (Serang, Cilegon, Pandeglang, Lebak, Tangerang Kab)'),
('B', 'DKI Jakarta, Bekasi, Depok, Tangerang'),
('D', 'Bandung, Cimahi, Bandung Barat'),
('E', 'Cirebon, Indramayu, Majalengka, Kuningan'),
('F', 'Bogor, Sukabumi, Cianjur'),
('T', 'Purwakarta, Karawang, Subang'),
('Z', 'Garut, Tasikmalaya, Ciamis, Banjar, Pangandaran'),
('G', 'Pekalongan, Tegal, Brebes, Batang, Pemalang'),
('H', 'Semarang, Salatiga, Kendal, Demak'),
('K', 'Pati, Kudus, Jepara, Rembang, Blora, Grobogan'),
('R', 'Banyumas, Cilacap, Purbalingga, Banjarnegara'),
('AA', 'Magelang, Purworejo, Kebumen, Temanggung, Wonosobo'),
('AB', 'DI Yogyakarta'),
('AD', 'Surakarta, Boyolali, Sukoharjo, Karanganyar, Wonogiri, Sragen, Klaten'),
('AE', 'Madiun, Ngawi, Magetan, Ponorogo, Pacitan'),
('AG', 'Kediri, Blitar, Tulungagung, Nganjuk, Trenggalek'),
('L', 'Surabaya'),
('M', 'Madura (Bangkalan, Sampang, Pamekasan, Sumenep)'),
('N', 'Malang, Probolinggo, Pasuruan, Lumajang, Batu'),
('P', 'Jember, Banyuwangi, Bondowoso, Situbondo'),
('S', 'Bojonegoro, Tuban, Lamongan, Mojokerto, Jombang'),
('W', 'Sidoarjo, Gresik'),
('BL', 'Aceh'),
('BB', 'Sumatera Utara Barat (Tapanuli, Nias, Sibolga)'),
('BK', 'Sumatera Utara Timur (Medan, Deli Serdang, Asahan)'),
('BA', 'Sumatera Barat'),
('BM', 'Riau'),
('BP', 'Kepulauan Riau (Batam, Tanjungpinang)'),
('BG', 'Sumatera Selatan'),
('BN', 'Kepulauan Bangka Belitung'),
('BE', 'Lampung'),
('BD', 'Bengkulu'),
('BH', 'Jambi'),
('KB', 'Kalimantan Barat'),
('DA', 'Kalimantan Selatan'),
('KH', 'Kalimantan Tengah'),
('KT', 'Kalimantan Timur'),
('KU', 'Kalimantan Utara'),
('DB', 'Sulawesi Utara (Manado, Bitung, Tomohon)'),
('DL', 'Sulawesi Utara Kepulauan (Sangihe, Talaud)'),
('DM', 'Gorontalo'),
('DN', 'Sulawesi Tengah'),
('DT', 'Sulawesi Tenggara'),
('DD', 'Sulawesi Selatan (Makassar, Gowa, Maros)'),
('DP', 'Sulawesi Selatan Bagian Utara (Parepare, Luwu)'),
('DC', 'Sulawesi Barat'),
('DK', 'Bali'),
('DR', 'Lombok (NTB)'),
('EA', 'Sumbawa (NTB)'),
('DH', 'Timor (NTT / Kupang)'),
('EB', 'Flores (NTT)'),
('ED', 'Sumba (NTT)'),
('DE', 'Maluku'),
('DG', 'Maluku Utara'),
('DS', 'Papua (Induk)'),
('PA', 'Papua Barat / Papua Pusat'),
('PB', 'Papua Barat Daya')
ON CONFLICT (code) DO UPDATE SET region_name = EXCLUDED.region_name;

-- ─── 4. INDEXES FOR PERFORMANCE ──────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_trx_plat_waktu 
  ON public.transaksi_pertalite (plat_nomor, waktu_pencatatan DESC);

CREATE INDEX IF NOT EXISTS idx_trx_operator_waktu
  ON public.transaksi_pertalite (operator_id, waktu_pencatatan DESC);

CREATE INDEX IF NOT EXISTS idx_operator_profiles_spbu 
  ON public.operator_profiles (spbu_id, is_active);

-- =============================================================================
-- SQL Migration: 02_security_and_rls.sql
-- Description: Row Level Security (RLS) policies and Audit Triggers.
-- Architecture: Shared Device (Multi-Operator)
--   - operator_id di transaksi_pertalite merujuk ke operator_profiles(id)
--   - RLS SELECT untuk operator: cek apakah transaksi dilakukan di SPBU yang sama
--     via sub-query EXISTS ke operator_profiles
-- =============================================================================

-- ─── 1. AUDIT TRAIL TRIGGER ──────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.fn_audit_transaction CASCADE;
CREATE OR REPLACE FUNCTION public.fn_audit_transaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_operator_name text;
  v_spbu_name text;
  v_enriched_details jsonb;
BEGIN
  -- Ambil nama kasir asli dan nama SPBU dari relasi
  SELECT op.nama_operator, s.nama
  INTO v_operator_name, v_spbu_name
  FROM public.operator_profiles op
  JOIN public.spbu s ON s.id = op.spbu_id
  WHERE op.id = NEW.operator_id;

  -- Sisipkan data tambahan ke dalam JSON details
  v_enriched_details := row_to_json(NEW)::jsonb || jsonb_build_object(
    'operator_name', COALESCE(v_operator_name, 'Unknown'),
    'spbu_name', COALESCE(v_spbu_name, 'Unknown')
  );

  INSERT INTO public.activity_logs (user_email, action, details, timestamp)
  VALUES (
    COALESCE(v_operator_name, 'System') || ' (' || COALESCE(v_spbu_name, 'Unknown') || ')',
    'INSERT_TRANSACTION',
    v_enriched_details,
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


-- ─── 2. RLS: TRANSAKSI_PERTALITE ─────────────────────────────────────────────
ALTER TABLE public.transaksi_pertalite ENABLE ROW LEVEL SECURITY;

-- Drop all old policies to prevent conflicts
DROP POLICY IF EXISTS "Akses baca berdasarkan jabatan dan lokasi SPBU" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_select_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_insert_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "Operator insert policy" ON public.transaksi_pertalite;

-- SELECT: Master bisa lihat semua, Operator hanya lihat transaksi di SPBU-nya
-- Logika: Cek apakah operator_id transaksi menunjuk ke operator_profiles yang
-- spbu_id-nya sama dengan spbu_id akun login (dari user_roles)
CREATE POLICY "trx_select_policy" ON public.transaksi_pertalite
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR EXISTS (
      SELECT 1 FROM public.operator_profiles op
      WHERE op.id = transaksi_pertalite.operator_id
        AND op.spbu_id = public.get_user_spbu_id()
    )
  );

-- INSERT: Operator bisa insert (fungsi RPC SECURITY DEFINER yang melakukan insert)
-- Master juga bisa insert untuk keperluan administratif
CREATE POLICY "trx_insert_policy" ON public.transaksi_pertalite
  FOR INSERT WITH CHECK (
    public.get_user_role() = 'master'
  );

-- ─── 5. RLS: USER_ROLES ──────────────────────────────────────────────────────
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

-- ─── 6. RLS: OPERATOR_PROFILES ───────────────────────────────────────────────
ALTER TABLE public.operator_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "operator_profiles_select" ON public.operator_profiles;
DROP POLICY IF EXISTS "operator_profiles_modify" ON public.operator_profiles;

CREATE POLICY "operator_profiles_select" ON public.operator_profiles
  FOR SELECT USING (
    auth.uid() IS NOT NULL
  );

CREATE POLICY "operator_profiles_modify" ON public.operator_profiles
  FOR ALL USING (
    public.get_user_role() = 'master'
  )
  WITH CHECK (
    public.get_user_role() = 'master'
  );

-- ─── 7. RLS: SPBU ────────────────────────────────────────────────────────────
ALTER TABLE public.spbu ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "spbu_select" ON public.spbu;
DROP POLICY IF EXISTS "spbu_modify" ON public.spbu;

CREATE POLICY "spbu_select" ON public.spbu
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "spbu_modify" ON public.spbu
  FOR ALL USING (public.get_user_role() = 'master')
  WITH CHECK (public.get_user_role() = 'master');

-- ─── 8. RLS: REGION_CODES ────────────────────────────────────────────────────
ALTER TABLE public.region_codes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "region_codes_select" ON public.region_codes;
DROP POLICY IF EXISTS "region_codes_modify" ON public.region_codes;

CREATE POLICY "region_codes_select" ON public.region_codes
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "region_codes_modify" ON public.region_codes
  FOR ALL USING (public.get_user_role() = 'master')
  WITH CHECK (public.get_user_role() = 'master');

-- ─── 9. RLS: ACTIVITY_LOGS ───────────────────────────────────────────────────
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "activity_logs_select" ON public.activity_logs;

CREATE POLICY "activity_logs_select" ON public.activity_logs
  FOR SELECT USING (public.get_user_role() = 'master');

NOTIFY pgrst, 'reload schema';
-- =============================================================================
-- SQL Migration: 03_auth_helpers.sql
-- Description: Helper functions for role and SPBU resolution.
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_user_role CASCADE;
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
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
SET search_path = public
STABLE
STABLE
AS $$
  SELECT spbu_id FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.get_user_spbu_id() TO authenticated;
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
SET search_path = public
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
  IF public.get_user_role() = 'master' THEN
    v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());
  ELSE
    v_spbu_id := public.get_user_spbu_id();
  END IF;

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
SET search_path = public
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
  SELECT spbu_id INTO v_spbu_id FROM public.operator_profiles WHERE id = p_operator_id AND is_active = true;
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
SET search_path = public
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
  IF public.get_user_role() = 'master' THEN
    v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());
  ELSE
    v_spbu_id := public.get_user_spbu_id();
  END IF;

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
SET search_path = public
AS $$
DECLARE
  v_spbu_id text;
  v_result json;
BEGIN
  IF public.get_user_role() = 'master' THEN
    v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());
  ELSE
    v_spbu_id := public.get_user_spbu_id();
  END IF;

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
-- =============================================================================
-- SQL Migration: 05_master_rpcs.sql
-- Description: RPCs for Master Dashboard (Shared Device / Multi-Operator)
-- Architecture:
--   - operator_id di transaksi_pertalite merujuk ke operator_profiles(id)
--   - SPBU didapat via JOIN: transaksi_pertalite.operator_id -> operator_profiles.spbu_id
-- =============================================================================

-- ─── 1. FUNCTION: get_master_dashboard_summary ──────────────────────────────
DROP FUNCTION IF EXISTS public.get_master_dashboard_summary CASCADE;
CREATE OR REPLACE FUNCTION public.get_master_dashboard_summary(p_filter text DEFAULT 'today')
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $
DECLARE
  v_start_time timestamp;
  v_total_revenue numeric := 0;
  v_total_volume numeric := 0;
  v_active_spbu_count integer := 0;
  v_today_trx_count integer := 0;
  v_weekly_volume json;
  v_spbu_list json;
  v_alerts json;
  v_result json;
BEGIN         
  IF p_filter = 'today' THEN
    v_start_time := date_trunc('day', NOW());
  ELSIF p_filter = 'weekly' THEN
    v_start_time := NOW() - INTERVAL '7 days';
  ELSIF p_filter = 'monthly' THEN
    v_start_time := NOW() - INTERVAL '30 days';
  ELSE
    v_start_time := '1970-01-01 00:00:00'::timestamp; -- 'all-time'
  END IF;

  -- Overall Stats (all SPBUs)
  SELECT 
    COALESCE(SUM(harga), 0),
    COALESCE(SUM(liter), 0),
    COUNT(id)
  INTO 
    v_total_revenue,
    v_total_volume,
    v_today_trx_count
  FROM public.transaksi_pertalite
  WHERE waktu_pencatatan >= v_start_time;

  SELECT COUNT(id) INTO v_active_spbu_count FROM public.spbu;

  -- 7-Day Weekly Volume (OPTIMIZED: No FULL TABLE SCAN)
  WITH days AS (
    SELECT generate_series(
      date_trunc('day', NOW()) - INTERVAL '6 days',
      date_trunc('day', NOW()),
      INTERVAL '1 day'
    )::date AS d
  ),
  daily_sums AS (
    SELECT 
      date_trunc('day', waktu_pencatatan)::date AS d,
      SUM(liter) AS total_liter
    FROM public.transaksi_pertalite
    WHERE waktu_pencatatan >= date_trunc('day', NOW()) - INTERVAL '6 days'
    GROUP BY 1
  )
  SELECT json_agg(COALESCE(ds.total_liter, 0) ORDER BY days.d) 
  INTO v_weekly_volume 
  FROM days
  LEFT JOIN daily_sums ds ON ds.d = days.d;

  -- 10 Recent Transactions per SPBU (via operator_profiles)
  WITH recent_trx_ranked AS (
    SELECT 
      t.id,
      t.plat_nomor,
      t.liter,
      t.harga,
      t.waktu_pencatatan,
      op.spbu_id,
      ROW_NUMBER() OVER (
        PARTITION BY op.spbu_id 
        ORDER BY t.waktu_pencatatan DESC
      ) as rn
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE t.waktu_pencatatan >= v_start_time
  ),
  recent_trx_json AS (
    SELECT 
      spbu_id,
      json_agg(
        json_build_object(
          'id', id,
          'plat_nomor', plat_nomor,
          'liter', liter,
          'harga', harga,
          'waktu_pencatatan', waktu_pencatatan
        ) ORDER BY waktu_pencatatan DESC
      ) AS transactions
    FROM recent_trx_ranked
    WHERE rn <= 10
    GROUP BY spbu_id
  ),
  -- SPBU Performance Stats
  spbu_stats AS (
    SELECT 
      op.spbu_id,
      COALESCE(SUM(t.harga), 0) AS revenue,
      COALESCE(SUM(t.liter), 0) AS volume,
      COUNT(t.id) AS trx_count
    FROM public.operator_profiles op
    LEFT JOIN public.transaksi_pertalite t 
      ON t.operator_id = op.id AND t.waktu_pencatatan >= v_start_time
    GROUP BY op.spbu_id
  )
  -- Combine into SPBU List
  SELECT json_agg(
    json_build_object(
      'id', s.id,
      'name', s.nama,
      'location', s.alamat,
      'revenue', COALESCE(st.revenue, 0),
      'volume', COALESCE(st.volume, 0),
      'trxCount', COALESCE(st.trx_count, 0),
      'recentTransactions', COALESCE(rt.transactions, '[]'::json)
    )
  )
  INTO v_spbu_list
  FROM public.spbu s
  LEFT JOIN spbu_stats st ON st.spbu_id = s.id
  LEFT JOIN recent_trx_json rt ON rt.spbu_id = s.id;

  -- Active Alerts (Mocked for now)
  v_alerts := '[
    {"id": 1, "type": "warning", "message": "SPBU #2 mengalami lonjakan transaksi mendadak.", "time": "10 menit yang lalu"},
    {"id": 2, "type": "info", "message": "Laporan mingguan telah siap diunduh.", "time": "1 jam yang lalu"}
  ]'::json;

  v_result := json_build_object(
    'stats', json_build_object(
      'totalRevenue', v_total_revenue,
      'totalVolume', v_total_volume,
      'activeSpbuCount', v_active_spbu_count,
      'todayTrxCount', v_today_trx_count
    ),
    'weekly_volume', v_weekly_volume,
    'spbu_list', COALESCE(v_spbu_list, '[]'::json),
    'alerts', v_alerts
  );

  RETURN v_result;
END;
$;
GRANT EXECUTE ON FUNCTION public.get_master_dashboard_summary(text) TO authenticated;


-- ─── 2. FUNCTION: get_master_analytics_summary ───────────────────────────────
DROP FUNCTION IF EXISTS public.get_master_analytics_summary CASCADE;
CREATE OR REPLACE FUNCTION public.get_master_analytics_summary(
  p_date_from text DEFAULT '',
  p_date_to text DEFAULT '',
  p_spbu_id text DEFAULT ''
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_sales numeric := 0;
  v_total_volume numeric := 0;
  v_total_trx integer := 0;
  v_days_count integer := 1;
  v_avg_trx_per_day numeric := 0;
  v_trend_json json;
  v_spbu_shares_json json;
  v_leaderboard_json json;
  v_result json;
BEGIN
  -- 1. Total KPIs
  SELECT 
    COALESCE(SUM(t.harga), 0),
    COALESCE(SUM(t.liter), 0),
    COUNT(t.id)
  INTO 
    v_total_sales,
    v_total_volume,
    v_total_trx
  FROM public.transaksi_pertalite t
  LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (p_spbu_id = '' OR op.spbu_id::text = p_spbu_id)
    AND (p_date_from = '' OR t.waktu_pencatatan >= (p_date_from || 'T00:00:00')::timestamp)
    AND (p_date_to = '' OR t.waktu_pencatatan <= (p_date_to || 'T23:59:59')::timestamp);

  IF p_date_from <> '' AND p_date_to <> '' THEN
    v_days_count := GREATEST((p_date_to::date - p_date_from::date) + 1, 1);
  ELSE
    v_days_count := 30;
  END IF;
  
  v_avg_trx_per_day := ROUND(v_total_trx::numeric / v_days_count::numeric, 1);

  -- 2. Daily Sales & Volume Trend
  WITH daily_trend AS (
    SELECT 
      t.waktu_pencatatan::date AS date_val,
      COALESCE(SUM(t.harga), 0) AS sales,
      COALESCE(SUM(t.liter), 0) AS volume
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (p_spbu_id = '' OR op.spbu_id::text = p_spbu_id)
      AND (p_date_from = '' OR t.waktu_pencatatan >= (p_date_from || 'T00:00:00')::timestamp)
      AND (p_date_to = '' OR t.waktu_pencatatan <= (p_date_to || 'T23:59:59')::timestamp)
    GROUP BY t.waktu_pencatatan::date
    ORDER BY date_val ASC
  )
  SELECT json_agg(
    json_build_object(
      'date', to_char(date_val, 'DD Mon'),
      'sales', sales,
      'volume', volume
    )
  ) INTO v_trend_json FROM daily_trend;

  -- 3. SPBU Contribution Shares
  WITH spbu_totals AS (
    SELECT 
      s.id AS spbu_id,
      COALESCE(s.nama, CONCAT('SPBU #', s.id)) AS spbu_name,
      COALESCE(SUM(t.harga), 0) AS sales,
      COALESCE(SUM(t.liter), 0) AS volume,
      COUNT(t.id) AS total_trx
    FROM public.spbu s
    LEFT JOIN public.operator_profiles op ON op.spbu_id = s.id
    LEFT JOIN public.transaksi_pertalite t 
      ON t.operator_id = op.id
      AND (p_date_from = '' OR t.waktu_pencatatan >= (p_date_from || 'T00:00:00')::timestamp)
      AND (p_date_to = '' OR t.waktu_pencatatan <= (p_date_to || 'T23:59:59')::timestamp)
    WHERE (p_spbu_id = '' OR s.id::text = p_spbu_id)
    GROUP BY s.id, s.nama
    ORDER BY sales DESC
  ),
  spbu_ranked AS (
    SELECT 
      spbu_id,
      spbu_name,
      sales,
      volume,
      total_trx,
      SUM(sales) OVER () AS global_sales,
      (sales / NULLIF(SUM(sales) OVER (), 0)) * 100 AS percentage
    FROM spbu_totals
  )
  SELECT json_agg(
    json_build_object(
      'spbu_id', spbu_id,
      'name', spbu_name,
      'value', ROUND(percentage, 1),
      'sales', sales,
      'volume', volume,
      'trx_count', total_trx
    )
  ) INTO v_spbu_shares_json FROM spbu_ranked WHERE sales > 0;

  -- 4. SPBU Leaderboard
  WITH spbu_totals AS (
    SELECT 
      s.id AS spbu_id,
      COALESCE(s.nama, CONCAT('SPBU #', s.id)) AS name,
      COALESCE(s.alamat, '-') AS location,
      COALESCE(SUM(t.harga), 0) AS revenue,
      COALESCE(SUM(t.liter), 0) AS volume,
      COUNT(t.id) AS trxCount,
      CASE 
        WHEN COUNT(t.id) = 0 THEN 0 
        ELSE SUM(t.harga) / COUNT(t.id) 
      END AS efficiency
    FROM public.spbu s
    LEFT JOIN public.operator_profiles op ON op.spbu_id = s.id
    LEFT JOIN public.transaksi_pertalite t 
      ON t.operator_id = op.id
      AND (p_date_from = '' OR t.waktu_pencatatan >= (p_date_from || 'T00:00:00')::timestamp)
      AND (p_date_to = '' OR t.waktu_pencatatan <= (p_date_to || 'T23:59:59')::timestamp)
    GROUP BY s.id, s.nama, s.alamat
  )
  SELECT json_agg(
    json_build_object(
      'id', spbu_id,
      'name', name,
      'location', location,
      'revenue', revenue,
      'volume', volume,
      'trxCount', trxCount,
      'efficiency', efficiency
    ) ORDER BY revenue DESC
  ) INTO v_leaderboard_json FROM spbu_totals;

  v_result := json_build_object(
    'kpis', json_build_object(
      'totalSales', v_total_sales,
      'totalVolume', v_total_volume,
      'totalTransactions', v_total_trx,
      'avgTrxPerDay', v_avg_trx_per_day
    ),
    'trend', COALESCE(v_trend_json, '[]'::json),
    'spbuShares', COALESCE(v_spbu_shares_json, '[]'::json),
    'leaderboard', COALESCE(v_leaderboard_json, '[]'::json)
  );

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_analytics_summary(text, text, text) TO authenticated;


-- ─── 3. FUNCTION: get_master_history_paginated ───────────────────────────────
DROP FUNCTION IF EXISTS public.get_master_history_paginated CASCADE;
CREATE OR REPLACE FUNCTION public.get_master_history_paginated(
  p_search text DEFAULT '',
  p_spbu_id text DEFAULT '',
  p_date_from text DEFAULT '',
  p_date_to text DEFAULT '',
  p_sort_field text DEFAULT 'waktu_pencatatan',
  p_sort_dir text DEFAULT 'desc',
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 10
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_offset integer;
  v_total_count integer := 0;
  v_trx_list json;
  v_result json;
  v_effective_spbu_id text;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;

  IF public.get_user_role() = 'master' THEN
    v_effective_spbu_id := p_spbu_id;
  ELSE
    v_effective_spbu_id := public.get_user_spbu_id();
  END IF;

  -- Total count
  SELECT COUNT(t.id) INTO v_total_count
  FROM public.transaksi_pertalite t
  LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (p_search = '' OR t.plat_nomor ILIKE '%' || p_search || '%')
    AND (v_effective_spbu_id = '' OR op.spbu_id::text = v_effective_spbu_id)
    AND (p_date_from = '' OR t.waktu_pencatatan >= (p_date_from || 'T00:00:00')::timestamp)
    AND (p_date_to = '' OR t.waktu_pencatatan <= (p_date_to || 'T23:59:59')::timestamp);

  -- Paginated records
  WITH paginated_trx AS (
    SELECT 
      t.id,
      t.plat_nomor,
      t.liter,
      t.harga,
      t.is_ojol,
      t.waktu_pencatatan,
      op.spbu_id,
      COALESCE(s.nama, CONCAT('SPBU #', op.spbu_id)) AS spbu_name,
      COALESCE(op.nama_operator, 'Sistem') AS operator_name
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE (p_search = '' OR t.plat_nomor ILIKE '%' || p_search || '%')
      AND (v_effective_spbu_id = '' OR op.spbu_id::text = v_effective_spbu_id)
      AND (p_date_from = '' OR t.waktu_pencatatan >= (p_date_from || 'T00:00:00')::timestamp)
      AND (p_date_to = '' OR t.waktu_pencatatan <= (p_date_to || 'T23:59:59')::timestamp)
    ORDER BY
      CASE WHEN p_sort_field = 'harga' AND p_sort_dir = 'asc' THEN t.harga END ASC,
      CASE WHEN p_sort_field = 'harga' AND p_sort_dir = 'desc' THEN t.harga END DESC,
      CASE WHEN p_sort_field = 'liter' AND p_sort_dir = 'asc' THEN t.liter END ASC,
      CASE WHEN p_sort_field = 'liter' AND p_sort_dir = 'desc' THEN t.liter END DESC,
      CASE WHEN p_sort_field = 'waktu_pencatatan' AND p_sort_dir = 'asc' THEN t.waktu_pencatatan END ASC,
      CASE WHEN (p_sort_field = 'waktu_pencatatan' OR p_sort_field IS NULL) AND (p_sort_dir = 'desc' OR p_sort_dir IS NULL) THEN t.waktu_pencatatan END DESC
    LIMIT p_page_size OFFSET v_offset
  )
  SELECT json_agg(
    json_build_object(
      'id', id,
      'plat_nomor', plat_nomor,
      'liter', liter,
      'harga', harga,
      'is_ojol', is_ojol,
      'waktu_pencatatan', waktu_pencatatan,
      'spbu_id', spbu_id,
      'spbu_name', spbu_name,
      'operator_name', operator_name
    )
  ) INTO v_trx_list FROM paginated_trx;

  v_result := json_build_object(
    'total_count', v_total_count,
    'transactions', COALESCE(v_trx_list, '[]'::json)
  );

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_history_paginated(text, text, text, text, text, text, integer, integer) TO authenticated;

NOTIFY pgrst, 'reload schema';
