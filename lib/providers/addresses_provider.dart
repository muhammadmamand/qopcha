import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_model.dart';
import '../services/address_service.dart';
import 'auth_provider.dart';

final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService();
});

final addressesProvider = StreamProvider<List<AddressModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<List<AddressModel>>.value(const []);
  }

  final service = ref.watch(addressServiceProvider);

  // Fire-and-forget migration of legacy single location.
  service.migrateLegacyLocationIfNeeded(user);

  return service.watchAddresses(user.id);
});

final defaultAddressProvider = Provider<AddressModel?>((ref) {
  final addresses = ref.watch(addressesProvider).valueOrNull ?? const [];
  if (addresses.isEmpty) return null;
  return addresses.firstWhere(
    (a) => a.isDefault,
    orElse: () => addresses.first,
  );
});
