import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../models/pengaturan_toko.dart';
import '../models/rekening_bank.dart';
import '../providers/pengaturan_provider.dart';
import '../services/layanan_cadangan.dart';
import '../widgets/komponen_pos.dart';

class PengaturanTokoScreen extends StatefulWidget {
  const PengaturanTokoScreen({super.key});

  @override
  State<PengaturanTokoScreen> createState() => _PengaturanTokoScreenState();
}

class _PengaturanTokoScreenState extends State<PengaturanTokoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController namaToko;
  late final TextEditingController alamat;
  late final TextEditingController telepon;
  late final TextEditingController qris;
  final List<_FormRekeningBank> rekeningBank = [];
  late final TextEditingController pesanStruk;

  String logo = '';
  String qrisGambar = '';
  bool sedangSimpan = false;
  bool sedangPilihLogo = false;
  bool sedangPilihQris = false;
  bool sedangCadangkan = false;
  String printerUrl = '';
  String printerNama = '';
  bool sedangMemuatPrinter = false;

  @override
  void initState() {
    super.initState();

    final data = context.read<PengaturanProvider>().pengaturan;

    namaToko = TextEditingController(text: data.namaToko);
    alamat = TextEditingController(text: data.alamat);
    telepon = TextEditingController(text: data.telepon);
    qris = TextEditingController(text: data.qris);
    final rekeningTersimpan = context.read<PengaturanProvider>().rekeningBank;
    if (rekeningTersimpan.isNotEmpty) {
      rekeningBank.addAll(rekeningTersimpan.map(_FormRekeningBank.fromModel));
    } else if (data.nomorRekening.isNotEmpty ||
        data.namaBank.isNotEmpty ||
        data.namaRekening.isNotEmpty) {
      rekeningBank.add(
        _FormRekeningBank(
          namaBank: data.namaBank,
          nomorRekening: data.nomorRekening,
          namaRekening: data.namaRekening,
        ),
      );
    }

    pesanStruk = TextEditingController(text: data.pesanStruk);

    logo = data.logo;
    qrisGambar = data.qrisGambar;
    printerUrl = data.printerUrl;
    printerNama = data.printerNama;
  }

  @override
  void dispose() {
    namaToko.dispose();
    alamat.dispose();
    telepon.dispose();
    qris.dispose();
    for (final rekening in rekeningBank) {
      rekening.dispose();
    }
    pesanStruk.dispose();

    super.dispose();
  }

  Future<void> _buatCadangan() async {
    setState(() => sedangCadangkan = true);
    try {
      final lokasi = await LayananCadangan.instance.buatCadangan();
      _tampilkanPesan('Backup berhasil disimpan di $lokasi.');
    } catch (error) {
      _tampilkanPesan('Backup gagal: $error', error: true);
    } finally {
      if (mounted) setState(() => sedangCadangkan = false);
    }
  }

  Future<void> _pulihkanCadangan() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pulihkan backup?'),
        content: const Text(
          'Data saat ini akan digantikan oleh data dari file backup. Lakukan backup terbaru sebelum melanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );
    if (setuju != true || !mounted) return;

    try {
      final lokasi = await LayananCadangan.instance.pilihDanPulihkan();
      if (lokasi != null && mounted) {
        _tampilkanPesan('Backup berhasil dipulihkan. Buka ulang aplikasi.');
      }
    } catch (error) {
      _tampilkanPesan('Restore gagal: $error', error: true);
    }
  }

  Future<void> _pilihPrinter() async {
    setState(() => sedangMemuatPrinter = true);
    try {
      final info = await Printing.info();
      if (!info.canListPrinters) {
        _tampilkanPesan(
          'Sistem ini tidak mendukung daftar printer otomatis.',
          error: true,
        );
        return;
      }
      final daftar = await Printing.listPrinters();
      final tersedia = daftar.where((printer) => printer.isAvailable).toList();
      if (!mounted) return;
      final terpilih = await showDialog<Printer>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Pilih Printer Struk'),
          children: tersedia.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Tidak ada printer yang tersedia.'),
                  ),
                ]
              : [
                  for (final printer in tersedia)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, printer),
                      child: Text(printer.name),
                    ),
                ],
        ),
      );
      if (terpilih != null && mounted) {
        setState(() {
          printerUrl = terpilih.url;
          printerNama = terpilih.name;
        });
        _tampilkanPesan(
          'Printer "${terpilih.name}" dipilih. Tekan Simpan Pengaturan.',
        );
      }
    } catch (error) {
      if (mounted) {
        _tampilkanPesan('Gagal memuat printer: $error', error: true);
      }
    } finally {
      if (mounted) setState(() => sedangMemuatPrinter = false);
    }
  }

  void _hapusPrinter() {
    setState(() {
      printerUrl = '';
      printerNama = '';
    });
    _tampilkanPesan('Pilihan printer dihapus. Tekan Simpan Pengaturan.');
  }

  Future<void> pilihGambarQris() async {
    if (sedangPilihQris) return;
    setState(() => sedangPilihQris = true);

    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (!mounted) return;
      if (file == null) {
        setState(() => sedangPilihQris = false);
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _tampilkanPesan('Gambar QR tidak dapat dibaca.', error: true);
        setState(() => sedangPilihQris = false);
        return;
      }
      if (bytes.length > 5 * 1024 * 1024) {
        _tampilkanPesan('Ukuran gambar QR maksimal 5 MB.', error: true);
        setState(() => sedangPilihQris = false);
        return;
      }

      final folderAplikasi = await getApplicationDocumentsDirectory();
      final folderQris = Directory(
        '${folderAplikasi.path}${Platform.pathSeparator}qris_toko',
      );
      if (!await folderQris.exists()) {
        await folderQris.create(recursive: true);
      }

      var ekstensi = '.png';
      final titikTerakhir = file.name.lastIndexOf('.');
      if (titikTerakhir != -1) {
        final ext = file.name.substring(titikTerakhir).toLowerCase();
        if (['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'].contains(ext)) {
          ekstensi = ext;
        }
      }
      final lokasiBaru =
          '${folderQris.path}${Platform.pathSeparator}qris_${DateTime.now().millisecondsSinceEpoch}$ekstensi';
      await File(lokasiBaru).writeAsBytes(bytes);

      if (!mounted) return;
      setState(() {
        qrisGambar = lokasiBaru;
        sedangPilihQris = false;
      });
      _tampilkanPesan('Gambar QR berhasil dipilih.');
    } catch (error) {
      if (!mounted) return;
      setState(() => sedangPilihQris = false);
      _tampilkanPesan('Gagal memilih gambar QR: $error', error: true);
    }
  }

  void hapusGambarQris() {
    setState(() => qrisGambar = '');
    _tampilkanPesan('Gambar QR dihapus. Tekan Simpan Pengaturan.');
  }

  // ============================================================
  // PILIH LOGO
  // ============================================================

  Future<void> pilihLogo() async {
    if (sedangPilihLogo) return;

    setState(() {
      sedangPilihLogo = true;
    });

    try {
      final file = await FilePicker.pickFile(type: FileType.image);

      if (!mounted) return;

      if (file == null) {
        setState(() {
          sedangPilihLogo = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        _tampilkanPesan('File logo tidak dapat dibaca.', error: true);

        setState(() {
          sedangPilihLogo = false;
        });

        return;
      }

      if (bytes.length > 5 * 1024 * 1024) {
        _tampilkanPesan('Ukuran logo maksimal 5 MB.', error: true);

        setState(() {
          sedangPilihLogo = false;
        });

        return;
      }

      final folderAplikasi = await getApplicationDocumentsDirectory();

      final folderLogo = Directory(
        '${folderAplikasi.path}${Platform.pathSeparator}logo_toko',
      );

      if (!await folderLogo.exists()) {
        await folderLogo.create(recursive: true);
      }

      String ekstensi = '.png';

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

      final namaFile = 'logo_${DateTime.now().millisecondsSinceEpoch}$ekstensi';

      final lokasiBaru = '${folderLogo.path}${Platform.pathSeparator}$namaFile';

      final fileBaru = File(lokasiBaru);

      await fileBaru.writeAsBytes(bytes);

      if (!mounted) return;

      setState(() {
        logo = lokasiBaru;
        sedangPilihLogo = false;
      });

      _tampilkanPesan('Logo toko berhasil dipilih.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sedangPilihLogo = false;
      });

      _tampilkanPesan('Gagal memilih logo: $e', error: true);
    }
  }

  // ============================================================
  // SIMPAN PENGATURAN
  // ============================================================

  Future<void> simpan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      sedangSimpan = true;
    });

    final rekeningTersimpan = <RekeningBank>[];
    for (final rekening in rekeningBank) {
      final namaBankValue = rekening.namaBank.text.trim();
      final nomorValue = rekening.nomorRekening.text.trim();
      final namaPemilikValue = rekening.namaRekening.text.trim();
      if (namaBankValue.isEmpty &&
          nomorValue.isEmpty &&
          namaPemilikValue.isEmpty) {
        continue;
      }
      if (namaBankValue.isEmpty ||
          nomorValue.isEmpty ||
          namaPemilikValue.isEmpty) {
        _tampilkanPesan(
          'Lengkapi semua data rekening atau hapus rekening kosong.',
          error: true,
        );
        setState(() => sedangSimpan = false);
        return;
      }
      rekeningTersimpan.add(
        RekeningBank(
          namaBank: namaBankValue,
          nomorRekening: nomorValue,
          namaRekening: namaPemilikValue,
        ),
      );
    }

    final rekeningPertama = rekeningTersimpan.isNotEmpty
        ? rekeningTersimpan.first
        : const RekeningBank(namaBank: '', nomorRekening: '', namaRekening: '');
    final data = PengaturanToko(
      namaToko: namaToko.text.trim(),
      alamat: alamat.text.trim(),
      telepon: telepon.text.trim(),
      logo: logo,
      qris: qris.text.trim(),
      qrisGambar: qrisGambar,
      namaBank: rekeningPertama.namaBank,
      nomorRekening: rekeningPertama.nomorRekening,
      namaRekening: rekeningPertama.namaRekening,
      pesanStruk: pesanStruk.text.trim(),
      printerUrl: printerUrl,
      printerNama: printerNama,
    );

    try {
      await context.read<PengaturanProvider>().simpan(data);
      await context.read<PengaturanProvider>().simpanRekening(
        rekeningTersimpan,
      );

      if (!mounted) return;

      setState(() {
        sedangSimpan = false;
      });

      _tampilkanPesan('Pengaturan toko berhasil disimpan.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sedangSimpan = false;
      });

      _tampilkanPesan('Gagal menyimpan pengaturan: $e', error: true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan Toko',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Identitas, pembayaran, dan struk',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                _KartuLogo(),

                const SizedBox(height: 18),

                const LabelBagian(judul: 'Identitas Toko'),

                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: namaToko,
                          decoration: const InputDecoration(
                            labelText: 'Nama Toko',
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
                          validator: (nilai) {
                            if (nilai == null || nilai.trim().isEmpty) {
                              return 'Nama toko wajib diisi';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: alamat,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Alamat',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: telepon,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const LabelBagian(judul: 'Pembayaran'),

                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: qris,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Data QRIS / QR Code',
                            hintText:
                                'Teks atau URL yang akan dibuat menjadi QR',
                            prefixIcon: Icon(Icons.qr_code_2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (qrisGambar.isNotEmpty &&
                            File(qrisGambar).existsSync())
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(qrisGambar),
                                height: 180,
                                width: 180,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: sedangPilihQris
                                  ? null
                                  : pilihGambarQris,
                              icon: sedangPilihQris
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.image_outlined),
                              label: Text(
                                sedangPilihQris
                                    ? 'Memilih...'
                                    : 'Pilih Gambar QR',
                              ),
                            ),
                            if (qrisGambar.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: hapusGambarQris,
                                child: const Text('Hapus Gambar'),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (rekeningBank.isEmpty)
                          const Text(
                            'Belum ada rekening bank. Tambahkan rekening untuk menerima transfer.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ...rekeningBank.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _EditorRekeningBank(
                              rekening: entry.value,
                              nomor: entry.key + 1,
                              onHapus: () => setState(() {
                                entry.value.dispose();
                                rekeningBank.removeAt(entry.key);
                              }),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(
                            () => rekeningBank.add(_FormRekeningBank()),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Rekening Bank'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const LabelBagian(judul: 'Struk'),

                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: pesanStruk,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Pesan di bagian bawah struk',
                        hintText: 'Terima kasih sudah berbelanja.',
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const LabelBagian(judul: 'Data dan Backup'),

                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Simpan salinan data secara berkala agar transaksi tidak hilang jika perangkat rusak atau berganti.',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: sedangCadangkan ? null : _buatCadangan,
                              icon: const Icon(Icons.backup_outlined),
                              label: const Text('Buat Backup'),
                            ),
                            OutlinedButton.icon(
                              onPressed: sedangCadangkan
                                  ? null
                                  : _pulihkanCadangan,
                              icon: const Icon(Icons.restore_outlined),
                              label: const Text('Restore Backup'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const LabelBagian(judul: 'Printer Struk'),

                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.print_outlined, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            printerNama.isEmpty
                                ? 'Belum ada printer dipilih'
                                : printerNama,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Pilih printer',
                          onPressed: sedangMemuatPrinter ? null : _pilihPrinter,
                          icon: sedangMemuatPrinter
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.settings_outlined),
                        ),
                        if (printerUrl.isNotEmpty)
                          IconButton(
                            tooltip: 'Hapus printer',
                            onPressed: _hapusPrinter,
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: sedangSimpan ? null : simpan,
                    icon: sedangSimpan
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      sedangSimpan ? 'Menyimpan...' : 'Simpan Pengaturan',
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
  // KARTU LOGO
  // ============================================================

  Widget _KartuLogo() {
    final adaLogo = logo.isNotEmpty && File(logo).existsSync();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, batas) {
            final sempit = batas.maxWidth < 500;

            final gambar = Container(
              width: 84,
              height: 84,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: adaLogo
                  ? Image.file(
                      File(logo),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.storefront_outlined,
                          size: 40,
                          color: Color(0xFF1E7A4C),
                        );
                      },
                    )
                  : const Icon(
                      Icons.storefront_outlined,
                      size: 40,
                      color: Color(0xFF1E7A4C),
                    ),
            );

            final teks = const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logo Toko',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Logo akan digunakan pada identitas toko dan struk.',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            );

            final tombol = OutlinedButton.icon(
              onPressed: sedangPilihLogo ? null : pilihLogo,
              icon: sedangPilihLogo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              label: Text(sedangPilihLogo ? 'Memilih...' : 'Pilih'),
            );

            if (sempit) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [gambar, const SizedBox(width: 14), teks]),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: tombol),
                ],
              );
            }

            return Row(
              children: [gambar, const SizedBox(width: 16), teks, tombol],
            );
          },
        ),
      ),
    );
  }
}

