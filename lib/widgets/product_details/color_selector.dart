import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mock_product_data.dart';
import 'pd_theme.dart';

class ColorSelector extends StatelessWidget {
  final List<MockColorOption> colors;
  final ValueNotifier<int> selectedIndex;

  const ColorSelector({
    super.key,
    required this.colors,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<int>(
      valueListenable: selectedIndex,
      builder: (context, index, _) {
        final safeIndex = index.clamp(0, colors.length - 1);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ڕەنگ',
                  style: PdTheme.label(size: 15, weight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    colors[safeIndex].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PdTheme.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: PdColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(colors.length, (i) {
                final c = colors[i];
                final selected = i == safeIndex;
                final isLight = c.color.computeLuminance() > 0.72;

                // Outer ring keeps the selected swatch readable for both very
                // light and very dark colors.
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    selectedIndex.value = i;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? PdColors.primary.withValues(alpha: 0.14)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? PdColors.primary
                            : PdColors.border.withValues(alpha: 0.9),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.color,
                        border: isLight
                            ? Border.all(
                                color: PdColors.border.withValues(alpha: 0.9),
                              )
                            : null,
                      ),
                      child: selected
                          ? Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 17,
                                color: isLight
                                    ? PdColors.primary
                                    : Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
