import 'package:intl/intl.dart';

String rupiah(int nilai) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(nilai);
}
