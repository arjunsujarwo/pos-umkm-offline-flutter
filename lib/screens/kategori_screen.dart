import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/produk_provider.dart';

class KategoriScreen extends StatefulWidget {
  const KategoriScreen({super.key});

  @override
  State<KategoriScreen> createState() => _KategoriScreenState();
}

class _KategoriScreenState extends State<KategoriScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdukProvider>().muatSemua();
    });
  }

  Future<void> _formKategori({int? id, String? namaAwal}) async {
    final provider = context.read<ProdukProvider>();
    final controller = TextEditingController(text: namaAwal ?? '');

    final nama = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(id == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            hintText: 'Contoh: Minuman',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );

    controller.dispose();
    if (nama == null || nama.isEmpty || !mounted) return;

    if (id == null) {
      await provider.tambahKategori(nama);
    } else {
      await provider.ubahKategori(id, nama);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProdukProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('Kelompokkan produk agar lebih rapi', style: TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _formKategori,
        icon: const Icon(Icons.add),
        label: const Text('Kategori Baru'),
      ),
      body: provider.daftarKategori.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 54, color: Colors.black26),
                  SizedBox(height: 10),
                  Text('Belum ada kategori.'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
              itemCount: provider.daftarKategori.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final kategori = provider.daftarKategori[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE68A00).withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.category_outlined, color: Color(0xFFE68A00)),
                    ),
                    title: Text(kategori.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Kategori produk', style: TextStyle(fontSize: 12)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (nilai) async {
                        if (nilai == 'ubah') {
                          await _formKategori(id: kategori.id, namaAwal: kategori.nama);
                        } else {
                          await provider.hapusKategori(kategori.id!);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'ubah', child: Text('Ubah')),
                        PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
