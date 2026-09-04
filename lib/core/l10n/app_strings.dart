import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_color_theme.dart';
import '../../providers/settings_provider.dart';

/// UI copy for Kurdish / English / Arabic. Use via [stringsProvider].
class AppStrings {
  final AppLanguage lang;

  const AppStrings(this.lang);

  String call(String ku, String en, String ar) => tr(lang, ku, en, ar);

  // —— Common ——
  String get guest => call('میوان', 'Guest', 'زائر');
  String get all => call('هەموو', 'All', 'الكل');
  String get cancel => call('پاشگەزبوونەوە', 'Cancel', 'إلغاء');
  String get yes => call('بەڵێ', 'Yes', 'نعم');
  String get no => call('نەخێر', 'No', 'لا');
  String get later => call('دواتر', 'Later', 'لاحقاً');
  String get seeAll => call('بینینی هەموو', 'See all', 'عرض الكل');
  String get clear => call('پاککردنەوە', 'Clear', 'مسح');
  String get retry => call('گەڕانەوە', 'Retry', 'إعادة المحاولة');
  String get tryAgain =>
      call('دووبارە هەوڵبدەرەوە', 'Try again', 'حاول مرة أخرى');
  String get errorGeneric => call('هەڵەیەک ڕوویدا', 'Something went wrong', 'حدث خطأ ما');
  String get comingSoon =>
      call('بەمزووانە بەردەست دەبێت', 'Coming soon', 'قريباً');

  // —— Home ——
  String get searchClothesHint =>
      call('گەڕان بۆ جل و بەرگ...', 'Search clothes...', 'ابحث عن ملابس...');
  String get searchFabricsHint =>
      call('گەڕان لە قوماش، جۆر، دووکان...', 'Search fabrics, type, shop...', 'ابحث عن قماش أو نوع أو متجر...');
  String get pickLocation =>
      call('شوێن دیاری بکە', 'Set location', 'حدد الموقع');
  String welcome(String name) =>
      call('بەخێربێیت، $name', 'Welcome, $name', 'مرحباً، $name');
  String get productsLoadError => call(
        'هەڵە لە بارکردنی بەرهەمەکان',
        'Could not load products',
        'تعذر تحميل المنتجات',
      );
  String get noProductsFound => call(
        'هێشتان هیچ بەرهەمێک نییە',
        'No products yet',
        'لا توجد منتجات بعد',
      );
  String get pendingBrowseBanner => call(
        'هەژمارەکەت چاوەڕوانە — دەتوانیت ببینیت بەڵام ناتوانیت داواکاری بکەیت',
        'Your account is pending — you can browse but cannot place orders',
        'حسابك قيد الانتظار — يمكنك التصفح لكن لا يمكنك الطلب',
      );
  String get approvalBanner => call(
        'پیرۆزە! هەژمارەکەت پەسەند کرا — ئێستا دەتوانیت داواکاری بکەیت',
        'Congrats! Your account was approved — you can place orders now',
        'تهانينا! تمت الموافقة على حسابك — يمكنك الطلب الآن',
      );
  String get fabricsSection => call('بەشی قوماش', 'Fabrics', 'الأقمشة');
  String get fabricsSubtitle => call(
        'تەنها قوماش — جۆر، کوالێتی، ڕەنگ و نرخ بە مەتر',
        'Fabrics only — type, quality, color and price per meter',
        'أقمشة فقط — النوع والجودة واللون والسعر بالمتر',
      );

