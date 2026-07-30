-- =============================================================================
-- SQL Migration: 07_optimize_rpcs.sql
-- Description: Optimize performance of master RPCs to solve LCP issues
-- =============================================================================

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
$$;
