import '../../providers/settings_provider.dart';

class LegalSection {
  final String title;
  final String? body;
  final List<String> bullets;

  const LegalSection({
    required this.title,
    this.body,
    this.bullets = const [],
  });
}

/// Full in-app privacy policy (matches server /privacy content).
class LegalPrivacyContent {
  final AppLanguage lang;

  const LegalPrivacyContent(this.lang);

  String get updated => switch (lang) {
        AppLanguage.english => 'Last updated August 28, 2026',
        AppLanguage.arabic => 'آخر تحديث: 28 أغسطس 2026',
        AppLanguage.kurdish => 'دوایین نوێکردنەوە: ٢٨ی ئابی ٢٠٢٦',
      };

  String get intro => switch (lang) {
        AppLanguage.english =>
          'Qopcha connects customers and shop owners in one app. This policy applies to the Qopcha mobile application and related services.',
        AppLanguage.arabic =>
          'قوپچە يربط العملاء وأصحاب المتاجر في تطبيق واحد. تنطبق هذه السياسة على تطبيق قوپچە للهاتف والخدمات المرتبطة به.',
        AppLanguage.kurdish =>
          'قۆپچە کڕیار و خاوەن دووکان لە یەک ئەپدا کۆدەکاتەوە. ئەم سیاسەتە بۆ ئەپی مۆبایلی قۆپچە و خزمەتگوزاریە پەیوەندیدارەکان جێبەجێ دەبێت.',
      };

  String get heroLead => switch (lang) {
        AppLanguage.english =>
          'Your trust matters. Here is how we collect, use, and protect your information.',
        AppLanguage.arabic =>
          'ثقتك مهمة لنا. هنا نوضح كيف نجمع معلوماتك ونستخدمها ونحميها.',
        AppLanguage.kurdish =>
          'متمانەت بۆمان گرنگە. لێرەدا ڕوون دەکەینەوە چۆن زانیاریەکانت کۆدەکەینەوە و پارێزگاریان لێدەکەین.',
      };

  String get badgeSecure => switch (lang) {
        AppLanguage.english => 'HTTPS encrypted',
        AppLanguage.arabic => 'مشفّر عبر HTTPS',
        AppLanguage.kurdish => 'پارێزراو بە HTTPS',
      };

  String get badgeNoSell => switch (lang) {
        AppLanguage.english => 'No data selling',
        AppLanguage.arabic => 'لا نبيع البيانات',
        AppLanguage.kurdish => 'نافرۆشتنی زانیاری',
      };

  List<LegalSection> get sections => switch (lang) {
        AppLanguage.english => _enSections,
        AppLanguage.arabic => _arSections,
        AppLanguage.kurdish => _kuSections,
      };

  String get contactTitle => switch (lang) {
        AppLanguage.english => 'Questions about your data?',
        AppLanguage.arabic => 'أسئلة حول بياناتك؟',
        AppLanguage.kurdish => 'پرسیارت هەیە دەربارەی زانیاریەکانت؟',
      };

  String contactBody(String email) => switch (lang) {
        AppLanguage.english =>
          'We can help with privacy requests, account deletion, or general support at $email.',
        AppLanguage.arabic =>
          'يسعدنا مساعدتك في طلبات الخصوصية أو حذف الحساب أو الدعم العام على $email.',
        AppLanguage.kurdish =>
          'ئامادەین یارمەتیت بدەین بۆ داوای تایبەتمەندی، سڕینەوەی هەژمار، یان پشتگیری گشتی لە $email.',
      };

