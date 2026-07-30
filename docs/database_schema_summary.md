# Ringkasan Skema Database FuelGuard (Shared Device / Multi-Operator)

File ini ditujukan untuk memberikan konteks kepada AI tentang skema database terbaru sistem pencatatan BBM FuelGuard. 

## Arsitektur: Shared Device (Multi-Operator)

Sistem menggunakan arsitektur **Shared Device**, di mana:
- **1 SPBU = 1 Akun Login** di mesin kasir (tablet/HP).
- Di setiap SPBU, ada **beberapa kasir fisik** (Budi, Siti, dll) yang bergantian menggunakan perangkat yang sama.
- Saat akan memasukkan transaksi, kasir **memilih namanya dari dropdown** (bukan login ulang).

## Aturan Akses & Relasi Kunci

### 1. Role Pengguna
Ada dua tipe role di tabel `user_roles`:
- `operator`: Akun yang berada di SPBU dan bertugas memasukkan data transaksi. **1 akun = 1 SPBU**.
- `master`: Akun pusat (admin) yang dapat melihat seluruh transaksi dari semua SPBU.

### 2. Relasi Transaksi ke SPBU & Multi-Operator
- Kolom `spbu_id` **tidak lagi disimpan secara langsung** di dalam tabel `transaksi_pertalite`.
- Setiap transaksi menyimpan `operator_id` yang **merujuk ke tabel `operator_profiles(id)`** (bukan `auth.users`!).
- `operator_profiles` menyimpan nama-nama kasir fisik seperti Budi atau Siti, beserta `spbu_id` tempat mereka bekerja.
- Untuk mengetahui SPBU tempat transaksi dilakukan, kita melakukan operasi **JOIN**:
  ```
  transaksi_pertalite.operator_id -> operator_profiles.id -> operator_profiles.spbu_id
  ```

### 3. Pembatasan Kuota
- Kuota bersifat **lintas cabang (global)** per hari berdasarkan plat nomor:
  - Motor Non-Ojol: Rp 50.000/hari
  - Motor Ojol: Rp 100.000/hari
- Untuk menghitung pemakaian hari ini, query memfilter `plat_nomor` dan `waktu_pencatatan >= date_trunc('day', NOW())` di seluruh cabang tanpa memfilter SPBU.

---

## Tabel-Tabel Utama

### 1. `spbu`
Menyimpan data master lokasi SPBU.
- `id` (text, PK) — Kode resmi SPBU, contoh: `'6176101'`
- `nama` (text)
- `alamat` (text)
- `manajer_id` (uuid) — *Catatan: Role manajer sudah tidak dipakai secara operasional.*

### 2. `transaksi_pertalite`
Menyimpan riwayat log pengisian BBM.
- `id` (bigint, PK, GENERATED ALWAYS AS IDENTITY)
- `plat_nomor` (text, NOT NULL)
- `liter` (numeric, NOT NULL)
- `harga` (bigint, NOT NULL)
- `waktu_pencatatan` (timestamptz, DEFAULT now())
- `operator_id` (uuid, **FK ke `operator_profiles(id)`**) — ID kasir yang melakukan transaksi
- `is_ojol` (boolean, DEFAULT false)

### 3. `operator_profiles`
**Tabel krusial** untuk menyimpan daftar nama kasir fisik di setiap cabang SPBU. Digunakan langsung dalam logika insert transaksi (`fn_safe_insert_transaction` mewajibkan `p_operator_id` dari tabel ini).
- `id` (uuid, PK, DEFAULT gen_random_uuid())
- `spbu_id` (text, FK ke `spbu(id)`, ON DELETE CASCADE)
- `nama_operator` (text, NOT NULL)
- `is_active` (boolean, DEFAULT true)
- `created_at` (timestamptz)
- UNIQUE constraint: `(spbu_id, nama_operator)`

### 4. `user_roles`
Mengatur hak akses dan penempatan SPBU untuk tiap **akun login** (auth.users).
- `user_id` (uuid, PK, FK ke `auth.users(id)`)
- `role` (text) — `'operator'` atau `'master'`
- `spbu_id` (text, FK ke `spbu(id)`)

### 5. `fuel_prices`
Harga bahan bakar yang berlaku per SPBU.
- `id` (uuid, PK)
- `spbu_id` (text, FK ke `spbu(id)`)
- `fuel_type` (text)
- `price_per_liter` (numeric)
- `updated_at` (timestamptz)

### 6. `region_codes`
Data awalan plat nomor dan daerah asalnya.
- `code` (text, PK)
- `region_name` (text)

---

## Ringkasan Fungsi RPC Utama (Remote Procedure Call)

