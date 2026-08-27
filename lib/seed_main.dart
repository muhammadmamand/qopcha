import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/product_model.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';

/// Demo credentials (Firebase Auth + Firestore).
class DemoAccounts {
  static const adminEmail = 'admin@qopcha.com';
  static const adminPassword = 'Admin123456';
  static const shopEmail = 'shop@qopcha.com';
  static const shopPassword = 'Shop123456';
  static const shopName = 'قۆپچە بوتیک';

  static const customerEmail = 'customer@qopcha.com';
  static const customerPassword = 'Customer123456';
}

/// Run with: `flutter run -t lib/seed_main.dart -d windows`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _SeedApp());
}

class _SeedApp extends StatelessWidget {
  const _SeedApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _SeedScreen(),
    );
  }
}

class _SeedScreen extends StatefulWidget {
  const _SeedScreen();

  @override
  State<_SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<_SeedScreen> {
  final _logs = <String>[];
  bool _done = false;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _log(String msg) {
    // ignore: avoid_print
    print(msg);
    if (!mounted) return;
    setState(() => _logs.add(msg));
  }

  Future<void> _run() async {
    _log('Qopcha seed starting…');
    try {
      final result = await seedDemoShopAndClothes(_log);
      _log('── Seed OK');
      _log('Admin:    ${DemoAccounts.adminEmail} / ${DemoAccounts.adminPassword}');
      _log('Shop:     ${DemoAccounts.shopEmail} / ${DemoAccounts.shopPassword}');
      _log(
        'Customer: ${DemoAccounts.customerEmail} / ${DemoAccounts.customerPassword}',
      );
      _log('Shop id:  ${result.shopOwnerId}');
      _log('Products: ${result.productsAdded} added');
      setState(() {
        _done = true;
        _ok = true;
      });
    } catch (e, st) {
      _log('── Seed FAILED: $e');
      _log('$st');
      setState(() {
        _done = true;
        _ok = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _done
                    ? (_ok ? 'Seed complete' : 'Seed failed')
                    : 'Seeding…',
                style: TextStyle(
                  color: _done
                      ? (_ok ? const Color(0xFF2D9B6A) : const Color(0xFFD64550))
                      : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      _logs[i],
                      style: const TextStyle(
                        color: Color(0xFFB4B4C0),
                        fontSize: 13,
                        fontFamily: 'Consolas',
                      ),
                    ),
                  ),
                ),
              ),
              if (_done)
                const Text(
                  'Close this window and run the main app.\n'
                  'Login as customer to shop, or shop to manage products.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SeedResult {
  final String shopOwnerId;
  final int productsAdded;

  const SeedResult({
    required this.shopOwnerId,
    required this.productsAdded,
  });
}

Future<SeedResult> seedDemoShopAndClothes(
  void Function(String) log,
) async {
  final auth = AuthService();
  final products = ProductService();
  final db = FirebaseFirestore.instance;

  await _ensureUser(
    auth: auth,
    log: log,
    email: DemoAccounts.adminEmail,
    password: DemoAccounts.adminPassword,
    name: 'ئەدمین',
    phone: '07500000000',
    role: UserRole.admin,
  );

  final shop = await _ensureUser(
    auth: auth,
    log: log,
    email: DemoAccounts.shopEmail,
    password: DemoAccounts.shopPassword,
    name: 'سارا عەلی',
    phone: '07501234567',
    role: UserRole.shopOwner,
    shopName: DemoAccounts.shopName,
    shopDescription: 'جل و بەرگی مۆدێرن و ئەوروپی بۆ ژنان و پیاوان',
    shopAddress: 'هەولێر، شەقامی ٦٠ مەتری',
    shopTier: ShopTier.gold,
  );

  await _ensureUser(
    auth: auth,
    log: log,
    email: DemoAccounts.customerEmail,
    password: DemoAccounts.customerPassword,
    name: 'ئاریان محەمەد',
    phone: '07509876543',
    role: UserRole.customer,
  );

  // Re-login as shop so writes are attributed to shop owner if rules require auth.
  await auth.login(
    phone: '07501234567',
    password: DemoAccounts.shopPassword,
  );

  final existing = await products.getProductsByShop(shop.id);
  if (existing.isNotEmpty) {
    log('Shop already has ${existing.length} products — skipping add.');
    await FirebaseAuth.instance.signOut();
    return SeedResult(shopOwnerId: shop.id, productsAdded: 0);
  }

  final now = DateTime.now();
  final catalog = _demoClothes(
    shopOwnerId: shop.id,
    shopName: shop.shopName ?? DemoAccounts.shopName,
    now: now,
  );

  var added = 0;
  for (final item in catalog) {
    await products.addProduct(item, announce: false);
    added++;
    log('  + ${item.name}');
  }

  await db.collection('_meta').doc('seed').set({
    'shopOwnerId': shop.id,
    'productsAdded': added,
    'seededAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  await FirebaseAuth.instance.signOut();
  return SeedResult(shopOwnerId: shop.id, productsAdded: added);
}

Future<UserModel> _ensureUser({
  required AuthService auth,
  required void Function(String) log,
  required String email,
  required String password,
  required String name,
  required String phone,
  required UserRole role,
  String? shopName,
  String? shopDescription,
  String? shopAddress,
  ShopTier? shopTier,
}) async {
  final fbAuth = FirebaseAuth.instance;
  final users = FirebaseFirestore.instance.collection('users');

  Future<UserModel> writeProfile(String uid) async {
    final user = UserModel(
      id: uid,
      name: name,
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      approvalStatus: ApprovalStatus.approved,
      shopName: shopName,
      shopDescription: shopDescription,
      shopAddress: shopAddress,
      shopTier: role == UserRole.shopOwner
          ? (shopTier ?? ShopTier.silver)
          : null,
      createdAt: DateTime.now(),
    );
    await users.doc(uid).set(user.toJson(), SetOptions(merge: true));
    return user;
  }

  try {
    final user = await auth.register(
      name: name,
      phone: phone,
      password: password,
      code: '000000',
      role: role,
      shopName: shopName,
      shopDescription: shopDescription,
      shopAddress: shopAddress,
      shopTier: shopTier,
      approvalStatus: ApprovalStatus.approved,
    );
    log('Created $role: $phone');
    return user;
  } catch (e) {
    final msg = e.toString();
    final already = msg.contains('پێشتر تۆمارکراوە') ||
        msg.contains('email-already-in-use') ||
        msg.contains('already');

    if (!already) rethrow;

    log('Auth exists for $email — ensuring Firestore profile…');
    final cred = await fbAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final snap = await users.doc(uid).get();
    if (snap.exists && snap.data() != null) {
      final data = Map<String, dynamic>.from(snap.data()!);
      data['id'] = uid;
      log('Already exists: $email');
      return UserModel.fromJson(data);
    }
    final repaired = await writeProfile(uid);
    log('Repaired Firestore profile: $email');
    return repaired;
  }
}

List<ProductModel> _demoClothes({
  required String shopOwnerId,
  required String shopName,
  required DateTime now,
}) {
  SizeStock s(String size, int qty) => SizeStock(size: size, quantity: qty);

  ProductModel p({
    required String name,
    required String description,
    required String category,
    required double price,
    required List<String> colors,
    required String material,
    required String brand,
    required List<String> imageUrls,
    required List<SizeStock> sizeStocks,
    bool featured = false,
  }) {
    return ProductModel(
      id: '',
      shopOwnerId: shopOwnerId,
      shopName: shopName,
      name: name,
      description: description,
      category: category,
      price: price,
      colors: colors,
      material: material,
      brand: brand,
      imageUrls: imageUrls,
      sizeStocks: sizeStocks,
      isFeatured: featured,
      createdAt: now,
      updatedAt: now,
    );
  }

  return [
    p(
      name: 'کراسی لینن سپی',
      description:
          'کراسی نەرم لە لینن، گونجاو بۆ هاوین. دیزاینی سادە و مۆدێرن.',
      category: 'کراس',
      price: 45000,
      colors: const ['سپی', 'کرێمی'],
      material: 'لینن',
      brand: 'Shik Line',
      imageUrls: const [
        'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800',
      ],
      sizeStocks: [s('S', 5), s('M', 8), s('L', 6), s('XL', 3)],
      featured: true,
    ),
    p(
      name: 'پانتۆڵی جین شین',
      description: 'جینی کلاسیک، برش ڕاست. کوالیتی بەرز و ئاسوودە.',
      category: 'پانتۆڵ',
      price: 65000,
      colors: const ['شین', 'کەحڵی'],
      material: 'دێنیم',
      brand: 'Denim Co',
      imageUrls: const [
        'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800',
      ],
      sizeStocks: [s('S', 4), s('M', 7), s('L', 5), s('XL', 4)],
      featured: true,
    ),
    p(
      name: 'کۆتی خۆڵەمێشی',
      description: 'کۆتی سووک بۆ پاییز، لەگەڵ جێبی لایەکی و قەڵەمبازی نەرم.',
      category: 'کۆت',
      price: 120000,
      colors: const ['خۆڵەمێشی', 'ڕەش'],
      material: 'وۆڵ مەخلووت',
      brand: 'Nord Atelier',
      imageUrls: const [
        'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=800',
      ],
      sizeStocks: [s('M', 3), s('L', 4), s('XL', 2)],
      featured: true,
    ),
    p(
      name: 'پۆشاکی ڕەشی ئێوارە',
      description: 'پۆشاکی فەرمی بۆ بۆنە تایبەتەکان، دیزاینی ئەلیگانت.',
      category: 'جلوبەرگی فەرمی',
      price: 95000,
      colors: const ['ڕەش'],
      material: 'پۆلیستەر نەرم',
      brand: 'Evening Edit',
      imageUrls: const [
        'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800',
      ],
      sizeStocks: [s('S', 2), s('M', 4), s('L', 3)],
    ),
    p(
      name: 'تیشێرتی سپی بنەڕەتی',
      description: 'تیشێرتی قطنی ١٠٠٪، گونجاو بۆ هەموو ڕۆژێک.',
      category: 'پۆشاک',
      price: 22000,
      colors: const ['سپی', 'ڕەش', 'خۆڵەمێشی'],
      material: 'قطن',
      brand: 'Basics',
      imageUrls: const [
        'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800',
      ],
      sizeStocks: [s('S', 10), s('M', 12), s('L', 10), s('XL', 8)],
    ),
    p(
      name: 'پێڵاوی سپۆرتی سپی',
      description: 'پێڵاوی سووک و ئاسوودە بۆ ڕۆژانە و وەرزش.',
      category: 'پێڵاو',
      price: 85000,
      colors: const ['سپی'],
      material: 'مێش + لاستیك',
      brand: 'Step',
      imageUrls: const [
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
      ],
      sizeStocks: [s('S', 3), s('M', 5), s('L', 4), s('XL', 2)],
      featured: true,
    ),
    p(
      name: 'جانتەی شانەی قاوەیی',
      description: 'جانتەی چەرمی دەستکرد، قەبارەی مامناوەند بۆ ڕۆژانە.',
      category: 'جانتە',
      price: 70000,
      colors: const ['قاوەیی', 'ڕەش'],
      material: 'چەرمی دەستکرد',
      brand: 'Carry',
      imageUrls: const [
        'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800',
      ],
      sizeStocks: [s('M', 6)],
    ),
    p(
      name: 'کراسەی وەرزشی شین',
      description: 'کراسەی هەناسەپێدەر بۆ ڕاهێنان و ڕۆیشتن.',
      category: 'جلوبەرگی وەرزشی',
      price: 38000,
      colors: const ['شین', 'ڕەش'],
      material: 'پۆلیستەر هەناسەپێدەر',
      brand: 'Active',
      imageUrls: const [
        'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800',
      ],
      sizeStocks: [s('S', 4), s('M', 6), s('L', 5), s('XL', 3)],
    ),
    p(
      name: 'کڵاوی بەیسۆڵ ڕەش',
      description: 'کڵاوی کلاسیک، ڕێکخستنی پشتەوە.',
      category: 'کڵاو',
      price: 18000,
      colors: const ['ڕەش', 'سپی'],
      material: 'قطن',
      brand: 'Cap Co',
      imageUrls: const [
        'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800',
      ],
      sizeStocks: [s('M', 15)],
    ),
    p(
      name: 'کاتژمێری مۆدێرن زیوینی',
      description: 'کاتژمێری دەستی باریک، گونجاو بۆ کار و بۆنە.',
      category: 'کاتژمێر',
      price: 110000,
      colors: const ['زیوینی', 'ڕەش'],
      material: 'پۆڵا + چەرم',
      brand: 'Tempo',
      imageUrls: const [
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800',
      ],
      sizeStocks: [s('M', 4)],
      featured: true,
    ),
  ];
}
