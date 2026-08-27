import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../models/delivery_zone.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/maps_launcher_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/order_preparing_animation.dart';
import '../../widgets/product_image.dart';
import 'admin_shell.dart';

/// ERP-style order boards for admin-run delivery.
enum AdminOrderBoard {
  /// New orders waiting for the shop owner to accept.
  inbox,

  /// Active delivery pipeline (confirmed → shipped → completed).
  delivery,

  /// Everything (reports / overview).
  all,
}

class AdminOrdersScreen extends ConsumerStatefulWidget {
  final AdminOrderBoard board;

  const AdminOrdersScreen({super.key, this.board = AdminOrderBoard.all});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _filter;

  @override
  void initState() {
    super.initState();
    _filter = switch (widget.board) {
      AdminOrderBoard.inbox => OrderStatus.pending,
      AdminOrderBoard.delivery => OrderStatus.confirmed,
      AdminOrderBoard.all => null,
    };
  }

  String get _title => switch (widget.board) {
    AdminOrderBoard.inbox => 'وەرگرتنی داواکاری',
    AdminOrderBoard.delivery => 'گەیاندن (ERP)',
    AdminOrderBoard.all => 'هەموو داواکارییەکان',
  };

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final pendingCount = ref.watch(adminPendingOrdersCountProvider);
    final users = ref.watch(allManagedUsersProvider).valueOrNull ?? const [];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeader(
            title: _title,
            subtitle: switch (widget.board) {
              AdminOrderBoard.inbox =>
                pendingCount > 0
                    ? '$pendingCount داواکاری چاوەڕوانی دووکانە'
                    : 'داواکاریی نوێ — دووکان قبوڵی دەکات',
              AdminOrderBoard.delivery =>
                'ناوبەندی گەیاندن — قبوڵکراو → نێردراو → گەیشتوو',
              AdminOrderBoard.all => 'تەواوی سیستەمی ئۆردەر و گەیاندن',
            },
            onLogout: () => ref.read(authProvider.notifier).logout(),
            showNotifications: true,
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'هەڵە لە بارکردنی داواکارییەکان',
                onRetry: () => ref.invalidate(adminOrdersProvider),
              ),
              data: (orders) {
                final pending = orders
                    .where((o) => o.status == OrderStatus.pending)
                    .length;
                final confirmed = orders
                    .where((o) => o.status == OrderStatus.confirmed)
                    .length;
                final ready = orders
                    .where((o) => o.status == OrderStatus.ready)
                    .length;
                final shipped = orders
                    .where((o) => o.status == OrderStatus.shipped)
                    .length;
                final completed = orders
                    .where((o) => o.status == OrderStatus.completed)
                    .length;
                final fees = orders
                    .where((o) => o.status == OrderStatus.completed)
                    .fold<double>(0, (s, o) => s + o.deliveryFee);

                var visible = orders;
                if (widget.board == AdminOrderBoard.inbox) {
                  visible = orders
                      .where(
                        (o) =>
                            o.status == OrderStatus.pending ||
                            o.status == OrderStatus.cancelled,
                      )
                      .toList();
                } else if (widget.board == AdminOrderBoard.delivery) {
                  visible = orders
                      .where(
                        (o) =>
                            o.status == OrderStatus.confirmed ||
                            o.status == OrderStatus.ready ||
                            o.status == OrderStatus.shipped ||
                            o.status == OrderStatus.completed,
                      )
                      .toList();
                }
                if (_filter != null) {
                  visible = visible.where((o) => o.status == _filter).toList();
                }

                return RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: () async => ref.invalidate(adminOrdersProvider),
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'چاوەڕوان',
                              value: '$pending',
                              color: AppColors.highlight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                              label: 'ئامادەیە',
                              value: '$ready',
                              color: AppColors.brand,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                              label: 'قبوڵکراو',
                              value: '$confirmed',
                              color: const Color(0xFFE67E22),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                              label: 'لە ڕێگادا',
                              value: '$shipped',
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                              label: 'گەیشتوو',
                              value: '$completed',
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      if (widget.board != AdminOrderBoard.inbox) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: AppDecorations.card(radius: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: AppColors.brand,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'کرێی گەیاندنی کۆکراوە (تەواوکراو): ${Formatters.price(fees)}',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'هەموو',
                              selected: _filter == null,
                              onTap: () => setState(() => _filter = null),
                            ),
                            if (widget.board != AdminOrderBoard.delivery)
                              _FilterChip(
                                label: 'چاوەڕوان',
                                selected: _filter == OrderStatus.pending,
                                color: AppColors.highlight,
                                onTap: () => setState(
                                  () => _filter = OrderStatus.pending,
                                ),
                              ),
                            if (widget.board != AdminOrderBoard.inbox) ...[
                              _FilterChip(
                                label: 'قبوڵکراو',
                                selected: _filter == OrderStatus.confirmed,
                                color: const Color(0xFFE67E22),
                                onTap: () => setState(
                                  () => _filter = OrderStatus.confirmed,
                                ),
                              ),
                              _FilterChip(
                                label: 'ئامادەیە',
                                selected: _filter == OrderStatus.ready,
                                color: AppColors.brand,
                                onTap: () =>
                                    setState(() => _filter = OrderStatus.ready),
                              ),
                              _FilterChip(
                                label: 'لە ڕێگادا',
                                selected: _filter == OrderStatus.shipped,
                                color: const Color(0xFF3B82F6),
                                onTap: () => setState(
                                  () => _filter = OrderStatus.shipped,
                                ),
                              ),
                              _FilterChip(
                                label: 'گەیشتوو',
                                selected: _filter == OrderStatus.completed,
                                color: AppColors.success,
                                onTap: () => setState(
                                  () => _filter = OrderStatus.completed,
                                ),
                              ),
                            ],
                            if (widget.board == AdminOrderBoard.inbox ||
                                widget.board == AdminOrderBoard.all)
                              _FilterChip(
                                label: 'ڕەتکراو',
                                selected: _filter == OrderStatus.cancelled,
                                color: AppColors.error,
                                onTap: () => setState(
                                  () => _filter = OrderStatus.cancelled,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: EmptyView(
                            message: 'هیچ داواکارییەک لەم قۆناغەدا نییە',
                            icon: Icons.inbox_outlined,
                          ),
                        )
                      else
                        ...visible.asMap().entries.map((entry) {
                          final index = entry.key;
                          final order = entry.value;
                          final client = users
                              .where((u) => u.id == order.userId)
                              .firstOrNull;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child:
                                _AdminErpOrderCard(
                                      order: order,
                                      client: client,
                                      board: widget.board,
                                    )
                                    .animate()
                                    .fadeIn(delay: (30 * index).ms)
                                    .slideY(begin: 0.04),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brand;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selected: selected,
        selectedColor: c,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.55),
        side: BorderSide(
          color: selected ? c : AppColors.border.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: AppDecorations.card(radius: 16),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminErpOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final UserModel? client;
  final AdminOrderBoard board;

  const _AdminErpOrderCard({
    required this.order,
    required this.board,
    this.client,
  });

  @override
  ConsumerState<_AdminErpOrderCard> createState() => _AdminErpOrderCardState();
}

class _AdminErpOrderCardState extends ConsumerState<_AdminErpOrderCard> {
  bool _expanded = true;
  bool _busy = false;

  Future<void> _updateStatus(OrderStatus status) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminServiceProvider)
          .updateOrderStatus(widget.order.id, status);
      if (!mounted) return;
      final msg = switch (status) {
        OrderStatus.confirmed => 'داواکاری قبوڵ کرا — چووە بەشی گەیاندن',
        OrderStatus.ready => 'داواکاریی دووکان ئامادەیە بۆ گەیاندن',
        OrderStatus.shipped => 'دەستی بە گەیاندن کرد',
        OrderStatus.completed => 'گەیاندن تەواو بوو',
        OrderStatus.cancelled => 'داواکاری ڕەتکرایەوە',
        OrderStatus.pending => 'گەڕێندرایەوە بۆ چاوەڕوان',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: status == OrderStatus.cancelled
              ? AppColors.error
              : AppColors.brand,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'نەتوانرا نوێ بکرێتەوە',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDeliveryZone() async {
    final deliveryDiscount = (widget.client?.deliveryDiscountPercent ?? 0)
        .clamp(0, 100)
        .toDouble();
    final zone = await showModalBottomSheet<DeliveryZone>(
      context: context,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ناوچەی گەیاندن هەڵبژێرە',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (deliveryDiscount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'داشکانی تایبەتی گەیاندن: ${deliveryDiscount.toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.highlight,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              for (final z in DeliveryZone.values)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text(
                    z.labelKu,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    z.subtitleKu,
                    style: TextStyle(fontFamily: AppTheme.fontFamily),
                  ),
                  trailing: Text(
                    Formatters.price(
                      widget.client?.deliveryFeeAfterDiscount(z.fee) ?? z.fee,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.brand,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, z),
                ),
            ],
          ),
        ),
      ),
    );
    if (zone == null) return;
    setState(() => _busy = true);
    try {
      final fee = widget.client?.deliveryFeeAfterDiscount(zone.fee) ?? zone.fee;
      await ref
          .read(adminServiceProvider)
          .setOrderDelivery(
            orderId: widget.order.id,
            zone: zone,
            deliveryDiscountPercent: deliveryDiscount,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deliveryDiscount > 0
                ? 'کرێی گەیاندن: ${Formatters.price(fee)} (داشکان ${deliveryDiscount.toStringAsFixed(0)}%)'
                : 'کرێی گەیاندن: ${Formatters.price(fee)}',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
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
            'نەتوانرا کرێ دیاری بکرێت',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  double? get _mapLat =>
      widget.order.deliveryLatitude ?? widget.client?.latitude;

  double? get _mapLng =>
      widget.order.deliveryLongitude ?? widget.client?.longitude;

  String get _mapAddress {
    final orderAddr = (widget.order.deliveryAddress ?? '').trim();
    if (orderAddr.isNotEmpty) return orderAddr;
    return widget.client?.location?.trim() ?? '';
  }

  bool get _canOpenMaps =>
      (_mapLat != null && _mapLng != null) || _mapAddress.isNotEmpty;

  Future<void> _openGoogleMaps() async {
    final ok = await const MapsLauncherService().openDirections(
      latitude: _mapLat,
      longitude: _mapLng,
      address: _mapAddress,
      label: widget.order.deliveryAddressLabel ?? widget.client?.name,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _canOpenMaps
                ? 'نەتوانرا Google Maps بکرێتەوە'
                : 'شوێنی گەیاندن بەردەست نییە',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final client = widget.client;
    final clientName = client?.name.isNotEmpty == true
        ? client!.name
        : order.customerName;
    final shops = order.shopNames;
    final address = _mapAddress;
    final phone = client?.phone.trim() ?? '';

    final statusColor = switch (order.status) {
      OrderStatus.completed => AppColors.success,
      OrderStatus.pending => AppColors.highlight,
      OrderStatus.confirmed => const Color(0xFFE67E22),
      OrderStatus.ready => AppColors.brand,
      OrderStatus.shipped => const Color(0xFF3B82F6),
      OrderStatus.cancelled => AppColors.error,
    };

    return Container(
      decoration: AppDecorations.card(radius: 22).copyWith(
        border: order.status == OrderStatus.pending
            ? Border.all(color: AppColors.highlight.withValues(alpha: 0.35))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.local_shipping_rounded,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ئۆردەر #${order.shortId}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${Formatters.date(order.createdAt)} · $clientName',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (order.status == OrderStatus.confirmed) ...[
              OrderPreparingAnimation(
                shopName: order.shopName,
                compact: true,
              ),
              const SizedBox(height: 12),
            ],
            _InfoBlock(
              icon: Icons.location_on_rounded,
              color: AppColors.brand,
              title: order.deliveryAddressLabel?.trim().isNotEmpty == true
                  ? 'ناونیشانی گەیاندن · ${order.deliveryAddressLabel}'
                  : 'ناونیشانی گەیاندن',
              lines: [
                address.isEmpty ? 'ناونیشان تۆمار نەکراوە' : address,
                if (order.deliveryFee > 0)
                  'کرێی گەیاندن: ${Formatters.price(order.deliveryFee)} (${order.deliveryZoneLabel})',
                if (_mapLat != null && _mapLng != null)
                  '${_mapLat!.toStringAsFixed(5)}, ${_mapLng!.toStringAsFixed(5)}',
              ],
            ),
            if (_canOpenMaps) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openGoogleMaps,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.map_rounded, size: 20),
                  label: Text(
                    'کردنەوە لە Google Maps',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
            if (_expanded) ...[
              const SizedBox(height: 10),
              _InfoBlock(
                icon: Icons.person_rounded,
                color: const Color(0xFF7C3AED),
                title: 'کڕیار',
                lines: [
                  clientName,
                  if (phone.isNotEmpty) 'تەلەفۆن: $phone',
                  if (client?.email.isNotEmpty == true)
                    'ئیمەیڵ: ${client!.email}',
                ],
              ),
              const SizedBox(height: 10),
              _InfoBlock(
                icon: Icons.storefront_rounded,
                color: AppColors.highlight,
                title: shops.length <= 1 ? 'دووکان' : 'دووکانەکان',
                lines: shops.isEmpty
                    ? const ['نەناسراو']
                    : [
                        for (final shop in shops)
                          '$shop • ${order.itemsForShop(shop).fold(0, (s, i) => s + i.quantity)} بەرهەم • ${Formatters.price(order.totalForShop(shop))}',
                      ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${order.itemCount} بەرهەم',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'کۆ: ${Formatters.price(order.grandTotal)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
              if (order.deliveryFee > 0)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    'کاڵا ${Formatters.price(order.total)} + گەیاندن ${Formatters.price(order.deliveryFee)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (phone.isNotEmpty)
                    ActionChip(
                      avatar: const Icon(Icons.call_rounded, size: 18),
                      label: Text(
                        'پەیوەندی',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => _call(phone),
                    ),
                  if (_canOpenMaps)
                    ActionChip(
                      avatar: const Icon(Icons.directions_rounded, size: 18),
                      label: Text(
                        'Google Maps',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: _openGoogleMaps,
                    ),
                  if (order.status == OrderStatus.ready ||
                      order.status == OrderStatus.shipped)
                    ActionChip(
                      avatar: const Icon(Icons.price_change_outlined, size: 18),
                      label: Text(
                        'کرێی گەیاندن',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: _busy ? null : _pickDeliveryZone,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.border.withValues(alpha: 0.7)),
              const SizedBox(height: 10),
              Text(
                'بەرهەمەکان',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              for (final shop in shops) ...[
                _ShopGroupHeader(
                  shopName: shop,
                  total: order.totalForShop(shop),
                ),
                const SizedBox(height: 8),
                ...order
                    .itemsForShop(shop)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OrderItemRow(
                          item: item,
                          preparing: order.status == OrderStatus.confirmed,
                        ),
                      ),
                    ),
              ],
              if (shops.isEmpty)
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OrderItemRow(
                      item: item,
                      preparing: order.status == OrderStatus.confirmed,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ..._actionButtons(order),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _actionButtons(OrderModel order) {
    if (_busy) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      ];
    }

    switch (order.status) {
      case OrderStatus.pending:
        return [
          Text(
            'دووکانی ${order.shopName.isEmpty ? 'فرۆشیار' : order.shopName} دەبێت ئەم داواکارییە قبوڵ بکات. ئەدمین لێرە قبوڵی ناکات.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ];
      case OrderStatus.confirmed:
        return const [];
      case OrderStatus.ready:
        return [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (order.deliveryFee <= 0) {
                  await _pickDeliveryZone();
                }
                if (!mounted) return;
                await _updateStatus(OrderStatus.shipped);
              },
              icon: const Icon(Icons.local_shipping_rounded, size: 18),
              label: const Text('دەستپێکردنی گەیاندن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ];
      case OrderStatus.shipped:
        return [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(OrderStatus.completed),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('گەیاندن تەواو بوو'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ];
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return [
          Text(
            order.statusDetail,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ];
    }
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;

  const _InfoBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                for (var i = 0; i < lines.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == lines.length - 1 ? 0 : 2,
                    ),
                    child: Text(
                      lines[i],
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: i == 0 ? 13.5 : 12,
                        fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600,
                        color: i == 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        height: 1.35,
                      ),
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

class _ShopGroupHeader extends StatelessWidget {
  final String shopName;
  final double total;

  const _ShopGroupHeader({required this.shopName, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.store_mall_directory_rounded,
          size: 16,
          color: AppColors.highlight,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            shopName,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          Formatters.price(total),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.highlight,
          ),
        ),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final CartItem item;
  final bool preparing;

  const _OrderItemRow({required this.item, this.preparing = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ProductImage(
                  path: item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              if (preparing)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.72),
                    child: Lottie.asset(
                      OrderPreparingAnimation.asset,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'قیاس: ${item.size}  •  دانە: ${item.quantity}  •  نرخ: ${Formatters.price(item.price)}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        Text(
          Formatters.price(item.lineTotal),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
