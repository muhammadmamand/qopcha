import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_image.dart';
import 'admin_shell.dart';

class AdminReturnsScreen extends ConsumerWidget {
  const AdminReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminHeader(
            title: 'گەڕاندنەوەکان',
            subtitle: 'داواکارییە گەڕاوەکان لەگەڵ هۆکار و وردەکاری',
            showNotifications: true,
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const LoadingView(),
              error: (_, _) => ErrorView(
                message: 'هەڵە لە بارکردنی گەڕاندنەوەکان',
                onRetry: () => ref.invalidate(adminOrdersProvider),
              ),
              data: (orders) {
                final returns = orders
                    .where((o) => o.status == OrderStatus.returned)
                    .toList()
                  ..sort((a, b) {
                    final at = a.returnRequestedAt ?? a.statusUpdatedAt ?? a.createdAt;
                    final bt = b.returnRequestedAt ?? b.statusUpdatedAt ?? b.createdAt;
                    return bt.compareTo(at);
                  });

                if (returns.isEmpty) {
                  return const EmptyView(
                    message: 'هیچ داواکارییەکی گەڕاندنەوە نییە',
                    icon: Icons.assignment_return_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  itemCount: returns.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _ReturnOrderCard(order: returns[index]);
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

class _ReturnOrderCard extends StatelessWidget {
  final OrderModel order;

  const _ReturnOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF8B5CF6);
    final requestedAt = order.returnRequestedAt ?? order.statusUpdatedAt;

    return Container(
      decoration: AppDecorations.card(radius: 20).copyWith(
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.shortId}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'گەڕاوەتەوە',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _metaRow(Icons.person_outline_rounded, order.customerName),
          _metaRow(Icons.storefront_outlined, order.shopsLabel),
          if (order.deliveryAddress?.trim().isNotEmpty == true)
            _metaRow(Icons.location_on_outlined, order.deliveryAddress!),
          if (requestedAt != null)
            _metaRow(
              Icons.schedule_rounded,
              'داواکاری: ${Formatters.dateTime(requestedAt)}',
            ),
          _metaRow(
            Icons.calendar_today_outlined,
            'داواکاری سەرەکی: ${Formatters.dateTime(order.createdAt)}',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هۆکاری گەڕاندنەوە',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.returnReason?.trim().isNotEmpty == true
                      ? order.returnReason!
                      : '—',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (order.returnNote?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    order.returnNote!,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'کاڵاکان',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in order.items) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: ProductImage(
                        path: item.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${item.size} × ${item.quantity} · ${item.shopName}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.price(item.lineTotal),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 20),
          Row(
            children: [
              Text(
                'کۆی گشتی',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.price(order.grandTotal),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
