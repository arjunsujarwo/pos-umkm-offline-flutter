import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../providers/pengaturan_provider.dart';
import '../providers/produk_provider.dart';
import 'kategori_screen.dart';
import 'kasir_screen.dart';
import 'laporan_screen.dart';
import 'pengaturan_toko_screen.dart';
import 'produk_screen.dart';
import 'riwayat_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  int _menuAktif = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    await Future.wait([
      context.read<ProdukProvider>().muatSemua(),
      context.read<PengaturanProvider>().muatPengaturan(),
    ]);
  }

  Future<void> _buka(Widget halaman) async {
    if (!mounted) return;

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => halaman));

    if (!mounted) return;

    // Setelah halaman menu ditutup, konten yang terlihat kembali ke dashboard.
    // Sinkronkan indikator menu agar tidak tertinggal di menu sebelumnya.
    setState(() {
      _menuAktif = 0;
    });

    await _refreshData();
  }

  void _pilihMenu(int index) {
    setState(() {
      _menuAktif = index;
    });

    switch (index) {
      case 0:
        break;

      case 1:
        _buka(const KasirScreen());
        break;

      case 2:
        _buka(const ProdukScreen());
        break;

      case 3:
        _buka(const KategoriScreen());
        break;

      case 4:
        _buka(const RiwayatScreen());
        break;

      case 5:
        _buka(const PengaturanTokoScreen());
        break;

      case 6:
        _buka(const LaporanScreen());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final toko = context.watch<PengaturanProvider>().pengaturan;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool desktop = constraints.maxWidth >= 1000;

        if (desktop) {
          return Scaffold(
            backgroundColor: const Color(0xFFF6F8F7),
            body: Row(
              children: [
                _Sidebar(
                  namaToko: toko.namaToko,
                  logoToko: toko.logo,
                  aktif: _menuAktif,
                  onPilih: _pilihMenu,
                ),
                Expanded(
                  child: _IsiDashboard(
                    namaToko: toko.namaToko,
                    logoToko: toko.logo,
                    refresh: _refreshData,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F7),
          body: _IsiDashboard(
            namaToko: toko.namaToko,
            logoToko: toko.logo,
            refresh: _refreshData,
          ),
          bottomNavigationBar: _NavigasiBawah(
            aktif: _menuAktif,
            onPilih: _pilihMenu,
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String namaToko;
  final String logoToko;
  final int aktif;
  final ValueChanged<int> onPilih;

  const _Sidebar({
    required this.namaToko,
    required this.logoToko,
    required this.aktif,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 235,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE8ECEA), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 22),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _LogoToko(pathLogo: logoToko, ukuran: 46),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      namaToko.isEmpty ? 'Toko Saya' : namaToko,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF18221E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _MenuSidebar(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      aktif: aktif == 0,
                      onTap: () => onPilih(0),
                    ),
                    _MenuSidebar(
                      icon: Icons.point_of_sale_rounded,
                      label: 'Kasir',
                      aktif: aktif == 1,
                      onTap: () => onPilih(1),
                    ),
                    _MenuSidebar(
                      icon: Icons.inventory_2_rounded,
                      label: 'Produk',
                      aktif: aktif == 2,
                      onTap: () => onPilih(2),
                    ),
                    _MenuSidebar(
                      icon: Icons.category_rounded,
                      label: 'Kategori',
                      aktif: aktif == 3,
                      onTap: () => onPilih(3),
                    ),
                    _MenuSidebar(
                      icon: Icons.receipt_long_rounded,
                      label: 'Riwayat Transaksi',
                      aktif: aktif == 4,
                      onTap: () => onPilih(4),
                    ),
                    _MenuSidebar(
                      icon: Icons.description_rounded,
                      label: 'Laporan Excel',
                      aktif: aktif == 6,
                      onTap: () => onPilih(6),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFE8ECEA)),
                    const SizedBox(height: 12),
                    _MenuSidebar(
                      icon: Icons.settings_rounded,
                      label: 'Pengaturan Toko',
                      aktif: aktif == 5,
                      onTap: () => onPilih(5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSidebar extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  const _MenuSidebar({
    required this.icon,
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: aktif ? const Color(0xFFE7F4ED) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: aktif
                      ? const Color(0xFF1E7A4C)
                      : const Color(0xFF68736E),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: aktif ? FontWeight.w800 : FontWeight.w500,
                      color: aktif
                          ? const Color(0xFF1E7A4C)
                          : const Color(0xFF303936),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IsiDashboard extends StatefulWidget {
  final String namaToko;
  final String logoToko;
  final Future<void> Function() refresh;

  const _IsiDashboard({
    required this.namaToko,
    required this.logoToko,
    required this.refresh,
  });

  @override
  State<_IsiDashboard> createState() => _IsiDashboardState();
}

class _IsiDashboardState extends State<_IsiDashboard> {
  DashboardData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muatDashboard();
  }

  Future<void> _muatDashboard() async {
    try {
      final data = await DashboardData.load();

      if (!mounted) return;

      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _data = DashboardData.empty();
        _loading = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _loading = true;
    });

    await widget.refresh();
    await _muatDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: const Color(0xFF1E7A4C),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool tablet = constraints.maxWidth >= 650;

            final double horizontalPadding = constraints.maxWidth >= 1200
                ? 32
                : constraints.maxWidth >= 650
                ? 24
                : 16;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                tablet ? 24 : 18,
                horizontalPadding,
                30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderDashboard(
                        namaToko: widget.namaToko,
                        logoToko: widget.logoToko,
                        onRefresh: _refreshDashboard,
                        loading: _loading,
                      ),

                      const SizedBox(height: 22),

                      _loading && _data == null
                          ? const _DashboardLoading()
                          : _DashboardContent(
                              data: _data ?? DashboardData.empty(),
                              tablet: tablet,
                            ),
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
}

class _DashboardContent extends StatelessWidget {
  final DashboardData data;
  final bool tablet;

  const _DashboardContent({required this.data, required this.tablet});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatistikGrid(data: data),

        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 900;

            if (!wide) {
              return Column(
                children: [
                  _GrafikPenjualan(data: data),
                  const SizedBox(height: 20),
                  _ProdukTerlaris(data: data),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _GrafikPenjualan(data: data)),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: _ProdukTerlaris(data: data)),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 900;

            if (!wide) {
              return Column(children: [_TransaksiTerbaru(data: data)]);
            }

            return _TransaksiTerbaru(data: data);
          },
        ),

        const SizedBox(height: 20),

        _KartuLaporan(),
      ],
    );
  }
}

class _HeaderDashboard extends StatelessWidget {
  final String namaToko;
  final String logoToko;
  final VoidCallback onRefresh;
  final bool loading;

  const _HeaderDashboard({
    required this.namaToko,
    required this.logoToko,
    required this.onRefresh,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final String nama = namaToko.isEmpty ? 'Toko Saya' : namaToko;

    final String tanggal = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 600;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LogoToko(pathLogo: logoToko, ukuran: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF18221E),
                          ),
                        ),
                        Text(
                          nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF69746F),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: loading ? null : onRefresh,
                    icon: loading
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$tanggal • Selamat datang 👋',
                style: const TextStyle(color: Color(0xFF69746F), fontSize: 12),
              ),
            ],
          );
        }

        return Row(
          children: [
            _LogoToko(pathLogo: logoToko, ukuran: 56),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF18221E),
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$tanggal • Selamat datang di $nama 👋',
                    style: const TextStyle(
                      color: Color(0xFF69746F),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: loading ? null : onRefresh,
                borderRadius: BorderRadius.circular(13),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        loading ? Icons.sync_rounded : Icons.refresh_rounded,
                        size: 18,
                        color: const Color(0xFF1E7A4C),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LogoToko extends StatelessWidget {
  final String pathLogo;
  final double ukuran;

  const _LogoToko({required this.pathLogo, required this.ukuran});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: const Color(0xFF1E7A4C),
        borderRadius: BorderRadius.circular(ukuran * .28),
      ),
      clipBehavior: Clip.antiAlias,
      child: pathLogo.isNotEmpty
          ? Image.file(
              File(pathLogo),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: ukuran * .48,
                );
              },
            )
          : Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: ukuran * .48,
            ),
    );
  }
}

