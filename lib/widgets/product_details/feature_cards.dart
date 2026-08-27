import 'package:flutter/material.dart';

import 'pd_theme.dart';

/// Slim trust row — one purpose, no card clutter.
class FeatureCards extends StatelessWidget {
  const FeatureCards({super.key});

  static const _items = [
    (Icons.local_shipping_outlined, 'گەیاندن'),
    (Icons.restart_alt_rounded, 'گەڕاندنەوە'),
    (Icons.verified_outlined, 'پارێزراو'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: PdColors.gray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PdColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 30,
                color: PdColors.border.withValues(alpha: 0.9),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: PdColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _items[i].$1,
                      size: 18,
                      color: PdColors.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _items[i].$2,
                    textAlign: TextAlign.center,
                    style: PdTheme.label(
                      size: 11.5,
                      weight: FontWeight.w800,
                      color: PdColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
