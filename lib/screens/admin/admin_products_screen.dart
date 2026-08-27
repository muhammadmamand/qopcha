import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/admin_provider.dart';
import 'admin_shell.dart';

enum _ProductFilter { all, featured, outOfStock, discounted }

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  _ProductFilter _filter = _ProductFilter.all;
  String _query = '';

  List<ProductModel> _apply(List<ProductModel> all) {
    var list = all;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.shopName.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (_filter) {
      case _ProductFilter.all:
        break;
      case _ProductFilter.featured:
        list = list.where((p) => p.isFeatured).toList();
      case _ProductFilter.outOfStock:
        list = list.where((p) => !p.inStock).toList();
      case _ProductFilter.discounted:
        list = list.where((p) => p.hasConfiguredDiscount).toList();
    }
    return list;
  }

  Future<void> _confirmDelete(ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'سڕینەوەی کاڵا',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'دڵنیایت دەتەوێت «${p.name}» بسڕیتەوە؟',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('نەخێر'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('سڕینەوە'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(adminServiceProvider).deleteProduct(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'کاڵا سڕایەوە',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'نەتوانرا بسڕدرێتەوە',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeader(
            title: 'کاڵاکان',
            subtitle: 'تایبەتکردن · کۆنترۆڵ · سڕینەوە',
            showNotifications: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'گەڕان بە ناو / دووکان / پۆل',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in _ProductFilter.values) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(
                        switch (f) {
                          _ProductFilter.all => 'هەموو',
                          _ProductFilter.featured => 'تایبەت',
                          _ProductFilter.outOfStock => 'تەواوبوو',
                          _ProductFilter.discounted => 'داشکاندن',
                        },
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: _filter == f ? Colors.white : AppColors.brand,
                        ),
                      ),
                      selected: _filter == f,
                      selectedColor: AppColors.brand,
                      backgroundColor: AppColors.brand.withValues(alpha: 0.08),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (all) {
                final list = _apply(all);
                if (all.isEmpty) {
                  return Center(
                    child: Text(
                      'هیچ کاڵایەک نییە',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'هیچ ئەنجامێک نەدۆزرایەوە',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return _AdminProductTile(
                      product: p,
                      onToggleFeatured: (v) => ref
                          .read(adminServiceProvider)
                          .setProductFeatured(p.id, v),
                      onDelete: () => _confirmDelete(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminProductTile extends StatelessWidget {
  final ProductModel product;
  final ValueChanged<bool> onToggleFeatured;
  final VoidCallback onDelete;

  const _AdminProductTile({
    required this.product,
    required this.onToggleFeatured,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final image =
        product.imageUrls.isNotEmpty ? product.imageUrls.first : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 88,
                height: 88,
                child: image.isEmpty
                    ? ColoredBox(
                        color: AppColors.surfaceVariant,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.textTertiary,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => ColoredBox(
                          color: AppColors.surfaceVariant,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.shopName} · ${product.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        Formatters.price(product.price),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.highlight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!product.inStock)
                        _MiniBadge(
                          label: 'تەواوبوو',
                          color: AppColors.error,
                        ),
                      if (product.hasConfiguredDiscount)
                        _MiniBadge(
                          label:
                              '-${product.discountPercent.toStringAsFixed(0)}%',
                          color: AppColors.brand,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'تایبەت',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Switch.adaptive(
                        value: product.isFeatured,
                        activeThumbColor: AppColors.brand,
                        onChanged: onToggleFeatured,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onDelete,
                        tooltip: 'سڕینەوە',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.error.withValues(alpha: 0.08),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
