import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/produk.dart';
import '../providers/produk_provider.dart';
import '../utils/format_rupiah.dart';
import 'form_produk_screen.dart';
import 'kategori_screen.dart';

class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  String _kataKunci = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ProdukProvider>().muatSemua();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProdukProvider>();

    final daftar = provider.daftarProduk.where((produk) {
      return produk.nama.toLowerCase().contains(_kataKunci.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produk', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              'Kelola katalog dan stok',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Kategori',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KategoriScreen()),
              );
            },
            icon: const Icon(Icons.category_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Produk Baru'),
      ),
      body: provider.sedangMemuat
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.muatSemua,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        onChanged: (nilai) {
                          setState(() {
                            _kataKunci = nilai;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari produk...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _kataKunci.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _kataKunci = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          const Text(
                            'Daftar Produk',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${daftar.length} produk',
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  if (daftar.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 52,
                              color: Colors.black26,
                            ),
                            SizedBox(height: 10),
                            Text('Belum ada produk.'),
                            SizedBox(height: 4),
                            Text(
                              'Tekan Produk Baru untuk menambahkan.',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final produk = daftar[index];

                          return _KartuProduk(
                            produk: produk,
                            onEdit: () => _bukaForm(produk: produk),
                            onDelete: () {
                              if (produk.id != null) {
                                _hapus(produk.id!);
                              }
                            },
                          );
                        }, childCount: daftar.length),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 360,
                              mainAxisExtent: 230,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _bukaForm({Produk? produk}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormProdukScreen(produk: produk)),
    );

    if (!mounted) return;

    await context.read<ProdukProvider>().muatSemua();
  }

  Future<void> _hapus(int id) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus produk?'),
          content: const Text(
            'Produk akan disembunyikan dari daftar kasir. '
            'Histori transaksi tetap aman.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (!mounted || setuju != true) return;

    await context.read<ProdukProvider>().hapusProduk(id);
  }
}

class _KartuProduk extends StatelessWidget {
  final Produk produk;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KartuProduk({
    required this.produk,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final stokRendah = produk.stok <= 5;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _FotoProduk(path: produk.foto, width: 92, height: double.infinity),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    produk.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rupiah(produk.harga),
                    style: const TextStyle(
                      color: Color(0xFF1E7A4C),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (stokRendah ? Colors.orange : const Color(0xFF1E7A4C))
                              .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Stok ${produk.stok}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: stokRendah
                            ? Colors.orange.shade800
                            : const Color(0xFF1E7A4C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (nilai) {
                if (nilai == 'ubah') {
                  onEdit();
                }

                if (nilai == 'hapus') {
                  onDelete();
                }
              },
              itemBuilder: (_) {
                return const [
                  PopupMenuItem(value: 'ubah', child: Text('Ubah')),
                  PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FotoProduk extends StatelessWidget {
  final String? path;
  final double width;
  final double height;

  const _FotoProduk({
    required this.path,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final adaFoto =
        path != null && path!.trim().isNotEmpty && File(path!).existsSync();

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: adaFoto
          ? Image.file(
              File(path!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _placeholder();
              },
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 34,
        color: Color(0xFF1E7A4C),
      ),
    );
  }
}