class _StatistikGrid extends StatelessWidget {
  final DashboardData data;

  const _StatistikGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int kolom = 4;

        if (constraints.maxWidth < 1050) {
          kolom = 2;
        }

        if (constraints.maxWidth < 560) {
          kolom = 1;
        }

        return GridView.builder(
          itemCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kolom,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: kolom == 1 ? 3.0 : 2.35,
          ),
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _KpiCard(
                  title: 'Penjualan Hari Ini',
                  value: _rupiah(data.penjualanHariIni),
                  subtitle: '${data.transaksiHariIni} transaksi',
                  icon: Icons.shopping_cart_rounded,
                  iconColor: const Color(0xFF1E7A4C),
                  background: const Color(0xFFEAF8F0),
                );

              case 1:
                return _KpiCard(
                  title: 'Produk Aktif',
                  value: '${data.jumlahProduk}',
                  subtitle: 'produk tersedia',
                  icon: Icons.inventory_2_rounded,
                  iconColor: const Color(0xFF2879E8),
                  background: const Color(0xFFEAF2FF),
                );

              case 2:
                return _KpiCard(
                  title: 'Kategori',
                  value: '${data.jumlahKategori}',
                  subtitle: 'kategori produk',
                  icon: Icons.sell_rounded,
                  iconColor: const Color(0xFF8056D9),
                  background: const Color(0xFFF2ECFF),
                );

