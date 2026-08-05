-- =============================================================================
-- SQL Migration: 02_security_and_rls.sql
-- Description: Row Level Security (RLS) policies and Audit Triggers.
-- Architecture: Shared Device (Multi-Operator)
--   - operator_id di transaksi_pertalite merujuk ke operator_profiles(id)
--   - RLS SELECT untuk operator: cek apakah transaksi dilakukan di SPBU yang sama
--     via sub-query EXISTS ke operator_profiles
-- =============================================================================

-- ─── 1. AUDIT TRAIL TRIGGER ──────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.fn_audit_transaction CASCADE;
CREATE OR REPLACE FUNCTION public.fn_audit_transaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_operator_name text;
  v_spbu_name text;
  v_enriched_details jsonb;
BEGIN
  -- Ambil nama kasir asli dan nama SPBU dari relasi
  SELECT op.nama_operator, s.nama
  INTO v_operator_name, v_spbu_name
  FROM public.operator_profiles op
  JOIN public.spbu s ON s.id = op.spbu_id
  WHERE op.id = NEW.operator_id;

  -- Sisipkan data tambahan ke dalam JSON details
  v_enriched_details := row_to_json(NEW)::jsonb || jsonb_build_object(
    'operator_name', COALESCE(v_operator_name, 'Unknown'),
    'spbu_name', COALESCE(v_spbu_name, 'Unknown')
  );

  INSERT INTO public.activity_logs (user_email, action, details, timestamp)
  VALUES (
    COALESCE(v_operator_name, 'System') || ' (' || COALESCE(v_spbu_name, 'Unknown') || ')',
    'INSERT_TRANSACTION',
    v_enriched_details,
    NOW()
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_transaction ON public.transaksi_pertalite;
CREATE TRIGGER trg_audit_transaction
  AFTER INSERT ON public.transaksi_pertalite
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_audit_transaction();


-- ─── 2. RLS: TRANSAKSI_PERTALITE ─────────────────────────────────────────────
ALTER TABLE public.transaksi_pertalite ENABLE ROW LEVEL SECURITY;

-- Drop all old policies to prevent conflicts
DROP POLICY IF EXISTS "Akses baca berdasarkan jabatan dan lokasi SPBU" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_select_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "trx_insert_policy" ON public.transaksi_pertalite;
DROP POLICY IF EXISTS "Operator insert policy" ON public.transaksi_pertalite;

-- SELECT: Master bisa lihat semua, Operator hanya lihat transaksi di SPBU-nya
-- Logika: Cek apakah operator_id transaksi menunjuk ke operator_profiles yang
-- spbu_id-nya sama dengan spbu_id akun login (dari user_roles)
CREATE POLICY "trx_select_policy" ON public.transaksi_pertalite
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR EXISTS (
      SELECT 1 FROM public.operator_profiles op
      WHERE op.id = transaksi_pertalite.operator_id
        AND op.spbu_id = public.get_user_spbu_id()
    )
  );

-- INSERT: Operator bisa insert (fungsi RPC SECURITY DEFINER yang melakukan insert)
-- Master juga bisa insert untuk keperluan administratif
CREATE POLICY "trx_insert_policy" ON public.transaksi_pertalite
  FOR INSERT WITH CHECK (
    public.get_user_role() = 'master'
  );

-- ─── 3. RLS: FUEL_PRICES ─────────────────────────────────────────────────────
ALTER TABLE public.fuel_prices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "fuel_prices_select" ON public.fuel_prices;
DROP POLICY IF EXISTS "fuel_prices_modify" ON public.fuel_prices;

CREATE POLICY "fuel_prices_select" ON public.fuel_prices
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "fuel_prices_modify" ON public.fuel_prices
  FOR ALL USING (
    public.get_user_role() = 'master'
  );

-- ─── 4. RLS: SUPPORT_TICKETS ─────────────────────────────────────────────────
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "support_tickets_select" ON public.support_tickets;
DROP POLICY IF EXISTS "support_tickets_insert" ON public.support_tickets;

CREATE POLICY "support_tickets_select" ON public.support_tickets
  FOR SELECT USING (
    public.get_user_role() = 'master'
    OR user_id = auth.uid()
  );

CREATE POLICY "support_tickets_insert" ON public.support_tickets
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- ─── 5. RLS: USER_ROLES ──────────────────────────────────────────────────────
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_roles_select" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_modify" ON public.user_roles;

CREATE POLICY "user_roles_select" ON public.user_roles
  FOR SELECT USING (
    auth.uid() = user_id
    OR public.get_user_role() = 'master'
  );

CREATE POLICY "user_roles_modify" ON public.user_roles
  FOR ALL USING (
    public.get_user_role() = 'master'
  );

-- ─── 6. RLS: OPERATOR_PROFILES ───────────────────────────────────────────────
ALTER TABLE public.operator_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "operator_profiles_select" ON public.operator_profiles;
DROP POLICY IF EXISTS "operator_profiles_modify" ON public.operator_profiles;

CREATE POLICY "operator_profiles_select" ON public.operator_profiles
  FOR SELECT USING (
    auth.uid() IS NOT NULL
  );

CREATE POLICY "operator_profiles_modify" ON public.operator_profiles
  FOR ALL USING (
    public.get_user_role() = 'master'
  )
  WITH CHECK (
    public.get_user_role() = 'master'
  );

-- ─── 7. RLS: SPBU ────────────────────────────────────────────────────────────
ALTER TABLE public.spbu ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "spbu_select" ON public.spbu;
DROP POLICY IF EXISTS "spbu_modify" ON public.spbu;

CREATE POLICY "spbu_select" ON public.spbu
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "spbu_modify" ON public.spbu
  FOR ALL USING (public.get_user_role() = 'master')
  WITH CHECK (public.get_user_role() = 'master');

-- ─── 8. RLS: REGION_CODES ────────────────────────────────────────────────────
ALTER TABLE public.region_codes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "region_codes_select" ON public.region_codes;
DROP POLICY IF EXISTS "region_codes_modify" ON public.region_codes;

CREATE POLICY "region_codes_select" ON public.region_codes
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "region_codes_modify" ON public.region_codes
  FOR ALL USING (public.get_user_role() = 'master')
  WITH CHECK (public.get_user_role() = 'master');

-- ─── 9. RLS: ACTIVITY_LOGS ───────────────────────────────────────────────────
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "activity_logs_select" ON public.activity_logs;

CREATE POLICY "activity_logs_select" ON public.activity_logs
  FOR SELECT USING (public.get_user_role() = 'master');

NOTIFY pgrst, 'reload schema';
