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
AS $$
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

  -- 7-Day Weekly Volume
  WITH days AS (
    SELECT generate_series(
      date_trunc('day', NOW()) - INTERVAL '6 days',
      date_trunc('day', NOW()),
      INTERVAL '1 day'
    )::date AS d
  ),
  daily_sums AS (
    SELECT 
      days.d,
      COALESCE(SUM(t.liter), 0) AS total_liter
    FROM days
    LEFT JOIN public.transaksi_pertalite t 
      ON t.waktu_pencatatan::date = days.d
    GROUP BY days.d
    ORDER BY days.d
  )
  SELECT json_agg(total_liter) INTO v_weekly_volume FROM daily_sums;

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
  spbu_stats AS (
    SELECT 
      s.id,
      COALESCE(s.nama, CONCAT('SPBU #', s.id)) AS name,
      COALESCE(s.alamat, '-') AS location,
      '-' AS manager,
      COALESCE(SUM(t.harga), 0) AS revenue,
      COALESCE(SUM(t.liter), 0) AS volume
    FROM public.spbu s
    LEFT JOIN public.operator_profiles op ON op.spbu_id = s.id
    LEFT JOIN public.transaksi_pertalite t 
      ON t.operator_id = op.id AND t.waktu_pencatatan >= v_start_time
    GROUP BY s.id, s.nama, s.alamat
  ),
  spbu_combined AS (
    SELECT 
      ss.id,
      ss.name,
      ss.location,
      ss.manager,
      ss.revenue,
      ss.volume,
      COALESCE(rt.transactions, '[]'::json) AS transactions
    FROM spbu_stats ss
    LEFT JOIN recent_trx_json rt ON rt.spbu_id = ss.id
    ORDER BY ss.revenue DESC
  )
  SELECT json_agg(
    json_build_object(
      'id', id,
      'name', name,
      'location', location,
      'manager', manager,
      'revenue', revenue,
      'volume', volume,
      'transactions', transactions
    )
  ) INTO v_spbu_list FROM spbu_combined;

  v_alerts := json_build_array(
    json_build_object(
      'id', '1',
      'spbu', 'SPBU 64.7501',
      'msg', 'Pengisian BBM mencapai kuota harian normal',
      'severity', 'info',
      'time', '5 menit yang lalu'
    )
  );

  v_result := json_build_object(
    'stats', json_build_object(
      'totalRevenue', v_total_revenue,
      'totalVolume', v_total_volume,
      'activeSpbuCount', v_active_spbu_count,
      'todayTrxCount', v_today_trx_count
    ),
    'weekly_volume', COALESCE(v_weekly_volume, '[0,0,0,0,0,0,0]'::json),
    'spbu_list', COALESCE(v_spbu_list, '[]'::json),
    'alerts', COALESCE(v_alerts, '[]'::json)
  );

  RETURN v_result;
END;
$$;
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
