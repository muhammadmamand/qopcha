import '../../providers/settings_provider.dart';
import 'legal_privacy_content.dart';

/// Full in-app About Us page for Qopcha.
class LegalAboutContent {
  final AppLanguage lang;

  const LegalAboutContent(this.lang);

  String get heroLead => switch (lang) {
        AppLanguage.english =>
          'Your modern clothing marketplace — discover local fashion, support Iraqi shops, and shop with confidence.',
        AppLanguage.arabic =>
          'سوقك العصري للملابس — اكتشف الموضة المحلية، ادعم المتاجر العراقية، وتسوق بثقة.',
        AppLanguage.kurdish =>
          'بازاڕی مۆدێرنی جل و بەرگەت — فاشنی ناوخۆیی بدۆزەرەوە، پشتیوانی دووکانە عێراقییەکان بکە، و بە متمانە کڕین بکە.',
      };

  String get badgeShoppers => switch (lang) {
        AppLanguage.english => 'For shoppers',
        AppLanguage.arabic => 'للمتسوقين',
        AppLanguage.kurdish => 'بۆ کڕیاران',
      };

  String get badgeShops => switch (lang) {
        AppLanguage.english => 'For shop owners',
        AppLanguage.arabic => 'لأصحاب المتاجر',
        AppLanguage.kurdish => 'بۆ خاوەن دووکان',
      };

  String get intro => switch (lang) {
        AppLanguage.english =>
          'Qopcha (قۆپچە) is a mobile marketplace built for Iraq. We bring together customers who want quality clothing and shop owners who want to grow online — in one simple, beautiful app.',
        AppLanguage.arabic =>
          'قوپچە سوق موبايل مصمم للعراق. نجمع بين العملاء الذين يبحثون عن ملابس جيدة وأصحاب المتاجر الذين يريدون النمو عبر الإنترنت — في تطبيق واحد بسيط وجميل.',
        AppLanguage.kurdish =>
          'قۆپچە بازاڕێکی مۆبایلە کە بۆ عێراق دروستکراوە. کڕیارانی جل و بەرگی باش و خاوەن دووکانانی کە دەتوانن لە ئینتەرنێت فرۆشیان زیاد بکەن لە یەک ئەپێکی سادە و جواندا کۆدەکاتەوە.',
      };

  List<LegalSection> get sections => switch (lang) {
        AppLanguage.english => _enSections,
        AppLanguage.arabic => _arSections,
        AppLanguage.kurdish => _kuSections,
      };

  String get contactTitle => switch (lang) {
        AppLanguage.english => 'Want to reach us?',
        AppLanguage.arabic => 'تريد التواصل معنا؟',
        AppLanguage.kurdish => 'دەتەوێت پەیوەندیمان پێوە بکەیت؟',
      };

  String contactBody(String email) => switch (lang) {
        AppLanguage.english =>
          'Questions, partnership ideas, or shop onboarding — we are happy to help at $email.',
        AppLanguage.arabic =>
          'أسئلة أو أفكار شراكة أو تسجيل متجر — يسعدنا مساعدتك على $email.',
        AppLanguage.kurdish =>
          'پرسیار، هاوکاری، یان تۆمارکردنی دووکان — ئامادەین لە $email یارمەتیت بدەین.',
      };

  static const _enSections = [
    LegalSection(
      title: 'What we do',
      body:
          'Qopcha helps you browse clothing and fabrics from trusted shops across Iraq, place orders, track delivery, and manage your profile — all from your phone.',
    ),
    LegalSection(
      title: 'For shoppers',
      bullets: [
        'Browse products by category, search, and discover new shops.',
        'Save favorites, apply discounts, and checkout with a clear cart.',
        'Track orders from pending to delivered with real-time updates.',
        'Set your delivery address and location for faster shipping.',
        'Get notifications about offers, new products, and order status.',
      ],
    ),
    LegalSection(
      title: 'For shop owners',
      bullets: [
        'Create your shop profile with logo, cover, and description.',
        'Add and edit products — including fabrics and ready-made clothing.',
        'Receive and manage customer orders from one dashboard.',
        'Reach more buyers without building your own app or website.',
      ],
    ),
    LegalSection(
      title: 'Our mission',
      body:
          'We believe local fashion deserves a modern digital home. Qopcha makes it easier for Iraqi businesses to sell online and for families to find quality clothes nearby — fairly, simply, and securely.',
    ),
    LegalSection(
      title: 'How Qopcha works',
      bullets: [
        'Download the app and create an account with your mobile number.',
        'Browse shops, add items to your cart, and confirm your order.',
        'Shops prepare your items; you follow progress in the app.',
        'Delivery is coordinated to the address you provide.',
      ],
    ),
    LegalSection(
      title: 'Languages & trust',
      bullets: [
        'Available in Kurdish, Arabic, and English.',
        'Secure sign-in with phone verification (WhatsApp or SMS).',
        'Your data is protected — see our Privacy Policy for details.',
      ],
    ),
  ];

