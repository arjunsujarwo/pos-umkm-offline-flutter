import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../services/layanan_laporan.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  late int _bulanTerpilih;
  late int _tahunTerpilih;

  bool _sedangExport = false;
  bool _localeSiap = false;

  String? _lokasiFile;

  @override
  void initState() {
    super.initState();

    final sekarang = DateTime.now();

    _bulanTerpilih = sekarang.month;
    _tahunTerpilih = sekarang.year;

    _inisialisasiLocale();
  }

  Future<void> _inisialisasiLocale() async {
    await initializeDateFormatting('id_ID');

    if (!mounted) {
      return;
    }

    setState(() {
      _localeSiap = true;
    });
  }

  List<int> get _daftarTahun {
    final tahunSekarang = DateTime.now().year;

    return List.generate(6, (index) => tahunSekarang - index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_localeSiap) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Bulanan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: EdgeInsets.all(desktop ? 28 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 24),
                      _buildFilterCard(theme),
                      const SizedBox(height: 20),
                      _buildInformasiCard(theme),
                      const SizedBox(height: 20),
                      _buildIsiLaporan(theme),
                      if (_lokasiFile != null) ...[
                        const SizedBox(height: 20),
                        _buildSuccessCard(theme),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.insert_chart_outlined_rounded,
            color: theme.colorScheme.primary,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan Penjualan',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Buat laporan penjualan bulanan dan export ke Excel.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _buildFilterCard(ThemeData theme) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Pilih Periode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;

                if (compact) {
                  return Column(
                    children: [
                      _buildDropdownBulan(),
                      const SizedBox(height: 14),
                      _buildDropdownTahun(),
                      const SizedBox(height: 18),
                      _buildTombolExport(),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: _buildDropdownBulan()),
                    const SizedBox(width: 14),
                    Expanded(child: _buildDropdownTahun()),
                    const SizedBox(width: 14),
                    Expanded(child: _buildTombolExport()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN BULAN
  // ============================================================

  Widget _buildDropdownBulan() {
    return DropdownButtonFormField<int>(
      initialValue: _bulanTerpilih,
      decoration: InputDecoration(
        labelText: 'Bulan',
        prefixIcon: const Icon(Icons.calendar_month_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: List.generate(12, (index) {
        final bulan = index + 1;

        final namaBulan = DateFormat(
          'MMMM',
          'id_ID',
        ).format(DateTime(_tahunTerpilih, bulan));

        return DropdownMenuItem<int>(
          value: bulan,
          child: Text(_capitalize(namaBulan)),
        );
      }),
      onChanged: _sedangExport
          ? null
          : (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _bulanTerpilih = value;
                _lokasiFile = null;
              });
            },
    );
  }

  // ============================================================
  // DROPDOWN TAHUN
  // ============================================================

  Widget _buildDropdownTahun() {
    return DropdownButtonFormField<int>(
      initialValue: _tahunTerpilih,
      decoration: InputDecoration(
        labelText: 'Tahun',
        prefixIcon: const Icon(Icons.event_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: _daftarTahun.map((tahun) {
        return DropdownMenuItem<int>(
          value: tahun,
          child: Text(tahun.toString()),
        );
      }).toList(),
      onChanged: _sedangExport
          ? null
          : (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _tahunTerpilih = value;
                _lokasiFile = null;
              });
            },
    );
  }

  // ============================================================
  // TOMBOL EXPORT
  // ============================================================

  Widget _buildTombolExport() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _sedangExport ? null : _exportExcel,
        icon: _sedangExport
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.file_download_outlined),
        label: Text(_sedangExport ? 'Membuat Excel...' : 'Export Excel'),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMASI
  // ============================================================

  Widget _buildInformasiCard(ThemeData theme) {
    final namaBulan = DateFormat(
      'MMMM',
      'id_ID',
    ).format(DateTime(_tahunTerpilih, _bulanTerpilih));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  const TextSpan(text: 'Data yang akan dibuat: '),
                  TextSpan(
                    text: '${_capitalize(namaBulan)} $_tahunTerpilih',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(
                    text:
                        '. Data diambil dari transaksi yang tersimpan di database lokal.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ISI EXCEL
  // ============================================================

  Widget _buildIsiLaporan(ThemeData theme) {
    final data = [
      const _LaporanItem(
        icon: Icons.summarize_outlined,
        title: 'Ringkasan',
        description:
            'Omzet, subtotal, diskon, transaksi, produk terjual, dan rata-rata transaksi.',
      ),
      const _LaporanItem(
        icon: Icons.receipt_long_outlined,
        title: 'Detail Transaksi',
        description:
            'Daftar detail seluruh item transaksi pada periode yang dipilih.',
      ),
      const _LaporanItem(
        icon: Icons.emoji_events_outlined,
        title: 'Produk Terlaris',
        description: 'Ranking produk berdasarkan jumlah unit yang terjual.',
      ),
      const _LaporanItem(
        icon: Icons.bar_chart_rounded,
        title: 'Penjualan Harian',
        description:
            'Rekap jumlah transaksi, produk terjual, dan omzet per hari.',
      ),
      const _LaporanItem(
        icon: Icons.payments_outlined,
        title: 'Metode Pembayaran',
        description: 'Rekap penjualan berdasarkan metode pembayaran.',
      ),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Isi File Excel',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Satu file Excel akan berisi lima sheet laporan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(data.length, (index) {
              final item = data[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == data.length - 1 ? 0 : 12,
                ),
                child: _buildItemLaporan(theme, item),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemLaporan(ThemeData theme, _LaporanItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: theme.colorScheme.primary,
            size: 21,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Widget _buildSuccessCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Laporan berhasil dibuat',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'File Excel tersimpan di:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            _lokasiFile ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (Platform.isWindows) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _bukaFolder,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Buka Folder Laporan'),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EXPORT EXCEL
  // ============================================================

  Future<void> _exportExcel() async {
    if (_sedangExport) {
      return;
    }

    setState(() {
      _sedangExport = true;
      _lokasiFile = null;
    });

    try {
      final lokasi = await LayananLaporan.instance.exportLaporanBulanan(
        bulan: _bulanTerpilih,
        tahun: _tahunTerpilih,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lokasiFile = lokasi;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan Excel berhasil dibuat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat laporan Excel:\n$e'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _sedangExport = false;
      });
    }
  }

  // ============================================================
  // BUKA FOLDER
  // ============================================================

  Future<void> _bukaFolder() async {
    if (_lokasiFile == null) {
      return;
    }

    if (!Platform.isWindows) {
      return;
    }

    try {
      final file = File(_lokasiFile!);

      if (!await file.exists()) {
        throw Exception('File laporan tidak ditemukan.');
      }

      await Process.run('explorer.exe', ['/select,', file.path]);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka folder: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // HELPER
  // ============================================================

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

// ============================================================
// MODEL ITEM LAPORAN
// ============================================================

class _LaporanItem {
  final IconData icon;
  final String title;
  final String description;

  const _LaporanItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
