# POS UMKM Offline — UI/UX Modern

Aplikasi Point of Sale (POS) offline untuk UMKM menggunakan Flutter + Provider + SQLite.

## UI/UX yang sudah diterapkan

- Dashboard modern dengan sidebar untuk desktop.
- Bottom navigation untuk layar mobile.
- Tema hijau profesional, kartu rounded, spacing konsisten, dan hierarchy tipografi.
- Dashboard berisi statistik, aksi cepat, dan status offline.
- Kasir desktop menggunakan layout dua panel: katalog produk + keranjang.
- Kasir mobile menggunakan katalog + ringkasan pembayaran di bawah.
- Pencarian produk real-time.
- Kartu produk dengan indikator stok.
- Form produk yang lebih rapi dan responsif.
- Pengaturan toko dipisah menjadi Identitas, Pembayaran, dan Struk.
- QR pembayaran dibuat sebagai halaman khusus.
- Riwayat transaksi menggunakan tampilan list yang lebih informatif.
- Halaman struk memiliki status transaksi berhasil dan tombol cetak.
- Printer struk dapat dipilih dan disimpan dari Pengaturan Toko.
- Cetak struk menggunakan printer tersimpan tanpa memilih ulang setiap transaksi.
- Kegagalan cetak ditampilkan sebagai notifikasi agar status printer dapat diperiksa.
- Backup dan restore database lokal dari Pengaturan Toko.
- Validasi stok saat memasukkan produk dan saat menyimpan pembayaran.
- Audit mutasi stok untuk penjualan dan pembatalan transaksi.
- Pembatalan transaksi mengembalikan stok tanpa menghapus histori.
- Pembayaran tunai mendukung nominal dibayar dan kalkulasi kembalian.

## Struktur

```text
lib/
├── data/
│   └── database.dart
├── models/
├── providers/
├── screens/
├── services/
├── utils/
├── widgets/
│   └── komponen_pos.dart
└── main.dart
```

## Menjalankan

```bash
flutter clean
flutter pub get
flutter analyze
flutter run -d windows
```

Untuk Android:

```bash
flutter devices
flutter run -d <device-id>
```

## Catatan

Database tetap lokal/offline. Fitur printer saat ini memakai package `printing` untuk printer/PDF yang tersedia melalui sistem operasi. Integrasi printer thermal Bluetooth/USB ESC-POS dapat ditambahkan sebagai tahap berikutnya tanpa mengubah UI utama.

## Backup data

Backup tersedia di **Pengaturan Toko > Data dan Backup**. Buat backup secara berkala
dan simpan file `.db` di lokasi lain (flashdisk, cloud drive, atau perangkat berbeda).
Restore menggantikan database aktif, sehingga aplikasi perlu dibuka ulang setelah proses
restore selesai.