  static const _enSections = [
    LegalSection(
      title: 'Information we collect',
      bullets: [
        'Account data — name, mobile number, email (optional), and role (customer or shop owner).',
        'Orders & commerce — products viewed, cart, orders, delivery addresses, and status updates.',
        'Location — when you allow it, for delivery and neighborhood matching.',
        'Photos & media — profile pictures and product images you upload.',
        'Device & usage — push tokens, essential app activity, and diagnostic data.',
        'Communications — support messages and one-time SMS verification codes.',
      ],
    ),
    LegalSection(
      title: 'How we use information',
      bullets: [
        'Create and secure your account, including phone verification.',
        'Process orders, coordinate payments, and manage deliveries.',
        'Show relevant products, shops, and notifications.',
        'Improve reliability, prevent abuse, and provide support.',
        'Meet legal obligations when required.',
      ],
    ),
    LegalSection(
      title: 'Sharing',
      body:
          'We do not sell your personal data. We share information only when needed to run the service:',
      bullets: [
        'Shop owners fulfilling your orders',
        'Cloud hosting and API infrastructure',
        'Firebase (Google) — authentication, messaging, storage',
        'SMS providers for verification codes',
      ],
    ),
    LegalSection(
      title: 'Retention & security',
      body:
          'We retain data while your account is active and as needed for legal or dispute purposes. We use HTTPS encryption, access controls, and industry-standard practices — though no system is perfectly secure.',
    ),
    LegalSection(
      title: 'Your choices',
      bullets: [
        'Update profile and addresses anytime in the app.',
        'Disable location or notifications in device settings.',
        'Request account deletion or ask questions via email.',
      ],
    ),
    LegalSection(
      title: 'Children & changes',
      body:
          'Qopcha is not directed at children under 13. We may update this policy; the date at the top will reflect changes.',
    ),
  ];

  static const _kuSections = [
    LegalSection(
      title: 'زانیاریەکانی کۆدەکەینەوە',
      bullets: [
        'زانیاری هەژمار — ناو، ژمارەی مۆبایل، ئیمەیڵ (ئەگەر هەبێت)، و ڕۆڵ (کڕیار یان خاوەن دووکان).',
        'داواکاری و بازرگانی — بەرهەمی بینراو، سەبەتە، داواکاری، ناونیشانی گەیاندن، و دۆخی داواکاری.',
        'شوێن — کاتێک ڕێگە دەدەیت، بۆ گەیاندن و گونجاندنی گەڕەک.',
        'وێنە و میدیا — وێنەی پرۆفایل و وێنەی بەرهەم کە دەینێریت.',
        'ئامێر و بەکارهێنان — تۆکنی ئاگاداری، چالاکی پێویستی ئەپ، و زانیاری دەستنیشانکردنی هەڵە.',
        'پەیوەندیکردن — نامەی پشتگیری و کۆدی پشتڕاستکردنەوەی SMS.',
      ],
    ),
    LegalSection(
      title: 'چۆن زانیاری بەکاردەهێنین',
      bullets: [
        'دروستکردن و پاراستنی هەژمارەکەت، لەگەڵ پشتڕاستکردنەوەی مۆبایل.',
        'جێبەجێکردنی داواکاری، ڕێکخستنی پارەدان، و بەڕێوەبردنی گەیاندن.',
        'پیشاندانی بەرهەم، دووکان، و ئاگاداری گونجاو.',
        'باشترکردنی متمانەپێکراوی، ڕێگری لە خراپ بەکارهێنان، و پێشکەشکردنی پشتگیری.',
        'جێبەجێکردنی ئەرکە یاساییەکان کاتێک پێویست بێت.',
      ],
    ),
    LegalSection(
      title: 'هاوبەشکردن',
      body:
          'ئێمە زانیاری کەسیت نافرۆشین. تەنها کاتێک پێویست بێت بۆ کارکردنی خزمەتگوزاری هاوبەشی دەکەین:',
      bullets: [
        'خاوەن دووکان کە داواکاریەکەت جێبەجێ دەکەن',
        'ژێرخانی هۆست و API',
        'Firebase (گۆگڵ) — چوونەژوورەوە، نامە، هەڵگرتن',
        'دابینکەرانی SMS بۆ کۆدی پشتڕاستکردنەوە',
      ],
    ),
    LegalSection(
      title: 'پاراستن و ئاسایش',
      body:
          'زانیاری دەپارێزین تا هەژمارەکەت چالاکە و ئەگەر بۆ مەبەستی یاسایی یان ناکۆکی پێویست بێت. HTTPS، کۆنترۆڵی دەستگەیشتن، و پێوەرە ستانداردەکان بەکاردەهێنین — بەڵام هیچ سیستەمێک ١٠٠٪ پارێزراو نییە.',
    ),
    LegalSection(
      title: 'هەڵبژاردەکانت',
      bullets: [
        'دەتوانیت پرۆفایل و ناونیشان لە ئەپدا نوێ بکەیتەوە.',
        'دەتوانیت شوێن یان ئاگاداری لە ڕێکخستنەکانی ئامێرەکەت کوژێنیتەوە.',
        'دەتوانیت داوای سڕینەوەی هەژمار بکەیت یان پرسیار لەڕێگەی ئیمەیڵ بکەیت.',
      ],
    ),
    LegalSection(
      title: 'منداڵان و گۆڕانکاریەکان',
      body:
          'قۆپچە بۆ منداڵانی خوار ١٣ ساڵ نییە. لەوانەیە ئەم سیاسەتە نوێ بکەینەوە؛ بەرواری سەرەوە گۆڕانکاریەکان پیشان دەدات.',
    ),
  ];

