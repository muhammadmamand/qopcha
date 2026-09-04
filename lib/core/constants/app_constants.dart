import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'قۆپچە';
  static const String appNameEn = 'Qopcha';
  static const String appTagline = 'جل و بەرگی مۆدێرن بۆ هەمووان';

  /// OS window title — ASCII on Windows avoids title-bar mojibake.
  static String get windowBrandTitle =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
          ? appNameEn
          : appName;

  static String windowTitle(String pageTitle) {
    final brand = windowBrandTitle;
    if (pageTitle.trim().isEmpty) return brand;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return '$pageTitle | $brand';
    }
    return '$pageTitle | $appName';
  }

  static const List<String> categories = [
    'هەموو',
    'پۆشاک',
    'پانتۆڵ',
    'کراس',
    'کۆت',
    'پێڵاو',
    'ئاکسەسوار',
    'جلوبەرگی وەرزشی',
    'جلوبەرگی فەرمی',
    'کڵاو',
    'جانتە',
    'کاتژمێر',
    'جلی منداڵان',
  ];

  /// Category stamped on fabric listings (and shown with the fabric-roll icon).
  static const String fabricCategory = 'قوماش';

  /// Clothing categories only (excludes All + fabric).
  static List<String> get clothingCategories =>
      categories.where((c) => c != 'هەموو' && c != fabricCategory).toList();

  static const List<String> sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

  /// Stock unit stored in [SizeStock.size] for fabric listings.
  static const String fabricStockUnit = 'مەتر';

  static const List<String> fabricTypes = [
    'هەموو',
    'کتان',
    'ئاوریشم',
    'جینز',
    'کتانی ناسک',
    'پۆلیستەر',
    'شیفۆن',
    'لینن',
    'مخمل',
    'جەرسێ',
    'سترێچ',
    'فۆل',
    'تویل',
    'مخلوط',
  ];

  static const List<String> fabricQualities = [
    'نایاب',
    'باش',
    'ناوەند',
    'ئاسایی',
  ];

  static const List<String> fabricPatterns = [
    'سادە',
    'گوڵدار',
    'هێڵدار',
    'چەقەرە',
    'چاپکراو',
  ];

  static const List<double> fabricWidthsCm = [110, 140, 150, 160, 180, 280];

  static const List<String> colors = [
    'ڕەش',
    'سپی',
    'شین',
    'سور',
    'سەوز',
    'زەرد',
    'پەمەیی',
    'قاوەیی',
    'خۆڵەمێشی',
    'بەنفەشی',
    'نارنجی',
    'زێڕین',
    'زیوینی',
    'شەرابی',
    'کەحڵی',
    'کرێمی',
  ];
}
