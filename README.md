# ☕ Maucoffee POS

[![Flutter](https://img.shields.io/badge/Flutter-v3.x-02569B?logo=flutter&logoColor=white&style=for-the-badge)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database-3ECF8E?logo=supabase&logoColor=white&style=for-the-badge)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-orange?style=for-the-badge)](#)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](#)

**Maucoffee POS** adalah aplikasi kasir (*Point of Sale*) modern, tangguh, dan berpenampilan premium yang dirancang khusus untuk kedai kopi. Dibangun menggunakan **Flutter** dan **Supabase**, aplikasi ini dirancang khusus untuk memiliki keandalan tinggi di lapangan melalui arsitektur **Offline-First** yang tangguh terhadap koneksi Wi-Fi tidak stabil.

---

## ✨ Fitur Utama (Core Features)

### 📶 1. Resiliensi Offline-First & Autentikasi Pintar
* **Transaksi Offline Tanpa Hambatan**: Koneksi Wi-Fi kafe macet/hilang? Kasir tetap bisa melakukan checkout! Transaksi otomatis tersimpan di antrean penyimpanan lokal dalam waktu 0.01 detik.
* **Background Sync Otomatis**: Begitu koneksi internet aktif kembali, antrean transaksi offline di HP kasir akan diunggah otomatis ke database Supabase Cloud di latar belakang tanpa mengganggu jalannya aplikasi.
* **Anti-Blocking UI Cache**: Katalog menu, kategori, absensi, dan riwayat di-preload secara instan dari cache lokal (0.0 detik) saat aplikasi dibuka. Tidak ada layar loading spinner berputar-putar yang memblokir kerja kasir.

### 🎨 2. Premium & Modern Navigation UI (iOS 18 Vibe)
* **Glassmorphic Floating Bottom Bar**: Bar navigasi melayang yang elegan dengan efek kaca buram dan transisi membal (*bouncy curve*) saat berpindah halaman.
* **Full-Screen Vertikal Grid Menu**: Akses cepat 4 baris x 2 kolom yang ramah ibu jari untuk menjangkau seluruh modul fitur dengan mudah.
* **Adaptif iOS & Android (Swipe-to-Back)**: Gestur usap tepi kiri layar untuk kembali secara alami aktif di iOS (menggunakan `CupertinoPageRoute`), sementara Android tetap mempertahankan transisi memudar (*FadeTransition*) yang halus.

### 🕒 3. Shift Kerja & Absensi Staf Aktif
* **Draggable & Snapping Shift Pill**: Tombol shift kerja melayang yang interaktif dan dapat diseret. Memantau durasi kerja aktif kasir secara real-time.
* **Pencegahan Error Offline**: Menampilkan status shift dan data kehadiran staf secara aman menggunakan data cadangan lokal saat terputus dari jaringan.

### 📊 4. Laporan Keuangan & Backdating
* **Pencatatan Pemasukan Manual**: Kasir bisa mencatat pemasukan non-produk secara manual langsung ke sistem keuangan.
* **Tanggal Custom (Backdate)**: Pemilik atau kasir bisa memasukkan tanggal transaksi kemarin atau hari-hari sebelumnya secara akurat.

---

## 🛠️ Tech Stack & Library

* **Frontend**: [Flutter](https://flutter.dev) (Dart)
* **Database & Auth**: [Supabase Cloud](https://supabase.com)
* **State Management**: [Flutter BLoC / Cubit](https://pub.dev/packages/flutter_bloc)
* **Local Storage (Cache)**: [SharedPreferences](https://pub.dev/packages/shared_preferences)
* **Network & Sync**: [Connectivity Plus](https://pub.dev/packages/connectivity_plus)
* **Pencetakan Kode QR**: [QR Flutter](https://pub.dev/packages/qr_flutter)
* **Pemindai QR**: [Mobile Scanner](https://pub.dev/packages/mobile_scanner)

---

## 📂 Struktur Folder (Clean Architecture)

Proyek ini menggunakan struktur folder bersih berbasis fitur (*feature-driven clean architecture*) untuk memisahkan logika data dengan tampilan UI:

```text
lib/
├── auth/                 # Autentikasi, login admin/karyawan, scanner QR staf
├── config/               # Service Locator (GetIt) dan User Preferences
├── features/             # Fitur-fitur utama aplikasi:
│   ├── absensi/          #   - Manajemen shift dan absensi staf (Cubit & UI)
│   ├── catalog/          #   - Katalog produk kasir dan kategori (Cubit & UI)
│   └── setting/          #   - Konfigurasi, sinkronisasi manual, profil kafe
├── home/                 # Halaman utama admin & karyawan, list staf kafe
├── model/                # Data model (Product, Category, Order, Employee, dsb)
├── navigation/           # Floating Bottom Navigation & Overlay Menu utama
├── repository/           # Lapisan data API Supabase Cloud terpusat
├── services/             # Sinkronisasi latar belakang (SyncManager) & penyimpanan offline
└── ui/                   # Global Design System (Color, Typography, Dimension, Shared Widget)
```

---

## 🚀 Cara Memulai (Getting Started)

### Prasyarat
* Flutter SDK (Versi terbaru disarankan)
* Akun & Proyek [Supabase](https://supabase.com/) aktif

### Langkah Instalasi

1. **Clone Repositori**
   ```bash
   git clone https://github.com/DoniiAdityapratama/maucoffee-pos.git
   cd maucoffee-pos
   ```

2. **Dapatkan Dependencies**
   ```bash
   flutter pub get
   ```

3. **Inisialisasi Project Ke Android / iOS**
   Pastikan file konfigurasi database Supabase dan kunci API sudah dikonfigurasi dengan benar di dalam kode inisialisasi utama.

4. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah Lisensi **MIT** - lihat berkas [LICENSE](LICENSE) untuk detail lebih lanjut.

Developed with ❤️ for **Maucoffee Kafe**.
