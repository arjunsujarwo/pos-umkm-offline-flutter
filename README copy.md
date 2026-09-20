# POS UMKM Offline - Flutter

Aplikasi POS sederhana untuk UMKM.

## Fitur versi awal

- Beranda/dashboard
- Transaksi kasir
- CRUD produk
- CRUD kategori
- Pengaturan toko
- Nama toko masuk ke struk
- Logo toko disimpan sebagai file lokal
- Metode pembayaran: Tunai, QRIS/QR Code, Transfer Bank
- QR pembayaran dari teks/nomor rekening
- Riwayat transaksi
- Preview dan cetak struk melalui sistem printer/PDF
- Database SQLite sehingga transaksi tetap berjalan tanpa internet

## Catatan printer

Versi awal memakai package `printing`. Ini cocok untuk printer yang dikenali Android/Windows sebagai printer sistem atau untuk menyimpan/membagikan PDF.

Dukungan printer thermal Bluetooth ESC/POS secara langsung sebaiknya dibuat sebagai modul berikutnya karena tiap printer/driver memiliki karakteristik berbeda. Arsitektur aplikasi sudah dipisahkan sehingga modul printer dapat ditambahkan tanpa mengubah logika transaksi.

## Instalasi

1. Install Flutter.
2. Jalankan:
   flutter doctor
3. Buat project kosong jika diperlukan:
   flutter create .
4. Salin isi folder `lib` dan `pubspec.yaml` dari paket ini ke project.
5. Jalankan:
   flutter pub get
6. Android:
   flutter run
7. Windows:
   flutter run -d windows

## Penting

Jalankan `flutter create .` dari folder project setelah mengekstrak ZIP agar folder `android`, `windows`, `web`, dll dibuat oleh Flutter.

Database dibuat otomatis pada first run.
