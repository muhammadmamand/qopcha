import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_animations.dart';
import '../core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final items = categories ?? AppConstants.categories;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = items[index];
          final isSelected = category == selected;

          return GestureDetector(
                onTap: () => onSelected(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(fontFamily: AppTheme.fontFamily),
                    ),
                  ),
                ),
              )
              .animate(delay: (index * 40).ms)
              .fadeIn(
                duration: AppAnimations.normal,
                curve: AppAnimations.smooth,
              )
              .slideX(begin: 0.15, curve: AppAnimations.smooth);
        },
      ),
    );
  }
}
