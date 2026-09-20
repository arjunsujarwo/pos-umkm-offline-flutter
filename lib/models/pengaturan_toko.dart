class PengaturanToko {
  final String namaToko;
  final String alamat;
  final String telepon;
  final String logo;
  final String qris;
  final String qrisGambar;
  final String namaBank;
  final String nomorRekening;
  final String namaRekening;
  final String pesanStruk;
  final String printerUrl;
  final String printerNama;

  const PengaturanToko({
    required this.namaToko,
    required this.alamat,
    required this.telepon,
    required this.logo,
    required this.qris,
    this.qrisGambar = '',
    required this.namaBank,
    required this.nomorRekening,
    required this.namaRekening,
    required this.pesanStruk,
    this.printerUrl = '',
    this.printerNama = '',
  });

  factory PengaturanToko.kosong() {
    return const PengaturanToko(
      namaToko: 'Toko Saya',
      alamat: '',
      telepon: '',
      logo: '',
      qris: '',
      qrisGambar: '',
      namaBank: '',
      nomorRekening: '',
      namaRekening: '',
      pesanStruk: 'Terima kasih sudah berbelanja.',
      printerUrl: '',
      printerNama: '',
    );
  }

  Map<String, dynamic> keMap() {
    return {
      'id': 1,
      'nama_toko': namaToko,
      'alamat': alamat,
      'telepon': telepon,
      'logo': logo,
      'qris': qris,
      'qris_gambar': qrisGambar,
      'nama_bank': namaBank,
      'nomor_rekening': nomorRekening,
      'nama_rekening': namaRekening,
      'pesan_struk': pesanStruk,
      'printer_url': printerUrl,
      'printer_nama': printerNama,
    };
  }

  factory PengaturanToko.dariMap(Map<String, dynamic> map) {
    return PengaturanToko(
      namaToko: map['nama_toko'] ?? 'Toko Saya',
      alamat: map['alamat'] ?? '',
      telepon: map['telepon'] ?? '',
      logo: map['logo'] ?? '',
      qris: map['qris'] ?? '',
      qrisGambar: map['qris_gambar'] ?? '',
      namaBank: map['nama_bank'] ?? '',
      nomorRekening: map['nomor_rekening'] ?? '',
      namaRekening: map['nama_rekening'] ?? '',
      pesanStruk: map['pesan_struk'] ?? '',
      printerUrl: map['printer_url'] ?? '',
      printerNama: map['printer_nama'] ?? '',
    );
  }
}
