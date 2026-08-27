import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import 'mock_product_data.dart';
import 'pd_theme.dart';

class ProductInfo extends StatelessWidget {
  final MockProduct product;

  const ProductInfo({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPercent > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.badge.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: PdColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              product.badge,
              style: PdTheme.label(
                size: 11.5,
                weight: FontWeight.w800,
                color: PdColors.primary,
              ),
            ),
          ),
        if (product.badge.trim().isNotEmpty) const SizedBox(height: 12),
        Text(
          product.title,
          style: PdTheme.display(
            size: 25,
            weight: FontWeight.w900,
            height: 1.25,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                Formatters.price(product.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PdTheme.display(
                  size: 27,
                  weight: FontWeight.w900,
                  color: hasDiscount ? PdColors.accent : PdColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 10),
              Text(
                Formatters.price(product.oldPrice),
                style: PdTheme.body(
                  size: 13.5,
                  color: PdColors.textTertiary,
                ).copyWith(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: PdColors.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: PdColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${product.discountPercent}٪-',
                  textDirection: TextDirection.ltr,
                  style: PdTheme.label(
                    size: 11,
                    weight: FontWeight.w900,
                    color: PdColors.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (product.taxNote.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 13,
                color: PdColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  product.taxNote,
                  style: PdTheme.body(size: 12, color: PdColors.textTertiary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
