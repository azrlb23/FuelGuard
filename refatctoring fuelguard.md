Ran command: `nvm use 20`
Ran command: `git branch`
Listed directory FuelGuard
Listed directory src
Searched for "supabase"
Viewed useTransactionAction.js:1-150
Viewed useDashboard.js:1-150
Viewed create_master_rpc.sql:1-100
Viewed security_audit_report.md:1-100

Berikut adalah analisis mendalam mengenai **Pemisahan Tanggung Jawab (*Separation of Concerns*)** antara **Backend (Supabase/PostgreSQL)** dan **Frontend (Vue 3)** pada proyek **FuelGuard**.

Secara umum, saat ini proyek FuelGuard memiliki beberapa bagian dengan pola *Fat Client / Thin Server* (logika bisnis dan pengolahan data agregat dilakukan di JS browser). Untuk arsitektur yang aman dan berkinerja tinggi, kita perlu memindahkan logika bisnis kritis dan kalkulasi data ke Supabase.

---

### 🟢 1. Kode yang HARUS & HANYA BISA ditaruh di Frontend (Vue 3)

Frontend bertanggung jawab penuh atas **Presentation Layer, User Experience (UX), Visual State, dan Rendering UI**.

| Kategori                             | Contoh di Kode FuelGuard                                     | Alasan Mengapa Harus di Frontend                             |
| :----------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| **Reaktivitas UI & Local State**     | `const loading = ref(false)`, `isModalOpen`, `activeTab` di composables/views | Mengatur komponen UI mana yang muncul, animasi loading, modal, dan state form sementara. |
| **Formatting Tampilan Visual**       | Mengubah angka menjadi `Rp 10.000` atau tanggal ke format `28 Juli 2026, 14:30` (`toLocaleTimeString`) | Backend sebaiknya mengembalikan data *raw* (ISO timestamp / angka desimal), frontend yang mengatur lokalisasi bahasa & format mata uang. |
| **Rendering Chart & Visualisasi**    | Konfigurasi Chart.js / ApexCharts pada komponen dashboard    | Backend menyediakan array angka ringkas, JS frontend yang menggambar canvas/SVG chart. |
| **UX Quick Pre-Validation**          | Cek plat nomor tidak boleh kosong sebelum tombol submit di-klik | Memberikan feedback seketika ke pengguna tanpa membuang kuota network request. *(Catatan: ini hanya untuk UX, bukan keamanan)*. |
| **Client-Side Routing & Navigation** | Guard Vue Router (`router.beforeEach`) untuk memindahkan tampilan dari `/` ke `/login` | Mengatur navigasi halaman di browser agar aplikasi terasa instan tanpa reload halaman (*Single Page App*). |
| **Toast & Interactive Alerts**       | Panggilan `toast.success("Transaksi Berhasil!")` atau `toast.warn(...)` | Menampilkan alert visual berbasis status respon yang dikembalikan backend. |

---

### 🔴 2. Kode yang HARUS dipindahkan ke Backend (Supabase: SQL / RPC / RLS / Triggers)

Backend bertindak sebagai **Single Source of Truth, Enforcement Keamanan, Integritas Data, dan Data Aggregator**.

