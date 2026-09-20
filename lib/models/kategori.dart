class Kategori {
  final int? id;
  final String nama;

  Kategori({
    this.id,
    required this.nama,
  });

  factory Kategori.dariMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'] as int?,
      nama: map['nama'] as String,
    );
  }

  Map<String, dynamic> keMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
    };
  }
}
