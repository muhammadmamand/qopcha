import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme/app_theme.dart';
import '../services/maps_launcher_service.dart';

/// Static OSM map preview so the user can confirm their pin.
/// Tap opens Google Maps (Android) or Apple Maps (iOS).
class LocationMapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? caption;
  final double height;
  final BorderRadius borderRadius;
  final bool openOnTap;

  const LocationMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.caption,
    this.height = 168,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.openOnTap = true,
  });

  /// OpenStreetMap static map (no API key).
  static String imageUrl({
    required double latitude,
    required double longitude,
    int width = 640,
    int height = 360,
    int zoom = 16,
  }) {
    return 'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$latitude,$longitude'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&maptype=mapnik'
        '&markers=$latitude,$longitude,red-pushpin';
  }

  Future<void> _openMaps(BuildContext context) async {
    if (!openOnTap) return;
    HapticFeedback.selectionClick();
    final opened = await const MapsLauncherService().openLocation(
      latitude: latitude,
      longitude: longitude,
      label: caption,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'نەتوانرا نەخشە بکرێتەوە',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl(latitude: latitude, longitude: longitude);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Honor a tight parent height (e.g. SizedBox(height: 140)) instead of
        // forcing [height] and overflowing.
        final resolvedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : height;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openOnTap ? () => _openMaps(context) : null,
            borderRadius: borderRadius,
            child: Ink(
              height: resolvedHeight,
              decoration: BoxDecoration(borderRadius: borderRadius),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      httpHeaders: const {
                        'User-Agent': 'QopchaApp/1.0 (shik-posh)',
                      },
                      placeholder: (_, _) => Container(
                        color: AppColors.surfaceVariant,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                      errorWidget: (_, _, _) => _MapFallback(
                        latitude: latitude,
                        longitude: longitude,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'کردنەوە لە نەخشە',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                        child: Text(
                          caption?.trim().isNotEmpty == true
                              ? caption!.trim()
                              : 'کرتە بکە بۆ کردنەوەی نەخشە',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapFallback extends StatelessWidget {
  final double latitude;
  final double longitude;

  const _MapFallback({
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brand.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 36, color: AppColors.brand),
              const SizedBox(height: 8),
              Text(
                'نەخشە ئامادەیە بۆ پاشەکەوت',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'شوێن تۆمارکراوە',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
