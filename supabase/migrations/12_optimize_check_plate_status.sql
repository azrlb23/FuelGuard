-- =============================================================================
-- SQL Patch Migration: 12_optimize_check_plate_status.sql
-- Description: Performance Optimization for fn_check_plate_status & Composite Index
-- Target RPC: fn_check_plate_status
-- =============================================================================

-- ─── 1. PERFORMANCE INDEX ────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_repeated_logs_plat_created 
  ON public.repeated_transaction_logs (plat_nomor, created_at DESC);

-- ─── 2. RPC: fn_check_plate_status (OPTIMIZED SINGLE-PASS CTE) ───────────────
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

  -- SINGLE-PASS CTE: Ambil transaksi hari ini, hitung agregasi & format history dalam 1x Query
  WITH trx_today AS (
    SELECT 
      t.id,
      t.liter,
      t.harga,
      t.waktu_pencatatan,
      t.is_ojol,
      op.spbu_id,
      op.nama_operator,
      COALESCE(s.nama, CONCAT('SPBU ', op.spbu_id)) AS spbu_nama
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE t.plat_nomor = v_plat_clean
      AND t.waktu_pencatatan >= v_today_start
  ),
  trx_stats AS (
    SELECT 
      COALESCE(SUM(liter), 0) AS total_liter,
      COALESCE(SUM(harga), 0) AS total_harga,
      COUNT(id)::int AS count_trx,
      (SELECT is_ojol FROM trx_today ORDER BY waktu_pencatatan ASC LIMIT 1) AS first_ojol,
      (
        SELECT json_build_object(
          'id', id,
          'liter', liter,
          'harga', harga,
          'waktu_pencatatan', waktu_pencatatan,
          'is_ojol', is_ojol,
          'spbu_id', spbu_id,
          'nama_operator', nama_operator
        ) FROM trx_today ORDER BY waktu_pencatatan DESC LIMIT 1
      ) AS last_trx_obj
    FROM trx_today
  ),
  history_union AS (
    SELECT 
      t.waktu_pencatatan AS waktu_raw,
      to_char(t.waktu_pencatatan AT TIME ZONE 'Asia/Makassar', 'HH24:MI') || ' WITA' AS waktu,
      COALESCE(t.spbu_id, 'Unknown') AS spbu_id,
      COALESCE(t.spbu_nama, CONCAT('SPBU ', t.spbu_id)) AS spbu_nama,
      'diterima' AS status,
      t.liter AS liter,
      t.harga AS harga,
      'Pengisian Berhasil' AS reason
    FROM trx_today t

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
  )
  SELECT 
    ts.total_liter,
    ts.total_harga,
    ts.count_trx,
    ts.first_ojol,
    ts.last_trx_obj,
    (SELECT json_agg(hu) FROM history_union hu)
  INTO 
    v_total_liter_today,
    v_total_harga_today,
    v_count_today,
    v_first_is_ojol,
    v_last_trx,
    v_history_today
  FROM trx_stats ts;

  IF v_last_trx IS NOT NULL THEN
    v_last_time := to_char((v_last_trx->>'waktu_pencatatan')::timestamptz AT TIME ZONE 'Asia/Makassar', 'HH24:MI');
  END IF;

  IF v_first_is_ojol IS NOT NULL AND v_first_is_ojol != p_is_ojol THEN
    RETURN json_build_object(
      'success', false,
      'reason', 'category_mismatch',
      'message', format('Kendaraan %s hari ini sudah terdaftar sebagai %s! Tidak dapat bertransaksi sebagai %s.',
        v_plat_clean,
        CASE WHEN v_first_is_ojol THEN 'Motor Ojol' ELSE 'Motor Biasa' END,
        CASE WHEN p_is_ojol THEN 'Motor Ojol' ELSE 'Motor Biasa' END
      ),
      'history_today', COALESCE(v_history_today, '[]'::json)
    );
  END IF;

  IF COALESCE(v_first_is_ojol, p_is_ojol) THEN
    v_max_quota := 100000;
  ELSE
    v_max_quota := 50000;
  END IF;

  v_has_refueled := v_total_harga_today >= v_max_quota;
  v_remaining_quota := GREATEST(0, v_max_quota - v_total_harga_today);

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
