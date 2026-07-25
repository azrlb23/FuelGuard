-- =============================================================================
-- SQL Migration: Stored Procedure for Master Dashboard Summary
-- Function Name: get_master_dashboard_summary
-- Security: Enforces Master Role Authorization Check via PostgreSQL/Supabase
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
  -- 1. Security Check: Verify caller is authenticated as 'master'
  BEGIN
    IF public.get_user_role() <> 'master' THEN
      RAISE EXCEPTION 'Access Denied: Master role required.';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    IF NOT EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND (raw_user_meta_data->>'role' = 'master' OR raw_app_meta_data->>'role' = 'master')
    ) THEN
      RAISE EXCEPTION 'Access Denied: Master authorization failed.';
    END IF;
  END;

  -- 2. Determine Start Timestamp based on p_filter
  IF p_filter = 'today' THEN
    v_start_time := date_trunc('day', NOW());
  ELSIF p_filter = 'weekly' THEN
    v_start_time := NOW() - INTERVAL '7 days';
  ELSIF p_filter = 'monthly' THEN
    v_start_time := NOW() - INTERVAL '30 days';
  ELSE
    v_start_time := '1970-01-01 00:00:00'::timestamp; -- 'all-time'
  END IF;

  -- 3. Calculate Overall Stats
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

  -- Count Active SPBUs
  SELECT COUNT(id) INTO v_active_spbu_count FROM public.spbu;

  -- 4. Calculate 7-Day Weekly Volume Array (Senin .. Minggu)
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

  -- 5. Calculate SPBU List with Revenue & Volume Aggregates
  WITH spbu_stats AS (
    SELECT 
      s.id,
      COALESCE(s.nama, s.name, CONCAT('SPBU #', s.id)) AS name,
      COALESCE(s.alamat, s.location, '-') AS location,
      COALESCE(s.manager, '-') AS manager,
      COALESCE(SUM(t.harga), 0) AS revenue,
      COALESCE(SUM(t.liter), 0) AS volume
    FROM public.spbu s
    LEFT JOIN public.transaksi_pertalite t 
      ON t.spbu_id = s.id AND t.waktu_pencatatan >= v_start_time
    GROUP BY s.id, s.nama, s.name, s.alamat, s.location, s.manager
    ORDER BY revenue DESC
  )
  SELECT json_agg(
    json_build_object(
      'id', id,
      'name', name,
      'location', location,
      'manager', manager,
      'revenue', revenue,
      'volume', volume
    )
  ) INTO v_spbu_list FROM spbu_stats;

  -- 6. System Alerts / Notifications
  v_alerts := json_build_array(
    json_build_object(
      'id', '1',
      'spbu', 'SPBU 64.7501',
      'msg', 'Pengisian BBM mencapai kuota harian normal',
      'severity', 'info',
      'time', '5 menit yang lalu'
    )
  );

  -- 7. Build Final JSON Response
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
