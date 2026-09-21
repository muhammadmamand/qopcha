import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_animations.dart';
import '../core/theme/app_theme.dart';
import 'category_filter_icons.dart';

class CategoryChips extends ConsumerWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final List<String>? categories;

  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final items = categories ?? AppConstants.categories;
    final idleCircle = AppColors.isDark
        ? AppColors.surfaceVariant
        : const Color(0xFFF4F7F7);
    final idleIcon = AppColors.isDark
        ? AppColors.textSecondary
        : const Color(0xFF2C3A3C);

    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = items[index];
          final isSelected = category == selected;
          final label = s.categoryLabel(category);
          final iconColor = isSelected ? AppColors.onBrand : idleIcon;

          return GestureDetector(
                onTap: () => onSelected(category),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: 62,
                        height: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.accentGradient : null,
                          color: isSelected ? null : idleCircle,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brand.withValues(alpha: 0.35)
                                : AppColors.border.withValues(alpha: 0.55),
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.brand.withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: AppColors.isDark ? 0.18 : 0.04,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: CategoryFilterIcon(
                          category: category,
                          color: iconColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 9),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          height: 1.15,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
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