  // —— Search ——
  String get search => call('گەڕان', 'Search', 'بحث');
  String get filters => call('فلتەر', 'Filters', 'فلاتر');
  String get clearAllFilters =>
      call('پاککردنەوەی هەموو فلتەرەکان', 'Clear all filters', 'مسح كل الفلاتر');
  String get seeAllCategories =>
      call('بینینی هەموو جۆرەکان', 'See all categories', 'عرض كل الفئات');
  String get shopByCategory =>
      call('کڕین بەپێی پۆل', 'Shop by category', 'تسوق حسب الفئة');
  String get shopByGender =>
      call('کڕین بەپێی ڕەگەز', 'Shop by gender', 'تسوق حسب الجنس');
  String get men => call('پیاوان', 'Men', 'رجال');
  String get women => call('ژنان', 'Women', 'نساء');
  String get menSubtitle => call(
        'کۆلێکشنە نوێیەکانی پیاوان ببینە',
        'Browse the latest men’s collection',
        'تصفح أحدث مجموعات الرجال',
      );
  String get womenSubtitle => call(
        'کۆلێکشنە نوێیەکانی ژنان ببینە',
        'Browse the latest women’s collection',
        'تصفح أحدث مجموعات النساء',
      );
  String get menCategories =>
      call('پۆلەکانی پیاوان', 'Men’s categories', 'فئات الرجال');
  String get womenCategories =>
      call('پۆلەکانی ژنان', 'Women’s categories', 'فئات النساء');
  String get searchError =>
      call('هەڵە لە گەڕان', 'Search failed', 'فشل البحث');
  String get noSearchResults =>
      call('هیچ ئەنجامێک نەدۆزرایەوە', 'No results found', 'لم يتم العثور على نتائج');
  String get searchHintClothes =>
      call('گەڕان بۆ جل، پۆل، براند...', 'Search clothes, category, brand...', 'ابحث عن ملابس أو فئة أو علامة...');
  String get searchHintItems =>
      call('کراس، پێڵاو، جانتە...', 'Shirts, shoes, bags...', 'قمصان، أحذية، حقائب...');
  String get searchHintShop =>
      call('دووکانی دڵخواز...', 'Favorite shops...', 'متاجر مفضلة...');

  String categoryLabel(String key) {
    return switch (key) {
      'هەموو' => all,
      'پۆشاک' => call('پۆشاک', 'Tops', 'ملابس'),
      'کراس' => call('کراس', 'Shirts', 'قمصان'),
      'پانتۆڵ' => call('پانتۆڵ', 'Pants', 'بناطيل'),
      'کۆت' => call('کۆت', 'Coats', 'معاطف'),
      'پێڵاو' => call('پێڵاو', 'Shoes', 'أحذية'),
      'ئاکسەسوار' => call('ئاکسەسوار', 'Accessories', 'إكسسوارات'),
      'جلوبەرگی وەرزشی' || 'وەرزشی' =>
        call('وەرزشی', 'Sports', 'رياضي'),
      'جلوبەرگی فەرمی' || 'فەرمی' => call('فەرمی', 'Formal', 'رسمي'),
      'کڵاو' => call('کڵاو', 'Hats', 'قبعات'),
      'جانتە' => call('جانتە', 'Bags', 'حقائب'),
      'کاتژمێر' => call('کاتژمێر', 'Watches', 'ساعات'),
      'جلی منداڵان' || 'منداڵان' => call('منداڵان', 'Kids', 'أطفال'),
      _ => key,
    };
  }

