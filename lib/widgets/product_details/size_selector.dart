import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pd_theme.dart';

class SizeSelector extends StatelessWidget {
  final List<String> sizes;
  final ValueNotifier<String?> selectedSize;
  final VoidCallback onSizeGuide;

  const SizeSelector({
    super.key,
    required this.sizes,
    required this.selectedSize,
    required this.onSizeGuide,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'قەبارە',
              style: PdTheme.label(size: 15, weight: FontWeight.w800),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onSizeGuide,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: PdColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.straighten_rounded,
                      size: 13,
                      color: PdColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ڕێبەری قەبارە',
                      style: PdTheme.label(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: PdColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<String?>(
          valueListenable: selectedSize,
          builder: (context, selected, _) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: sizes.map((size) {
                final isSelected = size == selected;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    selectedSize.value = size;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minWidth: 54),
                    height: 46,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? PdColors.primary : PdColors.gray,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? PdColors.primary
                            : PdColors.border.withValues(alpha: 0.8),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: PdColors.primary.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      size,
                      style: PdTheme.label(
                        size: 14,
                        weight: FontWeight.w800,
                        color: isSelected ? PdColors.white : PdColors.text,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
