import 'dart:io';

import 'package:excel_plus/excel_plus.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';

class LayananLaporan {
  LayananLaporan._();

  static final LayananLaporan instance = LayananLaporan._();

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  final DateFormat _tanggal = DateFormat('dd/MM/yyyy', 'id_ID');

  final DateFormat _tanggalWaktu = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

  // ============================================================
  // EXPORT LAPORAN BULANAN
  // ============================================================

  Future<String> exportLaporanBulanan({
    required int bulan,
    required int tahun,
  }) async {
    final db = await DatabaseLokal.instance.database;

    // ----------------------------------------------------------
    // TANGGAL AWAL DAN AKHIR BULAN
    // ----------------------------------------------------------

    final tanggalAwal = DateTime(tahun, bulan, 1);
    final tanggalAkhir = DateTime(tahun, bulan + 1, 1);

    final awalIso = tanggalAwal.toIso8601String();
    final akhirIso = tanggalAkhir.toIso8601String();

    // ----------------------------------------------------------
    // AMBIL DATA TOKO
    // ----------------------------------------------------------

    final dataPengaturan = await db.query(
      'pengaturan',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    final namaToko = dataPengaturan.isNotEmpty
        ? dataPengaturan.first['nama_toko']?.toString() ?? 'Toko Saya'
        : 'Toko Saya';

    final alamatToko = dataPengaturan.isNotEmpty
        ? dataPengaturan.first['alamat']?.toString() ?? ''
        : '';

    final teleponToko = dataPengaturan.isNotEmpty
        ? dataPengaturan.first['telepon']?.toString() ?? ''
        : '';

    // ----------------------------------------------------------
    // AMBIL TRANSAKSI BULANAN
    // ----------------------------------------------------------

    final transaksi = await db.query(
      'transaksi',
      where: "status = 'selesai' AND tanggal >= ? AND tanggal < ?",
      whereArgs: [awalIso, akhirIso],
      orderBy: 'tanggal ASC',
    );

    // ----------------------------------------------------------
    // AMBIL DETAIL TRANSAKSI BULANAN
    // ----------------------------------------------------------

    final detail = await db.rawQuery(
      '''
      SELECT
        dt.id,
        dt.transaksi_id,
        dt.produk_id,
        dt.nama_produk,
        dt.harga,
        dt.jumlah,
        dt.total,
        t.nomor,
        t.tanggal,
        t.metode_pembayaran
      FROM detail_transaksi dt
      INNER JOIN transaksi t
        ON t.id = dt.transaksi_id
      WHERE t.tanggal >= ?
        AND t.tanggal < ?
        AND t.status = 'selesai'
      ORDER BY t.tanggal ASC, dt.id ASC
      ''',
      [awalIso, akhirIso],
    );

    // ============================================================
    // HITUNG RINGKASAN
    // ============================================================

    int omzet = 0;
    int totalDiskon = 0;
    int totalSubtotal = 0;

    for (final item in transaksi) {
      omzet += _toInt(item['total']);
      totalDiskon += _toInt(item['diskon']);
      totalSubtotal += _toInt(item['subtotal']);
    }

    final jumlahTransaksi = transaksi.length;

    int produkTerjual = 0;

    for (final item in detail) {
      produkTerjual += _toInt(item['jumlah']);
    }

    final double rataRataTransaksi = jumlahTransaksi == 0
        ? 0
        : omzet / jumlahTransaksi;

    // ============================================================
    // REKAP METODE PEMBAYARAN
    // ============================================================

    final Map<String, int> pembayaran = {};

    for (final item in transaksi) {
      final metode = item['metode_pembayaran']?.toString() ?? 'Lainnya';

      pembayaran[metode] = (pembayaran[metode] ?? 0) + _toInt(item['total']);
    }

    // ============================================================
    // PRODUK TERLARIS
    // ============================================================

    final Map<String, _ProdukRekap> produkTerlaris = {};

    for (final item in detail) {
      final nama = item['nama_produk']?.toString() ?? 'Produk';

      final jumlah = _toInt(item['jumlah']);
      final total = _toInt(item['total']);

      if (!produkTerlaris.containsKey(nama)) {
        produkTerlaris[nama] = _ProdukRekap(nama: nama, jumlah: 0, omzet: 0);
      }

      produkTerlaris[nama]!.jumlah += jumlah;
      produkTerlaris[nama]!.omzet += total;
    }

    final daftarProdukTerlaris = produkTerlaris.values.toList()
      ..sort((a, b) {
        final hasilJumlah = b.jumlah.compareTo(a.jumlah);

        if (hasilJumlah != 0) {
          return hasilJumlah;
        }

        return b.omzet.compareTo(a.omzet);
      });

    // ============================================================
    // PENJUALAN HARIAN
    // ============================================================

    final Map<String, _HarianRekap> harian = {};

    // Rekap transaksi dan omzet per hari.
    for (final item in transaksi) {
      final tanggalString = item['tanggal']?.toString() ?? '';

      if (tanggalString.isEmpty) {
        continue;
      }

      final tanggal = DateTime.tryParse(tanggalString);

      if (tanggal == null) {
        continue;
      }

      final key = DateFormat('yyyy-MM-dd').format(tanggal);

      harian.putIfAbsent(key, () => _HarianRekap(tanggal: tanggal));

      harian[key]!.transaksi++;
      harian[key]!.omzet += _toInt(item['total']);
    }

    // Rekap jumlah produk terjual per hari.
    for (final item in detail) {
      final tanggalString = item['tanggal']?.toString() ?? '';

      if (tanggalString.isEmpty) {
        continue;
      }

      final tanggal = DateTime.tryParse(tanggalString);

      if (tanggal == null) {
        continue;
      }

      final key = DateFormat('yyyy-MM-dd').format(tanggal);

      harian.putIfAbsent(key, () => _HarianRekap(tanggal: tanggal));

      harian[key]!.produkTerjual += _toInt(item['jumlah']);
    }

    final daftarHarian = harian.values.toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    // ============================================================
    // BUAT WORKBOOK
    // ============================================================

    final excel = Excel.createExcel();

    // Hapus sheet default.
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ============================================================
    // SHEET 1 — RINGKASAN
    // ============================================================

    _buatSheetRingkasan(
      excel: excel,
      namaToko: namaToko,
      alamat: alamatToko,
      telepon: teleponToko,
      bulan: bulan,
      tahun: tahun,
      omzet: omzet,
      subtotal: totalSubtotal,
      diskon: totalDiskon,
      jumlahTransaksi: jumlahTransaksi,
      produkTerjual: produkTerjual,
      rataRataTransaksi: rataRataTransaksi,
      pembayaran: pembayaran,
    );

    // ============================================================
    // SHEET 2 — DETAIL TRANSAKSI
    // ============================================================

    _buatSheetDetailTransaksi(excel: excel, detail: detail);

    // ============================================================
    // SHEET 3 — PRODUK TERLARIS
    // ============================================================

    _buatSheetProdukTerlaris(excel: excel, data: daftarProdukTerlaris);

    // ============================================================
    // SHEET 4 — PENJUALAN HARIAN
    // ============================================================

    _buatSheetPenjualanHarian(excel: excel, data: daftarHarian);

    // ============================================================
    // SHEET 5 — METODE PEMBAYARAN
    // ============================================================

    _buatSheetPembayaran(excel: excel, pembayaran: pembayaran);

    // ============================================================
    // SIMPAN FILE EXCEL
    // ============================================================

    final bytes = excel.save();

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Gagal membuat file Excel.');
    }

    final direktori = await getApplicationDocumentsDirectory();

    final folderLaporan = Directory(path.join(direktori.path, 'Laporan POS'));

    if (!await folderLaporan.exists()) {
      await folderLaporan.create(recursive: true);
    }

    final namaBulan = DateFormat(
      'MMMM',
      'id_ID',
    ).format(DateTime(tahun, bulan));

    final namaFile =
        'Laporan_POS_${_sanitizeFileName(namaToko)}_${namaBulan}_$tahun.xlsx';

    final lokasi = path.join(folderLaporan.path, namaFile);

    final file = File(lokasi);

    await file.writeAsBytes(bytes, flush: true);

    return lokasi;
  }

