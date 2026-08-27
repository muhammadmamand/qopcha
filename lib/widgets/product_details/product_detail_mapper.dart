import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import 'mock_product_data.dart';

({double rating, int reviews}) displayRatingFor(String id) {
  final h = id.hashCode.abs();
  final rating = 4.5 + (h % 40) / 100;
  final reviews = 40 + (h % 180);
  return (rating: double.parse(rating.toStringAsFixed(1)), reviews: reviews);
}

Color colorSwatchFor(String name) {
  return switch (name.trim()) {
    'ڕەش' || 'Black' => const Color(0xFF1A1A1A),
    'سپی' || 'White' => const Color(0xFFF7F7F7),
    'شین' || 'کەحڵی' || 'Blue' => const Color(0xFF3B82F6),
    'سور' || 'شەرابی' || 'Red' => const Color(0xFFDC2626),
    'سەوز' || 'سەوزی تاریک' || 'Green' || 'Dark Green' =>
      const Color(0xFF14532D),
    'زەرد' || 'زێڕین' || 'Yellow' => const Color(0xFFEAB308),
    'پەمەیی' || 'Pink' => const Color(0xFFEC4899),
    'قاوەیی' || 'کرێمی' || 'Cream' || 'Brown' => const Color(0xFFC4A484),
    'خۆڵەمێشی' || 'زیوینی' || 'Gray' => const Color(0xFF9CA3AF),
    'بەنفەشی' || 'Purple' => const Color(0xFF7C3AED),
    'نارنجی' || 'Orange' => const Color(0xFFF15C22),
    _ => const Color(0xFF136C72),
  };
}

MockProduct toDetailView({
  required ProductModel product,
  required List<ProductModel> relatedProducts,
  required Set<String> favoriteIds,
  String? customerId,
  double personalDiscountPercent = 0,
}) {
  final rating = displayRatingFor(product.id);
  final discount = product
      .discountPercentFor(
        customerId,
        personalDiscountPercent: personalDiscountPercent,
      )
      .round()
      .clamp(0, 100);
  final colors = product.colors.isEmpty
      ? [const MockColorOption(name: 'سەرەکی', color: Color(0xFF136C72))]
      : product.colors
          .map((c) => MockColorOption(name: c, color: colorSwatchFor(c)))
          .toList();

  final sizes = product.availableSizes.isNotEmpty
      ? product.availableSizes
      : (product.sizeStocks.isNotEmpty
          ? product.sizeStocks.map((s) => s.size).toList()
          : const ['S', 'M', 'L', 'XL', 'XXL']);

  final images = product.imageUrls.where((u) => u.trim().isNotEmpty).toList();
  final material = product.material.trim().isEmpty
      ? '١٠٠٪ لۆکە'
      : product.material.trim();

  final related = relatedProducts
      .where((p) => p.id != product.id)
      .take(8)
      .map((p) {
        final r = displayRatingFor(p.id);
        return MockRelatedProduct(
          id: p.id,
          name: p.name,
          imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
          price: p.salePriceFor(
            customerId,
            personalDiscountPercent: personalDiscountPercent,
          ),
          rating: r.rating,
          isFavorite: favoriteIds.contains(p.id),
        );
      })
      .toList();

  return MockProduct(
    id: product.id,
    badge: product.isFabric
        ? (product.fabricType.isNotEmpty ? product.fabricType : 'قوماش')
        : product.isFeatured
            ? 'گەییشتووی نوێ'
            : (product.category.trim().isEmpty
                ? 'پێشنیارکراو'
                : product.category.trim()),
    title: product.name,
    rating: rating.rating,
    reviewCount: rating.reviews,
    price: product.salePriceFor(
      customerId,
      personalDiscountPercent: personalDiscountPercent,
    ),
    oldPrice: product.price,
    discountPercent: discount,
    taxNote: 'هەموو باجەکان دەگرێتەوە',
    imageUrls: images.isNotEmpty
        ? images
        : const [
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=900&q=80',
          ],
    colors: colors,
    sizes: sizes,
    description: product.description.trim().isEmpty
        ? 'وەسفی ئەم بەرهەمە بەم زووانە زیاد دەکرێت.'
        : product.description.trim(),
    fabricBadge: material,
    details: [
      if (product.isFabric) ...[
        if (product.fabricType.isNotEmpty)
          MockAccordionItem(title: 'جۆری قوماش', body: product.fabricType),
        if (product.fabricQuality.isNotEmpty)
          MockAccordionItem(title: 'کوالێتی', body: product.fabricQuality),
        if (product.fabricPattern.isNotEmpty)
          MockAccordionItem(title: 'نەخش', body: product.fabricPattern),
        MockAccordionItem(title: 'پێکهاتە', body: material),
        if (product.fabricWidthCm > 0)
          MockAccordionItem(
            title: 'پانی',
            body: '${product.fabricWidthCm.toStringAsFixed(0)} سم',
          ),
        if (product.fabricWeightGsm > 0)
          MockAccordionItem(
            title: 'کێش',
            body: '${product.fabricWeightGsm} GSM',
          ),
        if (product.fabricOrigin.isNotEmpty)
          MockAccordionItem(title: 'وڵات', body: product.fabricOrigin),
        if (product.fabricCare.isNotEmpty)
          MockAccordionItem(title: 'پاراستن', body: product.fabricCare),
        MockAccordionItem(
          title: 'کۆگا',
          body: '${product.totalStock} مەتر',
        ),
      ] else
        MockAccordionItem(
          title: 'ماددە',
          body: material,
        ),
      MockAccordionItem(
        title: 'براند',
        body: product.brand.trim().isEmpty ? 'قۆپچە' : product.brand.trim(),
      ),
      MockAccordionItem(
        title: 'گەیاندن',
        body:
            'نرخی گەیاندن لە کاتی گەیاندن وەردەگیرێت — شۆفێر بەپێی ناوچە دیاری دەکات: ناو شار ٣٬٠٠٠ · دەرەوەی شەقامی ١٢٠ مەتری ٤٬٠٠٠ · دەرەوەی شەقامی ١٥٠ مەتری ٥٬٠٠٠ دینار.',
      ),
      MockAccordionItem(
        title: 'گەڕاندنەوە',
        body:
            'گەڕاندنەوەی ئاسان لە ماوەی ٣٠ ڕۆژدا. کاڵا دەبێت بەکارنەهاتوو بێت لەگەڵ تاگە ڕەسەنەکان.',
      ),
    ],
    related: related,
  );
}

String formatDetailPrice(double amount) => Formatters.price(amount);
