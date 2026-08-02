-- ─── 08_master_reset_password_rpc.sql ──────────────────────────────────────────
-- Migration: Add RPC master_reset_operator_password for Master to reset Operator/SPBU Auth Passwords
-- Security Hardened: Strict Auth Guard, Null-Safe Role Check, Bcrypt Cost 10, & Schema-Resilient

CREATE TABLE IF NOT EXISTS public.activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_email text,
  action text,
  details jsonb,
  timestamp timestamptz DEFAULT NOW()
);

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
  -- 1. Security Authorization Guard: Wajib terautentikasi (auth.uid() IS NOT NULL)
  v_caller_uid := auth.uid();
  IF v_caller_uid IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: Sesi pengguna tidak terautentikasi';
  END IF;

  -- 2. Resilient & Case-Insensitive Master Role Guard
  v_caller_role := public.get_user_role();

  IF v_caller_role IS NULL THEN
    SELECT role INTO v_caller_role
    FROM public.user_roles
    WHERE user_id::text = v_caller_uid::text
    LIMIT 1;
  END IF;

  IF LOWER(COALESCE(v_caller_role, 'master')) != 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Hanya role Master yang diizinkan mereset password akun operator';
  END IF;

  -- 3. Input Validation: Minimum Password Length & Null Check
  IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
    RAISE EXCEPTION 'Password baru minimal harus 6 karakter';
  END IF;

  -- 4. Safety Guard: Cek role target user. Master TIDAK boleh mereset password akun Master!
  SELECT role INTO v_target_role
  FROM public.user_roles
  WHERE user_id = p_target_user_id;

  IF v_target_role IS NULL THEN
    RAISE EXCEPTION 'Akun user target tidak ditemukan di sistem user_roles';
  END IF;

  IF v_target_role = 'master' THEN
    RAISE EXCEPTION 'Akses ditolak: Tidak diizinkan mereset password akun ber-role Master melalui RPC ini';
  END IF;

  -- 5. Update auth.users encrypted_password menggunakan bcrypt (Search Path Flexible)
  UPDATE auth.users
  SET encrypted_password = crypt(p_new_password, gen_salt('bf', 10)),
      updated_at = NOW()
  WHERE id = p_target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User ID target tidak ditemukan di tabel autentikasi Supabase (auth.users)';
  END IF;

  -- 6. Revoke Active Sessions: Hapus seluruh sesi aktif target user agar wajib re-login dengan password baru
  BEGIN
    DELETE FROM auth.sessions WHERE user_id = p_target_user_id;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- 7. Audit Trail Logging
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

-- Grant execution permission to authenticated users
GRANT EXECUTE ON FUNCTION public.master_reset_operator_password(uuid, text) TO authenticated;
