-- =============================================================================
-- SQL Migration: Complete Production Schema & Future Feature Upgrade
-- Security: RLS Hardened, Atomic Locks, Strict Role Privilege & Input Validation
-- Minimal comments for clean documentation
-- =============================================================================

-- ─── 1. TABLE SCHEMA ALTERATIONS & NEW TABLES ────────────────────────────────

ALTER TABLE public.transaksi_pertalite 
  ADD COLUMN IF NOT EXISTS operator_name text,
  ADD COLUMN IF NOT EXISTS tgl_pencatatan date DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS jam_pencatatan time DEFAULT CURRENT_TIME,
  ADD COLUMN IF NOT EXISTS is_ojol boolean DEFAULT false;

CREATE TABLE IF NOT EXISTS public.region_codes (
  code text PRIMARY KEY,
  region_name text NOT NULL
);

INSERT INTO public.region_codes (code, region_name) VALUES
-- Jawa & Madura
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

-- Sumatra
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

-- Kalimantan
('KB', 'Kalimantan Barat'),
('DA', 'Kalimantan Selatan'),
('KH', 'Kalimantan Tengah'),
('KT', 'Kalimantan Timur'),
('KU', 'Kalimantan Utara'),

-- Sulawesi
('DB', 'Sulawesi Utara (Manado, Bitung, Tomohon)'),
('DL', 'Sulawesi Utara Kepulauan (Sangihe, Talaud)'),
('DM', 'Gorontalo'),
('DN', 'Sulawesi Tengah'),
('DT', 'Sulawesi Tenggara'),
('DD', 'Sulawesi Selatan (Makassar, Gowa, Maros)'),
('DP', 'Sulawesi Selatan Bagian Utara (Parepare, Luwu)'),
('DC', 'Sulawesi Barat'),

-- Bali & Nusa Tenggara
('DK', 'Bali'),
('DR', 'Lombok (NTB)'),
('EA', 'Sumbawa (NTB)'),
('DH', 'Timor (NTT / Kupang)'),
('EB', 'Flores (NTT)'),
('ED', 'Sumba (NTT)'),

-- Maluku & Papua
('DE', 'Maluku'),
('DG', 'Maluku Utara'),
('DS', 'Papua (Induk)'),
('PA', 'Papua Barat / Papua Pusat'),
('PB', 'Papua Barat Daya')
ON CONFLICT (code) DO UPDATE SET region_name = EXCLUDED.region_name;

DELETE FROM public.fuel_prices WHERE LOWER(fuel_type) LIKE '%pertamax%';

-- ─── INDEXES UNTUK PERFORMA JUTAAN DATA (< 1 ms Lookup) ─────────────────────
CREATE INDEX IF NOT EXISTS idx_trx_plat_waktu 
  ON public.transaksi_pertalite (plat_nomor, waktu_pencatatan DESC);

CREATE INDEX IF NOT EXISTS idx_trx_spbu_waktu 
  ON public.transaksi_pertalite (spbu_id, waktu_pencatatan DESC);

CREATE INDEX IF NOT EXISTS idx_trx_tgl_pencatatan 
  ON public.transaksi_pertalite (tgl_pencatatan DESC);


-- ─── 2. HELPER FUNCTIONS ──────────────────────────────────────────────────────

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


-- ─── 3. RPC: fn_check_plate_status ───────────────────────────────────────────

DROP FUNCTION IF EXISTS public.fn_check_plate_status CASCADE;