              default:
                return _KpiCard(
                  title: 'Total Transaksi',
                  value: _formatAngka(data.totalTransaksi),
                  subtitle: 'seluruh waktu',
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFFE86F1E),
                  background: const Color(0xFFFFF0E7),
                );
            }
          },
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color background;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF69746F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18221E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF77817D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrafikPenjualan extends StatelessWidget {
  final DashboardData data;

  const _GrafikPenjualan({required this.data});

  @override
  Widget build(BuildContext context) {
    final double maksimum =
        data.penjualanHarian.fold<double>(
          0,
          (previous, item) => item.nilai > previous ? item.nilai : previous,
        ) *
        1.2;

    return _Panel(
      title: 'Penjualan 7 Hari Terakhir',
      icon: Icons.bar_chart_rounded,
      iconColor: const Color(0xFF1E7A4C),
      trailing: const _SmallBadge(text: '7 Hari'),
      child: SizedBox(
        height: 250,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, right: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ChartLabel(_formatChartRupiah(maksimum)),
                    _ChartLabel(_formatChartRupiah(maksimum / 2)),
                    const _ChartLabel('Rp 0'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        painter: _BarChartPainter(
                          data: data.penjualanHarian,
                          maximum: maksimum,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: data.penjualanHarian
                          .map(
                            (item) => Expanded(
                              child: Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF7A8580),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<DataPenjualanHarian> data;
  final double maximum;

  _BarChartPainter({required this.data, required this.maximum});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintGrid = Paint()
      ..color = const Color(0xFFE9EEEB)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final double y = size.height * i / 3;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final paintBar = Paint()..color = const Color(0xFF42B98B);

    final double slotWidth = size.width / data.length;

    final double barWidth = (slotWidth * .48).clamp(12.0, 55.0);

    for (int i = 0; i < data.length; i++) {
      final value = data[i].nilai;

      final double tinggi = maximum <= 0 ? 0 : (value / maximum) * size.height;

      final double left = (slotWidth * i) + ((slotWidth - barWidth) / 2);

      final double top = size.height - tinggi;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, tinggi.clamp(4, size.height)),
        const Radius.circular(7),
      );

      canvas.drawRRect(rect, paintBar);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maximum != maximum;
  }
}

class _ChartLabel extends StatelessWidget {
  final String text;

  const _ChartLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 8, color: Color(0xFF89938F)),
    );
  }
}

class _ProdukTerlaris extends StatelessWidget {
  final DashboardData data;

  const _ProdukTerlaris({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Produk Terlaris',
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFFF2A900),
      trailing: const Text(
        '7 Hari',
        style: TextStyle(
          color: Color(0xFF1E7A4C),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: data.produkTerlaris.isEmpty
          ? const _EmptyState(
              icon: Icons.inventory_2_outlined,
              text: 'Belum ada data penjualan.',
            )
          : Column(
              children: data.produkTerlaris
                  .asMap()
                  .entries
                  .map(
                    (entry) => _ProdukTerlarisItem(
                      nomor: entry.key + 1,
                      item: entry.value,
                      terakhir: entry.key == data.produkTerlaris.length - 1,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ProdukTerlarisItem extends StatelessWidget {
  final int nomor;
  final ProdukTerlarisData item;
  final bool terakhir;

  const _ProdukTerlarisItem({
    required this.nomor,
    required this.item,
    required this.terakhir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: terakhir
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEAEFED))),
      ),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: nomor == 1
                  ? const Color(0xFFFFE9A8)
                  : const Color(0xFFF0F2F1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$nomor',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: nomor == 1
                    ? const Color(0xFF9A7100)
                    : const Color(0xFF66716C),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F5F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 19,
              color: Color(0xFF89938F),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.jumlah} terjual',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7A8580),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _rupiah(item.total),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18221E),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransaksiTerbaru extends StatelessWidget {
  final DashboardData data;

  const _TransaksiTerbaru({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Transaksi Terbaru',
      icon: Icons.access_time_rounded,
      iconColor: const Color(0xFF1E7A4C),
      trailing: const Text(
        'Terbaru',
        style: TextStyle(
          color: Color(0xFF1E7A4C),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: data.transaksiTerbaru.isEmpty
          ? const _EmptyState(
              icon: Icons.receipt_long_outlined,
              text: 'Belum ada transaksi.',
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text('No.', style: _TableHeaderStyle.style),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Waktu', style: _TableHeaderStyle.style),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('Item', style: _TableHeaderStyle.style),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.right,
                          style: _TableHeaderStyle.style,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                ...data.transaksiTerbaru.map(
                  (item) => _TransaksiItem(item: item),
                ),
              ],
            ),
    );
  }
}

class _TableHeaderStyle {
  static const style = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: Color(0xFF68736E),
  );
}

class _TransaksiItem extends StatelessWidget {
  final TransaksiDashboardData item;

  const _TransaksiItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAEFED))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.nomor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.waktu,
              style: const TextStyle(fontSize: 10, color: Color(0xFF69746F)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${item.jumlahItem} item',
              style: const TextStyle(fontSize: 10, color: Color(0xFF69746F)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _rupiah(item.total),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuLaporan extends StatelessWidget {
  const _KartuLaporan();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.all(compact ? 16 : 19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEAF8F0), Color(0xFFF4FAF7)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD8EDE1)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LaporanHeader(),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LaporanScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.file_download_rounded, size: 18),
                        label: const Text('Buat Laporan Excel'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E7A4C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const _LaporanHeader(),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LaporanScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.file_download_rounded, size: 18),
                      label: const Text('Buat Laporan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E7A4C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _LaporanHeader extends StatelessWidget {
  const _LaporanHeader();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.table_view_rounded,
              color: Color(0xFF1E7A4C),
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan Bulanan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Export data penjualan ke Excel '
                  'untuk laporan dan analisis.',
                  style: TextStyle(
                    color: Color(0xFF68736E),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final Widget child;

  const _Panel({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF18221E),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;

  const _SmallBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Color(0xFF69746F),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: const Color(0xFFB3BCB8)),
            const SizedBox(height: 7),
            Text(
              text,
              style: const TextStyle(fontSize: 11, color: Color(0xFF7A8580)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 100),
        child: CircularProgressIndicator(color: Color(0xFF1E7A4C)),
      ),
    );
  }
}

class _NavigasiBawah extends StatelessWidget {
  final int aktif;
  final ValueChanged<int> onPilih;

  const _NavigasiBawah({required this.aktif, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = aktif < 0
        ? 0
        : aktif > 6
        ? 6
        : aktif;

    return NavigationBar(
      height: 66,
      selectedIndex: selectedIndex,
      onDestinationSelected: onPilih,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale_rounded),
          label: 'Kasir',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: 'Produk',
        ),
        NavigationDestination(
          icon: Icon(Icons.category_outlined),
          selectedIcon: Icon(Icons.category_rounded),
          label: 'Kategori',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description_rounded),
          label: 'Laporan',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Pengaturan',
        ),
      ],
    );
  }
}

class DashboardData {
  final int penjualanHariIni;
  final int transaksiHariIni;
  final int jumlahProduk;
  final int jumlahKategori;
  final int totalTransaksi;
  final List<DataPenjualanHarian> penjualanHarian;
  final List<ProdukTerlarisData> produkTerlaris;
  final List<TransaksiDashboardData> transaksiTerbaru;

  const DashboardData({
    required this.penjualanHariIni,
    required this.transaksiHariIni,
    required this.jumlahProduk,
    required this.jumlahKategori,
    required this.totalTransaksi,
    required this.penjualanHarian,
    required this.produkTerlaris,
    required this.transaksiTerbaru,
  });

  factory DashboardData.empty() {
    return const DashboardData(
      penjualanHariIni: 0,
      transaksiHariIni: 0,
      jumlahProduk: 0,
      jumlahKategori: 0,
      totalTransaksi: 0,
      penjualanHarian: [],
      produkTerlaris: [],
      transaksiTerbaru: [],
    );
  }

  static Future<DashboardData> load() async {
    final db = await DatabaseLokal.instance.database;

    final produkResult = await db.rawQuery('''
      SELECT COUNT(*) AS jumlah
      FROM produk
      WHERE aktif = 1
      ''');

    final kategoriResult = await db.rawQuery('''
      SELECT COUNT(*) AS jumlah
      FROM kategori
      ''');

    final transaksiCount = await db.rawQuery('''
      SELECT COUNT(*) AS jumlah
      FROM transaksi
      ''');

    final sekarang = DateTime.now();

    final awalHari = DateTime(sekarang.year, sekarang.month, sekarang.day);

    final akhirHari = awalHari.add(const Duration(days: 1));

    final transaksiHariIni = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(total), 0) AS total,
        COUNT(*) AS jumlah
      FROM transaksi
      WHERE tanggal >= ?
        AND tanggal < ?
      ''',
      [awalHari.toIso8601String(), akhirHari.toIso8601String()],
    );

    final penjualanHarian = <DataPenjualanHarian>[];

    for (int i = 6; i >= 0; i--) {
      final tanggal = DateTime(
        sekarang.year,
        sekarang.month,
        sekarang.day,
      ).subtract(Duration(days: i));

      final mulai = DateTime(tanggal.year, tanggal.month, tanggal.day);

      final selesai = mulai.add(const Duration(days: 1));

      final result = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(total), 0) AS total
        FROM transaksi
        WHERE tanggal >= ?
          AND tanggal < ?
        ''',
        [mulai.toIso8601String(), selesai.toIso8601String()],
      );

      final nilai = _toInt(result.first['total']);

      penjualanHarian.add(
        DataPenjualanHarian(
          label: DateFormat('dd/MM').format(tanggal),
          nilai: nilai.toDouble(),
        ),
      );
    }

    final tujuhHariLalu = DateTime(
      sekarang.year,
      sekarang.month,
      sekarang.day,
    ).subtract(const Duration(days: 6));

    final produkTerlarisResult = await db.rawQuery(
      '''
      SELECT
        nama_produk,
        SUM(jumlah) AS jumlah,
        SUM(total) AS total
      FROM detail_transaksi
      WHERE transaksi_id IN (
        SELECT id
        FROM transaksi
        WHERE tanggal >= ?
      )
      GROUP BY produk_id, nama_produk
      ORDER BY jumlah DESC
      LIMIT 5
      ''',
      [tujuhHariLalu.toIso8601String()],
    );

    final produkTerlaris = produkTerlarisResult.map((row) {
      return ProdukTerlarisData(
        nama: row['nama_produk']?.toString() ?? 'Produk',
        jumlah: _toInt(row['jumlah']),
        total: _toInt(row['total']),
      );
    }).toList();

    final transaksiResult = await db.rawQuery('''
      SELECT
        t.id,
        t.nomor,
        t.tanggal,
        t.total,
        COALESCE(
          SUM(dt.jumlah),
          0
        ) AS jumlah_item
      FROM transaksi t
      LEFT JOIN detail_transaksi dt
        ON dt.transaksi_id = t.id
      GROUP BY
        t.id,
        t.nomor,
        t.tanggal,
        t.total
      ORDER BY t.tanggal DESC
      LIMIT 6
      ''');

    final transaksiTerbaru = transaksiResult.map((row) {
      final tanggalString = row['tanggal']?.toString() ?? '';

      DateTime? tanggal;

      try {
        tanggal = DateTime.parse(tanggalString);
      } catch (_) {}

      return TransaksiDashboardData(
        nomor: row['nomor']?.toString() ?? '-',
        waktu: tanggal == null ? '-' : DateFormat('HH:mm').format(tanggal),
        jumlahItem: _toInt(row['jumlah_item']),
        total: _toInt(row['total']),
      );
    }).toList();

    return DashboardData(
      penjualanHariIni: _toInt(transaksiHariIni.first['total']),
      transaksiHariIni: _toInt(transaksiHariIni.first['jumlah']),
      jumlahProduk: _toInt(produkResult.first['jumlah']),
      jumlahKategori: _toInt(kategoriResult.first['jumlah']),
      totalTransaksi: _toInt(transaksiCount.first['jumlah']),
      penjualanHarian: penjualanHarian,
      produkTerlaris: produkTerlaris,
      transaksiTerbaru: transaksiTerbaru,
    );
  }
}

