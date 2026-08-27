import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/hero_tags.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_card.dart';
import '../../widgets/premium_bottom_nav.dart';

enum _Gender { men, women }

class _CatDef {
  final String label;
  final String category;
  final IconData icon;
  final _Gender gender;

  const _CatDef({
    required this.label,
    required this.category,
    required this.icon,
    required this.gender,
  });
}

final _kTeal = AppColors.brand;
final _kCoral = AppColors.highlight;

const _menCats = <_CatDef>[
  _CatDef(
    label: 'پۆشاک',
    category: 'پۆشاک',
    icon: Icons.checkroom_outlined,
    gender: _Gender.men,
  ),
  _CatDef(
    label: 'پانتۆڵ',
    category: 'پانتۆڵ',
    icon: Icons.straighten_rounded,
    gender: _Gender.men,
  ),
  _CatDef(
    label: 'کۆت',
    category: 'کۆت',
    icon: Icons.dry_cleaning_outlined,
    gender: _Gender.men,
  ),
  _CatDef(
    label: 'پێڵاو',
    category: 'پێڵاو',
    icon: Icons.ice_skating_outlined,
    gender: _Gender.men,
  ),
  _CatDef(
    label: 'وەرزشی',
    category: 'جلوبەرگی وەرزشی',
    icon: Icons.sports_outlined,
    gender: _Gender.men,
  ),
  _CatDef(
    label: 'کڵاو',
    category: 'کڵاو',
    icon: Icons.balcony_outlined,
    gender: _Gender.men,
  ),
];

const _womenCats = <_CatDef>[
  _CatDef(
    label: 'کراس',
    category: 'کراس',
    icon: Icons.dry_cleaning_outlined,
    gender: _Gender.women,
  ),
  _CatDef(
    label: 'جانتە',
    category: 'جانتە',
    icon: Icons.shopping_bag_outlined,
    gender: _Gender.women,
  ),
  _CatDef(
    label: 'پێڵاو',
    category: 'پێڵاو',
    icon: Icons.ice_skating_outlined,
    gender: _Gender.women,
  ),
  _CatDef(
    label: 'کۆت',
    category: 'کۆت',
    icon: Icons.checkroom_outlined,
    gender: _Gender.women,
  ),
  _CatDef(
    label: 'ئاکسەسوار',
    category: 'ئاکسەسوار',
    icon: Icons.watch_outlined,
    gender: _Gender.women,
  ),
  _CatDef(
    label: 'فەرمی',
    category: 'جلوبەرگی فەرمی',
    icon: Icons.woman_2_outlined,
    gender: _Gender.women,
  ),
];

