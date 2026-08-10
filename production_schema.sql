-- =============================================================================
-- FULL PRODUCTION SCHEMA - FUELGUARD (HABIJAYA SYSTEM)
-- Version: 2.0 (Production Release)
-- Description: Complete Production Database Schema & Stored Procedures
-- Features: Multi-Tenant RLS Isolation, Shared Device Architecture,
--           Atomic Transaction Advisory Locks, Anti-Pengetap Audit Logs,
--           Server-Side Pricing & Quota Enforcement, Strict ASCII Regex Validation.
-- =============================================================================

-- ─── 1. EXTENSIONS ───────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── 2. CREATE TABLES (IN DEPENDENCY ORDER) ──────────────────────────────────

-- Table: spbu (Master data lokasi SPBU)
CREATE TABLE IF NOT EXISTS public.spbu (
  id text NOT NULL,
  nama text,
  alamat text,
  CONSTRAINT spbu_pkey PRIMARY KEY (id)
);

-- Table: region_codes (Lookup awalan kode wilayah plat nomor Indonesia)
CREATE TABLE IF NOT EXISTS public.region_codes (
  code text NOT NULL,
  region_name text NOT NULL,
  CONSTRAINT region_codes_pkey PRIMARY KEY (code)
);

-- Table: activity_logs (System Audit Trail)
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  timestamp timestamp with time zone NOT NULL DEFAULT now(),
  user_email text,
  action text NOT NULL,
  details jsonb,
  CONSTRAINT activity_logs_pkey PRIMARY KEY (id)
);

-- Table: operator_profiles (Kasir Fisik SPBU per Perangkat Shared Device)
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

-- Table: user_roles (Pengaturan Role Akun Login Supabase Auth)
CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id uuid NOT NULL,
  role text NOT NULL,
  spbu_id text,
  CONSTRAINT user_roles_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_roles_spbu_id_fkey FOREIGN KEY (spbu_id) REFERENCES public.spbu(id),
  CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Table: support_tickets (Modul Pelaporan Masalah & Pusat Bantuan IT)
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

-- Table: fuel_prices (Harga BBM Resmi Regional)
CREATE TABLE IF NOT EXISTS public.fuel_prices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  fuel_type text NOT NULL,
  price_per_liter numeric NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid,
  CONSTRAINT fuel_prices_pkey PRIMARY KEY (id),
  CONSTRAINT fuel_prices_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id)
);

-- Table: transaksi_pertalite (Log Utama Transaksi Pengisian Pertalite)
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

-- Table: repeated_transaction_logs (Audit Trail Transaksi Berulang & Pengetap)
CREATE TABLE IF NOT EXISTS public.repeated_transaction_logs (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  plat_nomor text NOT NULL,
  attempt_spbu_id text NOT NULL,
  attempt_operator_id uuid,
  is_ojol boolean DEFAULT false,
  attempted_liter numeric NOT NULL DEFAULT 0,
  total_harga_today numeric NOT NULL DEFAULT 0,
  reason text NOT NULL DEFAULT 'quota_exceeded'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT repeated_transaction_logs_pkey PRIMARY KEY (id),
  CONSTRAINT repeated_transaction_logs_spbu_fkey FOREIGN KEY (attempt_spbu_id) REFERENCES public.spbu(id),
  CONSTRAINT repeated_transaction_logs_operator_fkey FOREIGN KEY (attempt_operator_id) REFERENCES public.operator_profiles(id)
);

-- ─── 3. SEED INITIAL LOOKUP DATA ─────────────────────────────────────────────

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

-- ─── 4. PERFORMANCE INDEXES ──────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_trx_plat_waktu 
  ON public.transaksi_pertalite (plat_nomor, waktu_pencatatan DESC);

CREATE INDEX IF NOT EXISTS idx_trx_operator_waktu
  ON public.transaksi_pertalite (operator_id, waktu_pencatatan DESC);

CREATE INDEX IF NOT EXISTS idx_transaksi_pertalite_waktu
  ON public.transaksi_pertalite (waktu_pencatatan DESC);

CREATE INDEX IF NOT EXISTS idx_operator_profiles_spbu 
  ON public.operator_profiles (spbu_id, is_active);

CREATE INDEX IF NOT EXISTS idx_repeated_logs_spbu_date 
  ON public.repeated_transaction_logs (attempt_spbu_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_repeated_logs_plat 
  ON public.repeated_transaction_logs (plat_nomor);

-- ─── 5. SECURITY HELPER FUNCTIONS & TRIGGERS ─────────────────────────────────

-- Helper: Ambil role akun yang sedang login dari tabel user_roles (PL/pgSQL untuk deferred check)
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
BEGIN
  SELECT role INTO v_role FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1;
  RETURN v_role;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$;

-- Helper: Ambil spbu_id milik akun yang sedang login dari tabel user_roles (PL/pgSQL untuk deferred check)
CREATE OR REPLACE FUNCTION public.get_user_spbu_id()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_spbu_id text;
BEGIN
  SELECT spbu_id INTO v_spbu_id FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1;
  RETURN v_spbu_id;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$;

-- Trigger Function: Automatic Audit Logging for Transactions
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
  SELECT op.nama_operator, s.nama
  INTO v_operator_name, v_spbu_name
  FROM public.operator_profiles op
  JOIN public.spbu s ON s.id = op.spbu_id
  WHERE op.id = NEW.operator_id;

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

-- ─── 6. ROW LEVEL SECURITY (RLS) POLICIES ────────────────────────────────────

-- 6.1 RLS Table: transaksi_pertalite
ALTER TABLE public.transaksi_pertalite ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "trx_select_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_operator_select_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_insert_policy" ON public.transaksi_pertalite;

CREATE POLICY "trx_operator_select_policy" ON public.transaksi_pertalite
  FOR SELECT USING (
    (public.get_user_role() = 'master')
    OR
    (
      public.get_user_role() = 'operator'
      AND operator_id IN (
        SELECT id FROM public.operator_profiles WHERE spbu_id = public.get_user_spbu_id()
      )
    )
  );

CREATE POLICY "trx_insert_policy" ON public.transaksi_pertalite
  FOR INSERT WITH CHECK (
    public.get_user_role() = 'master'
  );

-- 6.2 RLS Table: fuel_prices
ALTER TABLE public.fuel_prices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fuel_prices_select" ON public.fuel_prices;
DROP POLICY IF EXISTS "fuel_prices_modify" ON public.fuel_prices;

CREATE POLICY "fuel_prices_select" ON public.fuel_prices
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "fuel_prices_modify" ON public.fuel_prices
  FOR ALL USING (public.get_user_role() = 'master');

-- 6.3 RLS Table: support_tickets
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "support_tickets_select" ON public.support_tickets;
DROP POLICY IF EXISTS "support_tickets_insert" ON public.support_tickets;

CREATE POLICY "support_tickets_select" ON public.support_tickets
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR user_id = auth.uid()
  );

