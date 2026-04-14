# KasirKu - Aplikasi Mobile Point of Sale (POS)

KasirKu adalah aplikasi Point of Sale (Kasir) berbasis mobile yang dibangun menggunakan Flutter dan SQLite. Aplikasi ini dirancang untuk mempermudah UMKM atau pemilik toko dalam mencatat penjualan, mengelola stok barang, dan melihat riwayat transaksi secara digital dan *offline-first* (tanpa memerlukan koneksi internet).

## 🚀 Fitur Utama

- **Manajemen Produk:** Tambah, edit, hapus, dan lihat daftar produk beserta stok kasir.
- **Sistem Kasir (Cart/Keranjang):** Memasukkan barang ke keranjang belanja, mengubah kuantitas, dan menghitung total harga secara *real-time*.
- **Transaksi Pembayaran:** Memproses pembayaran, menghitung uang kembalian, dan memotong stok barang secara otomatis.
- **Riwayat Transaksi:** Melihat catatan penjualan yang sudah terjadi beserta detail barang yang dibeli (struk digital).
- **Database Lokal Lokal (Offline):** Seluruh data tersimpan aman di perangkat menggunakan SQLite.

## 🛠️ Teknologi yang Digunakan

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Database:** [SQLite](https://pub.dev/packages/sqflite) (melalui `sqflite`)
- **State Management:** Provider (untuk sinkronisasi data antar halaman, seperti keranjang belanja)

## 📂 Struktur Folder Proyek

```text
lib/
├── models/       # Class representasi struktur data (User, Product, Transaction)
├── pages/        # Tampilan layar aplikasi (Home, Kasir, Riwayat, dll)
├── providers/    # Manajemen state aplikasi (CartProvider)
├── helpers/      # Konfigurasi dan Helper Database (DatabaseHelper)
├── widgets/      # Komponen UI yang dapat digunakan kembali (Cards, Buttons, dll)
└── main.dart     # Entry point utama aplikasi
```

## 🗄️ Struktur Database (SQLite)

Aplikasi ini menggunakan beberapa tabel utama:
1. `users` - Menyimpan data akun kasir/admin.
2. `products` - Menyimpan data katalog barang (Nama, Harga, Stok).
3. `transactions` - Menyimpan rekap nota penjualan (Tanggal, Total Harga, Uang Bayar, Kembalian).
4. `transaction_details` - Menyimpan detail barang ("keranjang") yang ada di dalam sebuah nota transaksi.

## ⚡ Cara Menjalankan Project

Ikuti langkah-langkah di bawah ini untuk menjalankan aplikasi di komputer Anda:

1. Pastikan Anda sudah menginstal **Flutter SDK** versi terbaru.
2. Lakukan *clone* repository ini atau ekstrak folder project.
3. Buka terminal di dalam root folder project.
4. Download semua *dependencies* (package) yang dibutuhkan:
   ```bash
   flutter pub get
   ```
5. Hubungkan emulator (Android/iOS) atau device fisik Anda.
6. Jalankan aplikasi:
   ```bash
   flutter run
   ```

## 👨‍💻 Dikembangkan Oleh
**[Nama Siswa / Kelompok]**
Dibuat untuk memenuhi Tugas/Ujian Akhir Sekolah.
