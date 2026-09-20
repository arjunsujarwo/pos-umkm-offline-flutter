import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../models/kategori.dart';
import '../models/produk.dart';

class ProdukProvider extends ChangeNotifier {
  List<Produk> daftarProduk = [];
  List<Kategori> daftarKategori = [];
  bool sedangMemuat = false;

  Future<void> muatSemua() async {
    sedangMemuat = true;
    notifyListeners();

    final db = await DatabaseLokal.instance.database;

    final dataProduk = await db.query(
      'produk',
      where: 'aktif = ?',
      whereArgs: [1],
      orderBy: 'nama ASC',
    );

    final dataKategori = await db.query(
      'kategori',
      orderBy: 'nama ASC',
    );

    daftarProduk = dataProduk.map(Produk.dariMap).toList();
    daftarKategori = dataKategori.map(Kategori.dariMap).toList();

    sedangMemuat = false;
    notifyListeners();
  }

  Future<void> tambahProduk(Produk produk) async {
    final db = await DatabaseLokal.instance.database;
    await db.insert('produk', produk.keMap());
    await muatSemua();
  }

  Future<void> ubahProduk(Produk produk) async {
    final db = await DatabaseLokal.instance.database;
    await db.update(
      'produk',
      produk.keMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
    await muatSemua();
  }

  Future<void> hapusProduk(int id) async {
    final db = await DatabaseLokal.instance.database;

    // Soft delete: produk tidak benar-benar dihapus agar histori transaksi aman.
    await db.update(
      'produk',
      {'aktif': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    await muatSemua();
  }

  Future<void> tambahKategori(String nama) async {
    final db = await DatabaseLokal.instance.database;
    await db.insert('kategori', {'nama': nama});
    await muatSemua();
  }

  Future<void> ubahKategori(int id, String nama) async {
    final db = await DatabaseLokal.instance.database;
    await db.update(
      'kategori',
      {'nama': nama},
      where: 'id = ?',
      whereArgs: [id],
    );
    await muatSemua();
  }

  Future<void> hapusKategori(int id) async {
    final db = await DatabaseLokal.instance.database;

    // Produk yang memakai kategori ini dibuat tanpa kategori.
    await db.update(
      'produk',
      {'kategori_id': null},
      where: 'kategori_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'kategori',
      where: 'id = ?',
      whereArgs: [id],
    );

    await muatSemua();
  }
}
