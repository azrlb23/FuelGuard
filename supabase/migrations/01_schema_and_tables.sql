-- =============================================================================
-- SQL Migration: 01_schema_and_tables.sql
-- Description: Core tables, enumerations, foreign keys, and indexes.
-- Architecture: Shared Device (Multi-Operator)
--   - operator_id di transaksi_pertalite merujuk ke operator_profiles(id)
--   - SPBU ditentukan via: transaksi_pertalite.operator_id -> operator_profiles.spbu_id
-- =============================================================================

-- ─── 1. EXTENSIONS & ENUMS ───────────────────────────────────────────────────
-- (Assuming standard Supabase extensions like pgcrypto are enabled by default)

-- ─── 2. TABLE ALTERATIONS (CLEANUP FROM OLD SCHEMA) ──────────────────────────
-- Remove obsolete columns from transaksi_pertalite
ALTER TABLE public.transaksi_pertalite 
  DROP COLUMN IF EXISTS shift CASCADE,
  DROP COLUMN IF EXISTS operator_email CASCADE,
  DROP COLUMN IF EXISTS jenis_kendaraan CASCADE,
  DROP COLUMN IF EXISTS spbu_id CASCADE,
  DROP COLUMN IF EXISTS operator_name CASCADE,
  DROP COLUMN IF EXISTS tgl_pencatatan CASCADE,
  DROP COLUMN IF EXISTS jam_pencatatan CASCADE;

-- Ensure is_ojol exists and is boolean
ALTER TABLE public.transaksi_pertalite
  ADD COLUMN IF NOT EXISTS is_ojol boolean DEFAULT false;

-- Ensure operator_id column exists (will be FK'd to operator_profiles below)
ALTER TABLE public.transaksi_pertalite 
  ADD COLUMN IF NOT EXISTS operator_id uuid;

-- ─── 3. NEW TABLES ────────────────────────────────────────────────────────────

-- Drop shift_config as it's no longer used
DROP TABLE IF EXISTS public.shift_config CASCADE;

-- Table: operator_profiles (Krusial untuk Shared Device / Multi-Operator)
-- Menyimpan daftar nama kasir fisik di setiap cabang SPBU.
-- Setiap transaksi menyimpan operator_id yang merujuk ke tabel ini.
CREATE TABLE IF NOT EXISTS public.operator_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spbu_id text NOT NULL REFERENCES public.spbu(id) ON DELETE CASCADE,
  nama_operator text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT NOW(),
  CONSTRAINT unique_spbu_operator UNIQUE (spbu_id, nama_operator)
);

CREATE INDEX IF NOT EXISTS idx_operator_profiles_spbu 
  ON public.operator_profiles (spbu_id, is_active);

-- Now add FK constraint: operator_id -> operator_profiles(id)
-- Drop old constraint if it wrongly points to auth.users
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'transaksi_pertalite_operator_id_fkey'
  ) THEN
    ALTER TABLE public.transaksi_pertalite DROP CONSTRAINT transaksi_pertalite_operator_id_fkey;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'transaksi_pertalite_operator_id_fkey'
  ) THEN
    ALTER TABLE public.transaksi_pertalite
      ADD CONSTRAINT transaksi_pertalite_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.operator_profiles(id);
  END IF;
END $$;

-- Table: region_codes (Lookup for vehicle plates)
CREATE TABLE IF NOT EXISTS public.region_codes (
  code text PRIMARY KEY,
  region_name text NOT NULL
);

