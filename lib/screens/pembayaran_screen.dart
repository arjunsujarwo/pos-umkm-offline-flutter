import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/kasir_provider.dart';
import '../providers/pengaturan_provider.dart';
import '../utils/format_rupiah.dart';
import 'qr_pembayaran_screen.dart';
import 'struk_screen.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  bool _sedangSimpan = false;
  final TextEditingController _nominalController = TextEditingController();

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _bayar() async {
    final kasir = context.read<KasirProvider>();
    final totalSebelumBayar = kasir.total;
    final nomor = await kasir.simpanTransaksi();

    if (!mounted || nomor == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StrukScreen(nomorTransaksi: nomor, total: totalSebelumBayar),
      ),
    );
  }

  Future<void> _prosesBayar() async {
    if (_sedangSimpan) return;
    setState(() => _sedangSimpan = true);
    try {
      await _bayar();
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi gagal disimpan. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangSimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kasir = context.watch<KasirProvider>();
    final pengaturanProvider = context.watch<PengaturanProvider>();
    final toko = pengaturanProvider.pengaturan;
    final rekeningBank = pengaturanProvider.rekeningBank;
    final adaGambarQris =
        toko.qrisGambar.isNotEmpty && File(toko.qrisGambar).existsSync();
    final adaQris = toko.qris.isNotEmpty || adaGambarQris;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              'Pilih metode pembayaran',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E7A4C), Color(0xFF2C9963)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total yang harus dibayar',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      rupiah(kasir.total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${kasir.keranjang.length} jenis produk • Diskon ${rupiah(kasir.diskon)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Metode Pembayaran',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _MetodePembayaran(
                terpilih: kasir.metodePembayaran == 'Tunai',
                ikon: Icons.payments_outlined,
                judul: 'Tunai',
                deskripsi: 'Bayar menggunakan uang tunai.',
                onTap: () =>
                    context.read<KasirProvider>().ubahMetodePembayaran('Tunai'),
              ),
              const SizedBox(height: 10),
              _MetodePembayaran(
                terpilih: kasir.metodePembayaran == 'QRIS',
                aktif: adaQris,
                ikon: Icons.qr_code_2,
                judul: 'QRIS / QR Code',
                deskripsi: !adaQris
                    ? 'Atur QRIS di Pengaturan Toko terlebih dahulu.'
                    : 'Tampilkan QR pembayaran toko.',
                onTap: !adaQris
                    ? null
                    : () => context.read<KasirProvider>().ubahMetodePembayaran(
                        'QRIS',
                      ),
                aksi: !adaQris
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QRPembayaranScreen(),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              _MetodePembayaran(
                terpilih: kasir.metodePembayaran == 'Transfer Bank',
                aktif: rekeningBank.isNotEmpty,
                ikon: Icons.account_balance_outlined,
                judul: 'Transfer Bank',
                deskripsi: rekeningBank.isEmpty
                    ? 'Atur rekening di Pengaturan Toko terlebih dahulu.'
                    : rekeningBank
                          .map(
                            (rekening) =>
                                '${rekening.namaBank} • ${rekening.nomorRekening}',
                          )
                          .join('\n'),
                onTap: rekeningBank.isEmpty
                    ? null
                    : () => context.read<KasirProvider>().ubahMetodePembayaran(
                        'Transfer Bank',
                      ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _BarisRingkas(
                        label: 'Subtotal',
                        nilai: rupiah(kasir.subtotal),
                      ),
                      const SizedBox(height: 8),
                      _BarisRingkas(
                        label: 'Diskon',
                        nilai: rupiah(kasir.diskon),
                      ),
                      const Divider(height: 24),
                      _BarisRingkas(
                        label: 'Total',
                        nilai: rupiah(kasir.total),
                        tebal: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (kasir.metodePembayaran == 'Tunai') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _nominalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal dibayar',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (nilai) {
                    final nominal =
                        int.tryParse(nilai.replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0;
                    context.read<KasirProvider>().ubahNominalDibayar(nominal);
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    kasir.kembalian < 0
                        ? 'Kurang: ${rupiah(kasir.kembalian.abs())}'
                        : 'Kembalian: ${rupiah(kasir.kembalian)}',
                    style: TextStyle(
                      color: kasir.kembalian < 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (kasir.pesanValidasi != null) ...[
                const SizedBox(height: 8),
                Text(
                  kasir.pesanValidasi!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: kasir.keranjang.isEmpty || _sedangSimpan
                      ? null
                      : _prosesBayar,
                  icon: _sedangSimpan
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _sedangSimpan ? 'Menyimpan...' : 'Selesaikan Transaksi',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetodePembayaran extends StatelessWidget {
  final bool terpilih;
  final bool aktif;
  final IconData ikon;
  final String judul;
  final String deskripsi;
  final VoidCallback? onTap;
  final VoidCallback? aksi;

  const _MetodePembayaran({
    required this.terpilih,
    this.aktif = true,
    required this.ikon,
    required this.judul,
    required this.deskripsi,
    required this.onTap,
    this.aksi,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: terpilih
            ? const Color(0xFF1E7A4C).withValues(alpha: .07)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: terpilih ? const Color(0xFF1E7A4C) : const Color(0xFFE1E7E3),
          width: terpilih ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        enabled: aktif,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (terpilih ? const Color(0xFF1E7A4C) : Colors.black12)
                .withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            ikon,
            color: terpilih ? const Color(0xFF1E7A4C) : Colors.black54,
          ),
        ),
        title: Text(judul, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(deskripsi, style: const TextStyle(fontSize: 12)),
        trailing: aksi != null
            ? IconButton.filledTonal(
                onPressed: aksi,
                icon: const Icon(Icons.visibility_outlined),
              )
            : Icon(
                terpilih ? Icons.radio_button_checked : Icons.radio_button_off,
                color: terpilih ? const Color(0xFF1E7A4C) : Colors.black26,
              ),
      ),
    );
  }
}

class _BarisRingkas extends StatelessWidget {
  final String label;
  final String nilai;
  final bool tebal;

  const _BarisRingkas({
    required this.label,
    required this.nilai,
    this.tebal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: tebal ? Colors.black87 : Colors.black54,
            fontWeight: tebal ? FontWeight.w800 : null,
          ),
        ),
        Text(
          nilai,
          style: TextStyle(
            fontWeight: tebal ? FontWeight.w900 : FontWeight.w600,
            fontSize: tebal ? 18 : null,
          ),
        ),
      ],
    );
  }
}
