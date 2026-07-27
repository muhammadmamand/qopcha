import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat('#,###');

  static String price(double amount) => '${_currencyFormat.format(amount)} IQD';

  static String date(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }
}
