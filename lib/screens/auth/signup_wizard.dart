import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

/// Professional multi-step signup for customers & shop owners.
class SignupWizard extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const SignupWizard({super.key, this.onSuccess});

  @override
  ConsumerState<SignupWizard> createState() => _SignupWizardState();
}

class _SignupWizardState extends ConsumerState<SignupWizard> {
  final _pageController = PageController();
  final _stepKeys = List.generate(4, (_) => GlobalKey<FormState>());

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _shopName = TextEditingController();
  final _shopDesc = TextEditingController();
  final _shopAddress = TextEditingController();

  UserRole _role = UserRole.customer;
  ShopTier _tier = ShopTier.gold;
  int _step = 0;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  static const _stepTitles = [
    'جۆری هەژمار',
    'زانیاری کەسی',
    'ناونیشان',
    'پاراستن',
  ];

  static const _stepSubtitles = [
    'کڕیار یان خاوەن دووکان هەڵبژێرە',
    'ناو و پەیوەندی خۆت بنووسە',
    'ناونیشان بۆ گەیاندن / دووکان',
    'وشەی نهێنی دابنێ و دووبارەی بکەرەوە',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _shopName.dispose();
    _shopDesc.dispose();
    _shopAddress.dispose();
    super.dispose();
  }

  String get _step3Title =>
      _role == UserRole.customer ? 'ناونیشانی گەیاندن' : 'زانیاری دووکان';

