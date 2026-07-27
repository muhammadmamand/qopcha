import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/hero_tags.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_card.dart';
import '../../widgets/premium_bottom_nav.dart';

enum _SearchAudience { women, men }

class _CatItem {
  final String label;
  final String category;
  final IconData icon;
  final Color bg;
  final _SearchAudience audience;

  const _CatItem({
    required this.label,
    required this.category,
    required this.icon,
    required this.bg,
    required this.audience,
  });
}

/// Soft pastels tinted by brand teal / orange / white mix.
const _kAccent = AppColors.brand;
const _kAccentDark = Color(0xFF0F555C);
const _kPageBg = AppColors.brandWhite;
const _kCta = AppColors.highlight;

const _categories = <_CatItem>[
  _CatItem(
    label: 'جانتە',
    category: 'جانتە',
    icon: Icons.shopping_bag_outlined,
    bg: Color(0xFFD7ECEE),
    audience: _SearchAudience.women,
  ),
  _CatItem(
    label: 'پێڵاو',
    category: 'پێڵاو',
    icon: Icons.ice_skating_outlined,
    bg: Color(0xFFFFE4D8),
    audience: _SearchAudience.women,
  ),
  _CatItem(
    label: 'کۆت',
    category: 'کۆت',
    icon: Icons.checkroom_outlined,
    bg: Color(0xFFE8F4F5),
    audience: _SearchAudience.women,
  ),
  _CatItem(
    label: 'کراس',
    category: 'کراس',
    icon: Icons.dry_cleaning_outlined,
    bg: Color(0xFFFFF0E8),
    audience: _SearchAudience.women,
  ),
  _CatItem(
    label: 'ئاکسەسوار',
    category: 'ئاکسەسوار',
    icon: Icons.watch_outlined,
    bg: Color(0xFFDDF0F1),
    audience: _SearchAudience.women,
  ),
  _CatItem(
    label: 'فەرمی',
    category: 'جلوبەرگی فەرمی',
    icon: Icons.woman_2_outlined,
    bg: Color(0xFFFFEADF),
    audience: _SearchAudience.women,
  ),
  _CatItem(
    label: 'پۆشاک',
    category: 'پۆشاک',
    icon: Icons.accessibility_new_rounded,
    bg: Color(0xFFD7ECEE),
    audience: _SearchAudience.men,
  ),
  _CatItem(
    label: 'پانتۆڵ',
    category: 'پانتۆڵ',
    icon: Icons.straighten_rounded,
    bg: Color(0xFFE8F4F5),
    audience: _SearchAudience.men,
  ),
  _CatItem(
    label: 'کۆت',
    category: 'کۆت',
    icon: Icons.checkroom_outlined,
    bg: Color(0xFFFFE4D8),
    audience: _SearchAudience.men,
  ),
  _CatItem(
    label: 'پێڵاو',
    category: 'پێڵاو',
    icon: Icons.ice_skating_outlined,
    bg: Color(0xFFFFF0E8),
    audience: _SearchAudience.men,
  ),
  _CatItem(
    label: 'وەرزشی',
    category: 'جلوبەرگی وەرزشی',
    icon: Icons.sports_outlined,
    bg: Color(0xFFDDF0F1),
    audience: _SearchAudience.men,
  ),
  _CatItem(
    label: 'کڵاو',
    category: 'کڵاو',
    icon: Icons.balcony_outlined,
    bg: Color(0xFFFFEADF),
    audience: _SearchAudience.men,
  ),
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  _SearchAudience _audience = _SearchAudience.women;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    final existing = ref.read(searchQueryProvider);
    if (existing.isNotEmpty) _searchController.text = existing;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    setState(() {});
  }

  void _clearAll() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedCategoryProvider.notifier).state = 'هەموو';
    setState(() {});
  }

  void _openFilterSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'فلتەر',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.clear_all_rounded, color: _kAccent),
                title: Text(
                  'پاککردنەوەی هەموو فلتەرەکان',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _clearAll();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.grid_view_rounded, color: _kAccent),
                title: Text(
                  'بینینی هەموو جۆرەکان',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(selectedCategoryProvider.notifier).state = 'هەموو';
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final allProductsAsync = ref.watch(productsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final query = ref.watch(searchQueryProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    final hasQuery = query.trim().isNotEmpty;
    final browsing = !hasQuery && selectedCategory == 'هەموو';

    final counts = <String, int>{};
    for (final p in allProductsAsync.valueOrNull ?? const []) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }

    final visibleCats =
        _categories.where((c) => c.audience == _audience).toList();

    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.menu_rounded,
                    onTap: () => context.go('/profile'),
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: Icons.shopping_bag_outlined,
                    badge: cartCount > 0 ? cartCount : null,
                    onTap: () => context.go('/cart'),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                      child: Text(
                        'دەتەوێت\nچی بدۆزیتەوە؟',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 34,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppColors.textPrimary,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 420.ms)
                          .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PillSearchField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              onChanged: _setQuery,
                              onClear: () {
                                _searchController.clear();
                                _setQuery('');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          _FilterFab(
                            active: selectedCategory != 'هەموو' || hasQuery,
                            onTap: _openFilterSheet,
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 400.ms)
                          .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: _AudienceToggle(
                        value: _audience,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _audience = v);
                        },
                      )
                          .animate()
                          .fadeIn(delay: 120.ms, duration: 400.ms)
                          .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                    ),
                  ),
                  if (browsing)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.92,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final cat = visibleCats[index];
                            final count = counts[cat.category] ?? 0;
                            return _CategoryCard(
                              item: cat,
                              count: count,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .state = cat.category;
                              },
                            )
                                .animate(delay: (40 + index * 50).ms)
                                .fadeIn(
                                  duration: AppAnimations.normal,
                                  curve: AppAnimations.smooth,
                                )
                                .slideY(
                                  begin: 0.08,
                                  curve: AppAnimations.smooth,
                                );
                          },
                          childCount: visibleCats.length,
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                        child: Row(
                          children: [
                            if (selectedCategory != 'هەموو' || hasQuery)
                              GestureDetector(
                                onTap: _clearAll,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            if (selectedCategory != 'هەموو' || hasQuery)
                              const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hasQuery
                                    ? 'ئەنجامەکان'
                                    : selectedCategory,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            productsAsync.maybeWhen(
                              data: (list) => Text(
                                '${list.length} دانە',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    productsAsync.when(
                      loading: () => const SliverToBoxAdapter(
                        child: ProductGridShimmer(count: 4),
                      ),
                      error: (e, _) => SliverFillRemaining(
                        child: ErrorView(
                          message: 'هەڵە لە گەڕان',
                          onRetry: () =>
                              ref.invalidate(filteredProductsProvider),
                        ),
                      ),
                      data: (products) {
                        if (products.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: kPremiumBottomNavClearance,
                              ),
                              child: EmptyView(
                                message: 'هیچ ئەنجامێک نەدۆزرایەوە',
                                icon: Icons.search_off_rounded,
                                action: TextButton(
                                  onPressed: _clearAll,
                                  child: const Text('گەڕانەوە'),
                                ),
                              ),
                            ),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.64,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = products[index];
                                final tag = productHeroTag(
                                  product.id,
                                  'search',
                                  index,
                                );
                                return ProductCard(
                                  product: product,
                                  index: index,
                                  heroTag: tag,
                                  onTap: () => context.push(
                                    '/product/${product.id}',
                                    extra: tag,
                                  ),
                                );
                              },
                              childCount: products.length,
                            ),
                          ),
                        );
                      },
                      skipLoadingOnReload: true,
                      skipLoadingOnRefresh: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final int? badge;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: _kAccentDark),
                  if (badge != null && badge! > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.ctaGradient,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _kCta.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badge! > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _PillSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    final focused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: focused
              ? _kAccent.withValues(alpha: 0.45)
              : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: focused
                ? _kAccent.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: focused ? 22 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        cursorColor: _kAccent,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'گەڕان بەدوای بەرهەم...',
          hintStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: focused ? _kAccent : AppColors.textTertiary,
            size: 22,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: onClear,
                  icon: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _FilterFab extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;

  const _FilterFab({required this.active, required this.onTap});

  @override
  State<_FilterFab> createState() => _FilterFabState();
}

