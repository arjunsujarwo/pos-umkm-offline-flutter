import 'package:flutter/foundation.dart';

import '../data/database.dart';

/// Provider khusus untuk mengambil dan mengolah
/// data yang akan ditampilkan pada Dashboard.
///
/// Provider ini TIDAK menyimpan data transaksi baru.
/// Tugasnya hanya membaca database SQLite dan
/// mengubahnya menjadi data yang mudah digunakan UI.
class DashboardProvider extends ChangeNotifier {
  bool sedangMemuat = false;

  // ==============================
  // STATISTIK UTAMA
  // ==============================

  double omzetHariIni = 0;

  int jumlahTransaksiHariIni = 0;

  int jumlahProdukTerjualHariIni = 0;

  double rataRataTransaksi = 0;

  // ==============================
  // DATA TAMBAHAN DASHBOARD
  // ==============================

  List<Map<String, dynamic>> transaksiTerbaru = [];

  List<Map<String, dynamic>> produkTerlaris = [];

  List<Map<String, dynamic>> stokMenipis = [];

  /// Memuat seluruh data yang dibutuhkan Dashboard.
  Future<void> muatDashboard() async {
    sedangMemuat = true;
    notifyListeners();

    try {
      await Future.wait([
        _muatStatistikHariIni(),
        _muatTransaksiTerbaru(),
        _muatProdukTerlaris(),
        _muatStokMenipis(),
      ]);
    } finally {
      sedangMemuat = false;
      notifyListeners();
    }
  }

  /// Mengambil statistik transaksi hari ini.
  Future<void> _muatStatistikHariIni() async {
    final db = await DatabaseLokal.instance.database;

    // SQLite menggunakan tanggal lokal dari aplikasi.
    final hasil = await db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) AS omzet,
        COUNT(*) AS jumlah_transaksi
      FROM transaksi
      WHERE status = 'selesai'
        AND DATE(tanggal) = DATE('now', 'localtime')
    ''');

    if (hasil.isEmpty) {
      return;
    }

    final data = hasil.first;

    omzetHariIni = (data['omzet'] as num?)?.toDouble() ?? 0;

    jumlahTransaksiHariIni = (data['jumlah_transaksi'] as num?)?.toInt() ?? 0;

    // Menghindari pembagian dengan angka 0.
    if (jumlahTransaksiHariIni > 0) {
      rataRataTransaksi = omzetHariIni / jumlahTransaksiHariIni;
    } else {
      rataRataTransaksi = 0;
    }

    // Menghitung jumlah seluruh item yang terjual hari ini.
    final hasilProduk = await db.rawQuery('''
      SELECT
        COALESCE(SUM(dt.jumlah), 0) AS jumlah
      FROM detail_transaksi dt
      INNER JOIN transaksi t
        ON t.id = dt.transaksi_id
      WHERE DATE(t.tanggal) =
        DATE('now', 'localtime')
        AND t.status = 'selesai'
    ''');

    if (hasilProduk.isNotEmpty) {
      jumlahProdukTerjualHariIni =
          (hasilProduk.first['jumlah'] as num?)?.toInt() ?? 0;
    }
  }

  /// Mengambil beberapa transaksi terakhir.
  Future<void> _muatTransaksiTerbaru() async {
    final db = await DatabaseLokal.instance.database;

    transaksiTerbaru = await db.query(
      'transaksi',
      orderBy: 'tanggal DESC',
      limit: 5,
    );
  }

  /// Mengambil produk yang paling banyak terjual.
  Future<void> _muatProdukTerlaris() async {
    final db = await DatabaseLokal.instance.database;

    produkTerlaris = await db.rawQuery('''
      SELECT
        produk_id,
        nama_produk,
        SUM(jumlah) AS jumlah_terjual,
        SUM(total) AS total_penjualan
      FROM detail_transaksi
      INNER JOIN transaksi t ON t.id = detail_transaksi.transaksi_id
      WHERE t.status = 'selesai'
      GROUP BY produk_id, nama_produk
      ORDER BY jumlah_terjual DESC
      LIMIT 5
    ''');
  }

  /// Mengambil produk dengan stok rendah.
  Future<void> _muatStokMenipis() async {
    final db = await DatabaseLokal.instance.database;

    stokMenipis = await db.query(
      'produk',
      where: 'aktif = ? AND stok <= ?',
      whereArgs: [1, 5],
      orderBy: 'stok ASC',
      limit: 5,
    );
  }
}
