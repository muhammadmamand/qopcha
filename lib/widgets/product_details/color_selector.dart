import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../product_image.dart';
import 'mock_product_data.dart';
import 'pd_theme.dart';

class ColorSelector extends StatelessWidget {
  final List<MockColorOption> colors;
  final ValueNotifier<int> selectedIndex;
  final ValueChanged<int>? onColorSelected;

  const ColorSelector({
    super.key,
    required this.colors,
    required this.selectedIndex,
    this.onColorSelected,
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: List.generate(colors.length, (i) {
                final c = colors[i];
                final selected = i == safeIndex;
                final isLight = c.color.computeLuminance() > 0.72;
                final hasPhoto =
                    c.imageUrl != null && c.imageUrl!.trim().isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    selectedIndex.value = i;
                    onColorSelected?.call(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? PdColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? PdColors.primary
                            : PdColors.border.withValues(alpha: 0.9),
                        width: selected ? 2.4 : 1,
                      ),
                    ),
                    child: ClipOval(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasPhoto ? Colors.transparent : c.color,
                          border: !hasPhoto && isLight
                              ? Border.all(
                                  color: PdColors.border.withValues(alpha: 0.9),
                                )
                              : null,
                        ),
                        child: hasPhoto
                            ? ProductImage(
                                path: c.imageUrl!,
                                fit: BoxFit.cover,
                                width: 56,
                                height: 56,
                              )
                            : null,
                      ),
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
