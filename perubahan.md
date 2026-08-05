# Catatan Perubahan System (Changelog) - FuelGuard

## 1. Pembaruan Layout & Mobile Navigation Drawer
- **Floating Header Bar (`MasterLayout.vue` & `AdminLayout.vue`)**:
  - Menerapkan header top-bar melayang dengan efek glassmorphism (`h-16 rounded-3xl bg-white/90 backdrop-blur-xl`) khusus tampilan mobile/tablet.
  - Menjadikan Logo & Brand dapat diklik untuk membuka menu navigasi mobile.
- **Teleported Mobile Drawer (`<Teleport to="body">`)**:
  - Memindahkan drawer overlay ke `document.body` menggunakan `<Teleport>` untuk mencegah pemotongan (*clipping*) dan kerusakan layout pada halaman utama.
  - Menerapkan mekanisme animasi slide-in & slide-out yang halus berdurasi 300ms (`transition-transform duration-300 ease-out`) persis seperti pada `OperatorLayout.vue`.
  - Mengembalikan estetika drawer Master ke tema Signature Dark Green Gradient (`bg-gradient-to-b from-[#143d2e] via-[#1b4d3a] to-[#256a50]`) dengan kartu profil glassmorphism transparan.
- **Batasan Skala Collapse Sidebar**:
  - Membatasi logika ciutkan/perluas sidebar (`toggleCollapse`) hanya pada perangkat desktop (`>= 1280px` / `xl`).

## 2. Penyederhanaan Form Konfigurasi Harga BBM Pertalite (`FuelPriceForm.vue`)
- **Pembersihan Teks & Elemen**:
  - Menghapus badge "Subsidi Acuan" dan teks "Auto-Sync Terhubung".
  - Menghapus tombol penyesuai angka `+50` dan `-50`.
- **Pembaruan Visual & Tombol**:
  - Mengganti ikon lama dengan logo resmi **FuelGuard** ter-invert bersih di dalam ikon box hijau.
  - Memperbarui gaya tombol "Simpan Harga Pertalite" dengan Green Glassmorphism Gradient (`bg-gradient-to-r from-[#143d2e] via-[#1b4d3a] to-[#256a50] hover:from-[#1b4d3a] hover:to-[#258f62] backdrop-blur-md`).

## 3. Penyelarasan Form Keamanan Akun (`SecurityForm.vue`)
- **Penyelarasan Style Tombol**:
  - Mengubah gaya tombol "Perbarui Password" agar identik 100% dengan tombol Simpan Harga Pertalite (Green Glassmorphism Gradient).

## 4. Penyesuaian Halaman Pengaturan (`MasterSettingsView.vue` & `SettingsView.vue`)
- **Pembersihan Sub-header**:
  - Menghapus teks deskripsi di bawah judul utama.
- **Standarisasi Ukuran Font Header**:
  - Menyepadankan ukuran font judul halaman pengaturan ke `text-3xl md:text-4xl font-extrabold text-[#143d2e] tracking-tight`, presisi dengan header halaman lain (Dashboard, Riwayat Transaksi, Kelola Operator, dll.).

## 5. Penyelarasan Tabel & Komponen Keseluruhan
- **Clean UI & Aset**:
  - Menghapus efek pulsa / dot berdetak pada komponen tabel dan status transaksi.
  - Memastikan konsistensi warna gradien hijau glassmorphism antara peran Operator, Admin, dan Master.
