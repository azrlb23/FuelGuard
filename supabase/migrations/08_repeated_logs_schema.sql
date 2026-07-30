-- =============================================================================
-- SQL Migration: 08_repeated_logs_schema.sql
-- Description: Logging & Analitik Transaksi Berulang (Anti-Pengetap Audit System)
--              + RLS Isolasi Transaksi Per-SPBU
--              + Updated RPC get_master_history_paginated (Operator SPBU Lock)
-- =============================================================================

-- ─── 1. TABEL BARU & INDEX ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.repeated_transaction_logs (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  plat_nomor text NOT NULL,
  attempt_spbu_id text NOT NULL,
  attempt_operator_id uuid,
  is_ojol boolean DEFAULT false,
  attempted_liter numeric NOT NULL DEFAULT 0,
  total_harga_today numeric NOT NULL DEFAULT 0,
  reason text NOT NULL DEFAULT 'quota_exceeded',
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT repeated_transaction_logs_pkey PRIMARY KEY (id),
  CONSTRAINT repeated_transaction_logs_spbu_fkey FOREIGN KEY (attempt_spbu_id) REFERENCES public.spbu(id),
  CONSTRAINT repeated_transaction_logs_operator_fkey FOREIGN KEY (attempt_operator_id) REFERENCES public.operator_profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_repeated_logs_spbu_date ON public.repeated_transaction_logs(attempt_spbu_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_repeated_logs_plat ON public.repeated_transaction_logs(plat_nomor);

-- ─── 2. ROW LEVEL SECURITY (RLS) ─────────────────────────────────────────────
ALTER TABLE public.repeated_transaction_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "repeated_logs_master_select" ON public.repeated_transaction_logs;
DROP POLICY IF EXISTS "repeated_logs_operator_select" ON public.repeated_transaction_logs;
DROP POLICY IF EXISTS "repeated_logs_insert" ON public.repeated_transaction_logs;

-- Master: Dapat melihat SELURUH log perulangan dari SEMUA SPBU tanpa batasan waktu
CREATE POLICY "repeated_logs_master_select" ON public.repeated_transaction_logs
  FOR SELECT USING (
    public.get_user_role() = 'master'
  );

-- Operator: Dapat melihat log perulangan dari SELURUH SPBU (Cross-SPBU) HARI INI SAJA
CREATE POLICY "repeated_logs_operator_select" ON public.repeated_transaction_logs
  FOR SELECT USING (
    public.get_user_role() = 'operator'
    AND created_at >= date_trunc('day', NOW())
  );

-- System RPC: Izinkan pencatatan otomatis via RPC
CREATE POLICY "repeated_logs_insert" ON public.repeated_transaction_logs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);


-- ─── 3. UPDATE: fn_safe_insert_transaction (Auto-Logging) ────────────────────
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
  -- Validate Operator
  IF p_operator_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_operator', 'message', 'Operator ID tidak valid.');
  END IF;

  SELECT spbu_id INTO v_spbu_id FROM public.operator_profiles WHERE id = p_operator_id AND is_active = true;
  IF v_spbu_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_spbu', 'message', 'Operator tidak terdaftar atau tidak aktif.');
  END IF;

  v_plat_clean := UPPER(TRIM(p_plat));
  IF v_plat_clean = '' OR p_liter <= 0 THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_input', 'message', 'Plat nomor dan liter harus valid.');
  END IF;

  -- Validasi Kode Wilayah Plat Indonesia (jika tabel region_codes ada)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'region_codes') THEN
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
  END IF;

  IF p_is_ojol THEN
    v_max_quota := 100000;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(v_plat_clean));

  -- Get Price
  SELECT price_per_liter INTO v_harga_per_liter
  FROM public.fuel_prices
  WHERE spbu_id = v_spbu_id
    AND LOWER(fuel_type) LIKE '%pertalite%'
  ORDER BY updated_at DESC NULLS LAST
  LIMIT 1;

  IF v_harga_per_liter IS NULL OR v_harga_per_liter <= 0 THEN
    v_harga_per_liter := 10000; -- Default fallback
  END IF;

  v_total_harga := p_liter * v_harga_per_liter;

  -- Quota Check
  SELECT 
    COALESCE(SUM(harga), 0),
    COUNT(id)
  INTO v_total_harga_today, v_count_today
  FROM public.transaksi_pertalite
  WHERE plat_nomor = v_plat_clean
    AND waktu_pencatatan >= date_trunc('day', NOW())
    AND waktu_pencatatan < date_trunc('day', NOW()) + INTERVAL '1 day';

  -- ANTI-PENGETAP LOGGING INJECTION
  IF (v_total_harga_today + v_total_harga) > v_max_quota THEN
    
    INSERT INTO public.repeated_transaction_logs (
      plat_nomor, attempt_spbu_id, attempt_operator_id, is_ojol, 
      attempted_liter, total_harga_today, reason, created_at
    ) VALUES (
      v_plat_clean, v_spbu_id, p_operator_id, p_is_ojol,
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

  -- Sukses Insert
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


-- ─── 4. RPC: get_operator_repeated_logs ──────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_operator_repeated_logs CASCADE;
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
  v_count_today integer;
  v_offset integer;
  v_logs json;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;

  SELECT COUNT(id) INTO v_count_today
  FROM public.repeated_transaction_logs
  WHERE (p_spbu_id IS NULL OR p_spbu_id = '' OR attempt_spbu_id = p_spbu_id)
    AND created_at >= date_trunc('day', NOW())
    AND (p_search = '' OR plat_nomor ILIKE '%' || p_search || '%');

  SELECT json_agg(t) INTO v_logs
  FROM (
    SELECT 
      l.id, 
      l.plat_nomor, 
      l.is_ojol, 
      l.attempted_liter,
      l.total_harga_today, 
      l.reason,
      l.attempt_spbu_id,
      to_char(l.created_at, 'DD Mon YYYY') as tanggal,
      to_char(l.created_at, 'HH24:MI') as waktu,
      op.nama_operator
    FROM public.repeated_transaction_logs l
    LEFT JOIN public.operator_profiles op ON op.id = l.attempt_operator_id
    WHERE (p_spbu_id IS NULL OR p_spbu_id = '' OR l.attempt_spbu_id = p_spbu_id)
      AND l.created_at >= date_trunc('day', NOW())
      AND (p_search = '' OR l.plat_nomor ILIKE '%' || p_search || '%')
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


-- ─── 5. RPC: get_master_repeated_analytics ───────────────────────────────────
DROP FUNCTION IF EXISTS public.get_master_repeated_analytics CASCADE;
CREATE OR REPLACE FUNCTION public.get_master_repeated_analytics(
  p_spbu_id text DEFAULT NULL,
  p_date_from date DEFAULT NULL,
  p_date_to date DEFAULT NULL
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
BEGIN
  IF public.get_user_role() = 'master' THEN
    v_effective_spbu := COALESCE(p_spbu_id, public.get_user_spbu_id());
  ELSE
    v_effective_spbu := public.get_user_spbu_id();
  END IF;

  SELECT COUNT(id) INTO v_total_detected
  FROM public.repeated_transaction_logs
  WHERE (v_effective_spbu IS NULL OR attempt_spbu_id = v_effective_spbu)
    AND (p_date_from IS NULL OR created_at >= p_date_from)
    AND (p_date_to IS NULL OR created_at < p_date_to + INTERVAL '1 day');

  SELECT json_agg(t) INTO v_top_plates
  FROM (
    SELECT 
      plat_nomor, 
      COUNT(*) as total_attempts, 
      MAX(created_at) as last_attempt
    FROM public.repeated_transaction_logs
    WHERE (v_effective_spbu IS NULL OR attempt_spbu_id = v_effective_spbu)
      AND (p_date_from IS NULL OR created_at >= p_date_from)
      AND (p_date_to IS NULL OR created_at < p_date_to + INTERVAL '1 day')
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
GRANT EXECUTE ON FUNCTION public.get_master_repeated_analytics(text, date, date) TO authenticated;


-- ─── 6. RLS: ISOLASI TRANSAKSI PER-SPBU ──────────────────────────────────────
-- Operator hanya bisa melihat transaksi yang dicatat di SPBU miliknya sendiri.
-- Master bebas melihat transaksi dari semua SPBU.
ALTER TABLE public.transaksi_pertalite ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "trx_select_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_operator_select_policy" ON public.transaksi_pertalite;

CREATE POLICY "trx_operator_select_policy" ON public.transaksi_pertalite
  FOR SELECT USING (
    -- Master: bebas lihat semua SPBU
    (public.get_user_role() = 'master')
    OR
    -- Operator: hanya bisa lihat transaksi yang berasal dari SPBU-nya sendiri
    (
      public.get_user_role() = 'operator'
      AND operator_id IN (
        SELECT id FROM public.operator_profiles WHERE spbu_id = public.get_user_spbu_id()
      )
    )
  );


-- ─── 7. UPDATE RPC: get_master_history_paginated (Operator SPBU Lock) ─────────
-- Jika caller adalah Operator, paksa p_spbu_id = SPBU milik operator tersebut.
-- Jika caller adalah Master, gunakan p_spbu_id yang dikirim (atau NULL = semua).
DROP FUNCTION IF EXISTS public.get_master_history_paginated CASCADE;
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
  v_effective_spbu text;
  v_offset integer;
  v_total_count integer;
  v_transactions json;
  v_date_from timestamp with time zone;
  v_date_to timestamp with time zone;
BEGIN
  -- Kunci SPBU untuk Operator: Operator selalu dipaksa membaca SPBU-nya sendiri
  IF public.get_user_role() = 'operator' THEN
    v_effective_spbu := public.get_user_spbu_id();
  ELSE
    v_effective_spbu := NULLIF(TRIM(p_spbu_id), '');
  END IF;

  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;

  IF p_date_from IS NOT NULL AND p_date_from != '' THEN
    v_date_from := (p_date_from || ' 00:00:00')::timestamp with time zone;
  END IF;

  IF p_date_to IS NOT NULL AND p_date_to != '' THEN
    v_date_to := (p_date_to || ' 23:59:59.999')::timestamp with time zone;
  END IF;

  -- Count Total
  SELECT COUNT(t.id) INTO v_total_count
  FROM public.transaksi_pertalite t
  JOIN public.operator_profiles op ON op.id = t.operator_id
  WHERE (v_effective_spbu IS NULL OR op.spbu_id = v_effective_spbu)
    AND (p_search = '' OR t.plat_nomor ILIKE '%' || p_search || '%')
    AND (v_date_from IS NULL OR t.waktu_pencatatan >= v_date_from)
    AND (v_date_to IS NULL OR t.waktu_pencatatan <= v_date_to);

  -- Get Data
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
      s.nama as spbu_nama
    FROM public.transaksi_pertalite t
    JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE (v_effective_spbu IS NULL OR op.spbu_id = v_effective_spbu)
      AND (p_search = '' OR t.plat_nomor ILIKE '%' || p_search || '%')
      AND (v_date_from IS NULL OR t.waktu_pencatatan >= v_date_from)
      AND (v_date_to IS NULL OR t.waktu_pencatatan <= v_date_to)
    ORDER BY
      CASE WHEN LOWER(p_sort_dir) = 'asc'  AND p_sort_field = 'plat_nomor'        THEN t.plat_nomor END ASC,
      CASE WHEN LOWER(p_sort_dir) = 'desc' AND p_sort_field = 'plat_nomor'        THEN t.plat_nomor END DESC,
      CASE WHEN LOWER(p_sort_dir) = 'asc'  AND p_sort_field = 'liter'             THEN t.liter END ASC,
      CASE WHEN LOWER(p_sort_dir) = 'desc' AND p_sort_field = 'liter'             THEN t.liter END DESC,
      CASE WHEN LOWER(p_sort_dir) = 'asc'  AND p_sort_field = 'harga'             THEN t.harga END ASC,
      CASE WHEN LOWER(p_sort_dir) = 'desc' AND p_sort_field = 'harga'             THEN t.harga END DESC,
      CASE WHEN LOWER(p_sort_dir) = 'asc'  AND p_sort_field = 'waktu_pencatatan'  THEN t.waktu_pencatatan END ASC,
      CASE WHEN LOWER(p_sort_dir) = 'desc' OR p_sort_field IS NULL               THEN t.waktu_pencatatan END DESC
    LIMIT p_page_size OFFSET v_offset
  ) sub;

  RETURN json_build_object(
    'total_count', COALESCE(v_total_count, 0),
    'transactions', COALESCE(v_transactions, '[]'::json)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_master_history_paginated(integer, integer, text, text, text, text, text, text) TO authenticated;


NOTIFY pgrst, 'reload schema';