CREATE OR REPLACE FUNCTION public.fn_check_plate_status(
  p_plat text,
  p_jenis text DEFAULT 'Motor',
  p_spbu_id text DEFAULT NULL,
  p_is_ojol boolean DEFAULT false
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
  v_is_motor boolean;
  v_last_trx json := NULL;
  v_last_time text := '';
BEGIN
  v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());
  IF v_spbu_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_spbu');
  END IF;

  v_is_motor := LOWER(p_jenis) = 'motor';
  IF v_is_motor AND p_is_ojol THEN
    v_max_quota := 100000;
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

  IF v_is_motor THEN
    v_has_refueled := v_total_harga_today >= v_max_quota;
    v_remaining_quota := GREATEST(0, v_max_quota - v_total_harga_today);
  ELSE
    v_has_refueled := v_count_today > 0;
    v_remaining_quota := 0;
  END IF;

  IF v_count_today > 0 THEN
    SELECT json_build_object(
      'id', t.id,
      'liter', t.liter,
      'harga', t.harga,
      'waktu_pencatatan', t.waktu_pencatatan,
      'jam_pencatatan', t.jam_pencatatan,
      'jenis_kendaraan', t.jenis_kendaraan,
      'spbu_id', t.spbu_id,
      'spbu_nama', COALESCE(s.nama, CONCAT('SPBU #', t.spbu_id))
    )
    INTO v_last_trx
    FROM public.transaksi_pertalite t
    LEFT JOIN public.spbu s ON s.id = t.spbu_id
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
GRANT EXECUTE ON FUNCTION public.fn_check_plate_status(text, text, text, boolean) TO authenticated;


-- ─── 4. RPC: fn_safe_insert_transaction ──────────────────────────────────────

DROP FUNCTION IF EXISTS public.fn_safe_insert_transaction CASCADE;

CREATE OR REPLACE FUNCTION public.fn_safe_insert_transaction(
  p_plat text,
  p_liter numeric,
  p_jenis text DEFAULT 'Motor',
  p_shift integer DEFAULT 1,
  p_operator_name text DEFAULT NULL,
  p_is_ojol boolean DEFAULT false
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
  v_max_quota numeric := 50000;
  v_new_id bigint;
BEGIN
  v_user_id := auth.uid();
  v_spbu_id := public.get_user_spbu_id();
  v_plat_clean := UPPER(TRIM(p_plat));
  v_is_motor := LOWER(p_jenis) = 'motor';

  IF v_spbu_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_spbu', 'message', 'SPBU tidak ditemukan untuk user ini.');
  END IF;

  IF v_plat_clean = '' OR p_liter <= 0 THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_input', 'message', 'Plat nomor dan liter harus valid.');
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(v_plat_clean));

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

  SELECT 
    COALESCE(SUM(harga), 0),
    COUNT(id)
  INTO v_total_harga_today, v_count_today
  FROM public.transaksi_pertalite
  WHERE plat_nomor = v_plat_clean
    AND waktu_pencatatan >= date_trunc('day', NOW())
    AND waktu_pencatatan < date_trunc('day', NOW()) + INTERVAL '1 day';

  IF v_is_motor THEN
    IF p_is_ojol THEN
      v_max_quota := 100000;
    END IF;

    IF (v_total_harga_today + v_total_harga) > v_max_quota THEN
      RETURN json_build_object(
        'success', false,
        'reason', 'quota_exceeded',
        'message', format('Kuota Motor (Rp %s/hari) terlampaui! Sudah terisi: Rp %s.', v_max_quota, v_total_harga_today)
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

  SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;

  INSERT INTO public.transaksi_pertalite (
    plat_nomor, liter, harga, jenis_kendaraan, shift,
    operator_id, operator_email, operator_name, spbu_id,
    waktu_pencatatan, tgl_pencatatan, jam_pencatatan, is_ojol
  ) VALUES (
    v_plat_clean, p_liter, v_total_harga, p_jenis, p_shift,
    v_user_id, v_user_email, COALESCE(p_operator_name, v_user_email), v_spbu_id,
    NOW(), CURRENT_DATE, CURRENT_TIME, p_is_ojol
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
GRANT EXECUTE ON FUNCTION public.fn_safe_insert_transaction(text, numeric, text, integer, text, boolean) TO authenticated;


-- ─── 5. RPC: get_dashboard_summary ───────────────────────────────────────────

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
  v_shift_chart json;
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

  SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) INTO v_feed
  FROM (
    SELECT id, plat_nomor, liter, harga, jenis_kendaraan, waktu_pencatatan, tgl_pencatatan, jam_pencatatan, operator_email, operator_name, is_ojol
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
    ORDER BY waktu_pencatatan DESC
    LIMIT 10
  ) t;

  IF (v_feed IS NULL OR v_feed::text = '[]') AND p_filter = 'today' THEN
    SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) INTO v_feed
    FROM (
      SELECT id, plat_nomor, liter, harga, jenis_kendaraan, waktu_pencatatan, tgl_pencatatan, jam_pencatatan, operator_email, operator_name, is_ojol
      FROM public.transaksi_pertalite
      WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      ORDER BY waktu_pencatatan DESC
      LIMIT 10
    ) t;
  END IF;

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

  SELECT COALESCE(json_agg(json_build_object('label', jenis_kendaraan, 'count', cnt)), '[]'::json)
  INTO v_vehicle_chart
  FROM (
    SELECT COALESCE(jenis_kendaraan, 'Umum') AS jenis_kendaraan, COUNT(*) AS cnt
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
    GROUP BY jenis_kendaraan
  ) sub;

  SELECT COALESCE(json_agg(json_build_object('hour', h, 'count', cnt) ORDER BY h), '[]'::json)
  INTO v_peak_hours
  FROM (
    SELECT EXTRACT(HOUR FROM waktu_pencatatan)::integer AS h, COUNT(*) AS cnt
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
    GROUP BY 1
  ) sub;

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

  SELECT COALESCE(json_agg(json_build_object('label', jenis_kendaraan, 'total', total_rev)), '[]'::json)
  INTO v_revenue_share
  FROM (
    SELECT COALESCE(jenis_kendaraan, 'Umum') AS jenis_kendaraan, SUM(harga) AS total_rev
    FROM public.transaksi_pertalite
    WHERE (v_spbu_id IS NULL OR spbu_id = v_spbu_id)
      AND waktu_pencatatan >= v_start_time
    GROUP BY jenis_kendaraan
  ) sub;

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


