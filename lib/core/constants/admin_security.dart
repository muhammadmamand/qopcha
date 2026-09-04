/// Admin access policy (client-side checks + allowlist).
/// Server rules and custom claims are the real authorization gate.
class AdminSecurity {
  AdminSecurity._();

  /// Production Contabo seed email (see VPS `ADMIN_EMAIL`).
  static const primaryEmail = 'admin@shikposh.com';

  /// Only these emails may use the admin console.
  static const allowedEmails = <String>{
    primaryEmail,
    'admin@qopcha.com',
  };

  /// Obscure route for the separate admin panel login.
  static const loginPath = '/staff-console';

  /// Strip invisible RTL/bidi marks and normalize lookalike punctuation.
  static String normalizeEmail(String? email) {
    var value = (email ?? '').trim().toLowerCase();
    value = value.replaceAll(
      RegExp(r'[\u200B-\u200D\uFEFF\u202A-\u202E\u2066-\u2069]'),
      '',
    );
    value = value
        .replaceAll('＠', '@')
        .replaceAll('．', '.')
        .replaceAll(RegExp(r'\s+'), '');
    return value;
  }

  static bool isAllowedAdminEmail(String? email) {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) return false;
    return allowedEmails.contains(normalized);
  }
}
