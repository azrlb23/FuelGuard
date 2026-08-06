-- =============================================================================
-- SQL Patch Migration: 10_fix_rpc_fuel_price_lookup.sql
-- Description: Derive spbu_id directly from auth.uid() & auto-resolve operator_id
-- =============================================================================

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
  -- 1. Check Login Auth Session
  IF auth.uid() IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'unauthorized',
      'message', 'Akses ditolak. Anda harus login terlebih dahulu.'
    );
  END IF;

  -- 2. Ambil spbu_id LANGSUNG dari auth.uid() (tabel user_roles)
  v_spbu_id := public.get_user_spbu_id();
  IF v_spbu_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'no_spbu',
      'message', 'Akun Anda tidak terikat dengan unit SPBU manapun.'
    );
  END IF;

  -- 3. Tentukan operator_id dari auth / operator_profiles SPBU tersebut
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

  -- 4. Validasi Format Plat Nomor
  IF NOT (v_plat_clean ~* '^[A-Z]{1,2}\s\d{1,4}(\s[A-Z]{1,3})?$') THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'invalid_format',
      'message', 'Format plat nomor tidak valid (Contoh valid: KT 1234 AB).'
    );
  END IF;

  -- 5. Validasi Kode Wilayah Plat Indonesia
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

  -- 6. Advisory Lock
  PERFORM pg_advisory_xact_lock(hashtext(v_plat_clean));

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

  -- 7. Ambil Harga BBM Pertalite dari tabel fuel_prices
  SELECT price_per_liter INTO v_harga_per_liter
  FROM public.fuel_prices
  WHERE LOWER(fuel_type) LIKE '%pertalite%'
  ORDER BY updated_at DESC NULLS LAST
  LIMIT 1;

  IF v_harga_per_liter IS NULL OR v_harga_per_liter <= 0 THEN
    v_harga_per_liter := 10000; -- Default fallback price
  END IF;

  v_total_harga := p_liter * v_harga_per_liter;

  -- 8. Cek Akumulasi Transaksi Harian
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

  -- 9. Simpan Transaksi Berhasil
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
