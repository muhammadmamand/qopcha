import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/product_image.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AddEditProductScreen({super.key, this.productId});

  bool get isEditing => productId != null;

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _materialController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _customColorController = TextEditingController();
  final _customCategoryController = TextEditingController();

  late List<String> _categoryOptions;
  late List<String> _colorOptions;
  String _category = AppConstants.categories[1];
  final Set<String> _selectedColors = {AppConstants.colors[0]};
  bool _isFeatured = false;
  bool _isLoading = false;
  bool _isPickingImage = false;
  final List<String> _images = [];
  final _imageStorage = ImageStorageService();
  final _picker = ImagePicker();

  final Map<String, TextEditingController> _sizeControllers = {};

  @override
  void initState() {
    super.initState();
    _categoryOptions =
        AppConstants.categories.where((c) => c != 'هەموو').toList();
    _colorOptions = List<String>.from(AppConstants.colors);
    for (final size in AppConstants.sizes) {
      _sizeControllers[size] = TextEditingController(text: '0');
    }
    if (widget.isEditing) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final product = await ref
        .read(productServiceProvider)
        .getProductById(widget.productId!);
    if (product == null || !mounted) return;

    _nameController.text = product.name;
    _descController.text = product.description;
    _priceController.text = product.price.toStringAsFixed(0);
    _brandController.text = product.brand;
    _materialController.text = product.material;
    setState(() {
      _images
        ..clear()
        ..addAll(product.imageUrls);
      if (!_categoryOptions.contains(product.category)) {
        _categoryOptions = [..._categoryOptions, product.category];
      }
      _category = product.category;
      _selectedColors
        ..clear()
        ..addAll(product.colors);
      for (final color in product.colors) {
        if (!_colorOptions.contains(color)) {
          _colorOptions.add(color);
        }
      }
      if (_selectedColors.isEmpty) {
        _selectedColors.add(AppConstants.colors[0]);
      }
      _isFeatured = product.isFeatured;
      for (final ss in product.sizeStocks) {
        if (_sizeControllers.containsKey(ss.size)) {
          _sizeControllers[ss.size]!.text = ss.quantity.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _materialController.dispose();
    _imageUrlController.dispose();
    _customColorController.dispose();
    _customCategoryController.dispose();
    for (final c in _sizeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      if (source == ImageSource.gallery) {
        final files = await _picker.pickMultiImage(imageQuality: 85);
        if (files.isEmpty) return;
        for (final file in files) {
          final saved = await _imageStorage.persistPickedImage(file.path);
          if (!mounted) return;
          setState(() => _images.add(saved));
        }
      } else {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (file == null) return;
        final saved = await _imageStorage.persistPickedImage(file.path);
        if (!mounted) return;
        setState(() => _images.add(saved));
      }
    } catch (_) {
      if (!mounted) return;
      _showError('نەتوانرا وێنە هەڵبژێردرێت. مۆڵەتەکان بپشکنە.');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _addImageFromUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showError('لینکی دروست بنووسە (http/https)');
      return;
    }
    setState(() {
      _images.add(url);
      _imageUrlController.clear();
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _addCustomColor() {
    final value = _customColorController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_colorOptions.contains(value)) {
        _colorOptions.add(value);
      }
      _selectedColors.add(value);
      _customColorController.clear();
    });
  }

  void _addCustomCategory() {
    final value = _customCategoryController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_categoryOptions.contains(value)) {
        _categoryOptions.add(value);
      }
      _category = value;
      _customCategoryController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (_selectedColors.isEmpty) {
      _showError('لانیکەم یەک ڕەنگ هەڵبژێرە');
      return;
    }

    final sizeStocks = <SizeStock>[];
    for (final entry in _sizeControllers.entries) {
      final qty = int.tryParse(entry.value.text) ?? 0;
      if (qty > 0) {
        sizeStocks.add(SizeStock(size: entry.key, quantity: qty));
      }
    }

    if (sizeStocks.isEmpty) {
      _showError('لانیکەم یەک قیاس بە ژمارەی بەردەست زیاد بکە');
      return;
    }

    if (_images.isEmpty) {
      _showError('لانیکەم یەک وێنە زیاد بکە');
      return;
    }

    setState(() => _isLoading = true);

    final product = ProductModel(
      id: widget.productId ?? '',
      shopOwnerId: user.id,
      shopName: user.shopName ?? user.name,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      price: double.parse(_priceController.text),
      colors: _selectedColors.toList(),
      material: _materialController.text.trim(),
      brand: _brandController.text.trim(),
      imageUrls: List<String>.from(_images),
      sizeStocks: sizeStocks,
      isFeatured: _isFeatured,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(productNotifierProvider.notifier);
    final success = widget.isEditing
        ? await notifier.updateProduct(product)
        : await notifier.addProduct(product);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'بەرهەم نوێکرایەوە' : 'بەرهەم زیادکرا',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } else {
      _showError('هەڵە لە پاشەکەوتکردن');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'دەستکاری بەرهەم' : 'بەرهەمی نوێ';
    final subtitle = widget.isEditing
        ? 'زانیارییەکان نوێ بکەرەوە'
        : 'بەرهەمێکی نوێ بۆ دووکانەکەت زیاد بکە';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _FormHeader(
            title: title,
            subtitle: subtitle,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  _SectionCard(
                    index: 0,
                    title: 'زانیاری سەرەکی',
                    icon: Icons.info_outline_rounded,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'ناوی بەرهەم *',
                            prefixIcon: Icon(Icons.label_outline_rounded),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'ناو بنووسە' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'وەسفی تەواو *',
                            prefixIcon: Icon(Icons.description_outlined),
                            alignLabelWithHint: true,
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'وەسف بنووسە' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'نرخ (IQD) *',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'نرخ بنووسە';
                                  }
                                  if (double.tryParse(v) == null) {
                                    return 'نرخی دروست';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _brandController,
                                decoration: const InputDecoration(
                                  labelText: 'براند',
                                  prefixIcon: Icon(Icons.storefront_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _materialController,
                          decoration: const InputDecoration(
                            labelText: 'ماددە (قوماش)',
                            prefixIcon: Icon(Icons.texture_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    index: 1,
                    title: 'جۆری جلوبەرگ',
                    icon: Icons.category_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جۆرێک هەڵبژێرە یان جۆرێکی نوێ زیاد بکە',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categoryOptions.asMap().entries.map((e) {
                            final category = e.value;
                            final selected = _category == category;
                            return _ChoiceChip(
                              label: category,
                              selected: selected,
                              onTap: () => setState(() => _category = category),
                            )
                                .animate()
                                .fadeIn(delay: (30 * e.key).ms)
                                .scale(
                                  begin: const Offset(0.92, 0.92),
                                  curve: Curves.easeOutBack,
                                );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        _AddCustomRow(
                          controller: _customCategoryController,
                          hint: 'جۆری نوێ (نموونە: شال)',
                          onAdd: _addCustomCategory,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    index: 2,
                    title: 'ڕەنگەکان',
                    icon: Icons.palette_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'دەتوانیت چەند ڕەنگێک هەڵبژێریت',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _colorOptions.asMap().entries.map((e) {
                            final color = e.value;
                            final selected = _selectedColors.contains(color);
                            return _ChoiceChip(
                              label: color,
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    if (_selectedColors.length > 1) {
                                      _selectedColors.remove(color);
                                    }
                                  } else {
                                    _selectedColors.add(color);
                                  }
                                });
                              },
                            )
                                .animate()
                                .fadeIn(delay: (25 * e.key).ms)
                                .scale(
                                  begin: const Offset(0.92, 0.92),
                                  curve: Curves.easeOutBack,
                                );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        _AddCustomRow(
                          controller: _customColorController,
                          hint: 'ڕەنگی نوێ (نموونە: زێڕین)',
                          onAdd: _addCustomColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    index: 3,
                    title: 'وێنە',
                    icon: Icons.image_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لە مۆبایل وێنە هەڵبژێرە یان لینک زیاد بکە',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ImagePickButton(
                                icon: Icons.photo_library_rounded,
                                label: 'گەلەری',
                                onTap: _isPickingImage
                                    ? null
                                    : () => _pickImages(ImageSource.gallery),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ImagePickButton(
                                icon: Icons.photo_camera_rounded,
                                label: 'کامێرا',
                                onTap: _isPickingImage
                                    ? null
                                    : () => _pickImages(ImageSource.camera),
                              ),
                            ),
                          ],
                        ),
                        if (_isPickingImage) ...[
                          const SizedBox(height: 12),
                          const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (_images.isEmpty)
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 34,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'هێشتا وێنە زیاد نەکراوە',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final path = _images[index];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: ProductImage(
                                        path: path,
                                        width: 110,
                                        height: 110,
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Material(
                                        color: Colors.black54,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () => _removeImage(index),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        bottom: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'سەرەکی',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _imageUrlController,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'یان لینکی وێنە',
                                  prefixIcon: Icon(Icons.link_rounded),
                                  isDense: true,
                                  hintText: 'https://...',
                                ),
                                onSubmitted: (_) => _addImageFromUrl(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _addImageFromUrl,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                ),
                                child: const Text('زیادکردن'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    index: 4,
                    title: 'قیاس و کۆگا',
                    icon: Icons.straighten_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ژمارەی بەردەست بۆ هەر قیاسێک (٠ = بەردەست نییە)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AppConstants.sizes.asMap().entries.map((e) {
                            final size = e.value;
                            return _SizeStockField(
                              size: size,
                              controller: _sizeControllers[size]!,
                            )
                                .animate()
                                .fadeIn(delay: (40 * e.key).ms)
                                .slideY(begin: 0.12);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FeaturedToggle(
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                  )
                      .animate()
                      .fadeIn(delay: 280.ms)
                      .slideY(begin: 0.08),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _SaveBar(
        isEditing: widget.isEditing,
        isLoading: _isLoading,
        onSave: _save,
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _FormHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_shopping_cart_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08);
  }
}

class _SectionCard extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.index,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (70 * index).ms, duration: 420.ms)
        .slideY(begin: 0.08, curve: Curves.easeOutCubic);
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? const Padding(
                        key: ValueKey('check'),
                        padding: EdgeInsetsDirectional.only(end: 6),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: AppColors.secondary,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.secondary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ImagePickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.secondary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCustomRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;

  const _AddCustomRow({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              prefixIcon: const Icon(Icons.add_rounded),
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('زیادکردن'),
          ),
        ),
      ],
    );
  }
}

class _SizeStockField extends StatelessWidget {
  final String size;
  final TextEditingController controller;

  const _SizeStockField({
    required this.size,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              size,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              isDense: true,
              hintText: '0',
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                borderSide: BorderSide(color: AppColors.secondary, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FeaturedToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.secondary,
        title: Text(
          'بەرهەمی تایبەت',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'لە پەڕەی سەرەکیدا پیشان بدرێت',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.star_rounded, color: AppColors.gold),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  final bool isEditing;
  final bool isLoading;
  final VoidCallback onSave;

  const _SaveBar({
    required this.isEditing,
    required this.isLoading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onSave,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
          label: Text(isEditing ? 'نوێکردنەوە' : 'زیادکردنی بەرهەم'),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