### Untuk Frontend Operator:
- **`fn_check_plate_status(p_plat, p_is_ojol, p_spbu_id)`** → json
  Mengembalikan sisa kuota, status pengisian, dan transaksi terakhir (lintas cabang) hari ini. JOIN ke `operator_profiles` untuk mendapatkan info SPBU pada transaksi terakhir.

- **`fn_safe_insert_transaction(p_plat, p_liter, p_operator_id, p_is_ojol)`** → json
  `p_operator_id` adalah UUID dari `operator_profiles` (bukan `auth.users`!). Fungsi ini:
  1. Mencari `spbu_id` dari `operator_profiles` berdasarkan `p_operator_id`.
  2. Mengambil harga per liter dari `fuel_prices` berdasarkan `spbu_id` tersebut.
  3. Melakukan lock atomik (`pg_advisory_xact_lock`) dan cek kuota lintas cabang.
  4. Insert transaksi baru.

- **`get_dashboard_summary(p_filter, p_spbu_id)`** → json
  Data statistik harian/mingguan untuk SPBU operator yang bersangkutan. Semua query JOIN via `operator_profiles`.

- **`get_export_transactions(p_start_date, p_end_date, p_spbu_id)`** → json
  Export data transaksi dengan filter tanggal dan SPBU.

### Untuk Frontend Master (Pusat):
- **`get_master_dashboard_summary(p_filter)`** → json
  Total volume, revenue agregat dari seluruh SPBU, top list SPBU berdasarkan revenue.

- **`get_master_analytics_summary(p_date_from, p_date_to, p_spbu_id)`** → json
  Data visualisasi grafik pendapatan, market share SPBU, dan efisiensi.

- **`get_master_history_paginated(p_search, p_spbu_id, p_date_from, p_date_to, p_sort_field, p_sort_dir, p_page, p_page_size)`** → json
  Query paginasi untuk riwayat dengan pencarian plat nomor dan filter tanggal/spbu.

### Helper Functions:
- **`get_user_role()`** → text — Mengembalikan role akun login (`'operator'` atau `'master'`).
- **`get_user_spbu_id()`** → text — Mengembalikan `spbu_id` akun login dari `user_roles`.

---

## Keamanan RLS (Row Level Security)

- **Operator** (`role = 'operator'`) hanya dapat melihat data transaksi yang dilakukan di **cabang SPBU mereka**. Validasi ini dilakukan menggunakan sub-query `EXISTS` yang mencocokkan `spbu_id` di tabel `operator_profiles` dengan `spbu_id` milik akun yang sedang login (dari `user_roles` via `get_user_spbu_id()`).
- **Master** (`role = 'master'`) memiliki hak akses baca tanpa batas untuk semua data.
- Semua validasi kuota dan insert dilakukan di database menggunakan fungsi RPC berbasis `SECURITY DEFINER`.

---

## Diagram Relasi Kunci

```
auth.users (akun login)
  └── user_roles (role + spbu_id per akun)

operator_profiles (daftar kasir fisik per SPBU)
  ├── spbu_id → spbu.id
  └── id ← transaksi_pertalite.operator_id

transaksi_pertalite (log pengisian BBM)
  └── operator_id → operator_profiles.id
        └── (via JOIN) → operator_profiles.spbu_id → spbu.id
```

---

## Urutan Berkas Migrasi (Supabase Migrations)
Berkas-berkas di dalam folder `supabase/migrations/` harus dieksekusi berurutan:
1. `01_schema_and_tables.sql` - Pembuatan tabel dasar, relasi, constraint unik, dan data awal (*seeder*).
2. `02_security_and_rls.sql` - Kebijakan *Row Level Security* (RLS) untuk membatasi akses baca/tulis berdasarkan *role* pengguna (`operator` vs `master`).
3. `03_auth_helpers.sql` - Fungsi utilitas (`get_user_role`, `get_user_spbu_id`) untuk kemudahan validasi keamanan.
4. `04_operator_rpcs.sql` - Berisi RPC utama bagi SPBU (`fn_safe_insert_transaction`, pengecekan plat, dan sinkronisasi kuota).
5. `05_master_rpcs.sql` - Berisi fungsi pengambilan data besar (*dashboard*, *analytics*, riwayat) bagi *Dashboard Analytics*.
6. `06_migrate_old_transactions.sql` - (Patch) Fungsi untuk mengaitkan transaksi lawas (sebelum arsitektur *Shared Device*) dengan profil `Legacy` sehingga data historis tidak hilang.
7. `07_optimize_rpcs.sql` - (Patch) Optimalisasi kueri SQL berat menggunakan filter indeks sebelum melakukan *generate_series* demi mendongkrak performa aplikasi (*Lighthouse LCP*).