class DataPenjualanHarian {
  final String label;
  final double nilai;

  const DataPenjualanHarian({required this.label, required this.nilai});
}

class ProdukTerlarisData {
  final String nama;
  final int jumlah;
  final int total;

  const ProdukTerlarisData({
    required this.nama,
    required this.jumlah,
    required this.total,
  });
}

class TransaksiDashboardData {
  final String nomor;
  final String waktu;
  final int jumlahItem;
  final int total;

  const TransaksiDashboardData({
    required this.nomor,
    required this.waktu,
    required this.jumlahItem,
    required this.total,
  });
}

int _toInt(Object? value) {
  if (value == null) return 0;

  if (value is int) return value;

  if (value is double) {
    return value.round();
  }

  return int.tryParse(value.toString()) ?? 0;
}

String _rupiah(int nilai) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(nilai);
}

String _formatAngka(int nilai) {
  return NumberFormat('#,##0', 'id_ID').format(nilai);
}

String _formatChartRupiah(double nilai) {
  if (nilai >= 1000000) {
    return 'Rp ${(nilai / 1000000).toStringAsFixed(1)}jt';
  }

  if (nilai >= 1000) {
    return 'Rp ${(nilai / 1000).toStringAsFixed(0)}rb';
  }

  return 'Rp ${nilai.toStringAsFixed(0)}';
}
