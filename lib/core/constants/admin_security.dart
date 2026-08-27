/// Admin access policy (client-side checks + allowlist).
/// Server rules and custom claims are the real authorization gate.
class AdminSecurity {
  AdminSecurity._();

  /// Only these emails may use the admin console.
  /// Add/remove production admin emails here.
  static const allowedEmails = <String>{
    'admin@qopcha.com',
    'admin@shikposh.com', // legacy Contabo seed
  };

  /// Obscure route for the separate admin panel login.
  static const loginPath = '/staff-console';

  static bool isAllowedAdminEmail(String? email) {
    final normalized = email?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return false;
    return allowedEmails.contains(normalized);
  }
}
