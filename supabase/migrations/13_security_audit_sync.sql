-- =============================================================================
-- SQL Patch Migration: 13_security_audit_sync.sql
-- Description: White-box pentest findings (2026-08-15).
--   Several critical auth fixes existed ONLY as ad-hoc changes applied directly
--   to the live database (visible in production_schema.sql as "[AUDIT FIX #n]"
--   comments) and were never captured as migration files. Any environment
--   rebuilt from supabase/migrations/ in order (fresh dev DB, staging, CI,
--   disaster recovery) would silently redeploy the vulnerable versions below.
--   This migration re-applies those fixes so the migration history matches
--   the secured production state, plus one NEW fix (#17) not yet live.
-- =============================================================================

-- ─── #1/#NEW-1 (RE-SYNC): master_reset_operator_password — NULL-role fail-open ──
-- Root cause: COALESCE(v_caller_role, 'master') silently treated an
-- authenticated user with NO row in user_roles as if they were 'master',
-- letting them reset any operator's password and kill their sessions.
CREATE OR REPLACE FUNCTION public.master_reset_operator_password(
  p_target_user_id uuid,
  p_new_password text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions, vault
AS $$
DECLARE
  v_caller_uid uuid;
  v_caller_role text;
  v_target_role text;
  v_caller_email text;
BEGIN
  v_caller_uid := auth.uid();
  IF v_caller_uid IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: Sesi pengguna tidak terautentikasi';
  END IF;

  v_caller_role := public.get_user_role();
  IF v_caller_role IS NULL THEN
    SELECT role INTO v_caller_role FROM public.user_roles WHERE user_id = v_caller_uid LIMIT 1;
  END IF;

  -- Fail closed: NULL role must be REJECTED, never fall back to 'master'.
  IF v_caller_role IS NULL OR LOWER(v_caller_role) != 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Hanya role Master yang diizinkan mereset password akun operator';
  END IF;

  IF p_new_password IS NULL OR length(p_new_password) < 8 THEN
    RAISE EXCEPTION 'Password baru minimal harus 8 karakter';
  END IF;

  SELECT role INTO v_target_role FROM public.user_roles WHERE user_id = p_target_user_id;
  IF v_target_role IS NULL THEN
    RAISE EXCEPTION 'Akun user target tidak ditemukan di sistem user_roles';
  END IF;

  IF v_target_role = 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Tidak diizinkan mereset password akun ber-role Master melalui RPC ini';
  END IF;

  UPDATE auth.users
  SET encrypted_password = crypt(p_new_password, gen_salt('bf', 10)),
      updated_at = NOW()
  WHERE id = p_target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User ID target tidak ditemukan di tabel autentikasi Supabase (auth.users)';
  END IF;

  BEGIN
    DELETE FROM auth.sessions WHERE user_id = p_target_user_id;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  BEGIN
    SELECT email INTO v_caller_email FROM auth.users WHERE id = v_caller_uid;

    INSERT INTO public.activity_logs (user_email, action, details, timestamp)
    VALUES (
      COALESCE(v_caller_email, 'master_admin@fuelguard'),
      'MASTER_RESET_OPERATOR_PASSWORD',
      json_build_object(
        'master_user_id', v_caller_uid,
        'target_user_id', p_target_user_id,
        'target_role', v_target_role
      )::jsonb,
      NOW()
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN json_build_object(
    'success', true,
    'message', 'Password akun operator berhasil diperbarui dan sesi aktif telah di-reset'
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.master_reset_operator_password(uuid, text) TO authenticated;


-- ─── #NEW-1 (RE-SYNC): manage_operator — NULL-role fail-open ────────────────
-- Root cause: `get_user_role() <> 'master'` evaluates to NULL (not TRUE) in
-- Postgres when get_user_role() is NULL, so `IF NULL THEN RAISE EXCEPTION`
-- never fires — a role-less authenticated account could create/update/
-- deactivate operator profiles at any SPBU.
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
  -- Fail closed: COALESCE to '' so a NULL role never slips past the check.
  IF COALESCE(public.get_user_role(), '') != 'master' THEN
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


-- ─── #15 (RE-SYNC): support_tickets INSERT — identity spoofing ──────────────
-- Root cause: WITH CHECK only required auth.uid() IS NOT NULL, so any
-- authenticated user could insert a ticket with an arbitrary user_id,
-- impersonating another account in the support queue.
DROP POLICY IF EXISTS "support_tickets_insert" ON public.support_tickets;
CREATE POLICY "support_tickets_insert" ON public.support_tickets
  FOR INSERT WITH CHECK (user_id = auth.uid());


-- ─── #6 (RE-SYNC): repeated_transaction_logs INSERT — unauthenticated-role writes ─
-- Root cause: WITH CHECK only required auth.uid() IS NOT NULL, letting any
-- authenticated account (including one with no operator/master role) write
-- arbitrary anti-fraud audit log rows.
DROP POLICY IF EXISTS "repeated_logs_insert" ON public.repeated_transaction_logs;
CREATE POLICY "repeated_logs_insert" ON public.repeated_transaction_logs
  FOR INSERT WITH CHECK (
    public.get_user_role() IN ('operator', 'master')
  );


-- ─── #17 (NEW): operator_profiles SELECT — cross-SPBU enumeration ───────────
-- Root cause: policy only required auth.uid() IS NOT NULL, so any
-- authenticated user (any operator at any branch, or a role-less account)
-- could read every cashier's name + UUID + SPBU assignment company-wide,
-- not just their own branch. This also supplied the operator_profiles.id
-- values needed to exploit the (already-fixed) fn_safe_insert_transaction
-- cross-SPBU IDOR. Scope reads to the caller's own SPBU; master keeps
-- unrestricted access (already used via get_master_team_overview RPC).
DROP POLICY IF EXISTS "operator_profiles_select" ON public.operator_profiles;
CREATE POLICY "operator_profiles_select" ON public.operator_profiles
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR spbu_id = public.get_user_spbu_id()
  );

-- ─── #18 (NEW): get_operator_repeated_logs — unauthenticated data exposure ──
-- Root cause: function had NO auth.uid() check and NO role rejection branch.
-- An anon (zero-credential) caller has get_user_role() = NULL, which falls
-- through to the ELSE branch and leaves v_effective_spbu = NULL, returning
-- TODAY'S repeated-transaction attempt log (plate numbers, operator names,
-- rejection reasons) for ALL SPBUs to anyone with the project's public
-- anon key — no login required. Confirmed live via Supabase security
-- advisors (flagged as anon-executable) and direct pg_get_functiondef.
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
  v_effective_spbu text;
  v_count_today integer;
  v_offset integer;
  v_logs json;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: Sesi tidak terautentikasi';
  END IF;

  IF public.get_user_role() = 'operator' THEN
    v_effective_spbu := public.get_user_spbu_id();
  ELSIF public.get_user_role() = 'master' THEN
    v_effective_spbu := NULLIF(TRIM(p_spbu_id), '');
  ELSE
    RAISE EXCEPTION 'Akses ditolak: Role tidak valid untuk mengakses log pengetap';
  END IF;

  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;

  SELECT COUNT(l.id) INTO v_count_today
  FROM public.repeated_transaction_logs l
  LEFT JOIN public.operator_profiles op ON op.id = l.attempt_operator_id
  WHERE (v_effective_spbu IS NULL OR l.attempt_spbu_id = v_effective_spbu)
    AND l.created_at >= date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar'
    AND (
      p_search = '' OR
      l.plat_nomor ILIKE '%' || p_search || '%' OR
      COALESCE(op.nama_operator, '') ILIKE '%' || p_search || '%' OR
      l.attempt_spbu_id ILIKE '%' || p_search || '%' OR
      l.reason ILIKE '%' || p_search || '%' OR
      to_char(l.created_at AT TIME ZONE 'Asia/Makassar', 'HH24:MI') ILIKE '%' || p_search || '%'
    );

  SELECT json_agg(t) INTO v_logs
  FROM (
    SELECT
      l.id,
      l.plat_nomor,
      l.attempt_spbu_id AS spbu_id,
      l.attempt_operator_id AS operator_id,
      COALESCE(op.nama_operator, 'Sistem') AS nama_operator,
      l.is_ojol,
      l.attempted_liter,
      l.total_harga_today,
      l.reason,
      l.created_at,
      to_char(l.created_at AT TIME ZONE 'Asia/Makassar', 'HH24:MI') AS jam_pencatatan
    FROM public.repeated_transaction_logs l
    LEFT JOIN public.operator_profiles op ON op.id = l.attempt_operator_id
    WHERE (v_effective_spbu IS NULL OR l.attempt_spbu_id = v_effective_spbu)
      AND l.created_at >= date_trunc('day', NOW() AT TIME ZONE 'Asia/Makassar') AT TIME ZONE 'Asia/Makassar'
      AND (
        p_search = '' OR
        l.plat_nomor ILIKE '%' || p_search || '%' OR
        COALESCE(op.nama_operator, '') ILIKE '%' || p_search || '%' OR
        l.attempt_spbu_id ILIKE '%' || p_search || '%' OR
        l.reason ILIKE '%' || p_search || '%' OR
        to_char(l.created_at AT TIME ZONE 'Asia/Makassar', 'HH24:MI') ILIKE '%' || p_search || '%'
      )
    ORDER BY l.created_at DESC
    LIMIT p_page_size OFFSET v_offset
  ) t;

  RETURN json_build_object(
    'total_count', v_count_today,
    'logs', COALESCE(v_logs, '[]'::json)
  );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.get_operator_repeated_logs(text, integer, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_operator_repeated_logs(text, integer, integer, text) TO authenticated;


-- ─── #19 (NEW): activity_logs INSERT — audit log forgery ────────────────────
-- Root cause: WITH CHECK (true) let ANY authenticated user insert arbitrary
-- rows (fake user_email/action/details) directly into the audit trail via
-- the REST table endpoint. Legitimate writes only ever come from the
-- fn_audit_transaction trigger and SECURITY DEFINER RPCs (which bypass RLS
-- as the function owner), so direct client inserts should be denied outright.
DROP POLICY IF EXISTS "activity_logs_insert" ON public.activity_logs;
CREATE POLICY "activity_logs_insert" ON public.activity_logs
  FOR INSERT WITH CHECK (false);

NOTIFY pgrst, 'reload schema';