-- [AUDIT FIX #15] Paksa user_id = auth.uid() agar tidak bisa buat tiket atas nama orang lain
CREATE POLICY "support_tickets_insert" ON public.support_tickets
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- 6.4 RLS Table: user_roles
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_roles_select" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_modify" ON public.user_roles;

CREATE POLICY "user_roles_select" ON public.user_roles
  FOR SELECT USING (
    auth.uid() = user_id
    OR public.get_user_role() = 'master'
  );

CREATE POLICY "user_roles_modify" ON public.user_roles
  FOR ALL USING (public.get_user_role() = 'master');

-- 6.5 RLS Table: operator_profiles
ALTER TABLE public.operator_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "operator_profiles_select" ON public.operator_profiles;
DROP POLICY IF EXISTS "operator_profiles_modify" ON public.operator_profiles;

CREATE POLICY "operator_profiles_select" ON public.operator_profiles
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "operator_profiles_modify" ON public.operator_profiles
  FOR ALL USING (public.get_user_role() = 'master');

-- 6.6 RLS Table: spbu
ALTER TABLE public.spbu ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "spbu_select" ON public.spbu;
DROP POLICY IF EXISTS "spbu_modify" ON public.spbu;

CREATE POLICY "spbu_select" ON public.spbu
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "spbu_modify" ON public.spbu
  FOR ALL USING (public.get_user_role() = 'master');

-- 6.7 RLS Table: repeated_transaction_logs
ALTER TABLE public.repeated_transaction_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "repeated_logs_master_select" ON public.repeated_transaction_logs;
DROP POLICY IF EXISTS "repeated_logs_operator_select" ON public.repeated_transaction_logs;
DROP POLICY IF EXISTS "repeated_logs_insert" ON public.repeated_transaction_logs;

CREATE POLICY "repeated_logs_master_select" ON public.repeated_transaction_logs
  FOR SELECT USING (public.get_user_role() = 'master');

CREATE POLICY "repeated_logs_operator_select" ON public.repeated_transaction_logs
  FOR SELECT USING (
    public.get_user_role() = 'operator'
    AND created_at >= date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar'
  );

-- [AUDIT FIX #6] Perketat: hanya role operator/master yang bisa insert log pengetap
CREATE POLICY "repeated_logs_insert" ON public.repeated_transaction_logs
  FOR INSERT WITH CHECK (
    public.get_user_role() IN ('operator', 'master')
  );

-- 6.8 RLS Table: activity_logs
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "activity_logs_select" ON public.activity_logs;
DROP POLICY IF EXISTS "activity_logs_insert" ON public.activity_logs;

CREATE POLICY "activity_logs_select" ON public.activity_logs
  FOR SELECT USING (public.get_user_role() = 'master');

CREATE POLICY "activity_logs_insert" ON public.activity_logs
  FOR INSERT WITH CHECK (true);

-- 6.9 RLS Table: region_codes
ALTER TABLE public.region_codes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "region_codes_public_read" ON public.region_codes;

CREATE POLICY "region_codes_public_read" ON public.region_codes
  FOR SELECT USING (true);

-- ─── 7. OPERATOR STORED PROCEDURES (RPCs) ────────────────────────────────────

-- 7.1 RPC: fn_check_plate_status
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
  v_plat_clean text;
  v_total_liter_today numeric := 0;
  v_total_harga_today numeric := 0;
  v_count_today integer := 0;
  v_has_refueled boolean := false;
  v_remaining_quota numeric := 0;
  v_max_quota numeric := 50000;
  v_first_is_ojol boolean := NULL;
  v_last_trx json := NULL;
  v_last_time text := '';
  v_today_start timestamptz;
  v_history_today json := NULL;
BEGIN
  v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());
  v_today_start := date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar';
  v_plat_clean := regexp_replace(UPPER(TRIM(p_plat)), '\s+', ' ', 'g');

  -- Validasi Strict ASCII Regex Plat Indonesia
  -- [AUDIT FIX #4] Seragamkan regex kode wilayah: 1-2 huruf (sesuai standar plat Indonesia)
  IF NOT (v_plat_clean ~* '^[A-Z]{1,2}\s\d{1,4}(\s[A-Z]{1,3})?$') THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'invalid_format',
      'message', 'Format plat nomor tidak valid (Contoh valid: KT 1234 AB).'
    );
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

  -- Kunci Kategori Harian
  SELECT is_ojol INTO v_first_is_ojol
  FROM public.transaksi_pertalite
  WHERE plat_nomor = v_plat_clean
    AND waktu_pencatatan >= v_today_start
  ORDER BY waktu_pencatatan ASC
  LIMIT 1;

  IF v_first_is_ojol IS NOT NULL AND v_first_is_ojol != p_is_ojol THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'category_mismatch',
      'message', format('Kendaraan %s hari ini sudah terdaftar sebagai %s! Tidak dapat bertransaksi sebagai %s.',
        v_plat_clean,
        CASE WHEN v_first_is_ojol THEN 'Motor Ojol' ELSE 'Motor Biasa' END,
        CASE WHEN p_is_ojol THEN 'Motor Ojol' ELSE 'Motor Biasa' END
      )
    );
  END IF;

  SELECT 
    COALESCE(SUM(liter), 0),
    COALESCE(SUM(harga), 0),
    COUNT(id)
  INTO v_total_liter_today, v_total_harga_today, v_count_today
  FROM public.transaksi_pertalite
  WHERE plat_nomor = v_plat_clean
    AND waktu_pencatatan >= v_today_start;

  IF COALESCE(v_first_is_ojol, p_is_ojol) THEN
    v_max_quota := 100000;
  ELSE
    v_max_quota := 50000;
  END IF;

  v_has_refueled := v_total_harga_today >= v_max_quota;
  v_remaining_quota := GREATEST(0, v_max_quota - v_total_harga_today);

  IF v_count_today > 0 THEN
    SELECT json_build_object(
      'id', t.id,
      'liter', t.liter,
      'harga', t.harga,
      'waktu_pencatatan', t.waktu_pencatatan,
      'is_ojol', t.is_ojol,
      'spbu_id', op.spbu_id,
      'nama_operator', op.nama_operator
    ) INTO v_last_trx
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE t.plat_nomor = v_plat_clean
      AND t.waktu_pencatatan >= v_today_start
    ORDER BY t.waktu_pencatatan DESC
    LIMIT 1;

    v_last_time := to_char((v_last_trx->>'waktu_pencatatan')::timestamptz AT TIME ZONE 'Asia/Makassar', 'HH24:MI');
  END IF;

  -- Ambil seluruh riwayat transaksi diterima & percobaan ditolak hari ini untuk plat ini
  SELECT json_agg(h) INTO v_history_today
  FROM (
    SELECT 
      t.waktu_pencatatan AS waktu_raw,
      to_char(t.waktu_pencatatan AT TIME ZONE 'Asia/Makassar', 'HH24:MI') || ' WITA' AS waktu,
      COALESCE(op.spbu_id, 'Unknown') AS spbu_id,
      COALESCE(s.nama, CONCAT('SPBU ', op.spbu_id)) AS spbu_nama,
      'diterima' AS status,
      t.liter AS liter,
      t.harga AS harga,
      'Pengisian Berhasil' AS reason
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE t.plat_nomor = v_plat_clean
      AND t.waktu_pencatatan >= v_today_start

    UNION ALL

    SELECT 
      r.created_at AS waktu_raw,
      to_char(r.created_at AT TIME ZONE 'Asia/Makassar', 'HH24:MI') || ' WITA' AS waktu,
      COALESCE(r.attempt_spbu_id, 'Unknown') AS spbu_id,
      COALESCE(s.nama, CONCAT('SPBU ', r.attempt_spbu_id)) AS spbu_nama,
      'ditolak' AS status,
      r.attempted_liter AS liter,
      r.total_harga_today AS harga,
      CASE 
        WHEN r.reason = 'quota_exceeded' THEN 'Kuota Habis'
        WHEN r.reason = 'category_mismatch' THEN 'Kategori Tidak Sesuai'
        WHEN r.reason = 'already_refueled' THEN 'Sudah Mengisi Hari Ini'
        ELSE r.reason
      END AS reason
    FROM public.repeated_transaction_logs r
    LEFT JOIN public.spbu s ON s.id = r.attempt_spbu_id
    WHERE r.plat_nomor = v_plat_clean
      AND r.created_at >= v_today_start

    ORDER BY waktu_raw DESC
  ) h;

  -- Mengembalikan baik 'plat' dan 'plat_nomor' untuk kompatibilitas penuh frontend Vue
  RETURN json_build_object(
    'success', true,
    'plat', v_plat_clean,
    'plat_nomor', v_plat_clean,
    'total_liter_today', v_total_liter_today,
    'total_harga_today', v_total_harga_today,
    'remainingQuota', v_remaining_quota,
    'hasRefueledToday', v_has_refueled,
    'count_today', v_count_today,
    'max_quota', v_max_quota,
    'is_ojol_locked', (v_first_is_ojol IS NOT NULL),
    'locked_is_ojol', v_first_is_ojol,
    'last_transaction', v_last_trx,
    'last_time', v_last_time,
    'history_today', COALESCE(v_history_today, '[]'::json)
  );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.fn_check_plate_status(text, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_check_plate_status(text, boolean, text) TO authenticated;

-- 7.2 RPC: fn_safe_insert_transaction
CREATE OR REPLACE FUNCTION public.fn_safe_insert_transaction(
  p_plat text,
  p_liter numeric,
  p_operator_id uuid DEFAULT NULL,
  p_is_ojol boolean DEFAULT false
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_spbu_id text;
  v_operator_id uuid;
  v_plat_clean text;
  v_harga_per_liter numeric;
  v_total_harga numeric;
  v_total_harga_today numeric;
  v_count_today integer;
  v_max_quota numeric := 50000;
  v_new_id bigint;
  v_first_is_ojol boolean := NULL;
  v_today_start timestamptz;
BEGIN
  -- 🔴 SECURITY CHECK 1: Proteksi Akses Tanpa Login (Anon / Unauthenticated)
  IF auth.uid() IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'unauthorized',
      'message', 'Akses ditolak. Anda harus login terlebih dahulu.'
    );
  END IF;

  -- 🔴 SECURITY CHECK 2: Ambil spbu_id LANGSUNG dari auth.uid() (tabel user_roles)
  v_spbu_id := public.get_user_spbu_id();
  IF v_spbu_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'no_spbu',
      'message', 'Akun Anda tidak terikat dengan unit SPBU manapun.'
    );
  END IF;

  -- 🔴 Tentukan operator_id dari auth / operator_profiles SPBU tersebut
  IF p_operator_id IS NOT NULL THEN
    SELECT id INTO v_operator_id 
    FROM public.operator_profiles 
    WHERE id = p_operator_id AND spbu_id = v_spbu_id AND is_active = true;
  END IF;

  -- Fallback jika p_operator_id tidak dikirim/tidak valid: gunakan profil operator aktif pertama di SPBU ini
  IF v_operator_id IS NULL THEN
    SELECT id INTO v_operator_id 
    FROM public.operator_profiles 
    WHERE spbu_id = v_spbu_id AND is_active = true 
    ORDER BY created_at ASC 
    LIMIT 1;
  END IF;

  IF v_operator_id IS NULL THEN
    RETURN json_build_object(
      'success', false, 
      'reason', 'no_operator', 
      'message', 'Tidak ditemukan profil operator aktif untuk SPBU ini. Buat profil operator terlebih dahulu.'
    );
  END IF;

  v_plat_clean := regexp_replace(UPPER(TRIM(p_plat)), '\s+', ' ', 'g');
  IF v_plat_clean = '' OR p_liter <= 0 THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_input', 'message', 'Plat nomor dan liter harus valid.');
  END IF;

  -- [AUDIT FIX #4] Seragamkan regex kode wilayah: 1-2 huruf (sesuai standar plat Indonesia)
  IF NOT (v_plat_clean ~* '^[A-Z]{1,2}\s\d{1,4}(\s[A-Z]{1,3})?$') THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'invalid_format',
      'message', 'Format plat nomor tidak valid (Contoh valid: KT 1234 AB).'
    );
  END IF;

  -- [AUDIT FIX #12] Langsung query region_codes (konsisten dengan fn_check_plate_status)
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

  -- [AUDIT FIX #2] Lock Transaksi Atomik SEBELUM semua pengecekan (cegah race condition category_mismatch)
  PERFORM pg_advisory_xact_lock(hashtext(v_plat_clean));

  -- Hitung waktu awal hari (WITA) 1x di tingkat fungsi utama
  v_today_start := date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar';

  SELECT is_ojol INTO v_first_is_ojol
  FROM public.transaksi_pertalite
  WHERE plat_nomor = v_plat_clean
    AND waktu_pencatatan >= v_today_start
  ORDER BY waktu_pencatatan ASC
  LIMIT 1;

  IF v_first_is_ojol IS NOT NULL AND v_first_is_ojol != p_is_ojol THEN
    INSERT INTO public.repeated_transaction_logs (
      plat_nomor, attempt_spbu_id, attempt_operator_id, is_ojol, 
      attempted_liter, total_harga_today, reason, created_at
      v_plat_clean, v_spbu_id, v_operator_id, p_is_ojol,
      p_liter, 0, 'category_mismatch', NOW()
    );

    RETURN json_build_object(
      'success', false,
      'reason', 'category_mismatch',
      'message', format('Kendaraan %s hari ini sudah terdaftar sebagai %s! Tidak dapat bertransaksi sebagai %s.',
        v_plat_clean,
        CASE WHEN v_first_is_ojol THEN 'Motor Ojol' ELSE 'Motor Biasa' END,
        CASE WHEN p_is_ojol THEN 'Motor Ojol' ELSE 'Motor Biasa' END
      )
    );
  END IF;

  IF COALESCE(v_first_is_ojol, p_is_ojol) THEN
    v_max_quota := 100000;
  ELSE
    v_max_quota := 50000;
  END IF;

  -- Get Price (Server-Side Pricing: Harga Regional Global)
  SELECT price_per_liter INTO v_harga_per_liter
  FROM public.fuel_prices
  WHERE LOWER(fuel_type) LIKE '%pertalite%'
  ORDER BY updated_at DESC NULLS LAST
  LIMIT 1;

  -- [AUDIT FIX #11] Fallback default harga Rp 10.000 jika belum dikonfigurasi
  IF v_harga_per_liter IS NULL OR v_harga_per_liter <= 0 THEN
    v_harga_per_liter := 10000;
  END IF;

  v_total_harga := p_liter * v_harga_per_liter;

  SELECT 
    COALESCE(SUM(harga), 0),
    COUNT(id)
  INTO v_total_harga_today, v_count_today
  FROM public.transaksi_pertalite
  WHERE plat_nomor = v_plat_clean
    AND waktu_pencatatan >= v_today_start;

  IF (v_total_harga_today + v_total_harga) > v_max_quota THEN
    INSERT INTO public.repeated_transaction_logs (
      plat_nomor, attempt_spbu_id, attempt_operator_id, is_ojol, 
      attempted_liter, total_harga_today, reason, created_at
    ) VALUES (
      v_plat_clean, v_spbu_id, v_operator_id, p_is_ojol,
      p_liter, (v_total_harga_today + v_total_harga), 'quota_exceeded', NOW()
    );

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
    v_plat_clean, p_liter, v_total_harga, v_operator_id, p_is_ojol, NOW()
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
REVOKE EXECUTE ON FUNCTION public.fn_safe_insert_transaction(text, numeric, uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_safe_insert_transaction(text, numeric, uuid, boolean) TO authenticated;

-- 7.3 RPC: get_dashboard_summary
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
  v_start_time timestamp with time zone;
  v_total_revenue numeric := 0;
  v_total_volume numeric := 0;
  v_today_trx_count integer := 0;
  v_recent_transactions json;
  v_weekly_volume json;
BEGIN
  -- [AUDIT FIX #8] Isolasi SPBU: operator dipaksa ke SPBU sendiri, role lain ditolak
  IF public.get_user_role() = 'operator' THEN
    v_spbu_id := public.get_user_spbu_id();
  ELSIF public.get_user_role() = 'master' THEN
    v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());
  ELSE
    RAISE EXCEPTION 'Akses ditolak: Role tidak valid untuk mengakses dashboard';
  END IF;

  IF p_filter = 'today' THEN
    v_start_time := date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar';
  ELSIF p_filter = 'weekly' THEN
    v_start_time := date_trunc('day', (NOW() AT TIME ZONE 'Asia/Makassar') - INTERVAL '6 days') AT TIME ZONE 'Asia/Makassar';
  ELSIF p_filter = 'monthly' THEN
    v_start_time := date_trunc('day', (NOW() AT TIME ZONE 'Asia/Makassar') - INTERVAL '29 days') AT TIME ZONE 'Asia/Makassar';
  ELSE
    v_start_time := '1970-01-01 00:00:00+00'::timestamp with time zone;
  END IF;

  SELECT 
    COALESCE(SUM(t.harga), 0),
    COALESCE(SUM(t.liter), 0),
    COUNT(t.id)
  INTO v_total_revenue, v_total_volume, v_today_trx_count
  FROM public.transaksi_pertalite t
  JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE op.spbu_id = v_spbu_id
    AND t.waktu_pencatatan >= v_start_time;

  -- 7 Recent Transactions
  SELECT json_agg(sub) INTO v_recent_transactions
  FROM (
    SELECT 
      t.id,
      t.plat_nomor,
      t.liter,
      t.harga,
      t.waktu_pencatatan,
      t.is_ojol,
      op.nama_operator
    FROM public.transaksi_pertalite t
    JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE op.spbu_id = v_spbu_id
      AND t.waktu_pencatatan >= v_start_time
    ORDER BY t.waktu_pencatatan DESC
    LIMIT 7
  ) sub;

  -- 7-Day Weekly Volume Array
  WITH days AS (
    SELECT generate_series(
      date_trunc('day', (NOW() AT TIME ZONE 'Asia/Makassar') - INTERVAL '6 days'),
      date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar'),
      INTERVAL '1 day'
    )::date AS d
  ),
  daily_sums AS (
    SELECT 
      date_trunc('day', t.waktu_pencatatan AT TIME ZONE 'Asia/Makassar')::date AS d,
      SUM(t.liter) AS total_liter
    FROM public.transaksi_pertalite t
    JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE op.spbu_id = v_spbu_id
      AND t.waktu_pencatatan >= date_trunc('day', (NOW() AT TIME ZONE 'Asia/Makassar') - INTERVAL '6 days') AT TIME ZONE 'Asia/Makassar'
    GROUP BY 1
  )
  SELECT json_agg(COALESCE(ds.total_liter, 0) ORDER BY days.d) 
  INTO v_weekly_volume
  FROM days
  LEFT JOIN daily_sums ds ON ds.d = days.d;

  RETURN json_build_object(
    'stats', json_build_object(
      'totalRevenue', v_total_revenue,
      'totalVolume', v_total_volume,
      'todayTrxCount', v_today_trx_count
    ),
    'recentTransactions', COALESCE(v_recent_transactions, '[]'::json),
    'weeklyVolume', COALESCE(v_weekly_volume, '[]'::json)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_dashboard_summary(text, text) TO authenticated;

-- 7.4 RPC: get_export_transactions
CREATE OR REPLACE FUNCTION public.get_export_transactions(
  p_start_date text DEFAULT '',
  p_end_date text DEFAULT '',
  p_spbu_id text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_effective_spbu text;
  v_start_time timestamptz;
  v_end_time timestamptz;
  v_result json;
BEGIN
  -- [AUDIT FIX #9] Tambah role check: hanya master/operator yang bisa export
  IF public.get_user_role() = 'operator' THEN
    v_effective_spbu := public.get_user_spbu_id();
  ELSIF public.get_user_role() = 'master' THEN
    v_effective_spbu := NULLIF(TRIM(p_spbu_id), '');
  ELSE
    RAISE EXCEPTION 'Akses ditolak: Role tidak valid untuk mengekspor data transaksi';
  END IF;

  -- [AUDIT FIX #NEW-3] Parse parameter tanggal dengan offset WITA (+08) agar jam 00:00-07:59 tidak terpotong
  IF p_start_date IS NOT NULL AND TRIM(p_start_date) != '' THEN
    v_start_time := (p_start_date || ' 00:00:00+08')::timestamp with time zone;
  END IF;

  IF p_end_date IS NOT NULL AND TRIM(p_end_date) != '' THEN
    v_end_time := (p_end_date || ' 23:59:59.999+08')::timestamp with time zone;
  END IF;

  SELECT json_agg(sub) INTO v_result
  FROM (
    SELECT 
      t.id,
      t.plat_nomor,
      t.liter,
      t.harga,
      t.waktu_pencatatan,
      t.is_ojol,
      op.nama_operator,
      op.spbu_id,
      s.nama AS spbu_nama
    FROM public.transaksi_pertalite t
    JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE (v_effective_spbu IS NULL OR op.spbu_id = v_effective_spbu)
      AND (v_start_time IS NULL OR t.waktu_pencatatan >= v_start_time)
      AND (v_end_time IS NULL OR t.waktu_pencatatan <= v_end_time)
    ORDER BY t.waktu_pencatatan DESC
  ) sub;

  RETURN COALESCE(v_result, '[]'::json);
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_export_transactions(text, text, text) TO authenticated;

-- 7.5 RPC: get_operator_repeated_logs
CREATE OR REPLACE FUNCTION public.get_operator_repeated_logs(
  p_spbu_id text DEFAULT NULL,
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 10,
  p_search text DEFAULT ''
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_effective_spbu text;
  v_count_today integer;
  v_offset integer;
  v_logs json;
BEGIN
  IF public.get_user_role() = 'operator' THEN
    v_effective_spbu := public.get_user_spbu_id();
  ELSE
    v_effective_spbu := NULLIF(TRIM(p_spbu_id), '');
  END IF;

  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;

  SELECT COUNT(l.id) INTO v_count_today
  FROM public.repeated_transaction_logs l
  LEFT JOIN public.operator_profiles op ON op.id = l.attempt_operator_id
  WHERE (v_effective_spbu IS NULL OR l.attempt_spbu_id = v_effective_spbu)
    AND l.created_at >= date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar'
    AND (
      p_search = '' OR
      l.plat_nomor ILIKE '%' || p_search || '%' OR
      COALESCE(op.nama_operator, '') ILIKE '%' || p_search || '%' OR
      l.attempt_spbu_id ILIKE '%' || p_search || '%' OR
      l.reason ILIKE '%' || p_search || '%' OR
      to_char(l.created_at AT TIME ZONE 'Asia/Makassar', 'HH24:MI') ILIKE '%' || p_search || '%'
    );

  SELECT json_agg(t) INTO v_logs
  FROM (
    SELECT 
      l.id, 
      l.plat_nomor,
      l.attempt_spbu_id AS spbu_id,
      l.attempt_operator_id AS operator_id,
      COALESCE(op.nama_operator, 'Sistem') AS nama_operator,
      l.is_ojol,
      l.attempted_liter,
      l.total_harga_today,
      l.reason,
      l.created_at,
      to_char(l.created_at AT TIME ZONE 'Asia/Makassar', 'HH24:MI') AS jam_pencatatan
    FROM public.repeated_transaction_logs l
    LEFT JOIN public.operator_profiles op ON op.id = l.attempt_operator_id
    WHERE (v_effective_spbu IS NULL OR l.attempt_spbu_id = v_effective_spbu)
      AND l.created_at >= date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar'
      AND (
        p_search = '' OR
        l.plat_nomor ILIKE '%' || p_search || '%' OR
        COALESCE(op.nama_operator, '') ILIKE '%' || p_search || '%' OR
        l.attempt_spbu_id ILIKE '%' || p_search || '%' OR
        l.reason ILIKE '%' || p_search || '%' OR
        to_char(l.created_at AT TIME ZONE 'Asia/Makassar', 'HH24:MI') ILIKE '%' || p_search || '%'
      )
    ORDER BY l.created_at DESC
    LIMIT p_page_size OFFSET v_offset
  ) t;

  RETURN json_build_object(
    'total_count', v_count_today,
    'logs', COALESCE(v_logs, '[]'::json)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_operator_repeated_logs(text, integer, integer, text) TO authenticated;

-- ─── 8. MASTER STORED PROCEDURES (RPCs) ──────────────────────────────────────

-- 8.1 RPC: get_master_dashboard_summary (Optimized LCP Summary - WITA Timezone Aligned)
CREATE OR REPLACE FUNCTION public.get_master_dashboard_summary(p_filter text DEFAULT 'today')
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role text;
  v_start_time timestamp with time zone;
  v_total_revenue numeric := 0;
  v_total_volume numeric := 0;
  v_active_spbu_count integer := 0;
  v_today_trx_count integer := 0;
  v_weekly_volume json;
  v_spbu_list json;
  v_alerts json;
  v_result json;
BEGIN         
  v_caller_role := public.get_user_role();
  IF v_caller_role IS NULL OR LOWER(v_caller_role) != 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Hanya role Master yang diizinkan melihat dashboard master';
  END IF;

  IF p_filter = 'today' THEN
    v_start_time := date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar';
  ELSIF p_filter = 'weekly' THEN
    v_start_time := date_trunc('day', (NOW() AT TIME ZONE 'Asia/Makassar') - INTERVAL '6 days') AT TIME ZONE 'Asia/Makassar';
  ELSIF p_filter = 'monthly' THEN
    v_start_time := date_trunc('day', (NOW() AT TIME ZONE 'Asia/Makassar') - INTERVAL '29 days') AT TIME ZONE 'Asia/Makassar';
  ELSE
    v_start_time := '1970-01-01 00:00:00+00'::timestamp with time zone;
  END IF;

  SELECT 
    COALESCE(SUM(harga), 0),
    COALESCE(SUM(liter), 0),
    COUNT(id)
  INTO v_total_revenue, v_total_volume, v_today_trx_count
  FROM public.transaksi_pertalite
  WHERE waktu_pencatatan >= v_start_time;

  SELECT COUNT(id) INTO v_active_spbu_count FROM public.spbu;

  -- 7-Day Weekly Volume (Aligned to WITA Timezone)
  WITH days AS (
    SELECT generate_series(
      date_trunc('day', (NOW() AT TIME ZONE 'Asia/Makassar') - INTERVAL '6 days'),
      date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar'),
      INTERVAL '1 day'
    )::date AS d
  ),
  daily_sums AS (
    SELECT 
      date_trunc('day', waktu_pencatatan AT TIME ZONE 'Asia/Makassar')::date AS d,
      SUM(liter) AS total_liter
    FROM public.transaksi_pertalite
    WHERE waktu_pencatatan >= date_trunc('day', (NOW() AT TIME ZONE 'Asia/Makassar') - INTERVAL '6 days') AT TIME ZONE 'Asia/Makassar'
    GROUP BY 1
  )
  SELECT json_agg(COALESCE(ds.total_liter, 0) ORDER BY days.d) 
  INTO v_weekly_volume 
  FROM days
  LEFT JOIN daily_sums ds ON ds.d = days.d;

  -- 10 Recent Transactions per SPBU
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
  SELECT json_agg(
    json_build_object(
      'id', s.id,
      'name', COALESCE(s.nama, CONCAT('SPBU #', s.id)),
      'location', COALESCE(s.alamat, '-'),
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

  v_alerts := '[
    {"id": 1, "type": "info", "message": "Sistem FuelGuard berjalan normal.", "time": "Sekarang"}
  ]'::json;

  v_result := json_build_object(
    'stats', json_build_object(
      'totalRevenue', v_total_revenue,
      'totalVolume', v_total_volume,
      'activeSpbuCount', v_active_spbu_count,
      'todayTrxCount', v_today_trx_count
    ),
    'weekly_volume', COALESCE(v_weekly_volume, '[]'::json),
    'spbu_list', COALESCE(v_spbu_list, '[]'::json),
    'alerts', v_alerts
  );

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_dashboard_summary(text) TO authenticated;

-- 8.2 RPC: get_master_history_paginated (Strict Multi-Tenant Role Isolation)
CREATE OR REPLACE FUNCTION public.get_master_history_paginated(
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 10,
  p_search text DEFAULT '',
  p_spbu_id text DEFAULT NULL,
  p_date_from text DEFAULT '',
  p_date_to text DEFAULT '',
  p_sort_field text DEFAULT 'waktu_pencatatan',
  p_sort_dir text DEFAULT 'desc'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role text;
  v_effective_spbu text;
  v_offset integer;
  v_total_count integer;
  v_transactions json;
  v_date_from timestamp with time zone;
  v_date_to timestamp with time zone;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: Sesi tidak terautentikasi';
  END IF;

  v_caller_role := public.get_user_role();

  IF v_caller_role = 'operator' THEN
    v_effective_spbu := public.get_user_spbu_id();
  ELSIF v_caller_role = 'master' THEN
    v_effective_spbu := NULLIF(TRIM(p_spbu_id), '');
  ELSE
    RAISE EXCEPTION 'Akses ditolak: Role tidak valid';
  END IF;

  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;

  -- [AUDIT FIX #NEW-3] Tambah offset +08 (WITA) agar tidak tergeser ke UTC
  IF p_date_from IS NOT NULL AND TRIM(p_date_from) != '' THEN
    v_date_from := (p_date_from || ' 00:00:00+08')::timestamp with time zone;
  END IF;

  IF p_date_to IS NOT NULL AND TRIM(p_date_to) != '' THEN
    v_date_to := (p_date_to || ' 23:59:59.999+08')::timestamp with time zone;
  END IF;

  SELECT COUNT(t.id) INTO v_total_count
  FROM public.transaksi_pertalite t
  JOIN public.operator_profiles op ON op.id = t.operator_id
  LEFT JOIN public.spbu s ON s.id = op.spbu_id
  WHERE (v_effective_spbu IS NULL OR op.spbu_id = v_effective_spbu)
    AND (
      p_search = '' OR
      t.plat_nomor ILIKE '%' || p_search || '%' OR
      COALESCE(op.nama_operator, '') ILIKE '%' || p_search || '%' OR
      COALESCE(s.nama, op.spbu_id) ILIKE '%' || p_search || '%'
    )
    AND (v_date_from IS NULL OR t.waktu_pencatatan >= v_date_from)
    AND (v_date_to IS NULL OR t.waktu_pencatatan <= v_date_to);

  SELECT json_agg(sub) INTO v_transactions
  FROM (
    SELECT 
      t.id,
      t.plat_nomor,
      t.liter,
      t.harga,
      t.waktu_pencatatan,
      t.is_ojol,
      t.operator_id,
      op.nama_operator,
      op.spbu_id,
      COALESCE(s.nama, CONCAT('SPBU #', op.spbu_id)) as spbu_nama
    FROM public.transaksi_pertalite t
    JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE (v_effective_spbu IS NULL OR op.spbu_id = v_effective_spbu)
      AND (
        p_search = '' OR
        t.plat_nomor ILIKE '%' || p_search || '%' OR
        COALESCE(op.nama_operator, '') ILIKE '%' || p_search || '%' OR
        COALESCE(s.nama, op.spbu_id) ILIKE '%' || p_search || '%'
      )
      AND (v_date_from IS NULL OR t.waktu_pencatatan >= v_date_from)
      AND (v_date_to IS NULL OR t.waktu_pencatatan <= v_date_to)
    ORDER BY
      CASE WHEN LOWER(p_sort_dir) = 'asc'  AND p_sort_field = 'plat_nomor'        THEN t.plat_nomor END ASC,
      CASE WHEN LOWER(p_sort_dir) = 'desc' AND p_sort_field = 'plat_nomor'        THEN t.plat_nomor END DESC,
      CASE WHEN LOWER(p_sort_dir) = 'asc'  AND p_sort_field = 'liter'             THEN t.liter END ASC,
      CASE WHEN LOWER(p_sort_dir) = 'desc' AND p_sort_field = 'liter'             THEN t.liter END DESC,
      CASE WHEN LOWER(p_sort_dir) = 'asc'  AND p_sort_field = 'harga'             THEN t.harga END ASC,
      CASE WHEN LOWER(p_sort_dir) = 'desc' AND p_sort_field = 'harga'             THEN t.harga END DESC,
      CASE WHEN LOWER(p_sort_dir) = 'asc'  AND p_sort_field = 'waktu_pencatatan' THEN t.waktu_pencatatan END ASC,
      CASE WHEN LOWER(p_sort_dir) = 'desc' AND p_sort_field = 'waktu_pencatatan' THEN t.waktu_pencatatan END DESC,
      t.waktu_pencatatan DESC
    LIMIT p_page_size OFFSET v_offset
  ) sub;

  RETURN json_build_object(
    'total_count', v_total_count,
    'transactions', COALESCE(v_transactions, '[]'::json)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_history_paginated(integer, integer, text, text, text, text, text, text) TO authenticated;

-- 8.3 RPC: get_master_team_overview
CREATE OR REPLACE FUNCTION public.get_master_team_overview(
  p_spbu_id text DEFAULT '',
  p_search text DEFAULT ''
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_caller_uid uuid;
  v_caller_role text;
  v_total_operators integer := 0;
  v_active_operators integer := 0;
  v_total_spbu integer := 0;
  v_spbu_list json;
  v_operators_json json;
  v_accounts_json json;
  v_result json;
BEGIN
  v_caller_uid := auth.uid();
  IF v_caller_uid IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: Sesi pengguna tidak terautentikasi';
  END IF;

  v_caller_role := public.get_user_role();
  IF v_caller_role IS NULL THEN
    SELECT role INTO v_caller_role FROM public.user_roles WHERE user_id = v_caller_uid LIMIT 1;
  END IF;

  IF LOWER(COALESCE(v_caller_role, '')) != 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Hanya role Master yang diizinkan melihat data tim';
  END IF;

  SELECT COUNT(id) INTO v_total_operators FROM public.operator_profiles;
  SELECT COUNT(id) INTO v_active_operators FROM public.operator_profiles WHERE is_active = true;
  SELECT COUNT(id) INTO v_total_spbu FROM public.spbu;

  SELECT json_agg(
    json_build_object(
      'id', id,
      'name', COALESCE(nama, CONCAT('SPBU #', id)),
      'alamat', COALESCE(alamat, '-')
    ) ORDER BY id ASC
  ) INTO v_spbu_list FROM public.spbu;

  WITH operator_details AS (
    SELECT 
      op.id,
      op.nama_operator,
      op.spbu_id,
      COALESCE(s.nama, CONCAT('SPBU #', op.spbu_id)) AS spbu_name,
      op.is_active,
      op.created_at
    FROM public.operator_profiles op
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE (COALESCE(p_spbu_id, '') = '' OR op.spbu_id::text = p_spbu_id)
      AND (COALESCE(p_search, '') = '' OR op.nama_operator ILIKE '%' || p_search || '%')
    ORDER BY op.created_at DESC, op.nama_operator ASC
  )
  SELECT json_agg(
    json_build_object(
      'id', id,
      'nama_operator', nama_operator,
      'spbu_id', spbu_id,
      'spbu_name', spbu_name,
      'is_active', is_active,
      'created_at', created_at
    )
  ) INTO v_operators_json FROM operator_details;

  -- Get SPBU authentication accounts list (Hanya Akun Login SPBU Terdaftar)
  WITH account_details AS (
    SELECT 
      ur.user_id,
      ur.spbu_id,
      COALESCE(s.nama, CONCAT('SPBU #', ur.spbu_id)) AS spbu_name,
      COALESCE(ur.role, 'operator') AS role,
      u.email
    FROM public.user_roles ur
    INNER JOIN auth.users u ON u.id = ur.user_id
    LEFT JOIN public.spbu s ON s.id = ur.spbu_id
    WHERE LOWER(COALESCE(ur.role, '')) != 'master'
      AND (COALESCE(p_spbu_id, '') = '' OR ur.spbu_id::text = p_spbu_id)
      AND (COALESCE(p_search, '') = '' OR s.nama ILIKE '%' || p_search || '%' OR COALESCE(u.email, '') ILIKE '%' || p_search || '%')
    ORDER BY ur.spbu_id ASC
  )
  SELECT json_agg(
    json_build_object(
      'user_id', user_id,
      'spbu_id', spbu_id,
      'spbu_name', spbu_name,
      'role', role,
      'email', email
    )
  ) INTO v_accounts_json FROM account_details;

  v_result := json_build_object(
    'kpis', json_build_object(
      'totalOperators', v_total_operators,
      'activeOperators', v_active_operators,
      'totalSpbu', v_total_spbu
    ),
    'spbuList', COALESCE(v_spbu_list, '[]'::json),
    'operators', COALESCE(v_operators_json, '[]'::json),
    'accounts', COALESCE(v_accounts_json, '[]'::json)
  );

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_team_overview(text, text) TO authenticated;

-- 8.4 RPC: manage_operator
CREATE OR REPLACE FUNCTION public.manage_operator(
  p_action text,
  p_id uuid DEFAULT NULL,
  p_spbu_id text DEFAULT '',
  p_nama_operator text DEFAULT '',
  p_is_active boolean DEFAULT true
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_id uuid;
  v_result json;
BEGIN
  -- [AUDIT FIX #NEW-1] Fix NULL bypass: NULL <> 'master' = NULL (evaluasi FALSE), lewati exception
  IF COALESCE(public.get_user_role(), '') != 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Hanya role Master yang diizinkan mengelola data operator';
  END IF;

  IF p_action = 'create' THEN
    IF p_nama_operator IS NULL OR TRIM(p_nama_operator) = '' THEN
      RAISE EXCEPTION 'Nama operator tidak boleh kosong';
    END IF;
    IF p_spbu_id IS NULL OR TRIM(p_spbu_id) = '' THEN
      RAISE EXCEPTION 'Pilih unit SPBU terlebih dahulu';
    END IF;

    INSERT INTO public.operator_profiles (spbu_id, nama_operator, is_active)
    VALUES (p_spbu_id, TRIM(p_nama_operator), COALESCE(p_is_active, true))
    RETURNING id INTO v_new_id;

    v_result := json_build_object(
      'success', true,
      'id', v_new_id,
      'message', 'Operator berhasil ditambahkan'
    );

  ELSIF p_action = 'update' THEN
    IF p_id IS NULL THEN
      RAISE EXCEPTION 'ID operator tidak valid';
    END IF;
    IF p_nama_operator IS NULL OR TRIM(p_nama_operator) = '' THEN
      RAISE EXCEPTION 'Nama operator tidak boleh kosong saat update';
    END IF;
    IF p_spbu_id IS NULL OR TRIM(p_spbu_id) = '' THEN
      RAISE EXCEPTION 'ID SPBU tidak boleh kosong saat update';
    END IF;

    UPDATE public.operator_profiles
    SET 
      nama_operator = TRIM(p_nama_operator),
      spbu_id = p_spbu_id,
      is_active = p_is_active
    WHERE id = p_id;

    v_result := json_build_object(
      'success', true,
      'message', 'Data operator berhasil diperbarui'
    );

  ELSIF p_action = 'toggle_status' THEN
    IF p_id IS NULL THEN
      RAISE EXCEPTION 'ID operator tidak valid';
    END IF;

    UPDATE public.operator_profiles
    SET is_active = NOT is_active
    WHERE id = p_id;

    v_result := json_build_object(
      'success', true,
      'message', 'Status operator berhasil diperbarui'
    );

  ELSE
    RAISE EXCEPTION 'Aksi manage_operator tidak dikenali: %', p_action;
  END IF;

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.manage_operator(text, uuid, text, text, boolean) TO authenticated;

-- 8.5 RPC: get_master_repeated_transactions
CREATE OR REPLACE FUNCTION public.get_master_repeated_transactions(
  p_spbu_id text DEFAULT NULL,
  p_date_from text DEFAULT NULL,
  p_date_to text DEFAULT NULL,
  p_limit integer DEFAULT 20,
  p_offset integer DEFAULT 0
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
  v_total_attempts integer := 0;
  v_total_plates integer := 0;
  v_logs json := '[]'::json;
  v_result json;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: Sesi tidak terautentikasi';
  END IF;

  v_role := public.get_user_role();
  IF v_role IS NULL OR LOWER(v_role) != 'master' THEN
    RAISE EXCEPTION 'Forbidden: Akses ditolak. Membutuhkan hak akses Master Admin.';
  END IF;

  -- [AUDIT FIX #NEW-3] Tambah offset +08 (WITA) untuk date parsing
  SELECT COUNT(r.id) INTO v_total_attempts
  FROM public.repeated_transaction_logs r
  WHERE (p_spbu_id IS NULL OR TRIM(p_spbu_id) = '' OR r.attempt_spbu_id = p_spbu_id)
    AND (p_date_from IS NULL OR TRIM(p_date_from) = '' OR r.created_at >= (p_date_from || ' 00:00:00+08')::timestamp with time zone)
    AND (p_date_to IS NULL OR TRIM(p_date_to) = '' OR r.created_at <= (p_date_to || ' 23:59:59.999+08')::timestamp with time zone);

  -- [OPTIMASI PERFORMANSI #3] Jalankan CTE 1x saja dengan window function COUNT(*) OVER() untuk total plates
  WITH raw_logs AS (
    SELECT 
      r.id,
      regexp_replace(UPPER(TRIM(r.plat_nomor)), '\s+', ' ', 'g') AS plat_nomor,
      r.attempt_spbu_id,
      COALESCE(s.nama, 'SPBU ' || r.attempt_spbu_id) AS spbu_nama,
      r.attempt_operator_id,
      COALESCE(op.nama_operator, 'Sistem') AS operator_nama,
      COALESCE(r.is_ojol, false) AS is_ojol,
      r.attempted_liter,
      r.total_harga_today,
      r.reason,
      r.created_at
    FROM public.repeated_transaction_logs r
    LEFT JOIN public.spbu s ON s.id = r.attempt_spbu_id
    LEFT JOIN public.operator_profiles op ON op.id = r.attempt_operator_id
    WHERE (p_spbu_id IS NULL OR TRIM(p_spbu_id) = '' OR r.attempt_spbu_id = p_spbu_id)
      AND (p_date_from IS NULL OR TRIM(p_date_from) = '' OR r.created_at >= (p_date_from || ' 00:00:00+08')::timestamp with time zone)
      AND (p_date_to IS NULL OR TRIM(p_date_to) = '' OR r.created_at <= (p_date_to || ' 23:59:59.999+08')::timestamp with time zone)
  ),
  grouped_plates AS (
    SELECT 
      plat_nomor,
      bool_or(is_ojol) AS is_ojol,
      COUNT(id) AS attempt_count,
      MAX(created_at) AS latest_attempt_at,
      json_agg(
        json_build_object(
          'id', id,
          'created_at', created_at,
          'spbu_id', attempt_spbu_id,
          'spbu_nama', spbu_nama,
          'operator_id', attempt_operator_id,
          'operator_nama', operator_nama,
          'is_ojol', is_ojol,
          'attempted_liter', attempted_liter,
          'total_harga_today', total_harga_today,
          'reason', reason
        ) ORDER BY created_at DESC
      ) AS attempts,
      COUNT(*) OVER() AS full_plate_count
    FROM raw_logs
    GROUP BY plat_nomor
  )
  SELECT 
    COALESCE(MAX(full_plate_count), 0),
    json_agg(
      json_build_object(
        'plat_nomor', plat_nomor,
        'is_ojol', is_ojol,
        'attempt_count', attempt_count,
        'latest_attempt_at', latest_attempt_at,
        'attempts', attempts
      ) ORDER BY latest_attempt_at DESC
    )
  INTO v_total_plates, v_logs
  FROM (
    SELECT * FROM grouped_plates
    ORDER BY latest_attempt_at DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 100)
    OFFSET GREATEST(p_offset, 0)
  ) g;

  v_result := json_build_object(
    'success', true,
    'total_attempts', v_total_attempts,
    'total_plates', v_total_plates,
    'data', COALESCE(v_logs, '[]'::json)
  );

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_repeated_transactions(text, text, text, integer, integer) TO authenticated;

-- 8.6 RPC: get_master_repeated_analytics
-- [AUDIT FIX #NEW-4] Ubah tipe parameter dari date ke text untuk konsistensi timezone
CREATE OR REPLACE FUNCTION public.get_master_repeated_analytics(
  p_spbu_id text DEFAULT NULL,
  p_date_from text DEFAULT NULL,
  p_date_to text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_detected integer;
  v_top_plates json;
  v_effective_spbu text;
  v_from timestamptz;
  v_to timestamptz;
BEGIN
  -- [AUDIT FIX #10] Tambah auth check dan role validation
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: Sesi tidak terautentikasi';
  END IF;

  IF public.get_user_role() = 'master' THEN
    v_effective_spbu := NULLIF(TRIM(p_spbu_id), '');
  ELSIF public.get_user_role() = 'operator' THEN
    v_effective_spbu := public.get_user_spbu_id();
  ELSE
    RAISE EXCEPTION 'Akses ditolak: Role tidak valid untuk mengakses analytics';
  END IF;

  -- [AUDIT FIX #NEW-4] Parse date string dengan offset WITA (+08) eksplisit
  IF p_date_from IS NOT NULL AND TRIM(p_date_from) != '' THEN
    v_from := (p_date_from || ' 00:00:00+08')::timestamp with time zone;
  END IF;
  IF p_date_to IS NOT NULL AND TRIM(p_date_to) != '' THEN
    v_to := (p_date_to || ' 23:59:59.999+08')::timestamp with time zone;
  END IF;

  SELECT COUNT(id) INTO v_total_detected
  FROM public.repeated_transaction_logs
  WHERE (v_effective_spbu IS NULL OR attempt_spbu_id = v_effective_spbu)
    AND (v_from IS NULL OR created_at >= v_from)
    AND (v_to IS NULL OR created_at <= v_to);

  SELECT json_agg(t) INTO v_top_plates
  FROM (
    SELECT 
      plat_nomor, 
      COUNT(*) as total_attempts, 
      MAX(created_at) as last_attempt
    FROM public.repeated_transaction_logs
    WHERE (v_effective_spbu IS NULL OR attempt_spbu_id = v_effective_spbu)
      AND (v_from IS NULL OR created_at >= v_from)
      AND (v_to IS NULL OR created_at <= v_to)
    GROUP BY plat_nomor
    ORDER BY total_attempts DESC
    LIMIT 10
  ) t;

  RETURN json_build_object(
    'total_detected', v_total_detected,
    'top_plates', COALESCE(v_top_plates, '[]'::json)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_repeated_analytics(text, text, text) TO authenticated;

-- 8.6.1 RPC: get_master_analytics_summary (LCP Master Analytics)
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
  v_caller_role text;
  v_effective_spbu text;
  v_total_sales numeric := 0;
  v_total_volume numeric := 0;
  v_total_trx integer := 0;
  v_days_count integer := 1;
  v_avg_trx_per_day numeric := 0;
  v_trend_json json;
  v_leaderboard_json json;
  v_start_time timestamptz;
  v_end_time timestamptz;
  v_result json;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: Sesi tidak terautentikasi';
  END IF;

  v_caller_role := public.get_user_role();
  IF v_caller_role IS NULL OR LOWER(v_caller_role) != 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Hanya role Master yang diizinkan melihat ringkasan analitik';
  END IF;

  v_effective_spbu := NULLIF(TRIM(p_spbu_id), '');

  IF p_date_from IS NOT NULL AND TRIM(p_date_from) != '' THEN
    v_start_time := (p_date_from || ' 00:00:00+08')::timestamp with time zone;
  END IF;

  IF p_date_to IS NOT NULL AND TRIM(p_date_to) != '' THEN
    v_end_time := (p_date_to || ' 23:59:59.999+08')::timestamp with time zone;
  END IF;

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
  JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (v_effective_spbu IS NULL OR op.spbu_id = v_effective_spbu)
    AND (v_start_time IS NULL OR t.waktu_pencatatan >= v_start_time)
    AND (v_end_time IS NULL OR t.waktu_pencatatan <= v_end_time);

  -- Hitung rentang hari untuk rata-rata harian
  IF v_start_time IS NOT NULL AND v_end_time IS NOT NULL THEN
    v_days_count := GREATEST(EXTRACT(DAY FROM (v_end_time - v_start_time))::integer + 1, 1);
  ELSE
    v_days_count := 30;
  END IF;
  
  v_avg_trx_per_day := ROUND(v_total_trx::numeric / v_days_count::numeric, 1);

  -- 2. Trend Penjualan Harian (Bar + Line Chart)
  WITH daily_trend AS (
    SELECT 
      (t.waktu_pencatatan AT TIME ZONE 'Asia/Makassar')::date AS date_val,
      COALESCE(SUM(t.harga), 0) AS sales,
      COALESCE(SUM(t.liter), 0) AS volume
    FROM public.transaksi_pertalite t
    JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (v_effective_spbu IS NULL OR op.spbu_id = v_effective_spbu)
      AND (v_start_time IS NULL OR t.waktu_pencatatan >= v_start_time)
      AND (v_end_time IS NULL OR t.waktu_pencatatan <= v_end_time)
    GROUP BY 1
    ORDER BY date_val ASC
  )
  SELECT json_agg(
    json_build_object(
      'date', to_char(date_val, 'DD Mon'),
      'sales', sales,
      'volume', volume
    )
  ) INTO v_trend_json FROM daily_trend;

  -- 3. Leaderboard Performa & Kontribusi SPBU
  WITH spbu_totals AS (
    SELECT 
      s.id AS spbu_id,
      COALESCE(s.nama, CONCAT('SPBU #', s.id)) AS spbu_name,
      COALESCE(SUM(t.harga), 0) AS revenue,
      COALESCE(SUM(t.liter), 0) AS volume,
      COUNT(t.id) AS total_trx
    FROM public.spbu s
    LEFT JOIN public.operator_profiles op ON op.spbu_id = s.id
    LEFT JOIN public.transaksi_pertalite t 
      ON t.operator_id = op.id 
      AND (v_start_time IS NULL OR t.waktu_pencatatan >= v_start_time)
      AND (v_end_time IS NULL OR t.waktu_pencatatan <= v_end_time)
    WHERE (v_effective_spbu IS NULL OR s.id = v_effective_spbu)
    GROUP BY s.id, s.nama
  ),
  spbu_ranked AS (
    SELECT 
      spbu_id,
      spbu_name,
      revenue,
      volume,
      total_trx,
      CASE WHEN v_total_sales > 0 THEN ROUND((revenue / v_total_sales) * 100, 1) ELSE 0 END AS share_pct,
      ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rank_pos
    FROM spbu_totals
  )
  SELECT json_agg(
    json_build_object(
      'rank', rank_pos,
      'spbu_id', spbu_id,
      'spbu_name', spbu_name,
      'revenue', revenue,
      'volume', volume,
      'total_trx', total_trx,
      'share_pct', share_pct,
      'status', CASE WHEN rank_pos = 1 AND revenue > 0 THEN 'Top Performer' WHEN revenue = 0 THEN 'No Activity' ELSE 'Normal' END
    ) ORDER BY revenue DESC
  ) INTO v_leaderboard_json FROM spbu_ranked;

  -- Build Result JSON (Kompatibilitas ganda kpis & kpi)
  v_result := json_build_object(
    'kpis', json_build_object(
      'totalSales', v_total_sales,
      'totalVolume', v_total_volume,
      'totalTrx', v_total_trx,
      'avgTrxPerDay', v_avg_trx_per_day
    ),
    'kpi', json_build_object(
      'total_sales', v_total_sales,
      'total_volume', v_total_volume,
      'total_trx', v_total_trx,
      'avg_trx_per_day', v_avg_trx_per_day
    ),
    'trend', COALESCE(v_trend_json, '[]'::json),
    'leaderboard', COALESCE(v_leaderboard_json, '[]'::json)
  );

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_analytics_summary(text, text, text) TO authenticated;


-- 8.7 RPC: get_spbu_top_plates
CREATE OR REPLACE FUNCTION public.get_spbu_top_plates(
  p_spbu_id text DEFAULT NULL,
  p_date_from text DEFAULT '',
  p_date_to text DEFAULT '',
  p_limit integer DEFAULT 10
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
  v_date_from timestamp with time zone;
  v_date_to timestamp with time zone;
  v_result json;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: Sesi tidak terautentikasi';
  END IF;

  v_role := public.get_user_role();
  IF v_role IS NULL OR LOWER(v_role) != 'master' THEN
    RAISE EXCEPTION 'Forbidden: Akses ditolak.';
  END IF;

  -- [AUDIT FIX #NEW-3] Tambah offset +08 (WITA) agar tidak tergeser ke UTC
  IF p_date_from IS NOT NULL AND TRIM(p_date_from) != '' THEN
    v_date_from := (p_date_from || ' 00:00:00+08')::timestamp with time zone;
  END IF;

  IF p_date_to IS NOT NULL AND TRIM(p_date_to) != '' THEN
    v_date_to := (p_date_to || ' 23:59:59.999+08')::timestamp with time zone;
  END IF;

  WITH raw_trx AS (
    SELECT 
      regexp_replace(UPPER(TRIM(t.plat_nomor)), '\s+', ' ', 'g') AS plat_nomor,
      t.liter,
      t.harga,
      COALESCE(t.is_ojol, false) AS is_ojol
    FROM public.transaksi_pertalite t
    INNER JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE (p_spbu_id IS NULL OR TRIM(p_spbu_id) = '' OR op.spbu_id = p_spbu_id)
      AND (v_date_from IS NULL OR t.waktu_pencatatan >= v_date_from)
      AND (v_date_to IS NULL OR t.waktu_pencatatan <= v_date_to)
  ),
  aggregated_plates AS (
    SELECT 
      plat_nomor,
      bool_or(is_ojol) AS is_ojol,
      COUNT(*) AS trx_count,
      SUM(liter) AS total_liter,
      SUM(harga) AS total_harga
    FROM raw_trx
    GROUP BY plat_nomor
    ORDER BY SUM(liter) DESC, COUNT(*) DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 50)
  )
  SELECT json_agg(
    json_build_object(
      'plat_nomor', plat_nomor,
      'is_ojol', is_ojol,
      'trx_count', trx_count,
      'total_liter', total_liter,
      'total_harga', total_harga
    )
  ) INTO v_result
  FROM aggregated_plates;

  RETURN json_build_object(
    'success', true,
    'top_plates', COALESCE(v_result, '[]'::json)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_spbu_top_plates(text, text, text, integer) TO authenticated;

-- 8.8 RPC: master_reset_operator_password
CREATE OR REPLACE FUNCTION public.master_reset_operator_password(
  p_target_user_id uuid,
  p_new_password text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions, vault
AS $$
DECLARE
  v_caller_uid uuid;
  v_caller_role text;
  v_target_role text;
  v_caller_email text;
BEGIN
  v_caller_uid := auth.uid();
  IF v_caller_uid IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: Sesi pengguna tidak terautentikasi';
  END IF;

  v_caller_role := public.get_user_role();
  IF v_caller_role IS NULL THEN
    SELECT role INTO v_caller_role FROM public.user_roles WHERE user_id = v_caller_uid LIMIT 1;
  END IF;

  -- [AUDIT FIX #1] Fix privilege escalation: NULL role HARUS ditolak, bukan di-fallback ke 'master'
  IF v_caller_role IS NULL OR LOWER(v_caller_role) != 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Hanya role Master yang diizinkan mereset password akun operator';
  END IF;

  -- [AUDIT FIX #16] Tingkatkan minimum password ke 8 karakter
  IF p_new_password IS NULL OR length(p_new_password) < 8 THEN
    RAISE EXCEPTION 'Password baru minimal harus 8 karakter';
  END IF;

  SELECT role INTO v_target_role FROM public.user_roles WHERE user_id = p_target_user_id;
  IF v_target_role IS NULL THEN
    RAISE EXCEPTION 'Akun user target tidak ditemukan di sistem user_roles';
  END IF;

  IF v_target_role = 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Tidak diizinkan mereset password akun ber-role Master melalui RPC ini';
  END IF;

  UPDATE auth.users
  SET encrypted_password = crypt(p_new_password, gen_salt('bf', 10)),
      updated_at = NOW()
  WHERE id = p_target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User ID target tidak ditemukan di tabel autentikasi Supabase (auth.users)';
  END IF;

  BEGIN
    DELETE FROM auth.sessions WHERE user_id = p_target_user_id;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  BEGIN
    SELECT email INTO v_caller_email FROM auth.users WHERE id = v_caller_uid;

    INSERT INTO public.activity_logs (user_email, action, details, timestamp)
    VALUES (
      COALESCE(v_caller_email, 'master_admin@fuelguard'),
      'MASTER_RESET_OPERATOR_PASSWORD',
      json_build_object(
        'master_user_id', v_caller_uid,
        'target_user_id', p_target_user_id,
        'target_role', v_target_role
      )::jsonb,
      NOW()
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN json_build_object(
    'success', true,
    'message', 'Password akun operator berhasil diperbarui'
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.master_reset_operator_password(uuid, text) TO authenticated;

-- ─── 9. SCHEMA RELOAD NOTIFICATION ───────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
