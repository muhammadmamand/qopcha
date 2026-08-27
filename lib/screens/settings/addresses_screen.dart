import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/kurdistan_locations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/address_model.dart';
import '../../providers/addresses_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/reverse_geocode_service.dart';
import '../../widgets/address_location_fields.dart';
import '../../widgets/location_map_preview.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    AddressModel? existing,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final saved = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _AddressEditorSheet(
        existing: existing,
        isFirstAddress:
            (ref.read(addressesProvider).valueOrNull ?? const []).isEmpty,
      ),
    );
    if (saved == null) return;

    try {
      await ref.read(addressServiceProvider).saveAddress(
            userId: user.id,
            address: saved,
            makeDefault: saved.isDefault ||
                (ref.read(addressesProvider).valueOrNull ?? const []).isEmpty,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'ناونیشان زیادکرا' : 'ناونیشان نوێکرایەوە',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'نەتوانرا ناونیشان پاشەکەوت بکرێت',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AddressModel address,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'سڕینەوەی ناونیشان؟',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          '«${address.label}» دەسڕدرێتەوە.',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'پاشگەزبوونەوە',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'سڕینەوە',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(addressServiceProvider).deleteAddress(user.id, address);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ناونیشان سڕایەوە',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'نەتوانرا بسڕدرێتەوە',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    AddressModel address,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null || address.isDefault) return;
    HapticFeedback.selectionClick();
    try {
      await ref.read(addressServiceProvider).setDefault(user.id, address);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'نەتوانرا ناونیشانی سەرەکی بگۆڕدرێت',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'ناونیشانی نوێ',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8, top + 6, 16, 18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ناونیشانەکان',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'زیادکردن، گۆڕین، سڕینەوە و هەڵبژاردن',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: addressesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'هەڵەیەک ڕوویدا',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppColors.error,
                  ),
                ),
              ),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return ListView(
                    padding: EdgeInsets.fromLTRB(24, 40, 24, 100 + bottom),
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        size: 56,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'هیچ ناونیشانێکت نییە',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ناونیشانێک زیاد بکە بۆ داواکاری و گەیاندن.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 100 + bottom),
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return _AddressCard(
                      address: address,
                      onTap: () => _setDefault(context, ref, address),
                      onEdit: () =>
                          _openEditor(context, ref, existing: address),
                      onDelete: () => _delete(context, ref, address),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: address.isDefault
                  ? AppColors.brand.withValues(alpha: 0.45)
                  : AppColors.border.withValues(alpha: 0.8),
              width: address.isDefault ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      address.isDefault
                          ? Icons.home_rounded
                          : Icons.location_on_outlined,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                address.label,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (address.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brand.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'سەرەکی',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.location,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (address.hasMapPin) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 110,
                    child: LocationMapPreview(
                      latitude: address.latitude!,
                      longitude: address.longitude!,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!address.isDefault)
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        'بیکە سەرەکی',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brand,
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'دەستکاری',
                    icon: Icon(
                      Icons.edit_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'سڕینەوە',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressEditorSheet extends StatefulWidget {
  final AddressModel? existing;
  final bool isFirstAddress;

  const _AddressEditorSheet({
    this.existing,
    required this.isFirstAddress,
  });

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _detailsController = TextEditingController();

  String? _city;
  String? _neighborhood;
  double? _latitude;
  double? _longitude;
  bool _isDefault = false;
  bool _detectingGps = false;

  static const _suggestions = ['ماڵ', 'کار', 'قوتابخانە', 'سەرەکی'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      final parsed = KurdistanLocations.parse(existing.location);
      _labelController.text = existing.label;
      _city = parsed.city;
      _neighborhood = parsed.neighborhood;
      _detailsController.text = parsed.details;
      _latitude = existing.latitude;
      _longitude = existing.longitude;
      _isDefault = existing.isDefault;
    } else {
      _isDefault = widget.isFirstAddress;
      _labelController.text = widget.isFirstAddress ? 'سەرەکی' : 'ماڵ';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String _composed() {
    return KurdistanLocations.compose(
      city: _city?.trim() ?? '',
      neighborhood: _neighborhood?.trim() ?? '',
      details: _detailsController.text.trim(),
    );
  }

  Future<void> _detectGps() async {
    if (_detectingGps) return;
    setState(() => _detectingGps = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GPS کوژاوەتەوە',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppColors.highlight,
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'مۆڵەتی شوێن پێویستە',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final place = await ReverseGeocodeService.instance.resolve(
        pos.latitude,
        pos.longitude,
      );

      if (!mounted) return;
      setState(() {
        _latitude = place.latitude;
        _longitude = place.longitude;
        if (place.city != null) _city = place.city;
        if (place.neighborhood != null) {
          _neighborhood = place.neighborhood;
        } else if (place.city != null) {
          final hoods = KurdistanLocations.neighborhoodsFor(place.city);
          if (_neighborhood == null || !hoods.contains(_neighborhood)) {
            _neighborhood = hoods.contains('ناو شار') ? 'ناو شار' : null;
          }
        }
        if (place.nearest.isNotEmpty) {
          _detailsController.text = place.nearest;
        } else if (place.nearby.isNotEmpty) {
          _detailsController.text =
              'نزیک ${place.nearby.first.typeLabel}: ${place.nearby.first.name}';
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'نەتوانرا شوێن بدۆزرێتەوە',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _detectingGps = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final city = _city?.trim() ?? '';
    final hood = _neighborhood?.trim() ?? '';
    if (city.isEmpty || hood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'شار و گەڕەک هەڵبژێرە',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.highlight,
        ),
      );
      return;
    }

    final location = _composed();
    final now = DateTime.now();
    final existing = widget.existing;
    final result = existing == null
        ? AddressModel.create(
            label: _labelController.text.trim(),
            location: location,
            latitude: _latitude,
            longitude: _longitude,
            isDefault: _isDefault,
          )
        : existing.copyWith(
            label: _labelController.text.trim(),
            location: location,
            latitude: _latitude,
            longitude: _longitude,
            clearCoords: _latitude == null || _longitude == null,
            isDefault: _isDefault,
            updatedAt: now,
          );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom + safeBottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
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
                widget.existing == null
                    ? 'ناونیشانی نوێ'
                    : 'دەستکاری ناونیشان',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'ناو / جۆر',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _labelController,
                textInputAction: TextInputAction.next,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'بۆ نموونە: ماڵ، کار',
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  filled: true,
                  fillColor: AppColors.surfaceVariant.withValues(alpha: 0.55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'ناو بنووسە' : null,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((s) {
                  final selected = _labelController.text.trim() == s;
                  return ChoiceChip(
                    label: Text(
                      s,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppColors.brand,
                    onSelected: (_) {
                      setState(() => _labelController.text = s);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              AddressLocationFields(
                city: _city,
                neighborhood: _neighborhood,
                detailsController: _detailsController,
                onCityChanged: (v) => setState(() {
                  _city = v;
                  _neighborhood = null;
                }),
                onNeighborhoodChanged: (v) => setState(() => _neighborhood = v),
                onDetectGps: _detectGps,
                detectingGps: _detectingGps,
                required: true,
                gpsLabel: _latitude != null && _longitude != null
                    ? 'GPS پاشەکەوتکرا'
                    : null,
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 140,
                    child: LocationMapPreview(
                      latitude: _latitude!,
                      longitude: _longitude!,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                activeTrackColor: AppColors.brand.withValues(alpha: 0.45),
                activeThumbColor: AppColors.brand,
                title: Text(
                  'بیکە ناونیشانی سەرەکی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'لە کاتی داواکاریدا بە شێوەی خۆکار هەڵدەبژێردرێت',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onChanged: widget.isFirstAddress && widget.existing == null
                    ? null
                    : (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.existing == null ? 'زیادکردن' : 'پاشەکەوتکردن',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