class _FilterFabState extends State<_FilterFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            shape: BoxShape.circle,
            border: widget.active
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: _kCta.withValues(alpha: 0.42),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _AudienceToggle extends StatelessWidget {
  final _SearchAudience value;
  final ValueChanged<_SearchAudience> onChanged;

  const _AudienceToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _AudienceSegment(
              label: 'ژنان',
              icon: Icons.woman_rounded,
              selected: value == _SearchAudience.women,
              onTap: () => onChanged(_SearchAudience.women),
            ),
          ),
          Expanded(
            child: _AudienceSegment(
              label: 'پیاوان',
              icon: Icons.man_rounded,
              selected: value == _SearchAudience.men,
              onTap: () => onChanged(_SearchAudience.men),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AudienceSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? _kAccentDark : Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.textPrimary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final _CatItem item;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.item,
    required this.count,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final count = widget.count;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(item.bg, Colors.white, 0.22)!,
                item.bg,
                Color.lerp(item.bg, const Color(0xFF2A2A32), 0.06)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(item.bg, Colors.black, 0.35)!
                    .withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.65),
                blurRadius: 0,
                offset: const Offset(0, -1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                // Soft light blob
                Positioned(
                  top: -28,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -36,
                  left: -24,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              size: 36,
                              color: const Color(0xFF2A2A32),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$count دانە',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_outward_rounded,
                              size: 16,
                              color: _kAccentDark,
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
        ),
      ),
    );
  }
}

