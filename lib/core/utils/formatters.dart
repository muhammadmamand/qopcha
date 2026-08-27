import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat('#,###', 'en_US');

  static String price(double amount) => '${_currencyFormat.format(amount)} IQD';

  static String grouped(num amount) => _currencyFormat.format(amount);

  static double? parseAmount(String? raw) {
    final cleaned = (raw ?? '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('٬', '')
        .trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static String date(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  static String dateTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '${date(value)} • $h:$min';
  }
}

/// Formats IQD amounts with commas while typing: 15000 → 15,000
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = Formatters.grouped(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
