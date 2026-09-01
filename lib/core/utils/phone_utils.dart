import '../../providers/settings_provider.dart';

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

  static String? validate(
    String? raw, {
    bool english = false,
    AppLanguage? language,
  }) {
    final lang = language ??
        (english ? AppLanguage.english : AppLanguage.kurdish);
    final p = normalize(raw);
    if (p.isEmpty) {
      return tr(lang, 'ژمارەی مۆبایل بنووسە', 'Enter your phone number',
          'أدخل رقم هاتفك');
    }
    if (!isValid(p)) {
      return tr(
        lang,
        'ژمارەیەکی دروست بنووسە (07xxxxxxxxx)',
        'Use a valid number like 07xxxxxxxxx',
        'استخدم رقماً صحيحاً مثل 07xxxxxxxxx',
      );
    }
    return null;
  }
}
