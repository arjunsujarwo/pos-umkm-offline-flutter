import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/produk.dart';
import '../providers/kasir_provider.dart';
import '../providers/produk_provider.dart';
import '../utils/format_rupiah.dart';
import 'pembayaran_screen.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
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
    final produk = context.watch<ProdukProvider>();
    final kasir = context.watch<KasirProvider>();

    final daftar = produk.daftarProduk.where((data) {
      final kata = _kataKunci.toLowerCase();

      return data.nama.toLowerCase().contains(kata);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kasir', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              'Buat transaksi baru',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Kosongkan keranjang',
            onPressed: kasir.keranjang.isEmpty ? null : _konfirmasiKosongkan,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, batas) {
          final desktop = batas.maxWidth >= 950;

          if (desktop) {
            return Row(
              children: [
                Expanded(
                  child: _PanelProduk(
                    daftar: daftar,
                    kataKunci: _kataKunci,
                    onCari: (nilai) {
                      setState(() {
                        _kataKunci = nilai;
                      });
                    },
                  ),
                ),
                SizedBox(width: 410, child: _PanelKeranjang(kasir: kasir)),
              ],
            );
          }

          return Column(
            children: [
              Expanded(
                child: _PanelProduk(
                  daftar: daftar,
                  kataKunci: _kataKunci,
                  onCari: (nilai) {
                    setState(() {
                      _kataKunci = nilai;
                    });
                  },
                ),
              ),
              _RingkasanBawah(kasir: kasir),
            ],
          );
        },
      ),
    );
  }

  Future<void> _konfirmasiKosongkan() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kosongkan keranjang?'),
          content: const Text(
            'Semua produk pada transaksi saat ini '
            'akan dihapus.',
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
              child: const Text('Kosongkan'),
            ),
          ],
        );
      },
    );

    if (!mounted || setuju != true) return;

    context.read<KasirProvider>().kosongkanKeranjang();
  }
}

class _PanelProduk extends StatelessWidget {
  final List<Produk> daftar;
  final String kataKunci;
  final ValueChanged<String> onCari;

  const _PanelProduk({
    required this.daftar,
    required this.kataKunci,
    required this.onCari,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: onCari,
            decoration: InputDecoration(
              hintText: 'Cari nama produk...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: kataKunci.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        onCari('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Daftar Produk',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${daftar.length} produk',
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: daftar.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 44, color: Colors.black26),
                        SizedBox(height: 8),
                        Text('Produk tidak ditemukan.'),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                    itemCount: daftar.length,
                    itemBuilder: (context, index) {
                      final data = daftar[index];

                      return _KartuProdukKasir(produk: data);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KartuProdukKasir extends StatelessWidget {
  final Produk produk;

  const _KartuProdukKasir({required this.produk});

  @override
  Widget build(BuildContext context) {
    final tersedia = produk.stok > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: tersedia
            ? () {
                context.read<KasirProvider>().tambahProduk(produk);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FotoProdukKasir(path: produk.foto, tersedia: tersedia),
              ),
              const SizedBox(height: 10),
              Text(
                produk.nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rupiah(produk.harga),
                      style: const TextStyle(
                        color: Color(0xFF1E7A4C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Stok ${produk.stok}',
                    style: TextStyle(
                      fontSize: 11,
                      color: tersedia ? Colors.black45 : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoProdukKasir extends StatelessWidget {
  final String? path;
  final bool tersedia;

  const _FotoProdukKasir({required this.path, required this.tersedia});

  @override
  Widget build(BuildContext context) {
    final adaFoto =
        path != null && path!.trim().isNotEmpty && File(path!).existsSync();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: adaFoto
          ? Opacity(
              opacity: tersedia ? 1 : 0.45,
              child: Image.file(
                File(path!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _placeholder();
                },
              ),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 42,
        color: tersedia ? const Color(0xFF1E7A4C) : Colors.black26,
      ),
    );
  }
}

class _PanelKeranjang extends StatelessWidget {
  final KasirProvider kasir;

  const _PanelKeranjang({required this.kasir});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8E4))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart_outlined),
                  SizedBox(width: 10),
                  Text(
                    'Keranjang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: kasir.keranjang.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 52,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 10),
                          Text('Keranjang masih kosong'),
                          SizedBox(height: 4),
                          Text(
                            'Pilih produk di sebelah kiri.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: kasir.keranjang.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 8);
                      },
                      itemBuilder: (context, index) {
                        final item = kasir.keranjang[index];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9F8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _FotoKeranjang(path: item.produk.foto),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.produk.nama,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      rupiah(item.produk.harga),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _KontrolJumlah(
                                jumlah: item.jumlah,
                                onKurang: () {
                                  context.read<KasirProvider>().kurangiJumlah(
                                    index,
                                  );
                                },
                                onTambah: () {
                                  context.read<KasirProvider>().tambahJumlah(
                                    index,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            _RingkasanPembayaran(kasir: kasir),
          ],
        ),
      ),
    );
  }
}

class _FotoKeranjang extends StatelessWidget {
  final String? path;

  const _FotoKeranjang({required this.path});

  @override
  Widget build(BuildContext context) {
    final adaFoto =
        path != null && path!.trim().isNotEmpty && File(path!).existsSync();

    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
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
    return const Icon(
      Icons.inventory_2_outlined,
      size: 20,
      color: Colors.black45,
    );
  }
}

class _KontrolJumlah extends StatelessWidget {
  final int jumlah;
  final VoidCallback onKurang;
  final VoidCallback onTambah;

  const _KontrolJumlah({
    required this.jumlah,
    required this.onKurang,
    required this.onTambah,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: onKurang,
          icon: const Icon(Icons.remove, size: 16),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$jumlah',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: onTambah,
          icon: const Icon(Icons.add, size: 16),
        ),
      ],
    );
  }
}

class _RingkasanPembayaran extends StatelessWidget {
  final KasirProvider kasir;

  const _RingkasanPembayaran({required this.kasir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8E4))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: Colors.black54)),
              Text(rupiah(kasir.subtotal)),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Diskon', style: TextStyle(color: Colors.black54)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(rupiah(kasir.diskon)),
                  IconButton(
                    tooltip: 'Atur diskon',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _tampilkanDialogDiskon(context, kasir),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                rupiah(kasir.total),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: kasir.keranjang.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PembayaranScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Lanjut Pembayaran'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingkasanBawah extends StatelessWidget {
  final KasirProvider kasir;

  const _RingkasanBawah({required this.kasir});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                    Text(
                      rupiah(kasir.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Atur diskon',
                onPressed: kasir.keranjang.isEmpty
                    ? null
                    : () => _tampilkanDialogDiskon(context, kasir),
                icon: const Icon(Icons.discount_outlined),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: kasir.keranjang.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PembayaranScreen(),
                          ),
                        );
                      },
                child: const Text('Bayar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _tampilkanDialogDiskon(
  BuildContext context,
  KasirProvider kasir,
) async {
  final controller = TextEditingController(
    text: kasir.diskon == 0 ? '' : kasir.diskon.toString(),
  );

  final nilai = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Atur Diskon'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Nominal diskon',
          hintText: 'Maksimal ${rupiah(kasir.subtotal)}',
          prefixText: 'Rp ',
        ),
        onSubmitted: (_) => Navigator.pop(
          context,
          int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), '')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: const Text('Hapus Diskon'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), '')),
          ),
          child: const Text('Terapkan'),
        ),
      ],
    ),
  );

  controller.dispose();

  if (nilai == null) return;
  kasir.ubahDiskon(nilai);
}
