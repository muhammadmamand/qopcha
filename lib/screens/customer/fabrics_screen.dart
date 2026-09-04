import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/hero_tags.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/fabric_icon.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/product_card.dart';

class FabricsScreen extends ConsumerStatefulWidget {
  const FabricsScreen({super.key});

  @override
  ConsumerState<FabricsScreen> createState() => _FabricsScreenState();
}

class _FabricsScreenState extends ConsumerState<FabricsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final fabricsAsync = ref.watch(fabricsProvider);
    final selectedType = ref.watch(selectedFabricTypeProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldFill,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(fabricsProvider);
          ref.invalidate(productsProvider);
        },
        color: AppColors.brand,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.fabricsSection,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.fabricsSubtitle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (v) =>
                          ref.read(fabricSearchQueryProvider.notifier).state =
                              v,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: AppColors.brand,
                      decoration: InputDecoration(
                        hintText: s.searchFabricsHint,
                        hintStyle: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.7),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.brand),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppConstants.fabricTypes.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final type = AppConstants.fabricTypes[i];
                          final selected = selectedType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: selected,
                            onSelected: (_) {
                              ref
                                  .read(selectedFabricTypeProvider.notifier)
                                  .state = type;
                            },
                            labelStyle: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            selectedColor: AppColors.brand,
                            backgroundColor: AppColors.card,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.brand
                                  : AppColors.border.withValues(alpha: 0.7),
                            ),
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            fabricsAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: ProductGridShimmer(count: 6)),
              error: (_, _) => SliverFillRemaining(
                child: ErrorView(
                  message: s.productsLoadError,
                  onRetry: () => ref.invalidate(fabricsProvider),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyView(
                      message: s.noProductsFound,
                      iconWidget: FabricIcon(
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    8,
                    14,
                    kPremiumBottomNavClearance + 24,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          index: index,
                          onTap: () => context.push(
                            '/product/${product.id}',
                            extra: productHeroTag(product.id, 'fabric', index),
                          ),
                          heroTag: productHeroTag(product.id, 'fabric', index),
                        )
                            .animate()
                            .fadeIn(
                              duration: AppAnimations.normal,
                              delay: (index * 40).ms,
                            );
                      },
                      childCount: products.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