  // —— Cart ——
  String get cart => call('سەبەتە', 'Cart', 'السلة');
  String get cartEmpty =>
      call('سەبەتەکەت بەتاڵە', 'Your cart is empty', 'سلتك فارغة');
  String get cartEmptyHint => call(
        'بەرهەمێک زیاد بکە و کڕینەکەت تەواو بکە',
        'Add a product and complete your purchase',
        'أضف منتجاً وأكمل عملية الشراء',
      );
  String get backToShop =>
      call('گەڕانەوە بۆ فرۆشگا', 'Back to shop', 'العودة للمتجر');
  String get clearCart => call('پاککردنەوە', 'Clear', 'مسح');
  String get clearCartTitle =>
      call('سڕینەوەی سەبەتە؟', 'Clear cart?', 'مسح السلة؟');
  String get clearCartBody => call(
        'هەموو بەرهەمەکان لە سەبەتە دەسڕدرێنەوە.',
        'All products will be removed from the cart.',
        'سيتم حذف كل المنتجات من السلة.',
      );
  String get delete => call('سڕینەوە', 'Delete', 'حذف');
  String get noItems =>
      call('هیچ بەرهەمێک نییە', 'No items', 'لا توجد منتجات');
  String get homeTab => call('سەرەکی', 'Home', 'الرئيسية');
  String get loginToCheckout => call(
        'بۆ داواکردن پێویستە بچیتە ژوورەوە',
        'Sign in to place an order',
        'سجّل الدخول لإتمام الطلب',
      );
  String get loginToCheckoutBody => call(
        'بۆ تەواوکردنی داواکاری پێویستە بچیتە ژوورەوە یان هەژمار دروست بکەیت.',
        'Sign in or create an account to complete your order.',
        'سجّل الدخول أو أنشئ حساباً لإتمام طلبك.',
      );
  String get pendingCannotOrder => call(
        'هەژمارەکەت چاوەڕوانی پەسەندکردنە — دەتوانیت سەبەتە ببینیت بەڵام ناتوانیت داواکاری بکەیت',
        'Your account is pending approval — you can view the cart but cannot order',
        'حسابك قيد الموافقة — يمكنك رؤية السلة لكن لا يمكنك الطلب',
      );
  String get cannotOrder =>
      call('ناتوانیت داواکاری بکەیت', 'You cannot place orders', 'لا يمكنك تقديم طلبات');
  String get orderSent => call(
        'داواکاریەکەت نێردرا بۆ دووکان — چاوەڕوانی قبوڵکردن',
        'Your order was sent to the shop — awaiting acceptance',
        'تم إرسال طلبك للمتجر — بانتظار القبول',
      );
  String get deliveryFeeNote => call(
        'نرخی گەیاندن لە کاتی گەیاندن وەردەگیرێت — شۆفێر بەپێی ناوچە دیاری دەکات '
        '(ناو شار ٣٬٠٠٠ · ١٢٠ مەتری ٤٬٠٠٠ · ١٥٠ مەتری ٥٬٠٠٠ دینار)',
        'Delivery fee is collected on delivery — the driver sets it by area '
        '(city 3,000 · 120m 4,000 · 150m 5,000 IQD)',
        'رسوم التوصيل تُحصّل عند التسليم — يحددها السائق حسب المنطقة '
        '(داخل المدينة ٣٬٠٠٠ · ١٢٠ م ٤٬٠٠٠ · ١٥٠ م ٥٬٠٠٠ دينار)',
      );
  String get itemCount => call('ژمارەی دانە', 'Items', 'عدد القطع');
  String get total => call('کۆی گشتی', 'Total', 'الإجمالي');
  String get loginToOrder =>
      call('چوونەژوورەوە بۆ داواکردن', 'Sign in to order', 'سجّل الدخول للطلب');
  String get checkout =>
      call('تەواوکردنی کڕین', 'Checkout', 'إتمام الشراء');
  String get waitingApproval =>
      call('چاوەڕوانی پەسەندکردن', 'Awaiting approval', 'بانتظار الموافقة');
  String get continueShopping =>
      call('بەردەوامبوون لە کڕین', 'Continue shopping', 'متابعة التسوق');
  String get locationNotSet =>
      call('شوێن دیاری نەکراوە', 'Location not set', 'الموقع غير محدد');
  String get locationRequiredBody => call(
        'بۆ تەواوکردنی داواکاری، تکایە شوێنی خۆت دیاری بکە.',
        'Please set your location to complete the order.',
        'يرجى تحديد موقعك لإتمام الطلب.',
      );
  String get setLocation =>
      call('دیاریکردنی شوێن', 'Set location', 'تحديد الموقع');
  String get chooseDeliveryAddress =>
      call('ناونیشانی گەیاندن هەڵبژێرە', 'Choose delivery address', 'اختر عنوان التوصيل');
  String get whichAddress => call(
        'کام ناونیشان بۆ ئەم داواکاریە؟',
        'Which address for this order?',
        'أي عنوان لهذا الطلب؟',
      );
  String get primary => call('سەرەکی', 'Primary', 'رئيسي');
  String get addNewAddress =>
      call('ناونیشانی نوێ زیاد بکە', 'Add new address', 'إضافة عنوان جديد');
  String get meter => call('مەتر', 'm', 'م');
  String sizeLabel(String size) => call('قیاس $size', 'Size $size', 'المقاس $size');
  String cartItemsSubtitle(int count) => call(
        '$count دانە لە سەبەتەدا',
        '$count items in cart',
        '$count قطعة في السلة',
      );
  String ordersSentMultiple(int n) => call(
        '$n داواکاری نێردرا بۆ دووکانەکان',
        '$n orders were sent to the shops',
        'تم إرسال $n طلبات للمتاجر',
      );
  String itemsPlusCount(int count) =>
      call('$count+ دانە', '$count+ items', '$count+ قطعة');

