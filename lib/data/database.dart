import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseLokal {
  DatabaseLokal._();

  static final DatabaseLokal instance = DatabaseLokal._();

  Database? _database;
  bool _ffiSudahDiinisialisasi = false;

  Future<String> get lokasiDatabase async {
    final folder = await getApplicationDocumentsDirectory();
    return join(folder.path, 'pos_umkm.db');
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    return _database = await _bukaDatabase();
  }

  Future<void> inisialisasi() async {
    if (_ffiSudahDiinisialisasi) {
      return;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _ffiSudahDiinisialisasi = true;

    await database;
  }

  Future<Database> _bukaDatabase() async {
    if (!_ffiSudahDiinisialisasi &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      _ffiSudahDiinisialisasi = true;
    }

    final lokasi = await lokasiDatabase;

    return openDatabase(
      lokasi,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE kategori (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL UNIQUE
          )
        ''');

        await db.execute('''
          CREATE TABLE produk (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            harga INTEGER NOT NULL,
            stok INTEGER NOT NULL DEFAULT 0,
            kategori_id INTEGER,
            foto TEXT,
            aktif INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (kategori_id)
              REFERENCES kategori(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE transaksi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nomor TEXT NOT NULL UNIQUE,
            tanggal TEXT NOT NULL,
            subtotal INTEGER NOT NULL,
            diskon INTEGER NOT NULL DEFAULT 0,
            total INTEGER NOT NULL,
            metode_pembayaran TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'selesai',
            nominal_dibayar INTEGER NOT NULL DEFAULT 0,
            kembalian INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE detail_transaksi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaksi_id INTEGER NOT NULL,
            produk_id INTEGER NOT NULL,
            nama_produk TEXT NOT NULL,
            harga INTEGER NOT NULL,
            jumlah INTEGER NOT NULL,
            total INTEGER NOT NULL,
            FOREIGN KEY (transaksi_id)
              REFERENCES transaksi(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE pengaturan (
            id INTEGER PRIMARY KEY,
            nama_toko TEXT NOT NULL,
            alamat TEXT,
            telepon TEXT,
            logo TEXT,
            qris TEXT,
            qris_gambar TEXT,
            nama_bank TEXT,
            nomor_rekening TEXT,
            nama_rekening TEXT,
            pesan_struk TEXT,
            printer_url TEXT,
            printer_nama TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE rekening_bank (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama_bank TEXT NOT NULL,
            nomor_rekening TEXT NOT NULL,
            nama_rekening TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE stok_mutasi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            produk_id INTEGER NOT NULL,
            transaksi_id INTEGER,
            tipe TEXT NOT NULL,
            jumlah INTEGER NOT NULL,
            stok_sebelum INTEGER NOT NULL,
            stok_sesudah INTEGER NOT NULL,
            keterangan TEXT,
            tanggal TEXT NOT NULL,
            FOREIGN KEY (produk_id) REFERENCES produk(id),
            FOREIGN KEY (transaksi_id) REFERENCES transaksi(id)
          )
        ''');

        await db.insert('kategori', {'nama': 'Umum'});

        await db.insert('pengaturan', {
          'id': 1,
          'nama_toko': 'Toko Saya',
          'alamat': '',
          'telepon': '',
          'logo': '',
          'qris': '',
          'nama_bank': '',
          'nomor_rekening': '',
          'nama_rekening': '',
          'pesan_struk': 'Terima kasih sudah berbelanja.',
          'printer_url': '',
          'printer_nama': '',
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE transaksi ADD COLUMN status TEXT NOT NULL DEFAULT 'selesai'",
          );
          await db.execute(
            'ALTER TABLE transaksi ADD COLUMN nominal_dibayar INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE transaksi ADD COLUMN kembalian INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute('''
            CREATE TABLE stok_mutasi (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              produk_id INTEGER NOT NULL,
              transaksi_id INTEGER,
              tipe TEXT NOT NULL,
              jumlah INTEGER NOT NULL,
              stok_sebelum INTEGER NOT NULL,
              stok_sesudah INTEGER NOT NULL,
              keterangan TEXT,
              tanggal TEXT NOT NULL,
              FOREIGN KEY (produk_id) REFERENCES produk(id),
              FOREIGN KEY (transaksi_id) REFERENCES transaksi(id)
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE pengaturan ADD COLUMN printer_url TEXT',
          );
          await db.execute(
            'ALTER TABLE pengaturan ADD COLUMN printer_nama TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE rekening_bank (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nama_bank TEXT NOT NULL,
              nomor_rekening TEXT NOT NULL,
              nama_rekening TEXT NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO rekening_bank (nama_bank, nomor_rekening, nama_rekening)
            SELECT nama_bank, nomor_rekening, nama_rekening
            FROM pengaturan
            WHERE id = 1 AND TRIM(COALESCE(nomor_rekening, '')) <> ''
          ''');
        }
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE pengaturan ADD COLUMN qris_gambar TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );
  }

  Future<void> tutup() async {
    await _database?.close();
    _database = null;
  }
}
