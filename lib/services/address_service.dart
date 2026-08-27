import '../models/address_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AddressService {
  final _api = ApiClient.instance;

  Stream<List<AddressModel>> watchAddresses(String userId) {
    return _api.poll(() => getAddresses(userId));
  }

  Future<List<AddressModel>> getAddresses(String userId) async {
    final data = await _api.getJson('/api/addresses');
    final raw = data['addresses'];
    if (raw is! List) return const [];
    final list = raw
        .whereType<Map>()
        .map((m) => AddressModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  Future<void> migrateLegacyLocationIfNeeded(UserModel user) async {
    final location = user.location?.trim() ?? '';
    if (location.isEmpty) return;
    final existing = await getAddresses(user.id);
    if (existing.isNotEmpty) return;
    final address = AddressModel.create(
      label: 'سەرەکی',
      location: location,
      latitude: user.latitude,
      longitude: user.longitude,
      isDefault: true,
    );
    await saveAddress(userId: user.id, address: address, makeDefault: true);
  }

  Future<AddressModel> saveAddress({
    required String userId,
    required AddressModel address,
    required bool makeDefault,
  }) async {
    final saved = address.copyWith(
      isDefault: makeDefault,
      updatedAt: DateTime.now(),
    );
    final data = await _api.postJson('/api/addresses', {
      ...saved.toJson(),
      'isDefault': makeDefault,
    });
    final raw = data['address'];
    if (raw is Map) {
      return AddressModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return saved;
  }

  Future<void> setDefault(String userId, AddressModel address) async {
    await saveAddress(userId: userId, address: address, makeDefault: true);
  }

  Future<void> deleteAddress(String userId, AddressModel address) async {
    await _api.delete('/api/addresses/${address.id}');
    if (!address.isDefault) return;
    final remaining = await getAddresses(userId);
    if (remaining.isEmpty) return;
    await setDefault(userId, remaining.first);
  }
}
