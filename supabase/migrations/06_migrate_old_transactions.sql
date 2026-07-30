-- =============================================================================
-- SQL Migration: 06_migrate_old_transactions.sql
-- Description: Migrasi transaksi lama (sebelum Shared Device) agar terbaca
--              kembali di Analytics Dashboard
-- =============================================================================

DO $$
DECLARE
  v_rec RECORD;
  v_spbu_id text;
  v_op_profile_id uuid;
BEGIN
  -- 1. Loop melalui transaksi yang operator_id-nya tidak ditemukan di operator_profiles
  -- (Yaitu data transaksi lama yang masih memakai ID auth.users)
  FOR v_rec IN 
    SELECT t.id, t.operator_id 
    FROM public.transaksi_pertalite t
    LEFT JOIN public.operator_profiles op ON op.id = t.operator_id
    WHERE op.id IS NULL
  LOOP
    -- 2. Cari SPBU dari user_roles (arsitektur lama)
    SELECT spbu_id INTO v_spbu_id 
    FROM public.user_roles 
    WHERE user_id = v_rec.operator_id;
    
    IF v_spbu_id IS NOT NULL THEN
      -- 3. Cari satu profil kasir yang ada di SPBU tersebut
      SELECT id INTO v_op_profile_id 
      FROM public.operator_profiles 
      WHERE spbu_id = v_spbu_id 
      LIMIT 1;
      
      -- 4. Jika SPBU itu belum punya profil kasir satupun, buatkan 1 profil "Legacy"
      IF v_op_profile_id IS NULL THEN
        INSERT INTO public.operator_profiles (spbu_id, nama_operator)
        VALUES (v_spbu_id, 'Kasir Migrasi (Legacy)')
        RETURNING id INTO v_op_profile_id;
      END IF;
      
      -- 5. Perbarui transaksi lama agar menggunakan ID profil kasir
      UPDATE public.transaksi_pertalite
      SET operator_id = v_op_profile_id
      WHERE id = v_rec.id;
    END IF;
  END LOOP;
END;
$$;
