import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_content_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notifications_provider.dart';
import 'admin_shell.dart';

class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _about = TextEditingController();
  final _terms = TextEditingController();
  final _privacy = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _hours = TextEditingController();
  final _instagram = TextEditingController();
  final _facebook = TextEditingController();
  final _tiktok = TextEditingController();
  final _telegram = TextEditingController();
  final _tagline = TextEditingController();
  final _promoTitle = TextEditingController();
  final _promoSubtitle = TextEditingController();
  final _promoCta = TextEditingController();
  final _announceTitle = TextEditingController();
  final _announceBody = TextEditingController();
  String _announceCategory = 'system';

  bool _hydrated = false;
  bool _saving = false;
  bool _sendingAnnounce = false;
  String? _docStamp;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _about.dispose();
    _terms.dispose();
    _privacy.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _hours.dispose();
    _instagram.dispose();
    _facebook.dispose();
    _tiktok.dispose();
    _telegram.dispose();
    _tagline.dispose();
    _promoTitle.dispose();
    _promoSubtitle.dispose();
    _promoCta.dispose();
    _announceTitle.dispose();
    _announceBody.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    final title = _announceTitle.text.trim();
    final body = _announceBody.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ناونیشان و دەق پڕ بکەوە',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
      );
      return;
    }
    setState(() => _sendingAnnounce = true);
    try {
      await ref.read(notificationServiceProvider).announceAdminBroadcast(
            title: title,
            body: body,
            category: _announceCategory,
          );
      if (!mounted) return;
      _announceTitle.clear();
      _announceBody.clear();
      setState(() => _announceCategory = 'system');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ئاگاداری نێردرا بۆ موشتەرییەکان',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
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
            'نەتوانرا ئاگاداری بنێردرێت',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingAnnounce = false);
    }
  }

  void _hydrate(AppContentModel c) {
    final stamp = c.updatedAt.toIso8601String();
    if (_hydrated && _docStamp == stamp) return;
    _about.text = c.aboutBody;
    _terms.text = c.termsBody;
    _privacy.text = c.privacyBody;
    _phone.text = c.supportPhone;
    _whatsapp.text = c.supportWhatsapp;
    _email.text = c.supportEmail;
    _hours.text = c.supportHours;
    _instagram.text = c.socialInstagram;
    _facebook.text = c.socialFacebook;
    _tiktok.text = c.socialTikTok;
    _telegram.text = c.socialTelegram;
    _tagline.text = c.homeTagline;
    _promoTitle.text = c.homePromoTitle;
    _promoSubtitle.text = c.homePromoSubtitle;
    _promoCta.text = c.homeCta;
    _docStamp = stamp;
    _hydrated = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final content = AppContentModel(
        aboutBody: _about.text.trim(),
        termsBody: _terms.text.trim(),
        privacyBody: _privacy.text.trim(),
        supportPhone: _phone.text.trim(),
        supportWhatsapp: _whatsapp.text.trim(),
        supportEmail: _email.text.trim(),
        supportHours: _hours.text.trim(),
        socialInstagram: _instagram.text.trim(),
        socialFacebook: _facebook.text.trim(),
        socialTikTok: _tiktok.text.trim(),
        socialTelegram: _telegram.text.trim(),
        homeTagline: _tagline.text.trim(),
        homePromoTitle: _promoTitle.text.trim(),
        homePromoSubtitle: _promoSubtitle.text.trim(),
        homeCta: _promoCta.text.trim(),
        updatedAt: DateTime.now(),
      );
      await ref.read(adminServiceProvider).saveAppContent(content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ناوەڕۆک پاشەکەوت کرا',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
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
            'نەتوانرا پاشەکەوت بکرێت',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appContentProvider);
    async.whenData(_hydrate);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeader(
            title: 'ناوەڕۆکی ئەپ',
            subtitle: 'یاسایی · پشتگیری · هۆم · ئاگاداری',
            showNotifications: true,
            action: IconButton(
              onPressed: _tabs.index == 3
                  ? (_sendingAnnounce ? null : _sendAnnouncement)
                  : (_saving ? null : _save),
              tooltip: _tabs.index == 3 ? 'ناردن' : 'پاشەکەوت',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.brand.withValues(alpha: 0.10),
              ),
              icon: (_tabs.index == 3 ? _sendingAnnounce : _saving)
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.brand,
                      ),
                    )
                  : Icon(
                      _tabs.index == 3
                          ? Icons.send_rounded
                          : Icons.save_rounded,
                      color: AppColors.brand,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.9),
                ),
              ),
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.brand,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.brand,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'یاسایی'),
                  Tab(text: 'پشتگیری'),
                  Tab(text: 'هۆم'),
                  Tab(text: 'ئاگاداری'),
                ],
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (_) => TabBarView(
                controller: _tabs,
                children: [
                  _SectionScroll(
                    children: [
                      _FieldCard(
                        label: 'دەربارەی ئێمە',
                        controller: _about,
                        maxLines: 8,
                        hint: 'کورتە دەربارەی ئەپ / براند',
                      ),
                      _FieldCard(
                        label: 'مەرجەکان',
                        controller: _terms,
                        maxLines: 10,
                        hint: 'مەرجەکانی بەکارهێنان',
                      ),
                      _FieldCard(
                        label: 'سیاسەتی پاراستن',
                        controller: _privacy,
                        maxLines: 10,
                        hint: 'چۆن زانیاری کەسی بەکاردەهێنرێت',
                      ),
                    ],
                  ),
                  _SectionScroll(
                    children: [
                      _FieldCard(
                        label: 'تەلەفۆن',
                        controller: _phone,
                        maxLines: 1,
                        hint: '0750xxxxxxx',
                        keyboard: TextInputType.phone,
                      ),
                      _FieldCard(
                        label: 'واتساپ',
                        controller: _whatsapp,
                        maxLines: 1,
                        hint: '964750xxxxxxx',
                        keyboard: TextInputType.phone,
                      ),
                      _FieldCard(
                        label: 'ئیمەیڵ',
                        controller: _email,
                        maxLines: 1,
                        hint: 'support@qopcha.com',
                        keyboard: TextInputType.emailAddress,
                      ),
                      _FieldCard(
                        label: 'کاتی کارکردن',
                        controller: _hours,
                        maxLines: 2,
                        hint: '٩:٠٠ — ٢١:٠٠',
                      ),
                      const _SupportSectionLabel(title: 'سۆشیال میدیا'),
                      _FieldCard(
                        label: 'Instagram',
                        controller: _instagram,
                        maxLines: 1,
                        hint: '@Qopcha یان لینکی پڕۆفایل',
                        keyboard: TextInputType.url,
                        ltr: true,
                      ),
                      _FieldCard(
                        label: 'Facebook',
                        controller: _facebook,
                        maxLines: 1,
                        hint: 'facebook.com/Qopcha',
                        keyboard: TextInputType.url,
                        ltr: true,
                      ),
                      _FieldCard(
                        label: 'TikTok',
                        controller: _tiktok,
                        maxLines: 1,
                        hint: '@Qopcha',
                        keyboard: TextInputType.url,
                        ltr: true,
                      ),
                      _FieldCard(
                        label: 'Telegram',
                        controller: _telegram,
                        maxLines: 1,
                        hint: 't.me/Qopcha',
                        keyboard: TextInputType.url,
                        ltr: true,
                      ),
                    ],
                  ),
                  _SectionScroll(
                    children: [
                      _FieldCard(
                        label: 'تاگلاین',
                        controller: _tagline,
                        maxLines: 2,
                        hint: 'بازاڕی جلوبەرگ',
                      ),
                      _FieldCard(
                        label: 'ناونیشانی پڕۆمۆ',
                        controller: _promoTitle,
                        maxLines: 2,
                        hint: 'داشکاندن بگرە تا',
                      ),
                      _FieldCard(
                        label: 'ژێرناونیشان',
                        controller: _promoSubtitle,
                        maxLines: 3,
                        hint: 'تەنها بۆ ماوەیەکی کەم',
                      ),
                      _FieldCard(
                        label: 'دوگمەی CTA',
                        controller: _promoCta,
                        maxLines: 1,
                        hint: 'ئیستا کڕین بکە',
                      ),
                      const _HomePreviewHint(),
                    ],
                  ),
                  _AnnouncementsTab(
                    titleController: _announceTitle,
                    bodyController: _announceBody,
                    category: _announceCategory,
                    onCategoryChanged: (c) =>
                        setState(() => _announceCategory = c),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: _tabs.index == 3
                  ? (_sendingAnnounce ? null : _sendAnnouncement)
                  : (_saving ? null : _save),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.brand.withValues(alpha: 0.45),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: (_tabs.index == 3 ? _sendingAnnounce : _saving)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _tabs.index == 3
                          ? Icons.campaign_rounded
                          : Icons.check_circle_rounded,
                    ),
              label: Text(
                _tabs.index == 3
                    ? 'ناردنی ئاگاداری بۆ موشتەری'
                    : 'پاشەکەوتکردنی ناوەڕۆک',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsTab extends ConsumerWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final String category;
  final ValueChanged<String> onCategoryChanged;

  const _AnnouncementsTab({
    required this.titleController,
    required this.bodyController,
    required this.category,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(adminAnnouncementsProvider);
    const cats = [
      ('system', 'نوێکاری ئەپ'),
      ('discount', 'داشکاندن'),
      ('promo', 'ئۆفەر'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.highlight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.highlight.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppColors.highlight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ئاگاداری بۆ هەموو موشتەری و دووکاندارەکان دەنێردرێت (لە ئەپ + پوش ئەگەر چالاک بێت).',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'جۆری ئاگاداری',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in cats)
              ChoiceChip(
                label: Text(
                  c.$2,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: category == c.$1 ? Colors.white : AppColors.brand,
                  ),
                ),
                selected: category == c.$1,
                selectedColor: AppColors.brand,
                backgroundColor: AppColors.brand.withValues(alpha: 0.08),
                showCheckmark: false,
                onSelected: (_) => onCategoryChanged(c.$1),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _FieldCard(
          label: 'ناونیشان',
          controller: titleController,
          maxLines: 2,
          hint: 'هەواڵی نوێ / ئۆفەر…',
        ),
        const SizedBox(height: 12),
        _FieldCard(
          label: 'دەق',
          controller: bodyController,
          maxLines: 6,
          hint: 'پەیامەکەت بۆ کڕیارەکان…',
        ),
        const SizedBox(height: 18),
        Text(
          'دوایین ئاگادارییەکان',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        recentAsync.when(
          loading: () => Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          ),
          error: (e, _) => Text('$e'),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                ),
                child: Text(
                  'هێشتا هیچ ئاگادارییەک نەنێردراوە',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final n in list) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.9),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              Formatters.date(n.createdAt),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.body,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionScroll extends StatelessWidget {
  final List<Widget> children;

  const _SectionScroll({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          children[i],
        ],
      ],
    );
  }
}

class _SupportSectionLabel extends StatelessWidget {
  final String title;

  const _SupportSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: [
          Icon(Icons.share_rounded, size: 18, color: AppColors.brand),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: AppColors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String hint;
  final TextInputType? keyboard;
  final bool ltr;

  const _FieldCard({
    required this.label,
    required this.controller,
    required this.maxLines,
    required this.hint,
    this.keyboard,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboard,
            textDirection: ltr ? TextDirection.ltr : null,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintTextDirection: ltr ? TextDirection.ltr : null,
              filled: true,
              fillColor: AppColors.surfaceVariant.withValues(alpha: 0.65),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePreviewHint extends StatelessWidget {
  const _HomePreviewHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.brand, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ئەم دەقانە بۆ سلایدەری هۆم بەکاردێن کاتێک هیچ ڕیکلامێکی چالاک نییە. وێنەی ڕیکلام لە بەشی «ڕیکلام» دەمێنێتەوە.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
