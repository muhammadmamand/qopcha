/// Admin access policy (client-side checks + allowlist).
/// Server role `admin` is the real authorization gate.
class AdminSecurity {
  AdminSecurity._();

  /// Contabo seed phone (see VPS `ADMIN_PHONE`).
  static const primaryPhone = '07503727574';

  /// Only these phones may use the admin console.
  static const allowedPhones = <String>{
    primaryPhone,
  };

  /// Obscure route for the separate admin panel login.
  static const loginPath = '/staff-console';

  /// Strip invisible RTL/bidi marks and normalize Iraqi mobile numbers.
  static String normalizePhone(String? phone) {
    var value = (phone ?? '').trim();
    value = value.replaceAll(
      RegExp(r'[\u200B-\u200D\uFEFF\u202A-\u202E\u2066-\u2069]'),
      '',
    );
    value = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (value.startsWith('+964')) {
      value = '0${value.substring(4)}';
    } else if (value.startsWith('964')) {
      value = '0${value.substring(3)}';
    }
    return value;
  }

  static bool isAllowedAdminPhone(String? phone) {
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) return false;
    return allowedPhones.contains(normalized);
  }

  /// @Deprecated — email admin login removed; kept for older call sites.
  static const primaryEmail = 'admin@qopcha.com';

  static bool isAllowedAdminEmail(String? email) => false;
}