  // ============================================================
  // SHEET RINGKASAN
  // ============================================================

  void _buatSheetRingkasan({
    required Excel excel,
    required String namaToko,
    required String alamat,
    required String telepon,
    required int bulan,
    required int tahun,
    required int omzet,
    required int subtotal,
    required int diskon,
    required int jumlahTransaksi,
    required int produkTerjual,
    required double rataRataTransaksi,
    required Map<String, int> pembayaran,
  }) {
    final sheet = excel['Ringkasan'];

    // ----------------------------------------------------------
    // JUDUL
    // ----------------------------------------------------------

    _setText(sheet, 'A1', 'LAPORAN PENJUALAN BULANAN', style: _styleJudul());

    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));

    // ----------------------------------------------------------
    // INFORMASI TOKO
    // ----------------------------------------------------------

    _setText(sheet, 'A3', 'Nama Toko', style: _styleLabel());

    _setText(sheet, 'B3', namaToko);

    _setText(sheet, 'A4', 'Alamat', style: _styleLabel());

    _setText(sheet, 'B4', alamat.isEmpty ? '-' : alamat);

    _setText(sheet, 'A5', 'Telepon', style: _styleLabel());

    _setText(sheet, 'B5', telepon.isEmpty ? '-' : telepon);

    _setText(sheet, 'A6', 'Periode', style: _styleLabel());

    _setText(
      sheet,
      'B6',
      '${DateFormat('MMMM', 'id_ID').format(DateTime(tahun, bulan))} $tahun',
    );

    // ----------------------------------------------------------
    // RINGKASAN PENJUALAN
    // ----------------------------------------------------------

    _setText(sheet, 'A8', 'RINGKASAN PENJUALAN', style: _styleSection());

    sheet.merge(CellIndex.indexByString('A8'), CellIndex.indexByString('B8'));

    _setText(sheet, 'A9', 'Subtotal', style: _styleLabel());

    _setInt(sheet, 'B9', subtotal);

    _setText(sheet, 'A10', 'Total Diskon', style: _styleLabel());

    _setInt(sheet, 'B10', diskon);

    _setText(sheet, 'A11', 'Omzet Bersih', style: _styleLabel());

    _setInt(sheet, 'B11', omzet, style: _styleHighlight());

    _setText(sheet, 'A12', 'Jumlah Transaksi', style: _styleLabel());

    _setInt(sheet, 'B12', jumlahTransaksi);

    _setText(sheet, 'A13', 'Produk Terjual', style: _styleLabel());

    _setInt(sheet, 'B13', produkTerjual);

    _setText(sheet, 'A14', 'Rata-rata Transaksi', style: _styleLabel());

    _setDouble(sheet, 'B14', rataRataTransaksi);

    // ----------------------------------------------------------
    // METODE PEMBAYARAN
    // ----------------------------------------------------------

    _setText(sheet, 'A17', 'METODE PEMBAYARAN', style: _styleSection());

    sheet.merge(CellIndex.indexByString('A17'), CellIndex.indexByString('B17'));

    _setText(sheet, 'A18', 'Metode', style: _styleHeader());

    _setText(sheet, 'B18', 'Total', style: _styleHeader());

    int row = 19;

    for (final entry in pembayaran.entries) {
      _setText(sheet, 'A$row', entry.key);

      _setInt(sheet, 'B$row', entry.value);

      row++;
    }

    // ----------------------------------------------------------
    // LEBAR KOLOM
    // ----------------------------------------------------------

    _setColumnWidth(sheet, 0, 28);
    _setColumnWidth(sheet, 1, 25);
    _setColumnWidth(sheet, 2, 20);
    _setColumnWidth(sheet, 3, 20);
  }

  // ============================================================
  // SHEET DETAIL TRANSAKSI
  // ============================================================

  void _buatSheetDetailTransaksi({
    required Excel excel,
    required List<Map<String, Object?>> detail,
  }) {
    final sheet = excel['Detail Transaksi'];

    final headers = [
      'No',
      'Nomor Transaksi',
      'Tanggal',
      'Produk',
      'Harga',
      'Jumlah',
      'Total',
      'Metode Pembayaran',
    ];

    _tulisHeader(sheet, headers);

    int row = 2;

    for (int i = 0; i < detail.length; i++) {
      final item = detail[i];

      final tanggal = DateTime.tryParse(item['tanggal']?.toString() ?? '');

      _setInt(sheet, 'A$row', i + 1);

      _setText(sheet, 'B$row', item['nomor']?.toString() ?? '-');

      _setText(
        sheet,
        'C$row',
        tanggal == null ? '-' : _tanggalWaktu.format(tanggal),
      );

      _setText(sheet, 'D$row', item['nama_produk']?.toString() ?? '-');

      _setInt(sheet, 'E$row', _toInt(item['harga']));

      _setInt(sheet, 'F$row', _toInt(item['jumlah']));

      _setInt(sheet, 'G$row', _toInt(item['total']));

      _setText(sheet, 'H$row', item['metode_pembayaran']?.toString() ?? '-');

      row++;
    }

    // ----------------------------------------------------------
    // LEBAR KOLOM
    // ----------------------------------------------------------

    _setColumnWidth(sheet, 0, 8);
    _setColumnWidth(sheet, 1, 25);
    _setColumnWidth(sheet, 2, 20);
    _setColumnWidth(sheet, 3, 32);
    _setColumnWidth(sheet, 4, 18);
    _setColumnWidth(sheet, 5, 12);
    _setColumnWidth(sheet, 6, 18);
    _setColumnWidth(sheet, 7, 22);
  }

  // ============================================================
  // SHEET PRODUK TERLARIS
  // ============================================================

  void _buatSheetProdukTerlaris({
    required Excel excel,
    required List<_ProdukRekap> data,
  }) {
    final sheet = excel['Produk Terlaris'];

    _tulisHeader(sheet, ['Ranking', 'Produk', 'Jumlah Terjual', 'Omzet']);

    int row = 2;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];

      _setInt(sheet, 'A$row', i + 1);

      _setText(sheet, 'B$row', item.nama);

      _setInt(sheet, 'C$row', item.jumlah);

      _setInt(sheet, 'D$row', item.omzet);

      row++;
    }

    _setColumnWidth(sheet, 0, 12);
    _setColumnWidth(sheet, 1, 35);
    _setColumnWidth(sheet, 2, 18);
    _setColumnWidth(sheet, 3, 20);
  }

  // ============================================================
  // SHEET PENJUALAN HARIAN
  // ============================================================

  void _buatSheetPenjualanHarian({
    required Excel excel,
    required List<_HarianRekap> data,
  }) {
    final sheet = excel['Penjualan Harian'];

    _tulisHeader(sheet, [
      'Tanggal',
      'Jumlah Transaksi',
      'Produk Terjual',
      'Omzet',
    ]);

    int row = 2;

    for (final item in data) {
      _setText(sheet, 'A$row', _tanggal.format(item.tanggal));

      _setInt(sheet, 'B$row', item.transaksi);

      _setInt(sheet, 'C$row', item.produkTerjual);

      _setInt(sheet, 'D$row', item.omzet);

      row++;
    }

    _setColumnWidth(sheet, 0, 18);
    _setColumnWidth(sheet, 1, 20);
    _setColumnWidth(sheet, 2, 20);
    _setColumnWidth(sheet, 3, 20);
  }

  // ============================================================
  // SHEET METODE PEMBAYARAN
  // ============================================================

  void _buatSheetPembayaran({
    required Excel excel,
    required Map<String, int> pembayaran,
  }) {
    final sheet = excel['Metode Pembayaran'];

    _tulisHeader(sheet, ['Metode Pembayaran', 'Total Penjualan']);

    int row = 2;

    for (final entry in pembayaran.entries) {
      _setText(sheet, 'A$row', entry.key);

      _setInt(sheet, 'B$row', entry.value);

      row++;
    }

    _setColumnWidth(sheet, 0, 25);
    _setColumnWidth(sheet, 1, 25);
  }

  // ============================================================
  // HELPER HEADER
  // ============================================================

  void _tulisHeader(Sheet sheet, List<String> headers) {
    for (int i = 0; i < headers.length; i++) {
      final kolom = _nomorKolom(i);

      _setText(sheet, '${kolom}1', headers[i], style: _styleHeader());
    }
  }

  // ============================================================
  // HELPER CELL
  // ============================================================

  void _setText(Sheet sheet, String cell, String value, {CellStyle? style}) {
    sheet.updateCell(
      CellIndex.indexByString(cell),
      TextCellValue(value),
      cellStyle: style,
    );
  }

  void _setInt(Sheet sheet, String cell, int value, {CellStyle? style}) {
    sheet.updateCell(
      CellIndex.indexByString(cell),
      IntCellValue(value),
      cellStyle: style ?? _styleNumber(),
    );
  }

  void _setDouble(Sheet sheet, String cell, double value, {CellStyle? style}) {
    sheet.updateCell(
      CellIndex.indexByString(cell),
      DoubleCellValue(value),
      cellStyle: style ?? _styleNumber(),
    );
  }

  // ============================================================
  // STYLE
  // ============================================================

  CellStyle _styleJudul() {
    return CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#1E7A4C'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  CellStyle _styleSection() {
    return CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#1E7A4C'),
    );
  }

  CellStyle _styleHeader() {
    return CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#168C63'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  CellStyle _styleLabel() {
    return CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#EAF5EF'),
    );
  }

  CellStyle _styleHighlight() {
    return CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#1E7A4C'),
      backgroundColorHex: ExcelColor.fromHexString('#E7F4ED'),
    );
  }

  CellStyle _styleNumber() {
    return CellStyle(numberFormat: NumFormat.standard_4);
  }

  // ============================================================
  // HELPER KOLOM
  // ============================================================

  String _nomorKolom(int index) {
    int angka = index + 1;

    String hasil = '';

    while (angka > 0) {
      final sisa = (angka - 1) % 26;

      hasil = String.fromCharCode(65 + sisa) + hasil;

      angka = (angka - 1) ~/ 26;
    }

    return hasil;
  }

  // ============================================================
  // HELPER LEBAR KOLOM
  // ============================================================

  void _setColumnWidth(Sheet sheet, int column, double width) {
    sheet.setColumnWidth(column, width);
  }

  // ============================================================
  // HELPER INTEGER
  // ============================================================

  int _toInt(Object? value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ============================================================
  // HELPER NAMA FILE
  // ============================================================

  String _sanitizeFileName(String value) {
    if (value.trim().isEmpty) {
      return 'Toko';
    }

    return value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}

// ============================================================
// MODEL INTERNAL — PRODUK
// ============================================================

class _ProdukRekap {
  final String nama;

  int jumlah;
  int omzet;

  _ProdukRekap({required this.nama, required this.jumlah, required this.omzet});
}

// ============================================================
// MODEL INTERNAL — HARIAN
// ============================================================

class _HarianRekap {
  final DateTime tanggal;

  int transaksi = 0;
  int produkTerjual = 0;
  int omzet = 0;

  _HarianRekap({required this.tanggal});
}
