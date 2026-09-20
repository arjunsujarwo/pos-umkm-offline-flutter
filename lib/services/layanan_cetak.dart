import 'dart:typed_data';
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/item_keranjang.dart';
import '../models/pengaturan_toko.dart';
import '../utils/format_rupiah.dart';

class LayananCetak {
  static Future<void> cetakStruk({
    required PengaturanToko toko,
    required String nomorTransaksi,
    required DateTime tanggal,
    required List<ItemKeranjang> item,
    required int subtotal,
    required int diskon,
    required int total,
    required String metodePembayaran,
  }) async {
    if (toko.printerUrl.isEmpty) {
      throw StateError('Printer belum dipilih di Pengaturan Toko.');
    }
    final printer = Printer(url: toko.printerUrl, name: toko.printerNama);

    final dokumen = await buatPdf(
      toko: toko,
      nomorTransaksi: nomorTransaksi,
      tanggal: tanggal,
      item: item,
      subtotal: subtotal,
      diskon: diskon,
      total: total,
      metodePembayaran: metodePembayaran,
    );

    final berhasil = await Printing.directPrintPdf(
      printer: printer,
      name: 'Struk $nomorTransaksi',
      onLayout: (_) async => dokumen,
    );
    if (!berhasil) {
      throw StateError(
        'Printer menolak pekerjaan cetak. Periksa printer, kertas, dan koneksi.',
      );
    }
  }

  static Future<Uint8List> buatPdf({
    required PengaturanToko toko,
    required String nomorTransaksi,
    required DateTime tanggal,
    required List<ItemKeranjang> item,
    required int subtotal,
    required int diskon,
    required int total,
    required String metodePembayaran,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logo;
    if (toko.logo.isNotEmpty) {
      final file = File(toko.logo);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          logo = pw.MemoryImage(bytes);
        }
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (logo != null) ...[
                pw.Center(
                  child: pw.SizedBox(
                    width: 64,
                    height: 64,
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 6),
              ],
              pw.Text(
                toko.namaToko,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (toko.alamat.isNotEmpty)
                pw.Text(toko.alamat, textAlign: pw.TextAlign.center),
              if (toko.telepon.isNotEmpty)
                pw.Text(toko.telepon, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Text('No: $nomorTransaksi'),
              pw.Text('Tanggal: ${tanggal.toString().substring(0, 16)}'),
              pw.Divider(),
              ...item.map(
                (data) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(data.produk.nama),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${data.jumlah} x ${rupiah(data.produk.harga)}',
                        ),
                        pw.Text(rupiah(data.total)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Subtotal'), pw.Text(rupiah(subtotal))],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Diskon'), pw.Text(rupiah(diskon))],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    rupiah(total),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('Pembayaran: $metodePembayaran'),
              pw.SizedBox(height: 12),
              pw.Text(toko.pesanStruk, textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