  static const _arSections = [
    LegalSection(
      title: 'المعلومات التي نجمعها',
      bullets: [
        'بيانات الحساب — الاسم، رقم الهاتف، البريد الإلكتروني (اختياري)، والدور (عميل أو صاحب متجر).',
        'الطلبات والتجارة — المنتجات المعروضة، السلة، الطلبات، عناوين التوصيل، وحالة الطلب.',
        'الموقع — عند السماح به، للتوصيل ومطابقة الحي.',
        'الصور والوسائط — صور الملف الشخصي وصور المنتجات التي ترفعها.',
        'الجهاز والاستخدام — رموز الإشعارات، نشاط التطبيق الضروري، وبيانات التشخيص.',
        'التواصل — رسائل الدعم ورموز التحقق عبر الرسائل النصية.',
      ],
    ),
    LegalSection(
      title: 'كيف نستخدم المعلومات',
      bullets: [
        'إنشاء حسابك وتأمينه، بما في ذلك التحقق من الهاتف.',
        'معالجة الطلبات وتنسيق المدفوعات وإدارة التوصيل.',
        'عرض المنتجات والمتاجر والإشعارات المناسبة.',
        'تحسين الموثوقية ومنع الإساءة وتقديم الدعم.',
        'الامتثال للالتزامات القانونية عند الحاجة.',
      ],
    ),
    LegalSection(
      title: 'المشاركة',
      body:
          'نحن لا نبيع بياناتك الشخصية. نشارك المعلومات فقط عند الحاجة لتشغيل الخدمة:',
      bullets: [
        'أصحاب المتاجر الذين ينفّذون طلباتك',
        'استضافة السحابة وبنية واجهة البرمجة',
        'Firebase (جوجل) — المصادقة والرسائل والتخزين',
        'مزوّدو الرسائل النصية لرموز التحقق',
      ],
    ),
    LegalSection(
      title: 'الاحتفاظ والأمان',
      body:
          'نحتفظ بالبيانات طالما حسابك نشط وكما يلزم لأغراض قانونية أو للنزاعات. نستخدم تشفير HTTPS وضوابط الوصول وممارسات قياسية — رغم أن أي نظام ليس آمناً بنسبة 100٪.',
    ),
    LegalSection(
      title: 'خياراتك',
      bullets: [
        'يمكنك تحديث الملف الشخصي والعناوين في التطبيق في أي وقت.',
        'يمكنك إيقاف الموقع أو الإشعارات من إعدادات الجهاز.',
        'يمكنك طلب حذف الحساب أو طرح أسئلة عبر البريد الإلكتروني.',
      ],
    ),
    LegalSection(
      title: 'الأطفال والتغييرات',
      body:
          'قوپچە غير موجّه للأطفال دون 13 عاماً. قد نحدّث هذه السياسة؛ سيظهر التاريخ أعلاه عند أي تغيير.',
    ),
  ];
}
