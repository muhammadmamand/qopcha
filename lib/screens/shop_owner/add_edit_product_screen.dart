import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/product_image.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  final bool isFabric;

  const AddEditProductScreen({
    super.key,
    this.productId,
    this.isFabric = false,
  });

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
  final _metersController = TextEditingController(text: '10');
  final _widthController = TextEditingController(text: '150');
  final _weightController = TextEditingController();
  final _originController = TextEditingController();
  final _careController = TextEditingController();

  late List<String> _categoryOptions;
  late List<String> _colorOptions;
  late bool _isFabric;
  String _category = AppConstants.categories[1];
  String _fabricType = AppConstants.fabricTypes[1];
  String _fabricQuality = AppConstants.fabricQualities[1];
  String _fabricPattern = AppConstants.fabricPatterns[0];
  final Set<String> _selectedColors = {AppConstants.colors[0]};
  bool _isFeatured = false;
  String _discountType = DiscountKind.percent;
  double _discountPercent = 0;
  final _discountAmountCtrl = TextEditingController();
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
    _isFabric = widget.isFabric;
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
    _priceController.text = Formatters.grouped(product.price);
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
      _discountType = product.discountType == DiscountKind.amount
          ? DiscountKind.amount
          : DiscountKind.percent;
      _discountPercent = product.discountPercent.clamp(0, 70).toDouble();
      _discountAmountCtrl.text = product.discountAmount > 0
          ? Formatters.grouped(product.discountAmount.round())
          : '';
      _isFabric = product.isFabric;
      if (product.isFabric) {
        _fabricType = product.fabricType.isNotEmpty
            ? product.fabricType
            : AppConstants.fabricTypes[1];
        _fabricQuality = product.fabricQuality.isNotEmpty
            ? product.fabricQuality
            : AppConstants.fabricQualities[1];
        _fabricPattern = product.fabricPattern.isNotEmpty
            ? product.fabricPattern
            : AppConstants.fabricPatterns[0];
        _metersController.text = '${product.totalStock}';
        if (product.fabricWidthCm > 0) {
          _widthController.text = product.fabricWidthCm.toStringAsFixed(0);
        }
        if (product.fabricWeightGsm > 0) {
          _weightController.text = '${product.fabricWeightGsm}';
        }
        _originController.text = product.fabricOrigin;
        _careController.text = product.fabricCare;
      }
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
    _discountAmountCtrl.dispose();
    _imageUrlController.dispose();
    _customColorController.dispose();
    _customCategoryController.dispose();
    _metersController.dispose();
    _widthController.dispose();
    _weightController.dispose();
    _originController.dispose();
    _careController.dispose();
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
    if (_isFabric) {
      final meters = int.tryParse(_metersController.text.trim()) ?? 0;
      if (meters <= 0) {
        _showError('ژمارەی مەتری بەردەست بنووسە');
        return;
      }
      sizeStocks.add(
        SizeStock(size: AppConstants.fabricStockUnit, quantity: meters),
      );
    } else {
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
    }

    if (_images.isEmpty) {
      _showError('لانیکەم یەک وێنە زیاد بکە');
      return;
    }

    final price = Formatters.parseAmount(_priceController.text);
    if (price == null || price <= 0) {
      _showError('نرخی دروست بنووسە');
      return;
    }

    setState(() => _isLoading = true);

    final product = ProductModel(
      id: widget.productId ?? '',
      shopOwnerId: user.id,
      shopName: user.shopName ?? user.name,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _isFabric ? 'قوماش' : _category,
      price: price,
      colors: _selectedColors.toList(),
      material: _materialController.text.trim(),
      brand: _brandController.text.trim(),
      imageUrls: List<String>.from(_images),
      sizeStocks: sizeStocks,
      productType: _isFabric ? ProductKind.fabric : ProductKind.clothing,
      fabricType: _isFabric ? _fabricType : '',
      fabricQuality: _isFabric ? _fabricQuality : '',
      fabricWidthCm: _isFabric
          ? (double.tryParse(_widthController.text.trim()) ?? 0)
          : 0,
      fabricWeightGsm: _isFabric
          ? (int.tryParse(_weightController.text.trim()) ?? 0)
          : 0,
      fabricPattern: _isFabric ? _fabricPattern : '',
      fabricOrigin: _isFabric ? _originController.text.trim() : '',
      fabricCare: _isFabric ? _careController.text.trim() : '',
      isFeatured: _isFeatured,
      discountType: _discountType,
      discountPercent:
          _discountType == DiscountKind.percent ? _discountPercent : 0,
      discountAmount: _discountType == DiscountKind.amount
          ? (Formatters.parseAmount(_discountAmountCtrl.text.trim()) ?? 0)
          : 0,
      discountForAllCustomers: true,
      discountCustomerIds: const [],
      discountSetBy: (_discountType == DiscountKind.amount
              ? (Formatters.parseAmount(_discountAmountCtrl.text.trim()) ?? 0) > 0
              : _discountPercent > 0)
          ? 'shop'
          : '',
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
    final title = widget.isEditing
        ? (_isFabric ? 'دەستکاری قوماش' : 'دەستکاری بەرهەم')
        : (_isFabric ? 'قوماشی نوێ' : 'بەرهەمی نوێ');
    final subtitle = widget.isEditing
        ? 'زانیارییەکان نوێ بکەرەوە'
        : (_isFabric
            ? 'قوماش بڵاوبکەرەوە بۆ فرۆشتن بە مەتر'
            : 'بەرهەمێکی نوێ بۆ دووکانەکەت زیاد بکە');

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
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: false,
                                ),
                                textDirection: TextDirection.ltr,
                                inputFormatters: [
                                  ThousandsSeparatorFormatter(),
                                ],
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: _isFabric
                                      ? 'نرخ بۆ هەر مەترێک (IQD) *'
                                      : 'نرخ (IQD) *',
                                  hintText: '25,000',
                                  prefixIcon: const Icon(Icons.payments_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'نرخ بنووسە';
                                  }
                                  final amount = Formatters.parseAmount(v);
                                  if (amount == null || amount <= 0) {
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
                        const SizedBox(height: 16),
                        _ShopDiscountEditor(
                          type: _discountType,
                          percent: _discountPercent,
                          amountController: _discountAmountCtrl,
                          price: Formatters.parseAmount(_priceController.text) ?? 0,
                          onTypeChanged: (value) =>
                              setState(() => _discountType = value),
                          onPercentChanged: (value) =>
                              setState(() => _discountPercent = value),
                          onAmountChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _materialController,
                          decoration: InputDecoration(
                            labelText: _isFabric
                                ? 'پێکهاتە (نموونە: ١٠٠٪ کتان)'
                                : 'ماددە (قوماش)',
                            prefixIcon: const Icon(Icons.texture_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isFabric)
                    _SectionCard(
                      index: 1,
                      title: 'وردەکاری قوماش',
                      icon: Icons.texture_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'جۆر',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppConstants.fabricTypes
                                .where((t) => t != 'هەموو')
                                .map(
                                  (type) => _ChoiceChip(
                                    label: type,
                                    selected: _fabricType == type,
                                    onTap: () =>
                                        setState(() => _fabricType = type),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'کوالێتی',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppConstants.fabricQualities
                                .map(
                                  (q) => _ChoiceChip(
                                    label: q,
                                    selected: _fabricQuality == q,
                                    onTap: () =>
                                        setState(() => _fabricQuality = q),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'نەخش',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppConstants.fabricPatterns
                                .map(
                                  (p) => _ChoiceChip(
                                    label: p,
                                    selected: _fabricPattern == p,
                                    onTap: () =>
                                        setState(() => _fabricPattern = p),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _widthController,
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr,
                                  decoration: const InputDecoration(
                                    labelText: 'پانی (سم)',
                                    prefixIcon:
                                        Icon(Icons.straighten_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr,
                                  decoration: const InputDecoration(
                                    labelText: 'کێش (GSM)',
                                    prefixIcon: Icon(Icons.fitness_center_outlined),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _originController,
                            decoration: const InputDecoration(
                              labelText: 'وڵاتی بەرهەمهێنان',
                              prefixIcon: Icon(Icons.public_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _careController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'چۆنیەتی پاراستن / شۆردن',
                              prefixIcon: Icon(Icons.local_laundry_service_outlined),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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
                  if (_isFabric)
                    _SectionCard(
                      index: 4,
                      title: 'کۆگا (مەتر)',
                      icon: Icons.straighten_rounded,
                      child: TextFormField(
                        controller: _metersController,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'چەند مەتر بەردەستە *',
                          prefixIcon: Icon(Icons.layers_outlined),
                          hintText: 'نموونە: ٥٠',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) {
                            return 'ژمارەی مەتر بنووسە';
                          }
                          return null;
                        },
                      ),
                    )
                  else
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
      decoration: BoxDecoration(
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
                    ? Padding(
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
                style: TextStyle(
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
              style: TextStyle(
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
              focusedBorder: OutlineInputBorder(
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

class _ShopDiscountEditor extends StatelessWidget {
  final String type;
  final double percent;
  final TextEditingController amountController;
  final double price;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<double> onPercentChanged;
  final VoidCallback onAmountChanged;

  const _ShopDiscountEditor({
    required this.type,
    required this.percent,
    required this.amountController,
    required this.price,
    required this.onTypeChanged,
    required this.onPercentChanged,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAmount = type == DiscountKind.amount;
    final amount = Formatters.parseAmount(amountController.text.trim()) ?? 0;
    final sale = isAmount
        ? (price - amount).clamp(0, price).toDouble()
        : (price <= 0 ? 0.0 : price * (1 - percent.clamp(0, 70) / 100));
    final active = isAmount ? amount > 0 : percent > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.highlight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.highlight.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'داشکاندن بۆ هەموو کڕیارەکان',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _DiscountTypeTab(
                  label: 'ڕێژە ٪',
                  selected: !isAmount,
                  onTap: () => onTypeChanged(DiscountKind.percent),
                ),
                _DiscountTypeTab(
                  label: 'بڕ IQD',
                  selected: isAmount,
                  onTap: () => onTypeChanged(DiscountKind.amount),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isAmount)
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              textDirection: TextDirection.ltr,
              inputFormatters: [ThousandsSeparatorFormatter()],
              onChanged: (_) => onAmountChanged(),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'چەند دینار دەکەیتەوە لە نرخ',
                hintText: 'نموونە: 5,000',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                  color: AppColors.highlight,
                ),
                filled: true,
                fillColor: AppColors.card,
              ),
            )
          else ...[
            Row(
              children: [
                Icon(Icons.percent_rounded, size: 18, color: AppColors.highlight),
                const Spacer(),
                Text(
                  '${percent.round()}٪',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    color: AppColors.highlight,
                  ),
                ),
              ],
            ),
            Slider(
              value: percent,
              min: 0,
              max: 70,
              divisions: 14,
              activeColor: AppColors.highlight,
              onChanged: onPercentChanged,
            ),
          ],
          const SizedBox(height: 8),
          if (active && price > 0)
            Text(
              'نرخی دوای داشکاندن: ${Formatters.price(sale)}',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            )
          else
            Text(
              isAmount
                  ? 'ژمارەی دینار بنووسە بۆ داشکاندن لە نرخ'
                  : '٠٪ واتە بەبێ داشکاندن دەفرۆشرێت',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscountTypeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DiscountTypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.highlight : AppColors.textTertiary,
            ),
          ),
        ),
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