#### A. Logika Bisnis & Validasi Kuota Transaksi *(Kritis dari segi Keamanan)*
* **Saat ini di Frontend:** [useTransactionAction.js](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/composables/useTransactionAction.js#L11-L82) (`checkPlateStatus` menghitung total liter hari ini dan memeriksa batas kuota Motor 5L / Mobil 1x di JS).
* **Mengapa harus di Backend Supabase?** 
  1. Penyerang dapat melewati pengecekan `checkPlateStatus()` di JS melalui Console DevTools atau HTTP request langsung menggunakan `Supabase Anon Key`.
  2. **Race Condition (TOCTOU):** Jika dua operator memasukkan plat yang sama secara bersamaan, pengecekan client-side tidak atomik.
* **Solusi Supabase Backend:**
  Gunakan PostgreSQL RPC Stored Procedure `fn_safe_insert_transaction` (atau Trigger `BEFORE INSERT`) yang melakukan `LOCK` row/table, mengecek transaksi hari ini di dalam database, lalu menolak insert (`RAISE EXCEPTION`) jika kuota habis.

#### B. Kalkulasi & Penetapan Harga BBM Resmi *(Cegah Parameter Tampering)*
* **Saat ini di Frontend:** Frontend menghitung `total_harga = liter * harga_per_liter` dan mengirimkan nilai `harga` tersebut ke Supabase.
* **Mengapa harus di Backend Supabase?**
  Operator/pengguna jahat bisa mengedit payload request HTTP menjadi `liter: 100, harga: 1000`.
* **Solusi Supabase Backend:**
  Biarkan backend mengambil `harga_per_liter` resmi yang tersimpan di tabel `harga_bbm` saat transaksi diproses di database: `harga = p_liter * (SELECT harga FROM harga_bbm WHERE aktif = true)`.

#### C. Agregasi & Hitungan Statistik Dashboard *(Performa & Kebocoran Data)*
* **Saat ini di Frontend:** [useDashboard.js](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/composables/useDashboard.js#L18-L150) menarik seluruh baris transaksi (`select('*')`) lalu melakukan `.reduce()`, filter shift (`06.00-14.00`), hitung peak hours, dan sorting pelanggan setia di browser.
* **Mengapa harus di Backend Supabase?**
  1. Jika ada 50.000 transaksi, frontend harus mendownload Megabyte data transaksi raw, membuat browser lambat dan *out of memory*.
  2. Data sensitif seluruh transaksi bocor ke client-side.
* **Solusi Supabase Backend:**
  Panggil PostgreSQL Stored Procedure / RPC (seperti yang mulai disusun pada [create_master_rpc.sql](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/create_master_rpc.sql)). Database akan mengeksekusi SQL `SUM()`, `COUNT()`, `GROUP BY date_trunc(...)` yang berjalan dalam hitungan milidetik dan hanya mengembalikan JSON ringkas (< 2 KB) ke frontend.

#### D. Hak Akses Data (*Authorization / Multi-Tenancy*)
* **Saat ini di Frontend:** Mengandalkan pengecekan role di Vue Router atau composables.
* **Mengapa harus di Backend Supabase?**
  Vue router guard hanya mencegah perpindahan halaman UI. Siapapun yang memegang `Anon Key` Supabase masih bisa querying tabel via REST API.
* **Solusi Supabase Backend:**
  Aktifkan **Row Level Security (RLS)** di PostgreSQL untuk tabel `transaksi_pertalite`, `spbu`, `user_roles`. Gunakan policy seperti `auth.uid() = operator_id` atau `get_user_role() = 'manajer'`.

#### E. Audit Logging Automatis
* **Saat ini di Frontend:** Menulis log manual via [supabaseClient.js](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/lib/supabaseClient.js#L15).
* **Solusi Supabase Backend:**
  Gunakan PostgreSQL **Audit Trigger** (`AFTER INSERT OR UPDATE OR DELETE ON transaksi_pertalite`). Log akan tercatat otomatis di server tanpa bergantung pada kode JS frontend.

---

### 📊 3. Ringkasan Matriks Separation of Concerns

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Vue 3 / SPA)                          │
│  - Render Form & UI State (loading, active tabs, modal)                │
│  - Format Tampilan (Rp 10.000, 28-07-2026)                             │
│  - Quick Pre-Validation UX (cek input tidak kosong)                    │
│  - Vue Router Guard (Redirect Navigasi UI)                             │
│  - Drawing Charts (Chart.js canvas dari data JSON ringkas)             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTP Request (RPC & Auth Token)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      BACKEND (Supabase / Postgres)                     │
│  - Enforce RLS (Row Level Security & Role Access)                      │
│  - Enforce Rules & Quota BBM (Atomis, Anti-Race Condition)             │
│  - Hitung Harga Resmi (Server-side calculation)                        │
│  - Aggregasi Data Dashboard (SQL SUM/COUNT/GROUP BY via RPC)           │
│  - Automatic Audit Trail (Database Triggers)                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 💡 Rekomendasi Langkah Refactoring Selanjutnya

1. **Pindahkan Logika Transaksi ke RPC:** Pastikan [useTransactionAction.js](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/composables/useTransactionAction.js) murni hanya memanggil `supabase.rpc('fn_safe_insert_transaction', {...})` tanpa melakukan kalkulasi kuota manual di `checkPlateStatus`.
2. **Gunakan RPC untuk Dashboard:** Ganti query `select('*')` pada [useDashboard.js](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/composables/useDashboard.js) dengan RPC `get_dashboard_summary`.
3. **Kunci Database dengan RLS:** Pastikan tabel-tabel utama di Supabase telah mengaktifkan RLS Policies.







Viewed MasterHistoryTable.vue:28-54
Searched for ".*"
Viewed useExcelExport.js:1-89
Viewed useMasterHistory.js:1-100
Viewed useMasterAnalytics.js:1-100
Viewed useTeam.js:1-34
Viewed FuelPriceForm.vue:1-100
Viewed SupportForm.vue:1-100

Setelah menganalisis seluruh sisa kode di repository FuelGuard (termasuk composables master, export data, komponen settings, dan support), berikut adalah **bagian-bagian kode tambahan yang BISA dan SEHARUSNYA dipindahkan ke Backend Supabase**:

---

### 1. `useMasterHistory.js` — Tabel Riwayat Transaksi & Filter Pagination

* **Kondisi Kode Saat Ini:**
  Fungsi `fetchAllData()` mendownload **seluruh transaksi** (`select('*')`) dan seluruh daftar SPBU ke memori browser, kemudian melakukan *fuzzy matching* string SPBU dan pagination di JavaScript menggunakan `computed` ([useMasterHistory.js L54-L100](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/composables/useMasterHistory.js#L54-L100)).
* **Masalah:**
  Jika ada 100.000 transaksi, browser harus mengunduh MB/GB data hanya untuk menampilkan 10 baris di halaman 1.
* **Solusi Backend Supabase:**
  Gunakan PostgreSQL Stored Procedure RPC **`get_master_history_paginated()`** (seperti yang sudah disiapkan di SQL migration).
  * Backend SQL melakukan `LEFT JOIN spbu`, pencarian `WHERE plat_nomor ILIKE ...`, dan paginasi `LIMIT p_page_size OFFSET ...`.
  * Frontend hanya menerima 10-25 item data yang dibutuhkan untuk halaman aktif beserta `total_count`.

---

### 2. `useMasterAnalytics.js` — Analytics KPI, Trend Penjualan, & Leaderboard SPBU

* **Kondisi Kode Saat Ini:**
  Fungsi `fetchDirectTableData()` menarik data mentah transaksi, lalu menghitung KPI (`totalSales`, `totalVolume`, `avg_trx_per_day`), pengelompokan tanggal trend (`trendMap`), dan *leaderboard* peringkat SPBU di loop JavaScript ([useMasterAnalytics.js L41-L100](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/composables/useMasterAnalytics.js#L41-L100)).
* **Masalah:**
  Kalkulasi agregasi analitik di client-side sangat berat dan tidak efektif untuk dataset besar.
* **Solusi Backend Supabase:**
  Pindahkan ke PostgreSQL RPC **`get_master_analytics_summary(p_spbu_id, p_date_from, p_date_to)`**.
  * Database Postgres memproses query dengan agregasi native SQL:
    ```sql
    SELECT 
      SUM(harga) AS total_sales,
      SUM(liter) AS total_volume,
      COUNT(id) AS total_trx,
      DATE_TRUNC('day', waktu_pencatatan) AS date_bucket
    FROM transaksi_pertalite
    GROUP BY date_bucket;
    ```
  * Respon kembali ke frontend berupa objek JSON siap konsumsi untuk grafik Chart.js.

---

### 3. `useExcelExport.js` — Export Data Transaksi ke File Excel

* **Kondisi Kode Saat Ini:**
  Melakukan *looping* pagination client-side (`pageSize = 1000`) terus-menerus hingga seluruh baris masuk ke array `allData` di memori browser ([useExcelExport.js L27-L48](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/composables/useExcelExport.js#L27-L48)).
* **Masalah:**
  Membuat puluhan request HTTP berturut-turut yang dapat mengenai limit API (*rate-limit*) dan berpotensi crash (*out of memory*) pada HP/browser spec rendah.
* **Solusi Backend Supabase:**
  * **Opsi A (PostgreSQL RPC):** Buat RPC function `get_export_transactions(p_start_date, p_end_date)` yang mengembalikan JSON siap export dalam **1 kali request**.
  * **Opsi B (Supabase Edge Function):** Buat Edge Function (Deno/TypeScript) `/functions/v1/export-transactions` yang mengunduh dan menyusun CSV/Excel stream langsung dari server ke browser pengunduh.

---

### 4. `FuelPriceForm.vue` & `ShiftForm.vue` — Pengaturan Harga BBM & Shift Operasional

* **Kondisi Kode Saat Ini:**
  `savePrices()` langsung melakukan `supabase.from('fuel_prices').upsert(updates)` dari client-side ([FuelPriceForm.vue L54-L57](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/components/settings/FuelPriceForm.vue#L54-L57)).
* **Masalah (Keamanan):**
  Jika RLS (*Row Level Security*) pada tabel `fuel_prices` belum diatur dengan ketat, siapapun yang memiliki akun Operator dapat mengubah harga BBM sistem melalui Console DevTools.
* **Solusi Backend Supabase:**
  1. Pasang **RLS Policy** di PostgreSQL pada tabel `fuel_prices`:
     ```sql
     CREATE POLICY "Hanya Manajer yang bisa update harga" 
     ON public.fuel_prices FOR ALL 
     USING (public.get_user_role() = 'manajer');
     ```
  2. Atau buat **RPC Procedure** `update_fuel_prices(p_prices json)` yang mengecek hak akses pengguna (`SECURITY DEFINER`) sebelum mengubah data.

---

### 5. `useTeam.js` — Proteksi Data Tim & User ID

* **Kondisi Kode Saat Ini:**
  `supabase.from('team_members').select('*')` langsung membaca tabel pengguna ([useTeam.js L13-L16](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/composables/useTeam.js#L13-L16)).
* **Solusi Backend Supabase:**
  Terapkan RLS Policy agar Operator tidak bisa melihat email sensitif, role, atau UUID dari anggota tim lain / manajer.

---

### 📋 Ringkasan Peta Arsitektur Akhir (Frontend vs Backend)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          FRONTEND (Vue 3 Client)                            │
│  - Presentation UI, Form Inputs, State Loading, Modal, Toasts               │
│  - Vue Router (Client Navigation Guard)                                     │
│  - Render Chart (Visualisasi Canvas/SVG)                                    │
│  - Formatter Tampilan (Intl.NumberFormat Rupiah, Date Formatters)           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ RPC Calls & RLS Tokens
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BACKEND (Supabase Postgres)                         │
│  - fn_safe_insert_transaction    ──► Mutasi Transaksi Atomis & Kuota BBM     │
│  - get_master_history_paginated  ──► Pagination & Search Filters SQL        │
│  - get_master_analytics_summary  ──► SQL SUM(), COUNT(), GROUP BY Analytics │
│  - get_dashboard_summary          ──► Heavy Data Aggregations                │
│  - RLS Policies                  ──► Hak Akses Data Per-Role                │
│  - Database Triggers             ──► Auto Audit Logging (activity_logs)     │
└─────────────────────────────────────────────────────────────────────────────┘
```

Viewed useTransactionHistory.js:1-100
Viewed usePresence.js:1-60
Viewed auth.js:1-84
Viewed ReportView.vue:1-100

Ada **beberapa bagian tambahan lagi** yang ditemukan setelah mengecek seluruh sisa file di folder `src/` (`views`, `stores`, `composables`, dan `components`). 

Berikut adalah temuan spesifik beserta solusinya:

---

### 1. `useTransactionHistory.js` — Restriksi Filter Transaksi Operator (*Broken Access Control*)

* **Kondisi Kode Saat Ini:**
  Di [useTransactionHistory.js L53-L60](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/composables/useTransactionHistory.js#L53-L60), ada logika untuk membatasi Operator agar **hanya bisa melihat transaksi hari ini jam 06.00–23.59**:
  ```javascript
  if (options.dateFilter) {
    query = query.gte('waktu_pencatatan', startOfDay)
                 .lte('waktu_pencatatan', endOfDay)
  }
  ```
* **Masalah Keamanan:**
  Karena filter ini berupa pengondisian `if (options.dateFilter)` di JS Frontend, seorang Operator yang paham DevTools dapat dengan mudah mengubah nilai `options.dateFilter = false` dan **mengintip seluruh riwayat transaksi hari-hari sebelumnya atau milik operator lain**.
* **Solusi Backend Supabase:**
  Jangan percaya filter di JS. Pindahkan proteksi ini ke **PostgreSQL RLS (Row Level Security) Policy**:
  ```sql
  CREATE POLICY "Operator hanya bisa lihat transaksi hari ini"
  ON public.transaksi_pertalite FOR SELECT
  USING (
    public.get_user_role() = 'manajer' 
    OR (
      operator_id = auth.uid() 
      AND waktu_pencatatan >= date_trunc('day', NOW())
    )
  );
  ```

---

### 2. `ReportView.vue` — Penggabungan Summary & Paginasi Laporan

* **Kondisi Kode Saat Ini:**
  Di [ReportView.vue L40-L64](file:///home/perhanjay/Documents/Programming/FuelGuard/FuelGuard/src/views/ReportView.vue#L40-L64), `fetchReport()` melakukan **2 kali network request terpisah**:
  1. Request ke RPC `get_report_summary` untuk statistik volume & revenue.
  2. Request ke tabel `transaksi_pertalite` dengan `.select('*', { count: 'exact' })` untuk mengisi tabel.
* **Solusi Backend Supabase:**
  Gabungkan kedua request tersebut ke dalam 1 RPC Function `get_report_data(p_start_date, p_end_date, p_page, p_limit)`. RPC ini dapat mengembalikan 1 payload JSON yang berisi objek `summary` dan array `items` terpaginasi sekaligus.

---

### 💡 Catatan Tambahan (Kode yang SUDAH TEPAT di Frontend)

Saat mengecek sisa file, ada beberapa kode yang **memang sudah benar berada di Frontend**:

1. **`usePresence.js` (Supabase Realtime Channel):**
   * Panggilan `supabase.channel('system-presence').track(...)` **sudah benar di Frontend**. Kehadiran (*presence*) dan status online WebSocket adalah fitur client-side murni yang menghubungkan browser pengguna secara realtime.
2. **`auth.js` (Pinia Store & Session Persistence):**
   * Panggilan `supabase.auth.getSession()` dan `supabase.auth.signInWithPassword()` **sudah benar di Frontend**. Supabase Auth SDK di JS secara otomatis menangani penyimpanan JWT Token di `localStorage` browser secara aman.

---

### 📌 Ringkasan Akhir Seluruh Item yang Harus Pindah ke Backend

| File Frontend              | Logika Saat Ini (Salah)                     | Solusi Backend (Supabase)                  |
| :------------------------- | :------------------------------------------ | :----------------------------------------- |
| `useTransactionAction.js`  | Cek kuota 5L/1x hari ini di JS              | Move ke RPC `fn_safe_insert_transaction`   |
| `TransactionForm.vue`      | Kirim `total_harga` hasil hitungan JS       | Move kalkulasi harga ke DB RPC / Trigger   |
| `useDashboard.js`          | Fetch `select('*')` + `.reduce()` di JS     | Move ke RPC `get_dashboard_summary`        |
| `useMasterHistory.js`      | Fetch `select('*')` + in-memory pagination  | Move ke RPC `get_master_history_paginated` |
| `useMasterAnalytics.js`    | Grouping trend & leaderboard di JS          | Move ke RPC `get_master_analytics_summary` |
| `useTransactionHistory.js` | Restriksi shift operator pakai `if` JS      | Move ke **PostgreSQL RLS Policy**          |
| `useExcelExport.js`        | Loop pagination fetch 1000 items di JS      | Move ke RPC / **Supabase Edge Function**   |
| `FuelPriceForm.vue`        | Direct `upsert` tabel `fuel_prices` dari UI | Enforce RLS Policy (Manager Only)          |