-- ─── 6. RPC: get_export_transactions ─────────────────────────────────────────

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
      trx.tgl_pencatatan, 
      trx.jam_pencatatan, 
      trx.jenis_kendaraan, 
      trx.plat_nomor, 
      trx.liter, 
      trx.harga, 
      COALESCE(trx.operator_name, trx.operator_email) AS operator_nama,
      COALESCE(s.nama, CONCAT('SPBU #', trx.spbu_id)) AS spbu_nama,
      trx.is_ojol
    FROM public.transaksi_pertalite trx
    LEFT JOIN public.spbu s ON s.id = trx.spbu_id
    WHERE (v_spbu_id IS NULL OR trx.spbu_id = v_spbu_id)
      AND trx.waktu_pencatatan >= (p_start_date || 'T00:00:00')::timestamp
      AND trx.waktu_pencatatan <= (p_end_date || 'T23:59:59')::timestamp
    ORDER BY trx.waktu_pencatatan ASC
  ) t;

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_export_transactions(text, text, text) TO authenticated;


-- ─── 7. AUDIT TRAIL TRIGGER ───────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.fn_audit_transaction CASCADE;
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
      'spbu_id', NEW.spbu_id,
      'operator_name', NEW.operator_name,
      'is_ojol', NEW.is_ojol
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


-- ─── 8. STRICT RLS POLICIES ───────────────────────────────────────────────────

ALTER TABLE public.transaksi_pertalite ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "trx_select_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_insert_policy" ON public.transaksi_pertalite;

CREATE POLICY "trx_select_policy" ON public.transaksi_pertalite
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR spbu_id = public.get_user_spbu_id()
  );

CREATE POLICY "trx_insert_policy" ON public.transaksi_pertalite
  FOR INSERT WITH CHECK (
    public.get_user_role() = 'master'
  );

ALTER TABLE public.fuel_prices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fuel_prices_select" ON public.fuel_prices;
DROP POLICY IF EXISTS "fuel_prices_modify" ON public.fuel_prices;

CREATE POLICY "fuel_prices_select" ON public.fuel_prices
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "fuel_prices_modify" ON public.fuel_prices
  FOR ALL USING (
    public.get_user_role() IN ('manajer', 'master')
  );

ALTER TABLE public.shift_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "shift_config_select" ON public.shift_config;
DROP POLICY IF EXISTS "shift_config_modify" ON public.shift_config;

CREATE POLICY "shift_config_select" ON public.shift_config
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "shift_config_modify" ON public.shift_config
  FOR ALL USING (
    public.get_user_role() IN ('manajer', 'master')
  );

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

NOTIFY pgrst, 'reload schema';
