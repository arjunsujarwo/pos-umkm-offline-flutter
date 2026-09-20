import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';

class LayananCadangan {
  LayananCadangan._();

  static final LayananCadangan instance = LayananCadangan._();

  Future<String> buatCadangan() async {
    final sumber = File(await DatabaseLokal.instance.lokasiDatabase);
    if (!await sumber.exists()) {
      throw StateError('Database belum tersedia untuk dicadangkan.');
    }

    final dokumen = await getApplicationDocumentsDirectory();
    final folder = Directory(path.join(dokumen.path, 'Backup POS'));
    await folder.create(recursive: true);

    final nama =
        'pos_umkm_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db';
    final tujuan = File(path.join(folder.path, nama));
    await tujuan.writeAsBytes(await sumber.readAsBytes(), flush: true);
    return tujuan.path;
  }

  Future<String?> pilihDanPulihkan() async {
    final hasil = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['db'],
      dialogTitle: 'Pilih backup database POS',
    );
    if (hasil == null || hasil.path == null) return null;

    final sumber = File(hasil.path!);
    final database = DatabaseLokal.instance;
    await database.tutup();
    final tujuan = File(await database.lokasiDatabase);

    try {
      await tujuan.parent.create(recursive: true);
      await sumber.copy(tujuan.path);
    } catch (_) {
      await database.database;
      rethrow;
    }

    await database.database;
    return tujuan.path;
  }
}
