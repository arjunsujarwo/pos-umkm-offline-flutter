import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../models/item_keranjang.dart';
import '../models/pengaturan_toko.dart';
import '../models/produk.dart';
import '../providers/pengaturan_provider.dart';
import '../services/layanan_cetak.dart';
import '../utils/format_rupiah.dart';

class StrukScreen extends StatefulWidget {
  final int nomorTransaksi;
  final int total;

  const StrukScreen({
    super.key,
    required this.nomorTransaksi,
    required this.total,
  });

  @override
  State<StrukScreen> createState() => _StrukScreenState();
}

class _StrukScreenState extends State<StrukScreen> {
  Map<String, dynamic>? _transaksi;
  List<Map<String, dynamic>> _detail = [];
  bool _sedangCetak = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final db = await DatabaseLokal.instance.database;
    final transaksi = await db.query(
      'transaksi',
      where: 'id = ?',
      whereArgs: [widget.nomorTransaksi],
      limit: 1,
    );
    final detail = await db.query(
      'detail_transaksi',
      where: 'transaksi_id = ?',
      whereArgs: [widget.nomorTransaksi],
    );
    if (!mounted) return;
    setState(() {
      _transaksi = transaksi.isEmpty ? null : transaksi.first;
      _detail = detail;
    });
  }

  Future<void> _cetak() async {
    if (_transaksi == null || _sedangCetak) return;
    setState(() => _sedangCetak = true);

    try {
      final toko = context.read<PengaturanProvider>().pengaturan;
      final item = _detail.map((data) {
        final produk = Produk(
          id: data['produk_id'] as int?,
          nama: data['nama_produk'] as String,
          harga: (data['harga'] as num).toInt(),
          stok: 0,
        );
        return ItemKeranjang(
          produk: produk,
          jumlah: (data['jumlah'] as num).toInt(),
        );
      }).toList();

      await LayananCetak.cetakStruk(
        toko: toko,
        nomorTransaksi: _transaksi!['nomor'] as String,
        tanggal: DateTime.parse(_transaksi!['tanggal'] as String),
        item: item,
        subtotal: (_transaksi!['subtotal'] as num).toInt(),
        diskon: (_transaksi!['diskon'] as num).toInt(),
        total: (_transaksi!['total'] as num).toInt(),
        metodePembayaran: _transaksi!['metode_pembayaran'] as String,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mencetak struk: $error')));
      }
    } finally {
      if (mounted) setState(() => _sedangCetak = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toko = context.watch<PengaturanProvider>().pengaturan;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaksi Berhasil',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Struk pembayaran',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            onPressed: _transaksi == null ? null : _cetak,
            icon: const Icon(Icons.print_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _transaksi == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 62,
                  color: Color(0xFF1E7A4C),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pembayaran berhasil',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  rupiah((_transaksi!['total'] as num).toInt()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E7A4C),
                  ),
                ),
                const SizedBox(height: 18),
                _IsiStruk(toko: toko, transaksi: _transaksi!, detail: _detail),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Transaksi Baru'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _transaksi == null || _sedangCetak ? null : _cetak,
                icon: _sedangCetak
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print_outlined),
                label: Text(_sedangCetak ? 'Mencetak...' : 'Cetak Struk'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IsiStruk extends StatelessWidget {
  final PengaturanToko toko;
  final Map<String, dynamic> transaksi;
  final List<Map<String, dynamic>> detail;

  const _IsiStruk({
    required this.toko,
    required this.transaksi,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final adaLogo = toko.logo.isNotEmpty && File(toko.logo).existsSync();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: adaLogo
                  ? Image.file(File(toko.logo), fit: BoxFit.cover)
                  : const Icon(
                      Icons.storefront_outlined,
                      size: 34,
                      color: Color(0xFF1E7A4C),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              toko.namaToko,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            if (toko.alamat.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                toko.alamat,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (toko.telepon.isNotEmpty)
              Text(
                toko.telepon,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            const Divider(height: 28),
            _InfoTransaksi(
              nomor: transaksi['nomor'].toString(),
              metode: transaksi['metode_pembayaran'].toString(),
              tanggal: DateTime.parse(transaksi['tanggal'] as String),
            ),
            const Divider(height: 28),
            ...detail.map(
              (data) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nama_produk'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${data['jumlah']} x ${rupiah((data['harga'] as num).toInt())}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      rupiah((data['total'] as num).toInt()),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 28),
            _Baris(
              label: 'Subtotal',
              nilai: (transaksi['subtotal'] as num).toInt(),
            ),
            const SizedBox(height: 7),
            _Baris(
              label: 'Diskon',
              nilai: (transaksi['diskon'] as num).toInt(),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _Baris(
                label: 'TOTAL',
                nilai: (transaksi['total'] as num).toInt(),
                tebal: true,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              toko.pesanStruk,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTransaksi extends StatelessWidget {
  final String nomor;
  final String metode;
  final DateTime tanggal;

  const _InfoTransaksi({
    required this.nomor,
    required this.metode,
    required this.tanggal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoBaris(label: 'Nomor', nilai: nomor),
        const SizedBox(height: 5),
        _InfoBaris(
          label: 'Tanggal',
          nilai:
              '${tanggal.day.toString().padLeft(2, '0')}/${tanggal.month.toString().padLeft(2, '0')}/${tanggal.year}',
        ),
        const SizedBox(height: 5),
        _InfoBaris(label: 'Pembayaran', nilai: metode),
      ],
    );
  }
}

class _InfoBaris extends StatelessWidget {
  final String label;
  final String nilai;
  const _InfoBaris({required this.label, required this.nilai});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.black45, fontSize: 12)),
      Flexible(
        child: Text(
          nilai,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    ],
  );
}

class _Baris extends StatelessWidget {
  final String label;
  final int nilai;
  final bool tebal;
  const _Baris({required this.label, required this.nilai, this.tebal = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontWeight: tebal ? FontWeight.w900 : null)),
      Text(
        rupiah(nilai),
        style: TextStyle(
          fontWeight: tebal ? FontWeight.w900 : FontWeight.w600,
          fontSize: tebal ? 18 : null,
        ),
      ),
    ],
  );
}