  // —— Profile ——
  String get myProfile => call('پڕۆفایلی من', 'My profile', 'ملفي');
  String get guestBrowseHint => call(
        'دەتوانیت بەرهەمەکان ببینیت. بۆ داواکردن و پرۆفایل، بچۆ ژوورەوە.',
        'You can browse products. Sign in to order and manage your profile.',
        'يمكنك تصفح المنتجات. سجّل الدخول للطلب وإدارة ملفك.',
      );
  String get changeLanguage =>
      call('گۆڕینی زمان', 'Change language', 'تغيير اللغة');
  String get signIn => call('چوونەژوورەوە', 'Sign in', 'تسجيل الدخول');
  String get createAccount =>
      call('دروستکردنی هەژمار', 'Create account', 'إنشاء حساب');
  String get deliveryPlace =>
      call('شوێنی گەیاندن', 'Delivery location', 'موقع التوصيل');
  String get personalInfo =>
      call('زانیاری کەسی', 'Personal info', 'المعلومات الشخصية');
  String get addresses => call('ناونیشانەکان', 'Addresses', 'العناوين');
  String get bodyMeasurements =>
      call('قیاسی جەستەم', 'Body measurements', 'قياسات الجسم');
  String get paymentMethods =>
      call('شێوازەکانی پارەدان', 'Payment methods', 'طرق الدفع');
  String get myFavorites => call('دڵخوازەکانم', 'Favorites', 'المفضلة');
  String get myReviews => call('هەڵسەنگاندنەکانم', 'My reviews', 'تقييماتي');
  String get discounts => call('داشکاندنەکان', 'Offers', 'العروض');
  String get helpSupport =>
      call('یارمەتی و پشتگیری', 'Help & support', 'المساعدة والدعم');
  String get logout => call('چوونەدەرەوە', 'Log out', 'تسجيل الخروج');
  String get logoutConfirm => call(
        'دڵنیایت دەتەوێت بچیتە دەرەوە؟',
        'Are you sure you want to log out?',
        'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      );
  String get editProfile =>
      call('دەستکاری پڕۆفایل', 'Edit profile', 'تعديل الملف');
  String get myOrders => call('داواکارییەکانم', 'My orders', 'طلباتي');
  String get orderPending => call('چاوەڕوان', 'Pending', 'قيد الانتظار');
  String get orderConfirmed => call('قبوڵکراو', 'Accepted', 'مقبول');
  String get orderShipped => call('نێردراو', 'Shipped', 'تم الشحن');
  String get orderDelivered => call('گەیشتوو', 'Delivered', 'تم التسليم');
  String get orderReturned => call('گەڕاوە', 'Returned', 'مرتجع');
  String preferredSize(String size) =>
      call('قەبارە: $size', 'Size: $size', 'المقاس: $size');
  String get couldNotOpen =>
      call('نەتوانرا بکرێتەوە', 'Could not open', 'تعذر الفتح');
  String workingHours(String hours) =>
      call('کاتی کارکردن: $hours', 'Hours: $hours', 'ساعات العمل: $hours');
  String get callPhone => call('پەیوەندی تەلەفۆن', 'Call', 'اتصال هاتفي');
  String get whatsapp => call('واتساپ', 'WhatsApp', 'واتساب');
  String get email => call('ئیمەیڵ', 'Email', 'البريد');
  String get socialMedia => call('سۆشیال میدیا', 'Social media', 'وسائل التواصل');
  String get noSupportYet => call(
        'هێشتا زانیاری پشتگیری دانەنراوە',
        'Support details are not set yet',
        'لم تُضف بيانات الدعم بعد',
      );

  // —— Settings ——
  String get settings => call('ڕێکخستنەکان', 'Settings', 'الإعدادات');
  String get settingsSubtitle => call(
        'ڕووکار، ئاگاداری و تایبەتمەندییەکان',
        'Appearance, notifications and preferences',
        'المظهر والإشعارات والتفضيلات',
      );
  String get appearance => call('ڕووکار', 'Appearance', 'المظهر');
  String get language => call('زمان', 'Language', 'اللغة');
  String get notifications => call('ئاگادارییەکان', 'Notifications', 'الإشعارات');
  String get aboutApp => call('دەربارەی ئەپ', 'About the app', 'حول التطبيق');
  String get aboutUs => call('دەربارەی ئێمە', 'About us', 'من نحن');
  String get terms => call('مەرجەکان', 'Terms', 'الشروط');
  String get privacyPolicy =>
      call('سیاسەتی پاراستن', 'Privacy policy', 'سياسة الخصوصية');
  String get termsAppliesToAllUsers => call(
        'بۆ کڕیار و خاوەن دووکان — بە بەکارهێنانی ئەپەکە ڕازیت لەسەر ئەم مەرجانە.',
        'For customers and shop owners — by using the app you agree to these terms.',
        'للعملاء وأصحاب المتاجر — باستخدام التطبيق فأنت توافق على هذه الشروط.',
      );
  String get aboutFallback => call(
        'قۆپچە بازاڕێکی جل و بەرگە بۆ کڕیار و فرۆشیاران لە عێراق.',
        'Qopcha is a clothing marketplace for shoppers and shop owners in Iraq.',
        'قوبتشا سوق ملابس للمتسوقين وأصحاب المتاجر في العراق.',
      );
  String get termsFallback => call(
        'بە بەکارهێنانی ئەپەکە، ڕەزامەندیت لەسەر مەرجەکانی خزمەتگوزاری و ڕێساکانی بازاڕ.',
        'By using the app, you agree to our service terms and marketplace rules.',
        'باستخدام التطبيق، فإنك توافق على شروط الخدمة وقواعد السوق.',
      );
  String get privacyFallback => call(
        'زانیاری کەسیت بە ئەمنی پارێزراوە و تەنها بۆ خزمەتگوزاری و داواکاری بەکاردێت.',
        'Your personal data is kept secure and used only for service and orders.',
        'بياناتك الشخصية محمية وتُستخدم فقط للخدمة والطلبات.',
      );
  String get brightnessMode =>
      call('دۆخی ڕووناکی', 'Brightness', 'وضع الإضاءة');
  String get appColor => call('ڕەنگی ئەپ', 'App color', 'لون التطبيق');
  String get themeSystem => call('سیستەم', 'System', 'النظام');
  String get themeLight => call('ڕووناک', 'Light', 'فاتح');
  String get themeDark => call('تاریک', 'Dark', 'داكن');
  String get kurdish => call('کوردی', 'Kurdish', 'كردي');
  String get arabic => call('العربية', 'Arabic', 'العربية');
  String get english => call('English', 'English', 'English');
  String get kurdishSubtitle =>
      call('کوردی · RTL', 'Kurdish · RTL', 'كردي · RTL');
  String get arabicSubtitle =>
      call('عەرەبی · RTL', 'Arabic · RTL', 'العربية · RTL');
  String get englishSubtitle =>
      call('ئینگلیزی · LTR', 'English · LTR', 'الإنجليزية · LTR');
  String get aboutVersionFallback => call(
        'وەشان ١.٠.٠ · بازاڕی جلوبەرگ',
        'Version 1.0.0 · Clothing marketplace',
        'الإصدار 1.0.0 · سوق الملابس',
      );
  String colorThemeLabel(AppColorTheme theme) => switch (theme) {
        AppColorTheme.red => call('سور', 'Red', 'أحمر'),
        AppColorTheme.orange => call('پرتەقاڵی', 'Orange', 'برتقالي'),
        AppColorTheme.yellow => call('زەرد', 'Yellow', 'أصفر'),
        AppColorTheme.ocean => call('زەریا', 'Ocean', 'المحيط'),
        AppColorTheme.teal => call('قۆپچە', 'Teal', 'فيروزي'),
        AppColorTheme.violet => call('مۆر', 'Violet', 'بنفسجي'),
        AppColorTheme.rose => call('گوڵەبی', 'Rose', 'وردي'),
        AppColorTheme.blossom => call('گوڵی بەهار', 'Blossom', 'زهر'),
        AppColorTheme.peony => call('گوڵی پێۆنی', 'Peony', 'بيونية'),
      };
  String get notificationTypes =>
      call('جۆری ئاگادارییەکان', 'Notification types', 'أنواع الإشعارات');
  String get notifyDiscounts =>
      call('داشکاندن و ئۆفەر', 'Discounts & offers', 'خصومات وعروض');
  String get notifyDiscountsSub => call(
        'کاتێک داشکاندن یان پرۆمۆ هەیە',
        'When there is a discount or promo',
        'عند وجود خصم أو عرض ترويجي',
      );
  String get notifyNewProducts =>
      call('بەرهەمی نوێ', 'New products', 'منتجات جديدة');
  String get notifyNewProductsSub => call(
        'کاتێک دووکان کاڵای نوێ زیاد دەکات',
        'When a shop adds a new product',
        'عندما يضيف متجر منتجاً جديداً',
      );
  String get notifyAppUpdates =>
      call('نوێکاری ئەپ', 'App updates', 'تحديثات التطبيق');
  String get notifyAppUpdatesSub => call(
        'گۆڕانکاری، نوێکاری و ئاگاداری سیستەم',
        'Changes, updates and system notices',
        'التغييرات والتحديثات وإشعارات النظام',
      );
  String get allNotifications =>
      call('هەموو ئاگادارییەکان', 'All notifications', 'كل الإشعارات');
  String get notificationsOn => call(
        'ئاگادارییەکان چالاکن — جۆرەکان لە خوارەوە',
        'Notifications are on — choose types below',
        'الإشعارات مفعّلة — اختر الأنواع أدناه',
      );
  String get notificationsOff => call(
        'هەموو ئاگادارییەکان ناچالاک کراون',
        'All notifications are turned off',
        'تم إيقاف كل الإشعارات',
      );
  String get notifOrders => call('داواکاری', 'Orders', 'الطلبات');
  String get notifOffers => call('ئۆفەر', 'Offers', 'عروض');
  String get notifWishlist => call('دڵخواز', 'Wishlist', 'المفضلة');
  String get notifAccount => call('هەژمار', 'Account', 'الحساب');
  String get notifSystem => call('سیستەم', 'System', 'النظام');

  // —— Discounts ——
  String get discountsPageTitle =>
      call('داشکاندنەکان', 'Offers', 'العروض');
  String get discountsPageSubtitle => call(
        'هەموو جۆرەکانی داشکاندن لە یەک شوێن',
        'All your discounts in one place',
        'كل أنواع الخصومات في مكان واحد',
      );
  String get discountsLoadError => call(
        'هەڵە لە بارکردنی داشکاندنەکان',
        'Could not load offers',
        'تعذر تحميل العروض',
      );
  String get discountedProducts =>
      call('بەرهەمی داشکاندراو', 'Discounted products', 'منتجات مخفضة');
  String get personalDiscount =>
      call('داشکاندنی کەسی', 'Personal discount', 'خصم شخصي');
  String get personalDiscountSub => call(
        'لە هەموو بەرهەمێکدا جێبەجێ دەبێت',
        'Applies to every product',
        'يُطبَّق على كل المنتجات',
      );
  String get personalDiscountNote => call(
        'ئەگەر ئۆفەری بەرهەم زیاتر بێت، ئۆفەری بەرهەم دەگیرێتەوە',
        'If a product offer is higher, that offer is used instead',
        'إذا كان عرض المنتج أعلى، يُستخدم عرض المنتج',
      );
  String get deliveryDiscount =>
      call('داشکاندنی گەیاندن', 'Delivery discount', 'خصم التوصيل');
  String get deliveryDiscountSub => call(
        'لە کاتی تەواوکردنی داواکارییەکەتدا دەخرێتە سەر',
        'Applied when you complete your order',
        'يُطبَّق عند إتمام طلبك',
      );
  String get productOffer =>
      call('ئۆفەری بەرهەم', 'Product offer', 'عرض المنتج');
  String upToPercent(int percent) =>
      call('تا $percent٪', 'Up to $percent%', 'حتى $percent٪');
  String productsWithOwnOffer(int count) => call(
        '$count بەرهەم ئۆفەری خۆی هەیە',
        '$count products have their own offer',
        '$count منتجات لها عرض خاص',
      );
  String get productOfferActive =>
      call('ئۆفەرێکی بەرهەم چالاکە', 'A product offer is active', 'عرض منتج مفعّل');
  String get noProductOffersNote => call(
        'ئێستا هیچ بەرهەمێک ئۆفەری خۆی نییە. داشکاندنەکانی سەرەوە هێشتا چالاکن.',
        'No products have their own offer right now. The discounts above are still active.',
        'لا توجد منتجات بعرض خاص حالياً. الخصومات أعلاه ما زالت مفعّلة.',
      );
  String get noDiscountsYet =>
      call('ئێستا هیچ داشکاندنێک نییە', 'No offers yet', 'لا توجد عروض حالياً');
  String get noDiscountsHint => call(
        'کاتێک ئۆفەری نوێ دەبێت، لێرە دەردەکەوێت',
        'When a new offer is available, it will show up here',
        'عند توفر عرض جديد، سيظهر هنا',
      );
  String get browseProducts =>
      call('گەڕان بۆ بەرهەم', 'Browse products', 'تصفح المنتجات');
  String get soldOut => call('تەواوبوو', 'Sold out', 'نفد');
  String get fabricBadge => call('قوماش', 'Fabric', 'قماش');
  String get visitShop =>
      call('سەردانی دووکان', 'Visit shop', 'زيارة المتجر');
  String productDiscountTag(int percent) =>
      call('بەرهەم $percent٪', 'Product $percent%', 'منتج $percent٪');
  String personalDiscountTag(int percent) =>
      call('کەسی $percent٪', 'Personal $percent%', 'شخصي $percent٪');

  // —— Auth leftovers ——
  String get adminCannotLoginHere => call(
        'ئەدمین ناتوانێت لێرە بچێتە ژوورەوە — پانێڵی بەڕێوەبردن بەکاربهێنە',
        'Admins cannot sign in here — use the admin panel',
        'لا يمكن للمسؤول الدخول من هنا — استخدم لوحة الإدارة',
      );
  String get passwordUpdated => call(
        'وشەی نهێنی نوێکرایەوە — ئێستا دەتوانیت بچیتە ژوورەوە',
        'Password updated — you can sign in now',
        'تم تحديث كلمة المرور — يمكنك تسجيل الدخول الآن',
      );
}

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(appSettingsProvider.select((s) => s.language));
  return AppStrings(lang);
});
