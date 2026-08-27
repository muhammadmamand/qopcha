/// Iraqi mobile helpers for login / signup.
class PhoneUtils {
  PhoneUtils._();

  /// Normalize to local form `07xxxxxxxxx` when possible.
  static String normalize(String? raw) {
    var p = (raw ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (p.startsWith('+964')) {
      p = '0${p.substring(4)}';
    } else if (p.startsWith('964')) {
      p = '0${p.substring(3)}';
    }
    return p;
  }

  /// Accepts typical Iraqi mobiles: 07XXXXXXXXX (11 digits).
  static bool isValid(String? raw) {
    final p = normalize(raw);
    return RegExp(r'^07[0-9]{9}$').hasMatch(p);
  }

  static String? validate(String? raw, {bool english = false}) {
    final p = normalize(raw);
    if (p.isEmpty) {
      return english ? 'Enter your phone number' : 'ژمارەی مۆبایل بنووسە';
    }
    if (!isValid(p)) {
      return english
          ? 'Use a valid number like 07xxxxxxxxx'
          : 'ژمارەیەکی دروست بنووسە (07xxxxxxxxx)';
    }
    return null;
  }
}
