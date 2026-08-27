import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'pd_theme.dart';

class ProductGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int discountPercent;
  final String? heroTag;
  final ValueNotifier<int> imageIndex;
  final bool fullBleed;

  const ProductGallery({
    super.key,
    required this.imageUrls,
    required this.discountPercent,
    required this.imageIndex,
    this.heroTag,
    this.fullBleed = true,
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  late final PageController _pageController;
  bool _zooming = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.imageIndex.value);
    widget.imageIndex.addListener(_onIndexFromOutside);
  }

  void _onIndexFromOutside() {
    final i = widget.imageIndex.value;
    if (_pageController.hasClients &&
        (_pageController.page?.round() ?? 0) != i) {
      _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    widget.imageIndex.removeListener(_onIndexFromOutside);
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    widget.imageIndex.value = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _placeholder({IconData icon = Icons.image_not_supported_rounded}) {
    return ColoredBox(
      color: PdColors.gray,
      child: Icon(icon, color: PdColors.textTertiary, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;
    final count = images.isEmpty ? 1 : images.length;
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.56,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: widget.heroTag ?? 'product-gallery-hero',
            child: Material(
              color: PdColors.gray,
              child: PageView.builder(
                controller: _pageController,
                physics: _zooming
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: count,
                onPageChanged: (i) => widget.imageIndex.value = i,
                itemBuilder: (context, i) {
                  final url = images.isEmpty ? '' : images[i];
                  return GestureDetector(
                    onDoubleTap: () => setState(() => _zooming = !_zooming),
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 3.2,
                      onInteractionStart: (_) {
                        if (!_zooming) setState(() => _zooming = true);
                      },
                      child: url.isEmpty
                          ? _placeholder()
                          : CachedNetworkImage(
                              key: ValueKey(url),
                              imageUrl: url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (_, _) => ColoredBox(
                                color: PdColors.gray,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: PdColors.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (_, _, _) => _placeholder(),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Top scrim keeps the floating back/share/favorite buttons readable.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + 96,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom scrim blends the image into the content sheet.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 190,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
          ),

          if (widget.discountPercent > 0)
            Positioned(
              top: top + 68,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PdColors.accent,
                      Color.lerp(PdColors.accent, Colors.black, 0.22) ??
                          PdColors.accent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: PdColors.accent.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  '${widget.discountPercent}٪-',
                  textDirection: TextDirection.ltr,
                  style: PdTheme.label(
                    size: 12,
                    weight: FontWeight.w900,
                    color: PdColors.white,
                  ),
                ),
              ),
            ),

          if (count > 1)
            Positioned(
              top: top + 68,
              left: 16,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.imageIndex,
                builder: (context, index, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      '${index + 1} / $count',
                      textDirection: TextDirection.ltr,
                      style: PdTheme.label(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: PdColors.white,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Thumbnails float over the photo so they never clash with the sheet.
          if (count > 1)
            Positioned(
              left: 16,
              right: 16,
              bottom: 46,
              child: SizedBox(
                height: 56,
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.imageIndex,
                  builder: (context, selected, _) {
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: count,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final isSelected = i == selected;
                        return GestureDetector(
                          onTap: () => _goTo(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            width: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                                width: isSelected ? 2.4 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 240),
                                opacity: isSelected ? 1 : 0.62,
                                child: CachedNetworkImage(
                                  imageUrl: images[i],
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) =>
                                      ColoredBox(color: PdColors.gray),
                                  errorWidget: (_, _, _) =>
                                      _placeholder(icon: Icons.image_rounded),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
