import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../models/item_keranjang.dart';
import '../models/produk.dart';
import '../providers/pengaturan_provider.dart';
import '../services/layanan_cetak.dart';
import '../utils/format_rupiah.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<Map<String, dynamic>> transaksi = [];
  bool sedangMemuat = true;
  String kataKunci = '';

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final db = await DatabaseLokal.instance.database;
    final data = await db.query('transaksi', orderBy: 'tanggal DESC');
    if (!mounted) return;
    setState(() {
      transaksi = data;
      sedangMemuat = false;
    });
  }

  Future<void> _batalkan(Map<String, dynamic> data) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan transaksi?'),
        content: const Text(
          'Stok akan dikembalikan dan transaksi tidak dihitung sebagai omzet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (setuju != true || !mounted) return;

    final db = await DatabaseLokal.instance.database;
    await db.transaction((tx) async {
      final detail = await tx.query(
        'detail_transaksi',
        where: 'transaksi_id = ?',
        whereArgs: [data['id']],
      );
      await tx.update(
        'transaksi',
        {'status': 'dibatalkan'},
        where: 'id = ? AND status = ?',
        whereArgs: [data['id'], 'selesai'],
      );
      for (final item in detail) {
        final produkId = (item['produk_id'] as num).toInt();
        final jumlah = (item['jumlah'] as num).toInt();
        final sebelum =
            ((await tx.query(
                      'produk',
                      columns: ['stok'],
                      where: 'id = ?',
                      whereArgs: [produkId],
                      limit: 1,
                    )).first['stok']
                    as num)
                .toInt();
        await tx.rawUpdate('UPDATE produk SET stok = stok + ? WHERE id = ?', [
          jumlah,
          produkId,
        ]);
        await tx.insert('stok_mutasi', {
          'produk_id': produkId,
          'transaksi_id': data['id'],
          'tipe': 'pembatalan',
          'jumlah': jumlah,
          'stok_sebelum': sebelum,
          'stok_sesudah': sebelum + jumlah,
          'keterangan': 'Pembatalan ${data['nomor']}',
          'tanggal': DateTime.now().toIso8601String(),
        });
      }
    });
    await _muat();
  }

  Future<void> _lihatDetail(Map<String, dynamic> data) async {
    final db = await DatabaseLokal.instance.database;
    final detail = await db.query(
      'detail_transaksi',
      where: 'transaksi_id = ?',
      whereArgs: [data['id']],
      orderBy: 'id ASC',
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _DialogDetailTransaksi(
        transaksi: data,
        detail: detail,
        cetakUlang: () => _cetakUlang(data, detail),
      ),
    );
  }

  Future<void> _cetakUlang(
    Map<String, dynamic> transaksi,
    List<Map<String, dynamic>> detail,
  ) async {
    try {
      final toko = context.read<PengaturanProvider>().pengaturan;
      final item = detail
          .map(
            (data) => ItemKeranjang(
              produk: Produk(
                id: (data['produk_id'] as num?)?.toInt(),
                nama: data['nama_produk'] as String,
                harga: (data['harga'] as num).toInt(),
                stok: 0,
              ),
              jumlah: (data['jumlah'] as num).toInt(),
            ),
          )
          .toList();

      await LayananCetak.cetakStruk(
        toko: toko,
        nomorTransaksi: transaksi['nomor'] as String,
        tanggal: DateTime.parse(transaksi['tanggal'] as String),
        item: item,
        subtotal: (transaksi['subtotal'] as num).toInt(),
        diskon: (transaksi['diskon'] as num).toInt(),
        total: (transaksi['total'] as num).toInt(),
        metodePembayaran: transaksi['metode_pembayaran'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Struk berhasil dicetak ulang.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak ulang struk: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasil = transaksi.where((data) {
      final nomor = data['nomor'].toString().toLowerCase();
      final metode = data['metode_pembayaran'].toString().toLowerCase();
      final kata = kataKunci.toLowerCase();
      return nomor.contains(kata) || metode.contains(kata);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Transaksi',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Semua transaksi tersimpan di perangkat',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
      body: sedangMemuat
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _muat,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        onChanged: (nilai) => setState(() => kataKunci = nilai),
                        decoration: InputDecoration(
                          hintText: 'Cari nomor transaksi atau metode...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: kataKunci.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () =>
                                      setState(() => kataKunci = ''),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                  ),
                  if (hasil.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Belum ada transaksi.')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      sliver: SliverList.separated(
                        itemCount: hasil.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final data = hasil[index];
                          final tanggal = DateTime.parse(
                            data['tanggal'] as String,
                          );
                          final total = (data['total'] as num).toInt();
                          final metode = data['metode_pembayaran'].toString();
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _lihatDetail(data),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1E7A4C,
                                        ).withValues(alpha: .10),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long_outlined,
                                        color: Color(0xFF1E7A4C),
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['nomor'] as String,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy • HH:mm',
                                            ).format(tanggal),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black45,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: .05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                            child: Text(
                                              metode,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          rupiah(total),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        if ((data['status'] ?? 'selesai') !=
                                            'selesai')
                                          const Text(
                                            'DIBATALKAN',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if ((data['status'] ?? 'selesai') ==
                                        'selesai')
                                      PopupMenuButton<String>(
                                        onSelected: (_) => _batalkan(data),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'batalkan',
                                            child: Text('Batalkan transaksi'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _DialogDetailTransaksi extends StatelessWidget {
  final Map<String, dynamic> transaksi;
  final List<Map<String, dynamic>> detail;
  final VoidCallback cetakUlang;

  const _DialogDetailTransaksi({
    required this.transaksi,
    required this.detail,
    required this.cetakUlang,
  });

  @override
  Widget build(BuildContext context) {
    final tanggal = DateTime.parse(transaksi['tanggal'] as String);
    final status = transaksi['status']?.toString() ?? 'selesai';
    return AlertDialog(
      title: const Text('Detail Transaksi'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailBaris(
                label: 'Nomor',
                nilai: transaksi['nomor'].toString(),
              ),
              _DetailBaris(
                label: 'Tanggal',
                nilai: DateFormat('dd MMM yyyy, HH:mm').format(tanggal),
              ),
              _DetailBaris(
                label: 'Pembayaran',
                nilai: transaksi['metode_pembayaran'].toString(),
              ),
              _DetailBaris(label: 'Status', nilai: status),
              const Divider(height: 24),
              if (detail.isEmpty)
                const Text('Detail produk tidak ditemukan.')
              else
                ...detail.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item['jumlah']} x ${item['nama_produk']}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          rupiah((item['total'] as num).toInt()),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 18),
              _DetailBaris(
                label: 'Subtotal',
                nilai: rupiah((transaksi['subtotal'] as num).toInt()),
              ),
              _DetailBaris(
                label: 'Diskon',
                nilai: rupiah((transaksi['diskon'] as num).toInt()),
              ),
              _DetailBaris(
                label: 'Total',
                nilai: rupiah((transaksi['total'] as num).toInt()),
                tebal: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        FilledButton.icon(
          onPressed: detail.isEmpty
              ? null
              : () {
                  Navigator.pop(context);
                  cetakUlang();
                },
          icon: const Icon(Icons.print_outlined),
          label: const Text('Cetak Ulang'),
        ),
      ],
    );
  }
}

class _DetailBaris extends StatelessWidget {
  final String label;
  final String nilai;
  final bool tebal;

  const _DetailBaris({
    required this.label,
    required this.nilai,
    this.tebal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tebal ? null : Colors.black54,
              fontWeight: tebal ? FontWeight.w800 : null,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: tebal ? FontWeight.w900 : null),
            ),
          ),
        ],
      ),
    );
  }
}