final _chipCats = <_CatDef>[
  ..._womenCats.take(3),
  ..._menCats.take(3),
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _menKey = GlobalKey();
  final _womenKey = GlobalKey();

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
    _scrollController.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    setState(() {});
  }

  void _selectCategory(String category) {
    HapticFeedback.selectionClick();
    ref.read(selectedCategoryProvider.notifier).state = category;
    setState(() {});
  }

  void _clearAll() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedCategoryProvider.notifier).state = 'هەموو';
    setState(() {});
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubicEmphasized,
      alignment: 0.08,
    );
  }

  void _openFilterSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sheet,
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
                leading: Icon(Icons.clear_all_rounded, color: _kTeal),
                title: Text(
                  'پاککردنەوەی هەموو فلتەرەکان',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _clearAll();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.grid_view_rounded, color: _kTeal),
                title: Text(
                  'بینینی هەموو جۆرەکان',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _selectCategory('هەموو');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String? _coverFor(String category, List<ProductModel> products) {
    for (final p in products) {
      if (p.category == category && p.imageUrls.isNotEmpty) {
        return p.imageUrls.first;
      }
    }
    return null;
  }

  int _countFor(String category, List<ProductModel> products) {
    return products.where((p) => p.category == category).length;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final allProductsAsync = ref.watch(productsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final query = ref.watch(searchQueryProvider);

    final hasQuery = query.trim().isNotEmpty;
    final browsing = !hasQuery && selectedCategory == 'هەموو';
    final allProducts = allProductsAsync.valueOrNull ?? const <ProductModel>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: browsing
            ? CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: _SearchField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _setQuery,
                        onClear: () {
                          _searchController.clear();
                          _setQuery('');
                        },
                        onFilterTap: _openFilterSheet,
                      )
                          .animate()
                          .fadeIn(duration: 380.ms)
                          .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                      child: _SectionTitle(title: 'کڕین بەپێی پۆل'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 96,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _CategoryChip(
                            label: 'هەموو',
                            icon: Icons.grid_view_rounded,
                            selected: true,
                            onTap: () => _selectCategory('هەموو'),
                          ),
                          ..._chipCats.map(
                            (c) => _CategoryChip(
                              label: c.label,
                              icon: c.icon,
                              selected: false,
                              onTap: () => _selectCategory(c.category),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 60.ms, duration: 400.ms),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                      child: _SectionTitle(title: 'کڕین بەپێی ڕەگەز'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _GenderCard(
                              title: 'پیاوان',
                              subtitle: 'کۆلێکشنە نوێیەکانی پیاوان ببینە',
                              gradient: [
                                const Color(0xFFD7ECEE),
                                Color.lerp(
                                      const Color(0xFFD7ECEE),
                                      Colors.white,
                                      0.55,
                                    ) ??
                                    Colors.white,
                              ],
                              accent: _kTeal,
                              icon: Icons.man_rounded,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _scrollTo(_menKey);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GenderCard(
                              title: 'ژنان',
                              subtitle: 'کۆلێکشنە نوێیەکانی ژنان ببینە',
                              gradient: [
                                const Color(0xFFFFE4D8),
                                Color.lerp(
                                      const Color(0xFFFFE4D8),
                                      Colors.white,
                                      0.55,
                                    ) ??
                                    Colors.white,
                              ],
                              accent: _kCoral,
                              icon: Icons.woman_rounded,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _scrollTo(_womenKey);
                              },
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 420.ms)
                          .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _menKey,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: _SectionTitle(
                        title: 'پۆلەکانی پیاوان',
                        actionLabel: 'بینینی هەموو',
                        onAction: () {
                          if (_menCats.isNotEmpty) {
                            _selectCategory(_menCats.first.category);
                          }
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CategoryCarousel(
                      items: _menCats,
                      products: allProducts,
                      coverFor: _coverFor,
                      countFor: _countFor,
                      onTap: (c) => _selectCategory(c.category),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _womenKey,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: _SectionTitle(
                        title: 'پۆلەکانی ژنان',
                        actionLabel: 'بینینی هەموو',
                        onAction: () {
                          if (_womenCats.isNotEmpty) {
                            _selectCategory(_womenCats.first.category);
                          }
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: kPremiumBottomNavClearance + 16,
                      ),
                      child: _CategoryCarousel(
                        items: _womenCats,
                        products: allProducts,
                        coverFor: _coverFor,
                        countFor: _countFor,
                        onTap: (c) => _selectCategory(c.category),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildHeader(showBack: true),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: _SearchField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _setQuery,
                      onClear: () {
                        _searchController.clear();
                        _setQuery('');
                      },
                      onFilterTap: _openFilterSheet,
                    ),
                  ),
                  Expanded(child: _buildResults(productsAsync)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader({bool showBack = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: _clearAll,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                'گەڕان',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(AsyncValue<List<ProductModel>> productsAsync) {
    return productsAsync.when(
      loading: () => const ProductGridShimmer(count: 4),
      error: (e, _) => ErrorView(
        message: 'هەڵە لە گەڕان',
        onRetry: () => ref.invalidate(filteredProductsProvider),
      ),
      data: (products) {
        if (products.isEmpty) {
          return EmptyView(
            message: 'هیچ ئەنجامێک نەدۆزرایەوە',
            icon: Icons.search_off_rounded,
            action: TextButton(
              onPressed: _clearAll,
              child: const Text('گەڕانەوە'),
            ),
          );
        }
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            kPremiumBottomNavClearance + 20,
          ),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.64,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final tag = productHeroTag(product.id, 'search', index);
            return ProductCard(
              product: product,
              index: index,
              heroTag: tag,
              onTap: () => context.push('/product/${product.id}', extra: tag),
            );
          },
        );
      },
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kTeal,
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField>
    with SingleTickerProviderStateMixin {
  static const _hints = <String>[
    'گەڕان بۆ جل، پۆل، براند...',
    'کراس، پێڵاو، جانتە...',
    'دووکانی دڵخواز...',
  ];

  late final AnimationController _caret;
  late final TextEditingController _textController;
  late final FocusNode _focus;

  Timer? _tick;
  int _hintIndex = 0;
  int _charIndex = 0;
  bool _deleting = false;
  String _visible = '';
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    _textController = widget.controller;
    _focus = widget.focusNode;
    _caret = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true);
    _textController.addListener(_refresh);
    _focus.addListener(_refresh);
    _scheduleTick(const Duration(milliseconds: 80));
  }

  @override
  void dispose() {
    _alive = false;
    _tick?.cancel();
    _tick = null;
    _textController.removeListener(_refresh);
    _focus.removeListener(_refresh);
    _caret.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!_alive || !mounted) return;
    setState(() {});
    // Pause typing while user has text; resume when cleared.
    if (_showHint && _tick == null) {
      _scheduleTick(const Duration(milliseconds: 120));
    }
  }

  bool get _showHint => _textController.text.isEmpty;

  void _scheduleTick(Duration delay) {
    _tick?.cancel();
    if (!_alive) return;
    _tick = Timer(delay, _onTick);
  }

  void _onTick() {
    _tick = null;
    if (!_alive || !mounted) return;

    if (!_showHint) {
      // Wait until field is empty again.
      _scheduleTick(const Duration(milliseconds: 250));
      return;
    }

    final full = _hints[_hintIndex];

    if (!_deleting) {
      if (_charIndex <= full.length) {
        _visible = full.substring(0, _charIndex);
        _charIndex++;
        setState(() {});
        _scheduleTick(const Duration(milliseconds: 48));
      } else {
        _deleting = true;
        _scheduleTick(const Duration(milliseconds: 1400));
      }
      return;
    }

    if (_charIndex > 0) {
      _charIndex--;
      _visible = full.substring(0, _charIndex);
      setState(() {});
      _scheduleTick(const Duration(milliseconds: 28));
      return;
    }

    _deleting = false;
    _hintIndex = (_hintIndex + 1) % _hints.length;
    _scheduleTick(const Duration(milliseconds: 220));
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.isNotEmpty;
    final focused = _focus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      height: 56,
      padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focused
              ? _kTeal.withValues(alpha: 0.45)
              : AppColors.border.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: focused ? _kTeal : AppColors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                TextField(
                  controller: _textController,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: _kTeal,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                if (_showHint)
                  IgnorePointer(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _visible,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: AppColors.textTertiary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _caret,
                          child: Container(
                            width: 1.4,
                            height: 14,
                            margin: const EdgeInsetsDirectional.only(start: 2),
                            color: _kTeal.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (hasText)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: widget.onClear,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onFilterTap,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? _kTeal
                      : _kTeal.withValues(alpha: 0.10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _kTeal.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : _kTeal,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? _kTeal : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  const _GenderCard({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GenderCard> createState() => _GenderCardState();
}

class _GenderCardState extends State<_GenderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 168,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.14),
                blurRadius: _pressed ? 8 : 16,
                offset: Offset(0, _pressed ? 4 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  left: -20,
                  bottom: -30,
                  child: Icon(
                    widget.icon,
                    size: 120,
                    color: widget.accent.withValues(alpha: 0.10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.isDark
                              ? AppColors.textPrimary
                              : const Color(0xFF16363A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: AppColors.isDark
                              ? AppColors.textSecondary
                              : const Color(0xFF4A6568),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: widget.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
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

class _CategoryCarousel extends StatelessWidget {
  final List<_CatDef> items;
  final List<ProductModel> products;
  final String? Function(String category, List<ProductModel> products) coverFor;
  final int Function(String category, List<ProductModel> products) countFor;
  final ValueChanged<_CatDef> onTap;

  const _CategoryCarousel({
    required this.items,
    required this.products,
    required this.coverFor,
    required this.countFor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final cover = coverFor(item.category, products);
          final count = countFor(item.category, products);
          return _PhotoCategoryCard(
            label: item.label,
            count: count,
            coverUrl: cover,
            icon: item.icon,
            onTap: () => onTap(item),
          )
              .animate(delay: (40 + index * 40).ms)
              .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.smooth)
              .slideX(begin: 0.06, curve: AppAnimations.smooth);
        },
      ),
    );
  }
}

class _PhotoCategoryCard extends StatefulWidget {
  final String label;
  final int count;
  final String? coverUrl;
  final IconData icon;
  final VoidCallback onTap;

  const _PhotoCategoryCard({
    required this.label,
    required this.count,
    required this.coverUrl,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PhotoCategoryCard> createState() => _PhotoCategoryCardState();
}

class _PhotoCategoryCardState extends State<_PhotoCategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 148,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: widget.coverUrl != null && widget.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _fallback(),
                          errorWidget: (_, _, _) => _fallback(),
                        )
                      : _fallback(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.count}+ دانە',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: _kTeal.withValues(alpha: 0.10),
      child: Icon(widget.icon, color: _kTeal, size: 36),
    );
  }
}
