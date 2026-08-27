import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/kurdistan_locations.dart';
import '../../core/constants/profile_avatars.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../models/address_model.dart';
import '../../models/user_model.dart';
import '../../providers/addresses_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_storage_service.dart';
import '../../services/reverse_geocode_service.dart';
import '../../widgets/address_location_fields.dart';
import '../../widgets/location_map_preview.dart';
import '../../widgets/profile_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationDetailsController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopDescriptionController = TextEditingController();
  final _shopAddressController = TextEditingController();

  String? _city;
  String? _neighborhood;
  String? _placeHint;
  double? _latitude;
  double? _longitude;
  List<NearbyPlace> _nearbyPlaces = const [];
  String _avatarValue = ProfileAvatars.defaultOption.storageValue;
  bool _isDetectingLocation = false;
  bool _didLoadUser = false;
  String? _shopLogoUrl;
  String? _shopCoverUrl;
  Uint8List? _pendingLogoBytes;
  Uint8List? _pendingCoverBytes;
  XFile? _pendingLogoFile;
  XFile? _pendingCoverFile;
  final _picker = ImagePicker();
  final _storage = ImageStorageService();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadUser) return;
    _didLoadUser = true;
    _hydrateFromUser(ref.read(currentUserProvider));
  }

  void _hydrateFromUser(UserModel? user) {
    final parsed = KurdistanLocations.parse(user?.location);
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _city = parsed.city;
    _neighborhood = parsed.neighborhood;
    _placeHint = user?.location;
    _latitude = user?.latitude;
    _longitude = user?.longitude;
    _nearbyPlaces = const [];
    final details = parsed.details.trim();
    final looksGps = RegExp(
      r'(^-?\d+\.\d+\s*,\s*-?\d+\.\d+$)|(^GPS:)',
      caseSensitive: false,
    ).hasMatch(details);
    _locationDetailsController.text = looksGps ? '' : details;
    _avatarValue = ProfileAvatars.isIconValue(user?.avatarUrl)
        ? user!.avatarUrl!.trim()
        : ProfileAvatars.defaultOption.storageValue;
    _shopNameController.text = user?.shopName ?? '';
    _shopDescriptionController.text = user?.shopDescription ?? '';
    _shopAddressController.text = user?.shopAddress ?? '';
    _shopLogoUrl = user?.shopLogoUrl;
    _shopCoverUrl = user?.shopCoverUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationDetailsController.dispose();
    _shopNameController.dispose();
    _shopDescriptionController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  String _composedLocation() {
    final city = _city?.trim() ?? '';
    final hood = _neighborhood?.trim() ?? '';
    final details = _locationDetailsController.text.trim();
    if (city.isEmpty && hood.isEmpty && details.isEmpty) return '';
    return KurdistanLocations.compose(
      city: city,
      neighborhood: hood,
      details: details,
    );
  }

  Future<void> _pickShopBrandImage({required bool logo}) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: logo ? 1024 : 1920,
        maxHeight: logo ? 1024 : 1080,
        imageQuality: logo ? 88 : 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (logo) {
          _pendingLogoFile = file;
          _pendingLogoBytes = bytes;
        } else {
          _pendingCoverFile = file;
          _pendingCoverBytes = bytes;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ù†Û•ØªÙˆØ§Ù†Ø±Ø§ ÙˆÛŽÙ†Û• Ù‡Û•ÚµØ¨Ú˜ÛŽØ±Ø¯Ø±ÛŽØª'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    var logoUrl = _shopLogoUrl;
    var coverUrl = _shopCoverUrl;
    try {
      if (user.isShopOwner && _pendingLogoFile != null) {
        logoUrl = await _storage.persistXFilePathOrBytes(
          path: _pendingLogoFile!.path,
          bytes: _pendingLogoBytes,
          folder: 'shop_logos',
        );
      }
      if (user.isShopOwner && _pendingCoverFile != null) {
        coverUrl = await _storage.persistXFilePathOrBytes(
          path: _pendingCoverFile!.path,
          bytes: _pendingCoverBytes,
          folder: 'shop_covers',
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ø¨Ø§Ø±Ú©Ø±Ø¯Ù†ÛŒ ÙˆÛŽÙ†Û•ÛŒ Ø¯ÙˆÙˆÚ©Ø§Ù† Ø³Û•Ø±Ú©Û•ÙˆØªÙˆÙˆ Ù†Û•Ø¨ÙˆÙˆ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final updatedUser = user.copyWith(
      name: _nameController.text.trim(),
      phone: PhoneUtils.normalize(_phoneController.text),
      location: _composedLocation(),
      latitude: _latitude,
      longitude: _longitude,
      clearLocationCoords: _latitude == null || _longitude == null,
      avatarUrl: _avatarValue,
      shopName: user.isShopOwner ? _shopNameController.text.trim() : null,
      shopDescription:
          user.isShopOwner ? _shopDescriptionController.text.trim() : null,
      shopAddress: user.isShopOwner ? _shopAddressController.text.trim() : null,
      shopLogoUrl: user.isShopOwner ? logoUrl : null,
      shopCoverUrl: user.isShopOwner ? coverUrl : null,
    );

    final success =
        await ref.read(authProvider.notifier).updateProfile(updatedUser);
    if (!mounted) return;

    if (success) {
      // Keep multi-address list in sync with profile location.
      final composed = _composedLocation().trim();
      if (composed.isNotEmpty) {
        try {
          final service = ref.read(addressServiceProvider);
          final existing = await service.getAddresses(user.id);
          final AddressModel? defaultAddr = existing.isEmpty
              ? null
              : existing.firstWhere(
                  (a) => a.isDefault,
                  orElse: () => existing.first,
                );
          final next = defaultAddr == null
              ? AddressModel.create(
                  label: 'Ø³Û•Ø±Û•Ú©ÛŒ',
                  location: composed,
                  latitude: _latitude,
                  longitude: _longitude,
                  isDefault: true,
                )
              : defaultAddr.copyWith(
                  location: composed,
                  latitude: _latitude,
                  longitude: _longitude,
                  clearCoords: _latitude == null || _longitude == null,
                  updatedAt: DateTime.now(),
                );
          await service.saveAddress(
            userId: user.id,
            address: next,
            makeDefault: true,
          );
        } catch (_) {
          // Profile already saved; address sync is best-effort.
        }
      }
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ù¾Ú•Û†ÙØ§ÛŒÙ„ Ø¨Û• Ø³Û•Ø±Ú©Û•ÙˆØªÙˆÙˆÛŒÛŒ Ù†ÙˆÛŽÚ©Ø±Ø§ÛŒÛ•ÙˆÛ•',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final message =
          ref.read(authProvider).error ?? 'Ù†Û•ØªÙˆØ§Ù†Ø±Ø§ Ù¾Ú•Û†ÙØ§ÛŒÙ„ Ù†ÙˆÛŽ Ø¨Ú©Ø±ÛŽØªÛ•ÙˆÛ•';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.replaceFirst('Exception: ', ''),
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ø¦Û•Ù… Ø®Ø§Ù†Û•ÛŒÛ• Ù¾ÛŽÙˆÛŒØ³ØªÛ•';
    return null;
  }

  Future<void> _detectLocation() async {
    if (_isDetectingLocation) return;
    setState(() => _isDetectingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Ø´ÙˆÛŽÙ†Ú©Ø§Ø±Û•Ú©Û• Ø¯Ø§Ú¯ÛŒØ±Ø³ÛŽÙ†Û•',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'GPS Ú©ÙˆÚ˜Ø§ÙˆÛ•ØªÛ•ÙˆÛ•. Ø¯Ø§Ú¯ÛŒØ±ÛŒ Ø¨Ú©Û•ØŒ Ù¾Ø§Ø´Ø§Ù† Ø¯ÙˆÙˆØ¨Ø§Ø±Û• Ù‡Û•ÙˆÚµØ¨Ø¯Û•Ø±Û•ÙˆÛ•.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ù¾Ø§Ø´Ú¯Û•Ø²Ø¨ÙˆÙˆÙ†Û•ÙˆÛ•'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ú©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ú•ÛŽÚ©Ø®Ø³ØªÙ†'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await Geolocator.openLocationSettings();
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationError('Ù…Û†ÚµÛ•ØªÛŒ Ø´ÙˆÛŽÙ† Ú•Û•ØªÚ©Ø±Ø§ÛŒÛ•ÙˆÛ•.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Ù…Û†ÚµÛ•ØªÛŒ Ø´ÙˆÛŽÙ† Ù¾ÛŽÙˆÛŒØ³ØªÛ•',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'Ù„Û• Ú•ÛŽÚ©Ø®Ø³ØªÙ†ÛŒ Ø¦Û•Ù¾Û•Ú©Û• Ù…Û†ÚµÛ•ØªÛŒ Ø´ÙˆÛŽÙ† Ø¨Ø¯Û•.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ù¾Ø§Ø´Ú¯Û•Ø²Ø¨ÙˆÙˆÙ†Û•ÙˆÛ•'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ú©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ú•ÛŽÚ©Ø®Ø³ØªÙ†'),
              ),
            ],
          ),
        );
        if (openSettings == true) await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;

      final place = await ReverseGeocodeService.instance.resolve(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      setState(() {
        _latitude = place.latitude;
        _longitude = place.longitude;
        _nearbyPlaces = place.nearby;
        if (place.city != null) _city = place.city;
        if (place.neighborhood != null) {
          _neighborhood = place.neighborhood;
        } else if (place.city != null) {
          final hoods = KurdistanLocations.neighborhoodsFor(place.city);
          if (_neighborhood == null || !hoods.contains(_neighborhood)) {
            _neighborhood = hoods.contains('Ù†Ø§Ùˆ Ø´Ø§Ø±') ? 'Ù†Ø§Ùˆ Ø´Ø§Ø±' : null;
          }
        }
        if (place.nearest.isNotEmpty) {
          _locationDetailsController.text = place.nearest;
        } else if (place.nearby.isNotEmpty) {
          _locationDetailsController.text =
              'Ù†Ø²ÛŒÚ© ${place.nearby.first.typeLabel}: ${place.nearby.first.name}';
        }
        _placeHint =
            place.summary.isNotEmpty ? place.summary : 'Ø´ÙˆÛŽÙ† Ø¯Û†Ø²Ø±Ø§ÛŒÛ•ÙˆÛ•';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            place.summary.isNotEmpty
                ? 'Ø´ÙˆÛŽÙ†: ${place.summary}'
                : 'Ø´ÙˆÛŽÙ† Ø¯Û†Ø²Ø±Ø§ÛŒÛ•ÙˆÛ•',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      _showLocationError(
        'Ù†Û•ØªÙˆØ§Ù†Ø±Ø§ Ù†Ø§ÙˆÛŒ Ø´ÙˆÛŽÙ† Ø¨Ø¯Û†Ø²Ø±ÛŽØªÛ•ÙˆÛ•. Ø¦ÛŒÙ†ØªÛ•Ø±Ù†ÛŽØª Ø¨Ù¾Ø´Ú©Ù†Û• ÛŒØ§Ù† Ø¨Û• Ø¯Û•Ø³Øª Ø¯ÛŒØ§Ø±ÛŒ Ø¨Ú©Û•.',
      );
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openChangePasswordSheet() async {
    HapticFeedback.selectionClick();
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _ChangePasswordSheet(),
    );
    if (!mounted || changed != true) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(
          'ÙˆØ´Û•ÛŒ Ù†Ù‡ÛŽÙ†ÛŒ Ø¨Û• Ø³Û•Ø±Ú©Û•ÙˆØªÙˆÙˆÛŒÛŒ Ú¯Û†Ú•Ø¯Ø±Ø§',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final name = _nameController.text.trim();
    final busy = isLoading;
    final pageBg = AppColors.isDark
        ? AppColors.surface
        : const Color(0xFFF4F7F7);

    if (user == null) {
      return Scaffold(
        backgroundColor: pageBg,
        body: Center(
          child: Text(
            'ØªÚ©Ø§ÛŒÛ• Ø¯ÙˆÙˆØ¨Ø§Ø±Û• Ø¨Ú†Û† Ú˜ÙˆÙˆØ±Û•ÙˆÛ•',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final roleLabel = user.isAdmin
        ? 'Ø¨Û•Ú•ÛŽÙˆÛ•Ø¨Û•Ø±'
        : user.isShopOwner
            ? 'Ø®Ø§ÙˆÛ•Ù† Ø¯ÙˆÙˆÚ©Ø§Ù†'
            : 'Ú©Ú•ÛŒØ§Ø±';

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          _EditTopBar(
            busy: busy,
            onBack: () => context.pop(),
            onSave: _save,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 8, 20, 28 + bottom),
                children: [
                  _AvatarPickerCard(
                    name: name.isEmpty ? user.name : name,
                    roleLabel: roleLabel,
                    selectedValue: _avatarValue,
                    onSelected: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _avatarValue = value);
                    },
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Ø²Ø§Ù†ÛŒØ§Ø±ÛŒ Ú©Û•Ø³ÛŒ'),
                  const SizedBox(height: 10),
                  _GroupedCard(
                    children: [
                      _FieldLabel('Ù†Ø§ÙˆÛŒ ØªÛ•ÙˆØ§Ùˆ'),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                        style: _valueStyle,
                        decoration: _filledDecoration(hint: 'Ù†Ø§ÙˆÛŒ Ø®Û†Øª'),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel('Ù…Û†Ø¨Ø§ÛŒÙ„'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        textDirection: TextDirection.ltr,
                        validator: (v) => PhoneUtils.validate(v),
                        style: _valueStyle,
                        decoration: _filledDecoration(hint: '07xxxxxxxxx'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Ù†Ø§ÙˆÙ†ÛŒØ´Ø§Ù†'),
                  const SizedBox(height: 10),
                  _GroupedCard(
                    children: [
                      AddressLocationFields(
                        city: _city,
                        neighborhood: _neighborhood,
                        detailsController: _locationDetailsController,
                        gpsLabel: _placeHint,
                        detectingGps: _isDetectingLocation,
                        onDetectGps: _detectLocation,
                        onCityChanged: (v) {
                          setState(() {
                            _city = v;
                            _neighborhood = null;
                          });
                        },
                        onNeighborhoodChanged: (v) {
                          setState(() => _neighborhood = v);
                        },
                        decorationBuilder: ({
                          required String hint,
                          required IconData icon,
                          Widget? suffix,
                          bool alignLabelWithHint = false,
                        }) =>
                            _locationDecoration(
                          hint: hint,
                          icon: icon,
                          suffix: suffix,
                          alignLabelWithHint: alignLabelWithHint,
                        ),
                      ),
                      if (_nearbyPlaces.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _FieldLabel('Ù†Ø²ÛŒÚ©ØªØ±ÛŒÙ† Ø´ÙˆÛŽÙ†Û•Ú©Ø§Ù†'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _nearbyPlaces.take(6).map((p) {
                            final selected = _locationDetailsController.text
                                .contains(p.name);
                            return FilterChip(
                              selected: selected,
                              showCheckmark: false,
                              label: Text(
                                p.name,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              selectedColor: AppColors.brand,
                              backgroundColor: AppColors.surfaceVariant
                                  .withValues(alpha: 0.7),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.brand
                                    : AppColors.border.withValues(alpha: 0.7),
                              ),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _locationDetailsController.text =
                                      'Ù†Ø²ÛŒÚ© ${p.typeLabel}: ${p.name}';
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      if (_latitude != null && _longitude != null) ...[
                        const SizedBox(height: 14),
                        LocationMapPreview(
                          latitude: _latitude!,
                          longitude: _longitude!,
                          caption: _composedLocation().isEmpty
                              ? _placeHint
                              : _composedLocation(),
                          height: 140,
                        ),
                      ],
                    ],
                  ),
                  if (user.isShopOwner) ...[
                    const SizedBox(height: 22),
                    const _SectionTitle('ÙˆÛŽÙ†Û•ÛŒ Ø¯ÙˆÙˆÚ©Ø§Ù†'),
                    const SizedBox(height: 10),
                    _ShopBrandImagesEditor(
                      coverBytes: _pendingCoverBytes,
                      coverUrl: _shopCoverUrl,
                      logoBytes: _pendingLogoBytes,
                      logoUrl: _shopLogoUrl,
                      onPickCover: () => _pickShopBrandImage(logo: false),
                      onPickLogo: () => _pickShopBrandImage(logo: true),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle('Ø²Ø§Ù†ÛŒØ§Ø±ÛŒ Ø¯ÙˆÙˆÚ©Ø§Ù†'),
                    const SizedBox(height: 10),
                    _GroupedCard(
                      children: [
                        _FieldLabel('Ù†Ø§ÙˆÛŒ Ø¯ÙˆÙˆÚ©Ø§Ù†'),
                        TextFormField(
                          controller: _shopNameController,
                          textInputAction: TextInputAction.next,
                          validator: _required,
                          style: _valueStyle,
                          decoration: _filledDecoration(hint: 'Ù†Ø§ÙˆÛŒ ÙØ±Û†Ø´Ú¯Ø§Ú©Û•Øª'),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel('Ù†Ø§ÙˆÙ†ÛŒØ´Ø§Ù†ÛŒ Ø¯ÙˆÙˆÚ©Ø§Ù†'),
                        TextFormField(
                          controller: _shopAddressController,
                          textInputAction: TextInputAction.next,
                          style: _valueStyle,
                          decoration: _filledDecoration(hint: 'Ù†Ø§ÙˆÙ†ÛŒØ´Ø§Ù†ÛŒ ØªÛ•ÙˆØ§Ùˆ'),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel('ÙˆÛ•Ø³ÙÛŒ Ø¯ÙˆÙˆÚ©Ø§Ù†'),
                        TextFormField(
                          controller: _shopDescriptionController,
                          minLines: 3,
                          maxLines: 5,
                          style: _valueStyle,
                          decoration: _filledDecoration(
                            hint: 'Ú©Û•Ù…ÛŽÚ© Ø¯Û•Ø±Ø¨Ø§Ø±Û•ÛŒ Ø¯ÙˆÙˆÚ©Ø§Ù†Û•Ú©Û•Øª',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  const _SectionTitle('Ù¾Ø§Ø±Ø§Ø³ØªÙ†'),
                  const SizedBox(height: 10),
                  _GroupedCard(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: busy ? null : _openChangePasswordSheet,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.brand.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.brand,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ÙˆØ´Û•ÛŒ Ù†Ù‡ÛŽÙ†ÛŒ',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Ú¯Û†Ú•ÛŒÙ†ÛŒ ÙˆØ´Û•ÛŒ Ù†Ù‡ÛŽÙ†ÛŒ Ú†ÙˆÙˆÙ†Û•Ú˜ÙˆÙˆØ±Û•ÙˆÛ•',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_left_rounded,
                                  color: AppColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _valueStyle => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  InputDecoration _filledDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w500,
        fontSize: 13.5,
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.65)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.brand, width: 1.35),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.35),
      ),
    );
  }

  InputDecoration _locationDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.55),
      alignLabelWithHint: alignLabelWithHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.brand, width: 1.35),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.35),
      ),
    );
  }
}

class _EditTopBar extends StatelessWidget {
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onSave;

  const _EditTopBar({
    required this.busy,
    required this.onBack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 10),
      child: Row(
        children: [
          Material(
            color: AppColors.card,
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: busy ? null : onBack,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.85),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Ø¯Û•Ø³ØªÚ©Ø§Ø±ÛŒ Ù¾Ú•Û†ÙØ§ÛŒÙ„',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Material(
            color: busy
                ? AppColors.textTertiary.withValues(alpha: 0.45)
                : AppColors.brand,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: busy ? null : onSave,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 40,
                width: 78,
                child: Center(
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Ù¾Ø§Ø´Û•Ú©Û•ÙˆØª',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 2),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _AvatarPickerCard extends StatelessWidget {
  final String name;
  final String roleLabel;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _AvatarPickerCard({
    required this.name,
    required this.roleLabel,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileAvatar(
          name: name,
          avatarValue: selectedValue,
          size: 88,
          showBorder: true,
        ),
        const SizedBox(height: 12),
        Text(
          name.isEmpty ? 'Ù†Ø§ÙˆÛŒ ØªÛ†' : name,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            roleLabel,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.brand,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: ProfileAvatars.all.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final option = ProfileAvatars.all[index];
              final selected = option.storageValue == selectedValue;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(option.storageValue),
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: option.color.withValues(
                        alpha: selected ? 0.22 : 0.1,
                      ),
                      border: Border.all(
                        color: selected
                            ? option.color
                            : AppColors.border.withValues(alpha: 0.7),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Icon(option.icon, color: option.color, size: 24),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GroupedCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupedCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _openForgotOtpPage() async {
    HapticFeedback.selectionClick();
    final phone = ref.read(authProvider).user?.phone.trim() ?? '';
    final uri = phone.isEmpty
        ? '/auth/forgot-password'
        : '/auth/forgot-password?phone=${Uri.encodeComponent(phone)}';
    final sent = await context.push<bool>(uri);
    if (!mounted || sent != true) return;
    Navigator.pop(context, true);
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final error = await ref.read(authProvider.notifier).changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }

    Navigator.pop(context, true);
  }

  InputDecoration _decoration({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: AppColors.textTertiary,
        fontSize: 13.5,
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.brand, width: 1.35),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.35),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom + safeBottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'گۆڕینی وشەی نهێنی',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'وشەی نهێنی ئێستا و نوێکە بنووسە',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _label('وشەی نهێنی ئێستا')),
                GestureDetector(
                  onTap: _saving ? null : _openForgotOtpPage,
                  child: Text(
                    'لەبیرچووە؟',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _currentController,
              obscureText: _obscureCurrent,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              enabled: !_saving,
              validator: (v) {
                if (v == null || v.isEmpty) return 'وشەی نهێنی ئێستا پێویستە';
                return null;
              },
              decoration: _decoration(
                hint: '••••••••',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            const SizedBox(height: 12),
            _label('وشەی نهێنی نوێ'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _newController,
              obscureText: _obscureNew,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              enabled: !_saving,
              validator: (v) {
                if (v == null || v.isEmpty) return 'وشەی نهێنی نوێ پێویستە';
                if (v.length < 6) return 'لانیکەم ٦ پیت بنووسە';
                return null;
              },
              decoration: _decoration(
                hint: 'لانیکەم ٦ پیت',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: 12),
            _label('دووبارەکردنەوەی وشەی نهێنی نوێ'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.done,
              enabled: !_saving,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'دووبارەکردنەوە پێویستە';
                if (v != _newController.text) {
                  return 'وشە نهێنییەکان یەکناگرنەوە';
                }
                return null;
              },
              decoration: _decoration(
                hint: '••••••••',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.textTertiary.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'پاشەکەوتکردنی وشەی نهێنی',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopBrandImagesEditor extends StatelessWidget {
  final Uint8List? coverBytes;
  final String? coverUrl;
  final Uint8List? logoBytes;
  final String? logoUrl;
  final VoidCallback onPickCover;
  final VoidCallback onPickLogo;

  const _ShopBrandImagesEditor({
    required this.coverBytes,
    required this.coverUrl,
    required this.logoBytes,
    required this.logoUrl,
    required this.onPickCover,
    required this.onPickLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onPickCover,
            borderRadius: BorderRadius.circular(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverBytes != null)
                      Image.memory(coverBytes!, fit: BoxFit.cover)
                    else if (coverUrl != null && coverUrl!.trim().isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => ColoredBox(
                          color: AppColors.brand.withValues(alpha: 0.12),
                        ),
                      )
                    else
                      ColoredBox(
                        color: AppColors.brand.withValues(alpha: 0.08),
                        child: Center(
                          child: Text(
                            'Ú©Ø§Ú¤Û•Ø±ÛŒ Ø¯ÙˆÙˆÚ©Ø§Ù† Ø²ÛŒØ§Ø¯ Ø¨Ú©Û•',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Ú©Ø§Ú¤Û•Ø±',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                elevation: 3,
                child: InkWell(
                  onTap: onPickLogo,
                  borderRadius: BorderRadius.circular(22),
                  child: Ink(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white, width: 3),
                      color: AppColors.brand.withValues(alpha: 0.08),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: logoBytes != null
                          ? Image.memory(logoBytes!, fit: BoxFit.cover)
                          : (logoUrl != null && logoUrl!.trim().isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: logoUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.brand,
                                  ),
                                )
                              : Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.brand,
                                ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -16),
          child: Text(
            'Ú©Ø§Ú¤Û•Ø± = Ø³Û•Ø±Û•ÙˆÛ• Â· Ù„Û†Ú¯Û† = Ø®ÙˆØ§Ø±Û•ÙˆÛ•ÛŒ Ú•Ø§Ø³Øª',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