  static const _kuSections = [
    LegalSection(
      title: 'ئێمە چی دەکەین',
      body:
          'قۆپچە یارمەتیت دەدات جل و بەرگ و قوماش لە دووکانە متمانەپێکراوەکانی عێراق ببینیت، داوا بکەیت، گەیاندن بەدواداچوون بکەیت، و پرۆفایلەکەت بەڕێوەببەیت — هەمووی لە مۆبایلەکەتەوە.',
    ),
    LegalSection(
      title: 'بۆ کڕیاران',
      bullets: [
        'گەڕان بەپێی پۆل، گەڕان، و دۆزینەوەی دووکانی نوێ.',
        'پاشەکەوتکردنی دڵخوازەکان، داشکاندن، و کڕین لە سەبەتەیەکی ڕوون.',
        'بەدواداچوونی داواکاری لە چاوەڕوانی تا گەیشتن.',
        'دیاریکردنی ناونیشان و شوێنی گەیاندن بۆ خێراتر گەیاندن.',
        'ئاگاداری بۆ ئۆفەر، بەرهەمی نوێ، و دۆخی داواکاری.',
      ],
    ),
    LegalSection(
      title: 'بۆ خاوەن دووکان',
      bullets: [
        'دروستکردنی پرۆفایلی دووکان بە لۆگۆ، کاوەر، و وەسف.',
        'زیادکردن و دەستکاری بەرهەم — قوماش و جل و بەرگی ئامادە.',
        'وەرگرتن و بەڕێوەبردنی داواکارییەکانی کڕیار لە یەک شوێن.',
        'گەیشتن بە کڕیاری زیاتر بەبێ ئەپ یان ماڵپەڕی تایبەت.',
      ],
    ),
    LegalSection(
      title: 'ئامانجەکەمان',
      body:
          'باوەڕمان وایە فاشنی ناوخۆیی شایانی ماڵێکی دیجیتاڵی مۆدێرنە. قۆپچە بۆ بازرگانییە عێراقییەکان ئاسانتر دەکات لە ئینتەرنێت بفرۆشن و بۆ خێزانەکان ئاسانترە جل و بەرگی باش لە نزیک بدۆزنەوە — بە دادپەروەری، سادەیی، و پاراستن.',
    ),
    LegalSection(
      title: 'قۆپچە چۆن کار دەکات',
      bullets: [
        'ئەپەکە دابەزێنە و بە ژمارەی مۆبایل هەژمار دروست بکە.',
        'دووکان بگەڕێ، بەرهەم بۆ سەبەتە زیاد بکە، داواکاری پشتڕاست بکەرەوە.',
        'دووکانەکان ئامادەی دەکەن؛ لە ئەپەکەدا بەدواداچوون بکە.',
        'گەیاندن بۆ ناونیشانی دیاریکراو ڕێکدەخرێت.',
      ],
    ),
    LegalSection(
      title: 'زمان و متمانە',
      bullets: [
        'بە کوردی، عەرەبی، و ئینگلیزی بەردەستە.',
        'چوونەژوورەوەی پارێزراو بە پشتڕاستکردنەوەی مۆبایل (واتساپ یان SMS).',
        'زانیاریەکانت پارێزراون — وردەکاری لە سیاسەتی تایبەتمەندی بخوێنەرەوە.',
      ],
    ),
  ];

  static const _arSections = [
    LegalSection(
      title: 'ماذا نفعل',
      body:
          'قوپچە يساعدك على تصفح الملابس والأقمشة من متاجر موثوقة في العراق، وتقديم الطلبات، وتتبع التوصيل، وإدارة ملفك — كل ذلك من هاتفك.',
    ),
    LegalSection(
      title: 'للمتسوقين',
      bullets: [
        'تصفح المنتجات حسب الفئة والبحث واكتشاف متاجر جديدة.',
        'حفظ المفضلة وتطبيق الخصومات والشراء من سلة واضحة.',
        'تتبع الطلبات من الانتظار حتى التسليم.',
        'تعيين عنوان التوصيل والموقع لتسليم أسرع.',
        'إشعارات بالعروض والمنتجات الجديدة وحالة الطلب.',
      ],
    ),
    LegalSection(
      title: 'لأصحاب المتاجر',
      bullets: [
        'إنشاء ملف متجرك مع الشعار والغلاف والوصف.',
        'إضافة وتعديل المنتجات — أقمشة وملابس جاهزة.',
        'استلام وإدارة طلبات العملاء من لوحة واحدة.',
        'الوصول إلى مزيد من المشترين دون بناء تطبيق أو موقع خاص.',
      ],
    ),
    LegalSection(
      title: 'مهمتنا',
      body:
          'نؤمن أن الموضة المحلية تستحق منصة رقمية عصرية. قوپچە يسهّل على الأعمال العراقية البيع عبر الإنترنت وعلى العائلات إيجاد ملابس جيدة قريباً — بعدالة وبساطة وأمان.',
    ),
    LegalSection(
      title: 'كيف يعمل قوپچە',
      bullets: [
        'حمّل التطبيق وأنشئ حساباً برقم هاتفك.',
        'تصفح المتاجر، أضف للسلة، وأكد طلبك.',
        'المتاجر تجهز طلبك؛ تابع التقدم في التطبيق.',
        'يتم التوصيل إلى العنوان الذي تحدده.',
      ],
    ),
    LegalSection(
      title: 'اللغات والثقة',
      bullets: [
        'متوفر بالكردية والعربية والإنجليزية.',
        'تسجيل دخول آمن مع التحقق من الهاتف (واتساب أو SMS).',
        'بياناتك محمية — راجع سياسة الخصوصية للتفاصيل.',
      ],
    ),
  ];
}
