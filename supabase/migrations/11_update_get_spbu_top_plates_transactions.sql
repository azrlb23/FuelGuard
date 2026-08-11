-- ─── 11. MIGRATION: UPDATE get_spbu_top_plates RPC TO INCLUDE SUB-TRANSACTIONS AND UNIQUE SPBU COUNT ───
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
  -- 1. Security Authorization Guard: Wajib Terautentikasi
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: Sesi tidak terautentikasi';
  END IF;

  -- 2. Role Check: Wajib Role Master
  v_role := public.get_user_role();
  IF v_role IS NULL OR LOWER(v_role) != 'master' THEN
    RAISE EXCEPTION 'Forbidden: Akses ditolak.';
  END IF;

  -- 3. Parse Date Range (WITA +08)
  IF p_date_from IS NOT NULL AND TRIM(p_date_from) != '' THEN
    v_date_from := (p_date_from || ' 00:00:00+08')::timestamp with time zone;
  END IF;

  IF p_date_to IS NOT NULL AND TRIM(p_date_to) != '' THEN
    v_date_to := (p_date_to || ' 23:59:59.999+08')::timestamp with time zone;
  END IF;

  -- 4. Query Raw Transactions within range & filter
  WITH raw_trx AS (
    SELECT 
      t.id,
      regexp_replace(UPPER(TRIM(t.plat_nomor)), '\s+', ' ', 'g') AS plat_nomor,
      t.liter,
      t.harga,
      COALESCE(t.is_ojol, false) AS is_ojol,
      t.waktu_pencatatan,
      op.spbu_id,
      COALESCE(s.nama, 'SPBU #' || op.spbu_id) AS spbu_nama
    FROM public.transaksi_pertalite t
    INNER JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE (p_spbu_id IS NULL OR TRIM(p_spbu_id) = '' OR op.spbu_id = p_spbu_id)
      AND (v_date_from IS NULL OR t.waktu_pencatatan >= v_date_from)
      AND (v_date_to IS NULL OR t.waktu_pencatatan <= v_date_to)
  ),
  top_plates AS (
    SELECT 
      plat_nomor,
      bool_or(is_ojol) AS is_ojol,
      COUNT(*) AS trx_count,
      COUNT(DISTINCT spbu_id) AS unique_spbu_count,
      SUM(liter) AS total_liter,
      SUM(harga) AS total_harga
    FROM raw_trx
    GROUP BY plat_nomor
    ORDER BY SUM(liter) DESC, COUNT(*) DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 50)
  ),
  detailed_transactions AS (
    SELECT 
      tp.plat_nomor,
      tp.is_ojol,
      tp.trx_count,
      tp.unique_spbu_count,
      tp.total_liter,
      tp.total_harga,
      json_agg(
        json_build_object(
          'id', r.id,
          'waktu_pencatatan', r.waktu_pencatatan,
          'spbu_id', r.spbu_id,
          'spbu_nama', r.spbu_nama,
          'liter', r.liter,
          'harga', r.harga,
          'is_ojol', r.is_ojol
        ) ORDER BY r.waktu_pencatatan DESC
      ) AS transactions
    FROM top_plates tp
    JOIN raw_trx r ON r.plat_nomor = tp.plat_nomor
    GROUP BY tp.plat_nomor, tp.is_ojol, tp.trx_count, tp.unique_spbu_count, tp.total_liter, tp.total_harga
    ORDER BY tp.total_liter DESC, tp.trx_count DESC
  )
  SELECT json_agg(
    json_build_object(
      'plat_nomor', plat_nomor,
      'is_ojol', is_ojol,
      'trx_count', trx_count,
      'unique_spbu_count', unique_spbu_count,
      'total_liter', total_liter,
      'total_harga', total_harga,
      'transactions', transactions
    )
  ) INTO v_result
  FROM detailed_transactions;

  RETURN json_build_object(
    'success', true,
    'top_plates', COALESCE(v_result, '[]'::json)
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_spbu_top_plates(text, text, text, integer) TO authenticated;
