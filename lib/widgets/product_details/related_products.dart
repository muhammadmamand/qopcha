import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import 'mock_product_data.dart';
import 'pd_theme.dart';

class RelatedProducts extends StatefulWidget {
  final List<MockRelatedProduct> products;
  final void Function(MockRelatedProduct product)? onTap;

  const RelatedProducts({
    super.key,
    required this.products,
    this.onTap,
  });

  @override
  State<RelatedProducts> createState() => _RelatedProductsState();
}

class _RelatedProductsState extends State<RelatedProducts> {
  late final Set<String> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = {
      for (final p in widget.products)
        if (p.isFavorite) p.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ڕەنگە حەزت لێی بێت',
          style: PdTheme.label(size: 17, weight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 268,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final p = widget.products[i];
              final fav = _favorites.contains(p.id);
              return GestureDetector(
                onTap: () => widget.onTap?.call(p),
                child: SizedBox(
                  width: 168,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: PdColors.gray,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: PdTheme.cardShadow,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: p.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (_, _) =>
                                    Container(color: PdColors.gray),
                                errorWidget: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.image_rounded,
                                    color: PdColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    if (fav) {
                                      _favorites.remove(p.id);
                                    } else {
                                      _favorites.add(p.id);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: PdColors.card,
                                    shape: BoxShape.circle,
                                    boxShadow: PdTheme.cardShadow,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: Icon(
                                      fav
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      key: ValueKey(fav),
                                      size: 18,
                                      color: fav
                                          ? PdColors.accent
                                          : PdColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PdTheme.label(size: 13, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            Formatters.price(p.price),
                            style: PdTheme.label(
                              size: 13,
                              weight: FontWeight.w800,
                              color: PdColors.primary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: PdColors.star,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: PdTheme.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: PdColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
