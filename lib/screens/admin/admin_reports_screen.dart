import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import 'admin_shell.dart';

/// Simple ERP-style ops report for admin delivery business.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final pendingUsers =
        ref.watch(pendingUsersProvider).valueOrNull?.length ?? 0;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeader(
            title: 'ڕاپۆرتی کارکردن',
            subtitle: 'کورتەی ئۆردەر و کارکردنی گەیاندن',
            onLogout: () => ref.read(authProvider.notifier).logout(),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'هەڵە لە بارکردنی ڕاپۆرت',
                onRetry: () => ref.invalidate(adminOrdersProvider),
              ),
              data: (orders) {
                final pending = orders
                    .where((o) => o.status == OrderStatus.pending)
                    .length;
                final active = orders
                    .where(
                      (o) =>
                          o.status == OrderStatus.confirmed ||
                          o.status == OrderStatus.ready ||
                          o.status == OrderStatus.shipped,
                    )
                    .length;
                final completed = orders
                    .where((o) => o.status == OrderStatus.completed)
                    .toList();
                final cancelled = orders
                    .where((o) => o.status == OrderStatus.cancelled)
                    .length;
                final sales = completed.fold<double>(0, (s, o) => s + o.total);
                final fees = completed.fold<double>(
                  0,
                  (s, o) => s + o.deliveryFee,
                );
                final today = DateTime.now();
                final todayOrders = orders.where((o) {
                  final d = o.createdAt;
                  return d.year == today.year &&
                      d.month == today.month &&
                      d.day == today.day;
                }).length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _ReportCard(
                      title: 'ئەمڕۆ',
                      value: '$todayOrders',
                      subtitle: 'داواکاریی نوێ',
                      icon: Icons.today_rounded,
                      color: AppColors.brand,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ReportCard(
                            title: 'چاوەڕوان',
                            value: '$pending',
                            subtitle: 'بۆ وەرگرتن',
                            icon: Icons.inbox_outlined,
                            color: AppColors.highlight,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ReportCard(
                            title: 'لە گەیاندن',
                            value: '$active',
                            subtitle: 'قبوڵکراو / نێردراو',
                            icon: Icons.local_shipping_outlined,
                            color: const Color(0xFF3B82F6),
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ReportCard(
                            title: 'گەیشتوو',
                            value: '${completed.length}',
                            subtitle: 'تەواوکراو',
                            icon: Icons.done_all_rounded,
                            color: AppColors.success,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ReportCard(
                            title: 'ڕەتکراو',
                            value: '$cancelled',
                            subtitle: 'هەڵوەشاوە',
                            icon: Icons.cancel_outlined,
                            color: AppColors.error,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ReportCard(
                      title: 'فرۆشی کاڵا (تەواوکراو)',
                      value: Formatters.price(sales),
                      subtitle: 'بێ کرێی گەیاندن',
                      icon: Icons.shopping_bag_outlined,
                      color: AppColors.brand,
                    ),
                    const SizedBox(height: 12),
                    _ReportCard(
                      title: 'کرێی گەیاندنی کۆکراوە',
                      value: Formatters.price(fees),
                      subtitle: 'لە داواکاریی تەواوکراو',
                      icon: Icons.payments_outlined,
                      color: const Color(0xFFE67E22),
                    ),
                    const SizedBox(height: 12),
                    _ReportCard(
                      title: 'هەژماری چاوەڕوان',
                      value: '$pendingUsers',
                      subtitle: 'بۆ پەسەندکردن',
                      icon: Icons.people_outline_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'قۆناغی کارکردن (وەک ERP)',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PipelineTip(
                      step: '١',
                      title: 'وەرگرتن',
                      body: 'داواکاریی نوێ قبوڵ بکە یان ڕەت بکەرەوە',
                    ),
                    _PipelineTip(
                      step: '٢',
                      title: 'کرێی گەیاندن',
                      body: 'ناوچە دیاری بکە (٣٫٠٠٠ / ٤٫٠٠٠ / ٥٫٠٠٠)',
                    ),
                    _PipelineTip(
                      step: '٣',
                      title: 'گەیاندن',
                      body: 'دەستپێکردن → گەیاندن تەواو',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool compact;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: AppDecorations.card(radius: 18),
      child: Row(
        children: [
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: compact ? 20 : 24),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineTip extends StatelessWidget {
  final String step;
  final String title;
  final String body;

  const _PipelineTip({
    required this.step,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.brand,
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
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
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    body,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
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
