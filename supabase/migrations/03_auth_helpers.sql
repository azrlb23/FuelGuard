-- =============================================================================
-- SQL Migration: 03_auth_helpers.sql
-- Description: Helper functions for role and SPBU resolution.
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_user_role CASCADE;
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE

AS $$
  SELECT role FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.get_user_role() TO authenticated;


DROP FUNCTION IF EXISTS public.get_user_spbu_id CASCADE;
CREATE OR REPLACE FUNCTION public.get_user_spbu_id()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT spbu_id FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.get_user_spbu_id() TO authenticated;
