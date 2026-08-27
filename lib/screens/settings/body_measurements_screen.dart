import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/body_measurements.dart';
import '../../providers/auth_provider.dart';

/// Lets a customer record body measurements (height, weight, waist, arm, ...)
/// so the shop can recommend the right clothing size.
class BodyMeasurementsScreen extends ConsumerStatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  ConsumerState<BodyMeasurementsScreen> createState() =>
      _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState
    extends ConsumerState<BodyMeasurementsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _shoulder = TextEditingController();
  final _chest = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController();
  final _arm = TextEditingController();
  final _leg = TextEditingController();
  final _neck = TextEditingController();
  final _shoe = TextEditingController();

  bool _didLoad = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    final m = ref.read(currentUserProvider)?.measurements ??
        BodyMeasurements.empty;
    _height.text = _format(m.heightCm);
    _weight.text = _format(m.weightKg);
    _shoulder.text = _format(m.shoulderCm);
    _chest.text = _format(m.chestCm);
    _waist.text = _format(m.waistCm);
    _hip.text = _format(m.hipCm);
    _arm.text = _format(m.armLengthCm);
    _leg.text = _format(m.legLengthCm);
    _neck.text = _format(m.neckCm);
    _shoe.text = _format(m.shoeSizeEu);
    for (final c in _controllers) {
      c.addListener(_onFieldChanged);
    }
  }

  List<TextEditingController> get _controllers => [
        _height,
        _weight,
        _shoulder,
        _chest,
        _waist,
        _hip,
        _arm,
        _leg,
        _neck,
        _shoe,
      ];

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  static String _format(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  double? _read(TextEditingController controller) {
    final text = controller.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// Live preview so the suggested size updates while typing.
  BodyMeasurements get _draft => BodyMeasurements(
        heightCm: _read(_height),
        weightKg: _read(_weight),
        shoulderCm: _read(_shoulder),
        chestCm: _read(_chest),
        waistCm: _read(_waist),
        hipCm: _read(_hip),
        armLengthCm: _read(_arm),
        legLengthCm: _read(_leg),
        neckCm: _read(_neck),
        shoeSizeEu: _read(_shoe),
      );

  String? _validateRange(String? value, double min, double max) {
    final text = (value ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'تەنها ژمارە بنووسە';
    if (parsed < min || parsed > max) {
      return 'نێوان ${_format(min)} و ${_format(max)}';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    HapticFeedback.lightImpact();
    setState(() => _saving = true);

    final updated = user.copyWith(
      measurements: _draft.copyWith(updatedAt: DateTime.now()),
      preferredSize: _draft.suggestedSize ?? user.preferredSize,
    );
    final ok = await ref.read(authProvider.notifier).updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      _toast(
        ref.read(authProvider).error?.replaceFirst('Exception: ', '') ??
            'نەتوانرا قیاسەکان پاشەکەوت بکرێن',
        error: true,
      );
      return;
    }

    context.pop();
    _toast('قیاسەکانت پاشەکەوت کران');
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: error ? AppColors.error : AppColors.brand,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openGuide() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _MeasureGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final draft = _draft;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Text(
            'تکایە بچۆ ژوورەوە',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _Header(
            completion: draft.completion,
            filled: draft.filledCount,
            total: draft.totalCount,
            suggestedSize: draft.suggestedSize,
            onBack: () => context.pop(),
            onGuide: _openGuide,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(18, 18, 18, 28 + bottom),
                children: [
                  _SectionLabel('پێکهاتەی جەستە'),
                  const SizedBox(height: 10),
                  _MeasureCard(
                    children: [
                      _MeasureField(
                        icon: Icons.height_rounded,
                        label: 'درێژی باڵا',
                        hint: 'بۆ نموونە ١٧٥',
                        unit: 'سم',
                        controller: _height,
                        validator: (v) => _validateRange(v, 80, 230),
                      ),
                      const _RowDivider(),
                      _MeasureField(
                        icon: Icons.monitor_weight_outlined,
                        label: 'کێش',
                        hint: 'بۆ نموونە ٧٢',
                        unit: 'کگم',
                        controller: _weight,
                        validator: (v) => _validateRange(v, 25, 250),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel('قیاسی جل'),
                  const SizedBox(height: 10),
                  _MeasureCard(
                    children: [
                      _MeasureField(
                        icon: Icons.open_in_full_rounded,
                        label: 'پانی شان',
                        hint: 'لە شانێک بۆ شانی تر',
                        unit: 'سم',
                        controller: _shoulder,
                        validator: (v) => _validateRange(v, 25, 80),
                      ),
                      const _RowDivider(),
                      _MeasureField(
                        icon: Icons.accessibility_new_rounded,
                        label: 'دەوری سنگ',
                        hint: 'بەسەر پانترین شوێنی سنگ',
                        unit: 'سم',
                        controller: _chest,
                        validator: (v) => _validateRange(v, 55, 170),
                      ),
                      const _RowDivider(),
                      _MeasureField(
                        icon: Icons.straighten_rounded,
                        label: 'دەوری کەمەر',
                        hint: 'باریکترین شوێنی ناوقەد',
                        unit: 'سم',
                        controller: _waist,
                        validator: (v) => _validateRange(v, 45, 170),
                      ),
                      const _RowDivider(),
                      _MeasureField(
                        icon: Icons.crop_square_rounded,
                        label: 'دەوری کەڵک',
                        hint: 'پانترین شوێنی سمت',
                        unit: 'سم',
                        controller: _hip,
                        validator: (v) => _validateRange(v, 50, 180),
                      ),
                      const _RowDivider(),
                      _MeasureField(
                        icon: Icons.swipe_right_alt_rounded,
                        label: 'درێژی قۆل',
                        hint: 'لە شان بۆ مەچەک',
                        unit: 'سم',
                        controller: _arm,
                        validator: (v) => _validateRange(v, 30, 100),
                      ),
                      const _RowDivider(),
                      _MeasureField(
                        icon: Icons.straighten_outlined,
                        label: 'درێژی قاچ',
                        hint: 'لە کەمەر بۆ پێ',
                        unit: 'سم',
                        controller: _leg,
                        validator: (v) => _validateRange(v, 40, 130),
                      ),
                      const _RowDivider(),
                      _MeasureField(
                        icon: Icons.rotate_90_degrees_ccw_rounded,
                        label: 'دەوری مل',
                        hint: 'بۆ کراس و قەمیس',
                        unit: 'سم',
                        controller: _neck,
                        validator: (v) => _validateRange(v, 25, 60),
                      ),
                      const _RowDivider(),
                      _MeasureField(
                        icon: Icons.ice_skating_rounded,
                        label: 'قەبارەی پێڵاو',
                        hint: 'بۆ نموونە ٤٢',
                        unit: 'EU',
                        controller: _shoe,
                        validator: (v) => _validateRange(v, 20, 55),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SummaryCard(measurements: draft),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.textTertiary.withValues(alpha: 0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        'پاشەکەوتکردنی قیاسەکان',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double completion;
  final int filled;
  final int total;
  final String? suggestedSize;
  final VoidCallback onBack;
  final VoidCallback onGuide;

  const _Header({
    required this.completion,
    required this.filled,
    required this.total,
    required this.suggestedSize,
    required this.onBack,
    required this.onGuide,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 6, 16, 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قیاسی جەستەم',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'قیاسەکان تۆمار بکە بۆ کڕینی جلی گونجاو',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onGuide,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.help_outline_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$filled لە $total خانە پڕکراوە',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: completion,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'قەبارەی پێشنیارکراو',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestedSize ?? '—',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.w900,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MeasureCard extends StatelessWidget {
  final List<Widget> children;
  const _MeasureCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border.withValues(alpha: 0.55),
    );
  }
}

class _MeasureField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final String unit;
  final TextEditingController controller;
  final String? Function(String?) validator;

  const _MeasureField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.unit,
    required this.controller,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  hint,
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
          const SizedBox(width: 10),
          SizedBox(
            width: 104,
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: '—',
                hintStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
                suffixText: unit,
                suffixStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
                errorStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant.withValues(alpha: 0.55),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.brand, width: 1.35),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BodyMeasurements measurements;

  const _SummaryCard({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final size = measurements.suggestedSize;
    final bmi = measurements.bmi;

    if (size == null && bmi == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'دەوری سنگ یان کەمەر بنووسە تا قەبارەی گونجاو پێشنیار بکەین.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checkroom_rounded, size: 20, color: AppColors.brand),
              const SizedBox(width: 8),
              Text(
                'پێشنیاری قەبارە',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (size != null)
            Text(
              'بەپێی قیاسەکانت، قەبارەی $size گونجاوترە بۆت.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          if (bmi != null) ...[
            const SizedBox(height: 6),
            Text(
              'ڕێژەی کێش بۆ باڵا (BMI): ${bmi.toStringAsFixed(1)}',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MeasureGuideSheet extends StatelessWidget {
  const _MeasureGuideSheet();

  static const _steps = [
    (
      Icons.height_rounded,
      'درێژی باڵا',
      'بێ پێڵاو، پشتت بدە بە دیوار و لە سەری سەرەوە تا زەوی بپێوە.',
    ),
    (
      Icons.accessibility_new_rounded,
      'دەوری سنگ',
      'مێتەرەکە بەسەر پانترین شوێنی سنگ ببە، ئاسۆیی و شل بێت.',
    ),
    (
      Icons.straighten_rounded,
      'دەوری کەمەر',
      'باریکترین شوێنی ناوقەد بپێوە، هەناسەت مەگرە.',
    ),
    (
      Icons.crop_square_rounded,
      'دەوری کەڵک',
      'پانترین شوێنی سمت بپێوە، هەردوو قاچ پێکەوە بێت.',
    ),
    (
      Icons.swipe_right_alt_rounded,
      'درێژی قۆل',
      'لە سەری شان تا مەچەک، قۆلەکە کەمێک چەماوە بێت.',
    ),
    (
      Icons.straighten_outlined,
      'درێژی قاچ',
      'لە کەمەر بۆ خوارەوە تا سەری پێ بپێوە.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'چۆن قیاس بکەم؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'مێتەری دەرزی بەکاربهێنە و جلی تەنک لەبەرت بێت',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            for (final step in _steps) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(step.$1, size: 20, color: AppColors.brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$2,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.$3,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
