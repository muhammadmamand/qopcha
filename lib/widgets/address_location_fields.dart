import 'package:flutter/material.dart';

import '../core/constants/kurdistan_locations.dart';
import '../core/theme/app_theme.dart';

/// City → neighborhood → optional details (+ optional GPS note).
class AddressLocationFields extends StatelessWidget {
  final String? city;
  final String? neighborhood;
  final TextEditingController detailsController;
  final String? gpsLabel;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onNeighborhoodChanged;
  final VoidCallback? onDetectGps;
  final bool detectingGps;
  final bool required;
  final InputDecoration Function({
    required String hint,
    required IconData icon,
    Widget? suffix,
    bool alignLabelWithHint,
  })? decorationBuilder;

  const AddressLocationFields({
    super.key,
    required this.city,
    required this.neighborhood,
    required this.detailsController,
    required this.onCityChanged,
    required this.onNeighborhoodChanged,
    this.gpsLabel,
    this.onDetectGps,
    this.detectingGps = false,
    this.required = false,
    this.decorationBuilder,
  });

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    bool alignLabelWithHint = false,
  }) {
    if (decorationBuilder != null) {
      return decorationBuilder!(
        hint: hint,
        icon: icon,
        suffix: suffix,
        alignLabelWithHint: alignLabelWithHint,
      );
    }
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.65),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.brand, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoods = KurdistanLocations.neighborhoodsFor(city);
    final cityValue =
        city != null && KurdistanLocations.cities.contains(city) ? city : null;
    final hoodValue =
        neighborhood != null && hoods.contains(neighborhood)
            ? neighborhood
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label('شار'),
        DropdownButtonFormField<String>(
          value: cityValue,
          isExpanded: true,
          decoration: _decoration(
            hint: 'شار هەڵبژێرە',
            icon: Icons.location_city_rounded,
          ),
          items: KurdistanLocations.cities
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onCityChanged,
          validator: required
              ? (v) =>
                  v == null || v.isEmpty ? 'تکایە شار هەڵبژێرە' : null
              : null,
        ),
        const SizedBox(height: 14),
        _Label('گەڕەک'),
        DropdownButtonFormField<String>(
          value: hoodValue,
          isExpanded: true,
          decoration: _decoration(
            hint: cityValue == null ? 'سەرەتا شار هەڵبژێرە' : 'گەڕەک هەڵبژێرە',
            icon: Icons.holiday_village_outlined,
          ),
          items: hoods
              .map(
                (n) => DropdownMenuItem(
                  value: n,
                  child: Text(
                    n,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: cityValue == null ? null : onNeighborhoodChanged,
          validator: required
              ? (v) =>
                  v == null || v.isEmpty ? 'تکایە گەڕەک هەڵبژێرە' : null
              : null,
        ),
        const SizedBox(height: 14),
        _Label('وردەکاری زیادە (ئارەزوومەندانە)'),
        TextFormField(
          controller: detailsController,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: _decoration(
            hint: 'نموونە: شەقام، نزیک مزگەوت، ژمارەی خانوو...',
            icon: Icons.edit_note_rounded,
            alignLabelWithHint: true,
          ),
        ),
        if (onDetectGps != null) ...[
          const SizedBox(height: 12),
          Material(
            color: AppColors.highlight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: detectingGps ? null : onDetectGps,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (detectingGps)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.highlight,
                        ),
                      )
                    else
                      Icon(
                        Icons.gps_fixed_rounded,
                        size: 18,
                        color: AppColors.highlight,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detectingGps
                                ? 'خەریکی دۆزینەوەی شوێن...'
                                : 'دۆزینەوەی شار و گەڕەک بە GPS',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.highlight,
                            ),
                          ),
                          if (gpsLabel != null && gpsLabel!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                gpsLabel!,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.highlight.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 8),
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
