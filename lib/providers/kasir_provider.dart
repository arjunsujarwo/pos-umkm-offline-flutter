import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../models/item_keranjang.dart';
import '../models/produk.dart';

class KasirProvider extends ChangeNotifier {
  final List<ItemKeranjang> keranjang = [];

  int diskon = 0;
  String metodePembayaran = 'Tunai';
  int nominalDibayar = 0;
  String? pesanValidasi;

  int get subtotal => keranjang.fold(0, (total, item) => total + item.total);

  int get total => (subtotal - diskon).clamp(0, 1 << 62);
  int get kembalian => metodePembayaran == 'Tunai' ? nominalDibayar - total : 0;

  void tambahProduk(Produk produk) {
    if (produk.stok <= 0) {
      pesanValidasi = 'Stok produk "${produk.nama}" habis.';
      notifyListeners();
      return;
    }

    final index = keranjang.indexWhere((item) => item.produk.id == produk.id);

    if (index >= 0) {
      if (keranjang[index].jumlah < produk.stok) {
        keranjang[index].jumlah++;
      } else {
        pesanValidasi = 'Jumlah "${produk.nama}" melebihi stok tersedia.';
      }
    } else {
      keranjang.add(ItemKeranjang(produk: produk));
    }

    notifyListeners();
  }

  void tambahJumlah(int index) {
    if (keranjang[index].jumlah < keranjang[index].produk.stok) {
      keranjang[index].jumlah++;
      notifyListeners();
    }
  }

  void kurangiJumlah(int index) {
    if (keranjang[index].jumlah > 1) {
      keranjang[index].jumlah--;
    } else {
      keranjang.removeAt(index);
    }
    notifyListeners();
  }

  void hapusItem(int index) {
    keranjang.removeAt(index);
    notifyListeners();
  }

  void kosongkanKeranjang() {
    keranjang.clear();
    diskon = 0;
    metodePembayaran = 'Tunai';
    nominalDibayar = 0;
    pesanValidasi = null;
    notifyListeners();
  }

  void ubahDiskon(int nilai) {
    diskon = nilai.clamp(0, subtotal);
    notifyListeners();
  }

  void ubahMetodePembayaran(String nilai) {
    metodePembayaran = nilai;
    if (nilai != 'Tunai') {
      nominalDibayar = total;
    }
    pesanValidasi = null;
    notifyListeners();
  }

  void ubahNominalDibayar(int nilai) {
    nominalDibayar = nilai;
    pesanValidasi = null;
    notifyListeners();
  }

  Future<int?> simpanTransaksi() async {
    if (keranjang.isEmpty) {
      pesanValidasi = 'Keranjang masih kosong.';
      notifyListeners();
      return null;
    }

    if (metodePembayaran == 'Tunai' && nominalDibayar < total) {
      pesanValidasi = 'Nominal pembayaran kurang dari total transaksi.';
      notifyListeners();
      return null;
    }

    final db = await DatabaseLokal.instance.database;

    final sekarang = DateTime.now();
    final nomor =
        'TRX${DateFormat('yyyyMMddHHmmss').format(sekarang)}${sekarang.millisecond.toString().padLeft(3, '0')}';

    int? idTransaksi;

    await db.transaction((transaksi) async {
      for (final item in keranjang) {
        final dataProduk = await transaksi.query(
          'produk',
          columns: ['stok', 'aktif'],
          where: 'id = ?',
          whereArgs: [item.produk.id],
          limit: 1,
        );
        if (dataProduk.isEmpty || dataProduk.first['aktif'] != 1) {
          throw StateError('Produk "${item.produk.nama}" tidak tersedia.');
        }
        final stok = (dataProduk.first['stok'] as num).toInt();
        if (stok < item.jumlah) {
          throw StateError(
            'Stok "${item.produk.nama}" tidak mencukupi. Tersisa $stok.',
          );
        }
      }

      idTransaksi = await transaksi.insert('transaksi', {
        'nomor': nomor,
        'tanggal': sekarang.toIso8601String(),
        'subtotal': subtotal,
        'diskon': diskon,
        'total': total,
        'metode_pembayaran': metodePembayaran,
        'nominal_dibayar': metodePembayaran == 'Tunai' ? nominalDibayar : total,
        'kembalian': kembalian,
      });

      for (final item in keranjang) {
        final stokSebelum =
            (await transaksi.query(
                  'produk',
                  columns: ['stok'],
                  where: 'id = ?',
                  whereArgs: [item.produk.id],
                  limit: 1,
                )).first['stok']
                as int;

        await transaksi.insert('detail_transaksi', {
          'transaksi_id': idTransaksi,
          'produk_id': item.produk.id,
          'nama_produk': item.produk.nama,
          'harga': item.produk.harga,
          'jumlah': item.jumlah,
          'total': item.total,
        });

        // Kurangi stok setelah transaksi berhasil disimpan.
        await transaksi.rawUpdate(
          'UPDATE produk SET stok = stok - ? WHERE id = ?',
          [item.jumlah, item.produk.id],
        );
        await transaksi.insert('stok_mutasi', {
          'produk_id': item.produk.id,
          'transaksi_id': idTransaksi,
          'tipe': 'penjualan',
          'jumlah': -item.jumlah,
          'stok_sebelum': stokSebelum,
          'stok_sesudah': stokSebelum - item.jumlah,
          'keterangan': 'Penjualan $nomor',
          'tanggal': sekarang.toIso8601String(),
        });
      }
    });

    keranjang.clear();
    diskon = 0;
    metodePembayaran = 'Tunai';
    nominalDibayar = 0;
    pesanValidasi = null;
    notifyListeners();

    return idTransaksi;
  }
}
