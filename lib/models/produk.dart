class Produk {
  final int? id;
  final String nama;
  final int harga;
  final int stok;
  final int? kategoriId;
  final String? foto;
  final bool aktif;

  Produk({
    this.id,
    required this.nama,
    required this.harga,
    required this.stok,
    this.kategoriId,
    this.foto,
    this.aktif = true,
  });

  factory Produk.dariMap(Map<String, dynamic> map) {
    return Produk(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      harga: (map['harga'] as num).toInt(),
      stok: (map['stok'] as num).toInt(),
      kategoriId: map['kategori_id'] as int?,
      foto: map['foto'] as String?,
      aktif: (map['aktif'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> keMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'harga': harga,
      'stok': stok,
      'kategori_id': kategoriId,
      'foto': foto,
      'aktif': aktif ? 1 : 0,
    };
  }
}