INSERT INTO public.region_codes (code, region_name) VALUES
('A', 'Banten (Serang, Cilegon, Pandeglang, Lebak, Tangerang Kab)'),
('B', 'DKI Jakarta, Bekasi, Depok, Tangerang'),
('D', 'Bandung, Cimahi, Bandung Barat'),
('E', 'Cirebon, Indramayu, Majalengka, Kuningan'),
('F', 'Bogor, Sukabumi, Cianjur'),
('T', 'Purwakarta, Karawang, Subang'),
('Z', 'Garut, Tasikmalaya, Ciamis, Banjar, Pangandaran'),
('G', 'Pekalongan, Tegal, Brebes, Batang, Pemalang'),
('H', 'Semarang, Salatiga, Kendal, Demak'),
('K', 'Pati, Kudus, Jepara, Rembang, Blora, Grobogan'),
('R', 'Banyumas, Cilacap, Purbalingga, Banjarnegara'),
('AA', 'Magelang, Purworejo, Kebumen, Temanggung, Wonosobo'),
('AB', 'DI Yogyakarta'),
('AD', 'Surakarta, Boyolali, Sukoharjo, Karanganyar, Wonogiri, Sragen, Klaten'),
('AE', 'Madiun, Ngawi, Magetan, Ponorogo, Pacitan'),
('AG', 'Kediri, Blitar, Tulungagung, Nganjuk, Trenggalek'),
('L', 'Surabaya'),
('M', 'Madura (Bangkalan, Sampang, Pamekasan, Sumenep)'),
('N', 'Malang, Probolinggo, Pasuruan, Lumajang, Batu'),
('P', 'Jember, Banyuwangi, Bondowoso, Situbondo'),
('S', 'Bojonegoro, Tuban, Lamongan, Mojokerto, Jombang'),
('W', 'Sidoarjo, Gresik'),
('BL', 'Aceh'),
('BB', 'Sumatera Utara Barat (Tapanuli, Nias, Sibolga)'),
('BK', 'Sumatera Utara Timur (Medan, Deli Serdang, Asahan)'),
('BA', 'Sumatera Barat'),
('BM', 'Riau'),
('BP', 'Kepulauan Riau (Batam, Tanjungpinang)'),
('BG', 'Sumatera Selatan'),
('BN', 'Kepulauan Bangka Belitung'),
('BE', 'Lampung'),
('BD', 'Bengkulu'),
('BH', 'Jambi'),
('KB', 'Kalimantan Barat'),
('DA', 'Kalimantan Selatan'),
('KH', 'Kalimantan Tengah'),
('KT', 'Kalimantan Timur'),
('KU', 'Kalimantan Utara'),
('DB', 'Sulawesi Utara (Manado, Bitung, Tomohon)'),
('DL', 'Sulawesi Utara Kepulauan (Sangihe, Talaud)'),
('DM', 'Gorontalo'),
('DN', 'Sulawesi Tengah'),
('DT', 'Sulawesi Tenggara'),
('DD', 'Sulawesi Selatan (Makassar, Gowa, Maros)'),
('DP', 'Sulawesi Selatan Bagian Utara (Parepare, Luwu)'),
('DC', 'Sulawesi Barat'),
('DK', 'Bali'),
('DR', 'Lombok (NTB)'),
('EA', 'Sumbawa (NTB)'),
('DH', 'Timor (NTT / Kupang)'),
('EB', 'Flores (NTT)'),
('ED', 'Sumba (NTT)'),
('DE', 'Maluku'),
('DG', 'Maluku Utara'),
('DS', 'Papua (Induk)'),
('PA', 'Papua Barat / Papua Pusat'),
('PB', 'Papua Barat Daya')
ON CONFLICT (code) DO UPDATE SET region_name = EXCLUDED.region_name;

-- ─── 4. ROLE CLEANUP ─────────────────────────────────────────────────────────
-- Clean up roles table to only 'operator' and 'master'
UPDATE public.user_roles SET role = 'operator' WHERE role = 'manajer';

-- ─── 5. INDEXES UNTUK PERFORMA ──────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_trx_plat_waktu 
  ON public.transaksi_pertalite (plat_nomor, waktu_pencatatan DESC);

-- Drop old index based on spbu_id column if it exists since the column was dropped
DROP INDEX IF EXISTS public.idx_trx_spbu_waktu;

-- Create an index on operator_id for fast joins with operator_profiles
CREATE INDEX IF NOT EXISTS idx_trx_operator_waktu
  ON public.transaksi_pertalite (operator_id, waktu_pencatatan DESC);
