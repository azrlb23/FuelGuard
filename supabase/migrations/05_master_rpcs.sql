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
SET search_path = public
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
    v_start_time := date_trunc('day', NOW() - INTERVAL '6 days');
  ELSIF p_filter = 'monthly' THEN
    v_start_time := date_trunc('day', NOW() - INTERVAL '29 days');
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
SET search_path = public
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
    AND (p_date_from = '' OR t.waktu_pencatatan::date >= p_date_from::date)
    AND (p_date_to = '' OR t.waktu_pencatatan::date <= p_date_to::date);

  -- Paginated records with operator_name
  WITH paginated_trx AS (
    SELECT 
      t.id,
      t.plat_nomor,
      t.liter,
      t.harga,
      t.is_ojol,
      t.waktu_pencatatan,
      op.spbu_id AS spbu_id,
      COALESCE(s.nama, CONCAT('SPBU #', op.spbu_id)) AS spbu_name,
      COALESCE(op.nama_operator, '-') AS operator_name
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    LEFT JOIN public.spbu s ON s.id = op.spbu_id
    WHERE (p_search = '' OR t.plat_nomor ILIKE '%' || p_search || '%')
      AND (v_effective_spbu_id = '' OR op.spbu_id::text = v_effective_spbu_id)
      AND (p_date_from = '' OR t.waktu_pencatatan::date >= p_date_from::date)
      AND (p_date_to = '' OR t.waktu_pencatatan::date <= p_date_to::date)
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


-- ─── 4. FUNCTION: get_master_team_overview ─────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_master_team_overview CASCADE;
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
  -- 1. Security Authorization Guard: Wajib Terautentikasi
  v_caller_uid := auth.uid();
  IF v_caller_uid IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: Sesi pengguna tidak terautentikasi';
  END IF;

  -- 2. Resilient & Case-Insensitive Master Role Check
  v_caller_role := public.get_user_role();

  IF v_caller_role IS NULL THEN
    SELECT role INTO v_caller_role
    FROM public.user_roles
    WHERE user_id::text = v_caller_uid::text
    LIMIT 1;
  END IF;

  IF LOWER(COALESCE(v_caller_role, '')) != 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Hanya role Master yang diizinkan melihat data tim';
  END IF;

  -- Count total operators
  SELECT COUNT(id) INTO v_total_operators FROM public.operator_profiles;
  SELECT COUNT(id) INTO v_active_operators FROM public.operator_profiles WHERE is_active = true;
  SELECT COUNT(id) INTO v_total_spbu FROM public.spbu;

  -- Get SPBU list for filter dropdowns
  SELECT json_agg(
    json_build_object(
      'id', id,
      'name', COALESCE(nama, CONCAT('SPBU #', id)),
      'alamat', COALESCE(alamat, '-')
    ) ORDER BY id ASC
  ) INTO v_spbu_list FROM public.spbu;

  -- Get operator list with joined SPBU name
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


-- ─── 5. FUNCTION: manage_operator ─────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.manage_operator CASCADE;
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
  -- Security Authorization Guard: Only Master Role is Allowed to Manage Operators
  IF public.get_user_role() <> 'master' THEN
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

-- ─── 8. RPC: get_master_repeated_transactions ────────────────────────────────
DROP FUNCTION IF EXISTS public.get_master_repeated_transactions CASCADE;
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
  -- 1. Security Check: Authenticated user & Role Verification
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: Sesi tidak terautentikasi';
  END IF;

  v_role := public.get_user_role();
  IF v_role IS NULL OR LOWER(v_role) != 'master' THEN
    RAISE EXCEPTION 'Forbidden: Akses ditolak. Membutuhkan hak akses Master Admin.';
  END IF;

  -- 2. Total Raw Attempt Count
  SELECT COUNT(r.id) INTO v_total_attempts
  FROM public.repeated_transaction_logs r
  WHERE (p_spbu_id IS NULL OR TRIM(p_spbu_id) = '' OR r.attempt_spbu_id = p_spbu_id)
    AND (p_date_from IS NULL OR TRIM(p_date_from) = '' OR r.created_at >= (p_date_from || ' 00:00:00')::timestamp with time zone)
    AND (p_date_to IS NULL OR TRIM(p_date_to) = '' OR r.created_at <= (p_date_to || ' 23:59:59.999')::timestamp with time zone);

  -- 3. Group by Plat Nomor (Normalized Whitespace)
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
      AND (p_date_from IS NULL OR TRIM(p_date_from) = '' OR r.created_at >= (p_date_from || ' 00:00:00')::timestamp with time zone)
      AND (p_date_to IS NULL OR TRIM(p_date_to) = '' OR r.created_at <= (p_date_to || ' 23:59:59.999')::timestamp with time zone)
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
      ) AS attempts
    FROM raw_logs
    GROUP BY plat_nomor
  )
  SELECT COUNT(*) INTO v_total_plates FROM grouped_plates;

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
      AND (p_date_from IS NULL OR TRIM(p_date_from) = '' OR r.created_at >= (p_date_from || ' 00:00:00')::timestamp with time zone)
      AND (p_date_to IS NULL OR TRIM(p_date_to) = '' OR r.created_at <= (p_date_to || ' 23:59:59.999')::timestamp with time zone)
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
      ) AS attempts
    FROM raw_logs
    GROUP BY plat_nomor
  )
  SELECT json_agg(
    json_build_object(
      'plat_nomor', plat_nomor,
      'is_ojol', is_ojol,
      'attempt_count', attempt_count,
      'latest_attempt_at', latest_attempt_at,
      'attempts', attempts
    ) ORDER BY latest_attempt_at DESC
  ) INTO v_logs
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


-- ─── 7. FUNCTION: get_spbu_top_plates ─────────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_spbu_top_plates(text, text, text, integer);
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

  -- 3. Parse Date Range
  IF p_date_from IS NOT NULL AND TRIM(p_date_from) != '' THEN
    v_date_from := (p_date_from || ' 00:00:00')::timestamp with time zone;
  END IF;

  IF p_date_to IS NOT NULL AND TRIM(p_date_to) != '' THEN
    v_date_to := (p_date_to || ' 23:59:59.999')::timestamp with time zone;
  END IF;

  -- 4. Query & Aggregate Top Plates by plat_nomor
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

NOTIFY pgrst, 'reload schema';
