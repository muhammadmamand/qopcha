import 'package:flutter/material.dart';

class MockColorOption {
  final String name;
  final Color color;
  const MockColorOption({required this.name, required this.color});
}

class MockRelatedProduct {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double rating;
  final bool isFavorite;

  const MockRelatedProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    this.isFavorite = false,
  });
}

class MockAccordionItem {
  final String title;
  final String body;
  const MockAccordionItem({required this.title, required this.body});
}

class MockProduct {
  final String id;
  final String badge;
  final String title;
  final double rating;
  final int reviewCount;
  final double price;
  final double oldPrice;
  final int discountPercent;
  final String taxNote;
  final List<String> imageUrls;
  final List<MockColorOption> colors;
  final List<String> sizes;
  final String description;
  final String fabricBadge;
  final List<MockAccordionItem> details;
  final List<MockRelatedProduct> related;

  const MockProduct({
    required this.id,
    required this.badge,
    required this.title,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.oldPrice,
    required this.discountPercent,
    required this.taxNote,
    required this.imageUrls,
    required this.colors,
    required this.sizes,
    required this.description,
    required this.fabricBadge,
    required this.details,
    required this.related,
  });
}

/// داتای نموونەیی بۆ لاپەڕەی وردەکاری بەرهەم
abstract final class MockProductData {
  static const product = MockProduct(
    id: 'mock-premium-tee',
    badge: 'گەییشتووی نوێ',
    title: 'تیشێرتی لۆکەیی نایابی فراوان',
    rating: 4.8,
    reviewCount: 120,
    price: 23.99,
    oldPrice: 29.99,
    discountPercent: 20,
    taxNote: 'هەموو باجەکان دەگرێتەوە',
    imageUrls: [
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=900&q=80',
      'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=900&q=80',
      'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=900&q=80',
      'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=900&q=80',
      'https://images.unsplash.com/photo-1562157873-818bc0726f68?w=900&q=80',
      'https://images.unsplash.com/photo-1554568218-0f1715e72254?w=900&q=80',
    ],
    colors: [
      MockColorOption(name: 'سەوزی تاریک', color: Color(0xFF14532D)),
      MockColorOption(name: 'ڕەش', color: Color(0xFF1A1A1A)),
      MockColorOption(name: 'سپی', color: Color(0xFFF7F7F7)),
      MockColorOption(name: 'کرێمی', color: Color(0xFFF5E6D3)),
      MockColorOption(name: 'شین', color: Color(0xFF3B82F6)),
    ],
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    description:
        'ئەم تیشێرتە لە ١٠٠٪ لۆکەی نەرم دروستکراوە، لەگەڵ قاڵبێکی فراوان و شێوازێکی لوکس. گونجاوە بۆ بەکارهێنانی ڕۆژانە — هەناسەپێدراو، بەهێز، و جوان لە بەیانییەوە تا ئێوارە.',
    fabricBadge: '١٠٠٪ لۆکە',
    details: [
      MockAccordionItem(
        title: 'ماددە',
        body:
            '١٠٠٪ لۆکەی نایاب، ٢٢٠ گرام. دەستی نەرم و کەمترین داخوران دوای شوشتن.',
      ),
      MockAccordionItem(
        title: 'قاڵب',
        body:
            'قاڵبی فراوان و ئاسوودە لەگەڵ شانەی نزم. مۆدێل ١٨٣ سم قەبارەی L لەبەردایە.',
      ),
      MockAccordionItem(
        title: 'ڕێنمایی چاودێری',
        body:
            'بە ئاوە سارد بشۆ لەگەڵ ڕەنگی هاوشێوە. سپید مەکە. بە گەرمی نزم وشک بکەوە. لەکاتی پێویستدا ئاسنی سارد بەکاربهێنە.',
      ),
      MockAccordionItem(
        title: 'گەیاندن',
        body:
            'گەیاندنی خۆڕایی بۆ داواکاری زیاتر لە ٥٠\$. گەیاندنی خێرا لە کاتی پارەدان بەردەستە (٢–٤ ڕۆژی کارکردن).',
      ),
      MockAccordionItem(
        title: 'گەڕاندنەوە',
        body:
            'گەڕاندنەوەی ئاسان لە ماوەی ٣٠ ڕۆژدا. کاڵا دەبێت بەکارنەهاتوو بێت لەگەڵ تاگە ڕەسەنەکان.',
      ),
    ],
    related: [
      MockRelatedProduct(
        id: 'r1',
        name: 'کراسی لینێنی ئاسوودە',
        imageUrl:
            'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80',
        price: 42.00,
        rating: 4.7,
      ),
      MockRelatedProduct(
        id: 'r2',
        name: 'تیشێرتی سادەی گردن',
        imageUrl:
            'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600&q=80',
        price: 19.50,
        rating: 4.9,
        isFavorite: true,
      ),
      MockRelatedProduct(
        id: 'r3',
        name: 'پۆلۆی نەرم',
        imageUrl:
            'https://images.unsplash.com/photo-1586363104862-3a5e2ab60d99?w=600&q=80',
        price: 34.99,
        rating: 4.6,
      ),
      MockRelatedProduct(
        id: 'r4',
        name: 'هودیی مینیمال',
        imageUrl:
            'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=600&q=80',
        price: 58.00,
        rating: 4.8,
      ),
    ],
  );
}
