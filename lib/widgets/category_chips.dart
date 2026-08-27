import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_animations.dart';
import '../core/theme/app_theme.dart';
import 'category_filter_icons.dart';

class CategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final List<String>? categories;

  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.categories,
  });

  /// Shorter chip labels for long category names.
  static String labelFor(String category) {
    switch (category) {
      case 'جلوبەرگی وەرزشی':
        return 'وەرزشی';
      case 'جلوبەرگی فەرمی':
        return 'فەرمی';
      case 'جلی منداڵان':
        return 'منداڵان';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = categories ?? AppConstants.categories;
    final idleCircle = AppColors.isDark
        ? AppColors.surfaceVariant
        : const Color(0xFFF2F4F5);
    final idleIcon = AppColors.isDark
        ? AppColors.textSecondary
        : const Color(0xFF2C3A3C);

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = items[index];
          final isSelected = category == selected;
          final label = labelFor(category);
          final iconColor = isSelected ? AppColors.onBrand : idleIcon;

          return GestureDetector(
                onTap: () => onSelected(category),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 68,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brand : idleCircle,
                          shape: BoxShape.circle,
                        ),
                        child: CategoryFilterIcon(
                          category: category,
                          color: iconColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          height: 1.15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.brand
                              : AppColors.textSecondary,
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(delay: (index * 35).ms)
              .fadeIn(
                duration: AppAnimations.normal,
                curve: AppAnimations.smooth,
              )
              .slideX(begin: 0.12, curve: AppAnimations.smooth);
        },
      ),
    );
  }
}
