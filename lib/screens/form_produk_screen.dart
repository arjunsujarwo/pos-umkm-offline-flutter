import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/produk.dart';
import '../providers/produk_provider.dart';

class FormProdukScreen extends StatefulWidget {
  final Produk? produk;

  const FormProdukScreen({super.key, this.produk});

  @override
  State<FormProdukScreen> createState() => _FormProdukScreenState();
}

class _FormProdukScreenState extends State<FormProdukScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nama;
  late final TextEditingController _harga;
  late final TextEditingController _stok;

  int? _kategoriId;

  String? _fotoPath;
  bool _hapusFoto = false;
  bool _sedangMemilihFoto = false;
  bool _sedangMenyimpan = false;

  @override
  void initState() {
    super.initState();

    _nama = TextEditingController(text: widget.produk?.nama ?? '');

    _harga = TextEditingController(text: widget.produk?.harga.toString() ?? '');

    _stok = TextEditingController(text: widget.produk?.stok.toString() ?? '');

    _kategoriId = widget.produk?.kategoriId;
    _fotoPath = widget.produk?.foto;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ProdukProvider>().muatSemua();
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _harga.dispose();
    _stok.dispose();
    super.dispose();
  }

  // ============================================================
  // PILIH FOTO
  // ============================================================

  Future<void> _pilihFoto() async {
    if (_sedangMemilihFoto) return;

    setState(() {
      _sedangMemilihFoto = true;
    });

    try {
      final file = await FilePicker.pickFile(type: FileType.image);

      if (!mounted) return;

      if (file == null) {
        setState(() {
          _sedangMemilihFoto = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        _tampilkanPesan('File gambar tidak dapat dibaca.', error: true);

        setState(() {
          _sedangMemilihFoto = false;
        });

        return;
      }

      if (bytes.length > 5 * 1024 * 1024) {
        _tampilkanPesan('Ukuran gambar maksimal 5 MB.', error: true);

        setState(() {
          _sedangMemilihFoto = false;
        });

        return;
      }

      final folderAplikasi = await getApplicationDocumentsDirectory();

      final folderFoto = Directory(
        '${folderAplikasi.path}${Platform.pathSeparator}produk',
      );

      if (!await folderFoto.exists()) {
        await folderFoto.create(recursive: true);
      }

      String ekstensi = '.jpg';

      final namaAsli = file.name;
      final titikTerakhir = namaAsli.lastIndexOf('.');

      if (titikTerakhir != -1) {
        final ext = namaAsli.substring(titikTerakhir).toLowerCase();

        const daftarEkstensi = [
          '.jpg',
          '.jpeg',
          '.png',
          '.webp',
          '.gif',
          '.bmp',
        ];

        if (daftarEkstensi.contains(ext)) {
          ekstensi = ext;
        }
      }

      final namaFile =
          'produk_${DateTime.now().millisecondsSinceEpoch}$ekstensi';

      final lokasiBaru = '${folderFoto.path}${Platform.pathSeparator}$namaFile';

      final fileBaru = File(lokasiBaru);

      await fileBaru.writeAsBytes(bytes);

      if (!mounted) return;

      setState(() {
        _fotoPath = lokasiBaru;
        _hapusFoto = false;
        _sedangMemilihFoto = false;
      });

      _tampilkanPesan('Foto produk berhasil dipilih.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sedangMemilihFoto = false;
      });

      _tampilkanPesan('Gagal memilih foto: $e', error: true);
    }
  }

  // ============================================================
  // HAPUS FOTO
  // ============================================================

  Future<void> _hapusFotoProduk() async {
    final foto = _fotoPath;

    setState(() {
      _fotoPath = null;
      _hapusFoto = true;
    });

    if (foto != null && foto.isNotEmpty) {
      _tampilkanPesan('Foto akan dihapus saat produk disimpan.');
    }
  }

  // ============================================================
  // SIMPAN
  // ============================================================

  Future<void> _simpan() async {
    if (_sedangMenyimpan) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ProdukProvider>();

    setState(() {
      _sedangMenyimpan = true;
    });

    try {
      String? fotoUntukDatabase;

      if (_hapusFoto) {
        fotoUntukDatabase = null;
      } else {
        fotoUntukDatabase = _fotoPath;
      }

      final produk = Produk(
        id: widget.produk?.id,
        nama: _nama.text.trim(),
        harga: int.parse(_harga.text),
        stok: int.parse(_stok.text),
        kategoriId: _kategoriId,
        foto: fotoUntukDatabase,
        aktif: widget.produk?.aktif ?? true,
      );

      if (widget.produk == null) {
        await provider.tambahProduk(produk);
      } else {
        await provider.ubahProduk(produk);

        if (_hapusFoto) {
          await _hapusFileFoto(widget.produk?.foto);
        } else if (_fotoPath != null && _fotoPath != widget.produk?.foto) {
          await _hapusFileFoto(widget.produk?.foto);
        }
      }

      if (!mounted) return;

      _tampilkanPesan(
        widget.produk == null
            ? 'Produk berhasil ditambahkan.'
            : 'Produk berhasil diperbarui.',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sedangMenyimpan = false;
      });

      _tampilkanPesan('Gagal menyimpan produk: $e', error: true);
    }
  }

  // ============================================================
  // HAPUS FILE FOTO LAMA
  // ============================================================

  Future<void> _hapusFileFoto(String? path) async {
    if (path == null || path.isEmpty) return;

    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Jangan menggagalkan proses simpan hanya karena
      // file foto lama gagal dihapus.
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _tampilkanPesan(String pesan, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesan),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? Colors.red.shade700
              : const Color(0xFF1E7A4C),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProdukProvider>();
    final kategori = provider.daftarKategori;
    final edit = widget.produk != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          edit ? 'Edit Produk' : 'Produk Baru',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              children: [
                _buildFotoSection(),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E7A4C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Produk',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Isi data produk agar siap digunakan di kasir.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _nama,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    hintText: 'Contoh: Kopi Susu Gula Aren',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (nilai) {
                    if (nilai == null || nilai.trim().isEmpty) {
                      return 'Nama produk wajib diisi';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _harga,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual',
                          hintText: '15000',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (nilai) {
                          final angka = int.tryParse(nilai ?? '');

                          if (angka == null) {
                            return 'Masukkan harga berupa angka';
                          }

                          if (angka < 0) {
                            return 'Harga tidak boleh negatif';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stok,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok',
                          hintText: '20',
                          prefixIcon: Icon(Icons.warehouse_outlined),
                        ),
                        validator: (nilai) {
                          final angka = int.tryParse(nilai ?? '');

                          if (angka == null) {
                            return 'Masukkan stok berupa angka';
                          }

                          if (angka < 0) {
                            return 'Stok tidak boleh negatif';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<int?>(
                  initialValue: _kategoriId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tanpa kategori'),
                    ),
                    ...kategori.map(
                      (data) => DropdownMenuItem<int?>(
                        value: data.id,
                        child: Text(data.nama),
                      ),
                    ),
                  ],
                  onChanged: (nilai) {
                    setState(() {
                      _kategoriId = nilai;
                    });
                  },
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sedangMenyimpan ? null : _simpan,
                    icon: _sedangMenyimpan
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _sedangMenyimpan
                          ? 'Menyimpan...'
                          : edit
                          ? 'Simpan Perubahan'
                          : 'Simpan Produk',
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

  // ============================================================
  // FOTO SECTION
  // ============================================================

  Widget _buildFotoSection() {
    final adaFoto =
        _fotoPath != null &&
        _fotoPath!.isNotEmpty &&
        File(_fotoPath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_camera_outlined, color: Color(0xFF1E7A4C)),
              SizedBox(width: 10),
              Text(
                'Foto Produk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Gunakan foto produk agar katalog terlihat lebih menarik.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 230,
              color: const Color(0xFFF3F5F4),
              child: adaFoto
                  ? Image.file(
                      File(_fotoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildFotoKosong();
                      },
                    )
                  : _buildFotoKosong(),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sedangMemilihFoto ? null : _pilihFoto,
                  icon: _sedangMemilihFoto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          adaFoto
                              ? Icons.edit_outlined
                              : Icons.add_photo_alternate_outlined,
                        ),
                  label: Text(
                    _sedangMemilihFoto
                        ? 'Memilih...'
                        : adaFoto
                        ? 'Ganti Foto'
                        : 'Tambah Foto',
                  ),
                ),
              ),
              if (adaFoto) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Hapus Foto',
                  onPressed: _hapusFotoProduk,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOTO KOSONG
  // ============================================================

  Widget _buildFotoKosong() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 58, color: Colors.black26),
        SizedBox(height: 10),
        Text(
          'Belum ada foto produk',
          style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4),
        Text(
          'Klik Tambah Foto untuk memilih gambar',
          style: TextStyle(color: Colors.black38, fontSize: 12),
        ),
      ],
    );
  }
}
