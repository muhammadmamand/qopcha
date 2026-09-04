import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../widgets/fabric_icon.dart';

/// Opens the public shop profile / storefront for customers.
void openShopStorefront(
  BuildContext context, {
  required String shopOwnerId,
  String? shopName,
}) {
  final id = shopOwnerId.trim();
  if (id.isEmpty) return;
  final name = (shopName ?? '').trim();
  final path = name.isEmpty
      ? '/store/$id'
      : '/store/$id?name=${Uri.encodeQueryComponent(name)}';
  context.push(path);
}

/// Ask the shop owner whether they are adding clothing or fabric, then open
/// the add-product screen with the right kind.
Future<void> openShopAddProductChooser(
  BuildContext context,
  WidgetRef ref,
) async {
  final kind = await showAppModalBottomSheet<String>(
    context: context,
    ref: ref,
    backgroundColor: AppColors.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'چی زیاد دەکەیت؟',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'جل و بەرگ یان قوماش هەڵبژێرە',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _AddKindTile(
                icon: Icons.checkroom_rounded,
                title: 'جل و بەرگ',
                subtitle: 'پۆشاک، پێڵاو، جانتا...',
                onTap: () => Navigator.pop(ctx, 'clothing'),
              ),
              const SizedBox(height: 8),
              _AddKindTile(
                iconWidget: FabricIcon(size: 24, color: AppColors.brand),
                title: 'قوماش',
                subtitle: 'فرۆشتن بە مەتر — جۆر، کوالێتی، ڕەنگ',
                onTap: () => Navigator.pop(ctx, 'fabric'),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (!context.mounted || kind == null) return;
  openShopAddProduct(context, isFabric: kind == 'fabric');
}

/// Opens the add-product form directly (clothing or fabric).
void openShopAddProduct(BuildContext context, {bool isFabric = false}) {
  if (isFabric) {
    context.push('/shop/add-product?kind=fabric');
  } else {
    context.push('/shop/add-product');
  }
}

class _AddKindTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddKindTile({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: iconWidget ??
                    Icon(icon, color: AppColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
