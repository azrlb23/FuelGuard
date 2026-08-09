-- =============================================================================
-- SQL Patch Migration: 09_fix_plate_regex_validation.sql
-- Description: Server-Side License Plate Format Regex Enforcement (Anti-Pentest Bypass)
-- Target RPCs: fn_safe_insert_transaction & fn_check_plate_status
-- =============================================================================

-- ─── 1. UPDATE: fn_check_plate_status ─────────────────────────────────────────
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
BEGIN
  v_spbu_id := COALESCE(p_spbu_id, public.get_user_spbu_id());
  v_today_start := date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar';
  v_plat_clean := regexp_replace(UPPER(TRIM(p_plat)), '\s+', ' ', 'g');

  -- 🔴 VALIDASI SERVER-SIDE REGEX PLAT NOMOR INDONESIA
  -- Format: 1-2 Huruf Wilayah + 1 Spasi + 1-4 Digit Angka + (Opsional 1 Spasi + 1-3 Huruf Akhiran)
  -- Contoh Valid: KT 1234 AB, B 123 A, DK 1234
  -- Contoh Ditolak: KT 8887 CROSS (huruf akhiran > 3), KT 0123 AB (angka diawali 0)
  IF NOT (v_plat_clean ~* '^[A-Z]{1,3}\s\d{1,4}(\s[A-Z]{1,3})?$') THEN
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

  -- Cari transaksi pertama plat ini hari ini untuk mengunci status is_ojol harian
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

  -- Hitung akumulasi transaksi plat hari ini (waktu WITA)
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
    'last_time', v_last_time
  );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.fn_check_plate_status(text, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_check_plate_status(text, boolean, text) TO authenticated;


-- ─── 2. UPDATE: fn_safe_insert_transaction ────────────────────────────────────
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
  IF p_operator_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_operator', 'message', 'Operator ID tidak valid.');
  END IF;

  SELECT spbu_id INTO v_spbu_id FROM public.operator_profiles WHERE id = p_operator_id AND is_active = true;
  IF v_spbu_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'no_spbu', 'message', 'Operator tidak terdaftar atau tidak aktif.');
  END IF;

  v_plat_clean := regexp_replace(UPPER(TRIM(p_plat)), '\s+', ' ', 'g');
  IF v_plat_clean = '' OR p_liter <= 0 THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_input', 'message', 'Plat nomor dan liter harus valid.');
  END IF;

  -- 🔴 VALIDASI SERVER-SIDE REGEX PLAT NOMOR INDONESIA
  IF NOT (v_plat_clean ~* '^[A-Z]{1,3}\s\d{1,4}(\s[A-Z]{1,3})?$') THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'invalid_format',
      'message', 'Format plat nomor tidak valid (Contoh valid: KT 1234 AB).'
    );
  END IF;

  -- Validasi Kode Wilayah Plat Indonesia
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

  DECLARE
    v_first_is_ojol boolean := NULL;
    v_today_start timestamptz;
  BEGIN
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
      ) VALUES (
        v_plat_clean, v_spbu_id, p_operator_id, p_is_ojol,
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
  END;

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
    AND waktu_pencatatan >= date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar';

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
REVOKE EXECUTE ON FUNCTION public.fn_safe_insert_transaction(text, numeric, uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_safe_insert_transaction(text, numeric, uuid, boolean) TO authenticated;
