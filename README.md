# Vue-Supabase Dashboard Monitor

![Vue.js](https://img.shields.io/badge/Vue.js-3.5-4FC08D?style=for-the-badge&logo=vuedotjs&logoColor=white)
![Vite](https://img.shields.io/badge/Vite-6.0-646CFF?style=for-the-badge&logo=vite&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Auth_&_DB-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-4.0-38B2AC?style=for-the-badge&logo=tailwindcss&logoColor=white)

**Vue-Supabase Dashboard Monitor** adalah aplikasi web monitoring operasional yang modern dan responsif. Aplikasi ini dirancang untuk memfasilitasi manajemen data secara *real-time* dengan pemisahan hak akses yang ketat antara manajemen dan operasional lapangan, didukung oleh infrastruktur backend Supabase yang andal.

---

## Fitur Unggulan

### 1. Konsol Operator (Operator Layout)
* **Antarmuka Fokus:** Desain minimalis untuk input data cepat di lapangan.
* **Validasi Transaksi:** Pencegahan input duplikat untuk kendaraan yang sama pada hari yang sama.
* **Riwayat Harian:** Tampilan riwayat transaksi harian per operator.
* **Responsivitas:** Tampilan adaptif yang optimal untuk perangkat seluler.

### 2. Dasbor Manajerial (Admin Layout)
* **Statistik Real-time:** Visualisasi volume penjualan, pendapatan, dan pertumbuhan transaksi.
* **Manajemen Riwayat:** Tabel data lengkap dengan fitur penomoran halaman (pagination) sisi server.
* **Pusat Bantuan (IT Support):** Modul pelaporan masalah sistem dan kontak darurat teknis.

### 3. Modul Laporan & Analitik
* **Filter Kustom:** Pemilihan rentang tanggal fleksibel untuk analisis periode tertentu.
* **Kalkulasi Sisi Server:** Menggunakan PostgreSQL RPC untuk perhitungan statistik akurat tanpa batasan baris.
* **Ekspor Data:** Fitur unduh laporan dalam format Excel (.xlsx) dengan dukungan data skala besar (teknik *chunking*).
* **Tata Letak Adaptif:** Tampilan *fit-to-screen* dengan area gulir (scroll) terisolasi pada tabel data.

---

## Teknologi yang Digunakan

Daftar teknologi utama berdasarkan konfigurasi proyek:

* **Kerangka Kerja Frontend:** Vue.js 3 (Composition API)
* **Build Tool:** Vite
* **Manajemen State:** Pinia
* **Styling:** Tailwind CSS v4 & DaisyUI
* **Basis Data & Backend:** Supabase (PostgreSQL)
* **Autentikasi:** Supabase Auth
* **Utilitas:** XLSX (Ekspor Data), Vue3-Toastify (Notifikasi)

---

```text
src/
├── assets/          # Aset statis (Gambar, CSS Global)
├── components/      # Komponen Vue yang dapat digunakan kembali
│   ├── auth/        # Komponen autentikasi
│   ├── dashboard/   # Komponen visualisasi dasbor
│   ├── history/     # Komponen tabel riwayat
│   ├── operator/    # Komponen input operator
│   ├── report/      # Komponen header dan statistik laporan
│   └── support/     # Komponen formulir bantuan
├── composables/     # Logika bisnis yang dapat digunakan kembali (misal: Export Excel)
├── layouts/         # Tata letak halaman (Admin & Operator)
├── lib/             # Konfigurasi klien eksternal (Supabase)
├── stores/          # Manajemen state global (Pinia)
└── views/           # Halaman utama aplikasi
```

Hak Cipta © 2025 PT. Habi Jaya. Seluruh hak cipta dilindungi undang-undang. Sistem ini bersifat privat dan hanya ditujukan untuk penggunaan internal perusahaan.