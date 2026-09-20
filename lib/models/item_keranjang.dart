import 'produk.dart';

class ItemKeranjang {
  final Produk produk;
  int jumlah;

  ItemKeranjang({
    required this.produk,
    this.jumlah = 1,
  });

  int get total => produk.harga * jumlah;
}
