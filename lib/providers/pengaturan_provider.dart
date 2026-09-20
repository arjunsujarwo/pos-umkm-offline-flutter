import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/pengaturan_toko.dart';
import '../models/rekening_bank.dart';

class PengaturanProvider extends ChangeNotifier {
  PengaturanToko pengaturan = PengaturanToko.kosong();
  List<RekeningBank> rekeningBank = [];

  Future<void> muatPengaturan() async {
    final db = await DatabaseLokal.instance.database;

    final hasil = await db.query(
      'pengaturan',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (hasil.isNotEmpty) {
      pengaturan = PengaturanToko.dariMap(hasil.first);
    }
    final rekening = await db.query('rekening_bank', orderBy: 'id ASC');
    rekeningBank = rekening.map(RekeningBank.dariMap).toList();
    notifyListeners();
  }

  Future<void> simpan(PengaturanToko data) async {
    final db = await DatabaseLokal.instance.database;

    await db.transaction((txn) async {
      await txn.insert(
        'pengaturan',
        data.keMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete('rekening_bank');
      for (final rekening in rekeningBank) {
        await txn.insert('rekening_bank', rekening.keMap());
      }
    });

    pengaturan = data;
    notifyListeners();
  }

  Future<void> simpanRekening(List<RekeningBank> rekening) async {
    final db = await DatabaseLokal.instance.database;
    await db.transaction((txn) async {
      await txn.delete('rekening_bank');
      for (final item in rekening) {
        await txn.insert('rekening_bank', item.keMap());
      }
    });
    rekeningBank = List.unmodifiable(rekening);
    notifyListeners();
  }
}