  Future<void> _goNext() async {
    final form = _stepKeys[_step].currentState;
    if (form != null && !form.validate()) return;

    if (_step < 3) {
      HapticFeedback.selectionClick();
      setState(() => _step++);
      await _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _submit();
  }

  Future<void> _goBack() async {
    if (_step == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _step--);
    await _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    final success = await ref.read(authProvider.notifier).register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          role: _role,
          location: _role == UserRole.customer ? _address.text.trim() : null,
          shopName:
              _role == UserRole.shopOwner ? _shopName.text.trim() : null,
          shopDescription:
              _role == UserRole.shopOwner ? _shopDesc.text.trim() : null,
          shopAddress:
              _role == UserRole.shopOwner ? _shopAddress.text.trim() : null,
          shopTier: _role == UserRole.shopOwner ? _tier : null,
        );

    if (!mounted) return;

    if (success) {
      widget.onSuccess?.call();
    } else {
      final err = ref.read(authProvider).error ?? 'هەڵەیەک ڕوویدا';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final titles = [..._stepTitles];
    titles[2] = _step3Title;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: _StepHeader(
            step: _step,
            total: 4,
            title: titles[_step],
            subtitle: _step == 2
                ? (_role == UserRole.customer
                    ? 'ناونیشان پێویستە بۆ گەیاندنی داواکاری'
                    : 'وردەکاری دووکان و پڕۆفایل هەڵبژێرە')
                : _stepSubtitles[_step],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StepScroll(
                formKey: _stepKeys[0],
                child: _RoleStep(
                  role: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),
              ),
              _StepScroll(
                formKey: _stepKeys[1],
                child: _PersonalStep(
                  name: _name,
                  email: _email,
                  phone: _phone,
                ),
              ),
              _StepScroll(
                formKey: _stepKeys[2],
                child: _role == UserRole.customer
                    ? _AddressStep(address: _address)
                    : _ShopStep(
                        shopName: _shopName,
                        shopDesc: _shopDesc,
                        shopAddress: _shopAddress,
                        tier: _tier,
                        onTier: (t) => setState(() => _tier = t),
                      ),
              ),
              _StepScroll(
                formKey: _stepKeys[3],
                child: _PasswordStep(
                  password: _password,
                  confirm: _confirmPassword,
                  obscurePass: _obscurePass,
                  obscureConfirm: _obscureConfirm,
                  onTogglePass: () =>
                      setState(() => _obscurePass = !_obscurePass),
                  onToggleConfirm: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _goBack,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'پێشوو',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _step == 3
                          ? AppColors.ctaGradient
                          : AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_step == 3
                                  ? AppColors.highlight
                                  : AppColors.brand)
                              .withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == 3 ? 'دروستکردنی هەژمار' : 'هەنگاوی داهاتوو',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.step,
    required this.total,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(total, (i) {
            final active = i <= step;
            final current = i == step;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                height: current ? 5 : 4,
                margin: EdgeInsetsDirectional.only(
                  end: i == total - 1 ? 0 : 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: active ? AppColors.accentGradient : null,
                  color: active ? null : AppColors.border,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'هەنگاو ${step + 1} لە $total',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ).animate(key: ValueKey('t-$step')).fadeIn(duration: 280.ms).slideX(
              begin: 0.04,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _StepScroll extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Widget child;

  const _StepScroll({required this.formKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(key: formKey, child: child),
    );
  }
}

class _RoleStep extends StatelessWidget {
  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  const _RoleStep({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RoleOption(
          icon: Icons.shopping_bag_outlined,
          title: 'کڕیار',
          subtitle: 'گەڕان، کڕین، و گەیاندن بۆ ماڵەوە',
          selected: role == UserRole.customer,
          onTap: () => onChanged(UserRole.customer),
        ),
        const SizedBox(height: 14),
        _RoleOption(
          icon: Icons.storefront_rounded,
          title: 'خاوەن دووکان',
          subtitle: 'فرۆشتنی بەرهەم و بەڕێوەبردنی دووکان',
          selected: role == UserRole.shopOwner,
          onTap: () => onChanged(UserRole.shopOwner),
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.accentGradient : null,
            color: selected ? null : AppColors.brandWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.border,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.brand,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        height: 1.35,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected
                    ? Colors.white
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalStep extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;

  const _PersonalStep({
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'ناوی تەواو',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'ناو بنووسە' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'ئیمەیڵ',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'ئیمەیڵ بنووسە';
            if (!v.contains('@') || !v.contains('.')) {
              return 'ئیمەیڵی دروست بنووسە';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phone,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'ژمارەی مۆبایل',
            prefixIcon: Icon(Icons.phone_outlined),
            hintText: '07xxxxxxxxx',
          ),
          validator: (v) =>
              v == null || v.trim().length < 10 ? 'ژمارەی مۆبایل بنووسە' : null,
        ),
      ],
    );
  }
}

class _AddressStep extends StatelessWidget {
  final TextEditingController address;

  const _AddressStep({required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ناونیشان پێویستە بۆ گەیاندنی داواکارییەکانت.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: address,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'ناونیشانی تەواو',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: Icon(Icons.location_on_outlined),
            ),
            hintText: 'شار، گەڕەک، شەقام، ژمارەی خانوو...',
          ),
          validator: (v) => v == null || v.trim().length < 8
              ? 'ناونیشانی تەواو بنووسە'
              : null,
        ),
      ],
    );
  }
}

class _ShopStep extends StatelessWidget {
  final TextEditingController shopName;
  final TextEditingController shopDesc;
  final TextEditingController shopAddress;
  final ShopTier tier;
  final ValueChanged<ShopTier> onTier;

  const _ShopStep({
    required this.shopName,
    required this.shopDesc,
    required this.shopAddress,
    required this.tier,
    required this.onTier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: shopName,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'ناوی دووکان',
            prefixIcon: Icon(Icons.store_outlined),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'ناوی دووکان بنووسە' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: shopDesc,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'وەسفی دووکان',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Icon(Icons.description_outlined),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: shopAddress,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'ناونیشانی دووکان',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'ناونیشانی دووکان بنووسە' : null,
        ),
        const SizedBox(height: 20),
        Text(
          'جۆری پڕۆفایلی دووکان',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...ShopTier.values.map((t) {
          final selected = t == tier;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTier(t),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brand.withValues(alpha: 0.08)
                        : AppColors.brandWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.brand : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t.labelKu} · ${t.labelEn}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.subtitle,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected
                            ? AppColors.brand
                            : AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  final TextEditingController password;
  final TextEditingController confirm;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;

  const _PasswordStep({
    required this.password,
    required this.confirm,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: password,
          obscureText: obscurePass,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'وشەی نهێنی',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePass ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onTogglePass,
            ),
          ),
          validator: (v) {
            if (v == null || v.length < 6) {
              return 'لانیکەم ٦ پیت بنووسە';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirm,
          obscureText: obscureConfirm,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'دووبارەکردنەوەی وشەی نهێنی',
            prefixIcon: const Icon(Icons.lock_person_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirm ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleConfirm,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'وشەی نهێنی دووبارە بکەرەوە';
            }
            if (v != password.text) {
              return 'وشە نهێنییەکان یەک ناگرنەوە';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بۆ پاراستنی باشتر:',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _Tip('لانیکەم ٦ پیت'),
              _Tip('تێکەڵەی پیت و ژمارە باشترە'),
              _Tip('وشەی نهێنی هاوبەش مەکە'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;

  const _Tip(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_rounded, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
