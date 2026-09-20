class RekeningBank {
  final int? id;
  final String namaBank;
  final String nomorRekening;
  final String namaRekening;

  const RekeningBank({
    this.id,
    required this.namaBank,
    required this.nomorRekening,
    required this.namaRekening,
  });

  Map<String, dynamic> keMap() => {
    if (id != null) 'id': id,
    'nama_bank': namaBank,
    'nomor_rekening': nomorRekening,
    'nama_rekening': namaRekening,
  };

  factory RekeningBank.dariMap(Map<String, dynamic> map) => RekeningBank(
    id: (map['id'] as num?)?.toInt(),
    namaBank: map['nama_bank'] as String? ?? '',
    nomorRekening: map['nomor_rekening'] as String? ?? '',
    namaRekening: map['nama_rekening'] as String? ?? '',
  );
}
