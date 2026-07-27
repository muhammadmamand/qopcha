import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _avatarController;
  late final TextEditingController _shopNameController;
  late final TextEditingController _shopDescriptionController;
  late final TextEditingController _shopAddressController;
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _avatarController = TextEditingController(text: user?.avatarUrl ?? '');
    _shopNameController = TextEditingController(text: user?.shopName ?? '');
    _shopDescriptionController = TextEditingController(
      text: user?.shopDescription ?? '',
    );
    _shopAddressController = TextEditingController(
      text: user?.shopAddress ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _avatarController.dispose();
    _shopNameController.dispose();
    _shopDescriptionController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final updatedUser = user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      avatarUrl: _avatarController.text.trim(),
      shopName: user.isShopOwner ? _shopNameController.text.trim() : null,
      shopDescription: user.isShopOwner
          ? _shopDescriptionController.text.trim()
          : null,
      shopAddress: user.isShopOwner ? _shopAddressController.text.trim() : null,
    );

    final success = await ref
        .read(authProvider.notifier)
        .updateProfile(updatedUser);
    if (!mounted) return;

    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile information updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final message =
          ref.read(authProvider).error ?? 'Could not update profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
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
            title: const Text('Turn on location'),
            content: const Text(
              'GPS/location services are disabled. Turn them on, then tap the GPS button again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open settings'),
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
        _showLocationError('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location permission required'),
            content: const Text(
              'Allow location access from app settings to detect your position.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open settings'),
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

      setState(() {
        _locationController.text =
            '${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current GPS location detected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      _showLocationError(
        'Could not detect your location. Check GPS and try again.',
      );
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isLoading = ref.watch(authProvider).isLoading;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        leading: IconButton(
          onPressed: isLoading ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                child: Text(
                  _nameController.text.trim().isEmpty
                      ? '?'
                      : _nameController.text.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: _required,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              validator: _validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              validator: _required,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'City / area or GPS coordinates',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Detect current GPS location',
                  onPressed: _isDetectingLocation ? null : _detectLocation,
                  icon: _isDetectingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _avatarController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'Profile image URL (optional)',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            if (user.isShopOwner) ...[
              const SizedBox(height: 28),
              const Text(
                'Shop information',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _shopNameController,
                textInputAction: TextInputAction.next,
                validator: _required,
                decoration: const InputDecoration(
                  labelText: 'Shop name',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _shopDescriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Shop description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _shopAddressController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Shop address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _save,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isLoading ? 'Saving...' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