class _FormRekeningBank {
  final TextEditingController namaBank;
  final TextEditingController nomorRekening;
  final TextEditingController namaRekening;

  _FormRekeningBank({
    String namaBank = '',
    String nomorRekening = '',
    String namaRekening = '',
  }) : namaBank = TextEditingController(text: namaBank),
       nomorRekening = TextEditingController(text: nomorRekening),
       namaRekening = TextEditingController(text: namaRekening);

  factory _FormRekeningBank.fromModel(RekeningBank rekening) =>
      _FormRekeningBank(
        namaBank: rekening.namaBank,
        nomorRekening: rekening.nomorRekening,
        namaRekening: rekening.namaRekening,
      );

  void dispose() {
    namaBank.dispose();
    nomorRekening.dispose();
    namaRekening.dispose();
  }
}

class _EditorRekeningBank extends StatelessWidget {
  final _FormRekeningBank rekening;
  final int nomor;
  final VoidCallback onHapus;

  const _EditorRekeningBank({
    required this.rekening,
    required this.nomor,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: rekening.namaBank,
                decoration: InputDecoration(
                  labelText: 'Nama Bank $nomor',
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: rekening.nomorRekening,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nomor Rekening',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: rekening.namaRekening,
          decoration: const InputDecoration(
            labelText: 'Atas Nama',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        TextButton.icon(
          onPressed: onHapus,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus rekening'),
        ),
      ],
    );
  }
}
