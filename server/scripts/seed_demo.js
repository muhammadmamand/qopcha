'use strict';

/**
 * Seed demo shop + clothing products into the local/VPS API.
 * Usage: node scripts/seed_demo.js [baseUrl]
 */
const BASE = (process.argv[2] || 'http://127.0.0.1:8090').replace(/\/$/, '');

async function req(path, { method = 'GET', body, token } = {}) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      Accept: 'application/json',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error || `${res.status} ${path}`);
  }
  return data;
}

const products = [
  {
    name: 'کاتی شەرت کلاسیک',
    description: 'شەرتی نەرم و ڕۆژانە بۆ پیاوان',
    category: 'پیاوان',
    price: 35000,
    colors: ['سپی', 'ڕەش', 'شینی تۆخ'],
    material: 'کاتن ١٠٠٪',
    brand: 'قۆپچە',
    imageUrls: [
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800',
    ],
    sizeStocks: [
      { size: 'M', quantity: 8 },
      { size: 'L', quantity: 10 },
      { size: 'XL', quantity: 6 },
    ],
    isFeatured: true,
    productType: 'clothing',
  },
  {
    name: 'جلکی هاوینەی ئافرەتان',
    description: 'جلکی سووک و مۆدێرن بۆ هاوین',
    category: 'ئافرەتان',
    price: 55000,
    colors: ['پەمەیی', 'سپی'],
    material: 'لینن',
    brand: 'قۆپچە',
    imageUrls: [
      'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=800',
    ],
    sizeStocks: [
      { size: 'S', quantity: 5 },
      { size: 'M', quantity: 7 },
      { size: 'L', quantity: 4 },
    ],
    isFeatured: true,
    discountPercent: 15,
    discountType: 'percent',
    discountForAllCustomers: true,
    discountSetBy: 'shop',
    productType: 'clothing',
  },
  {
    name: 'پانتۆڵی جین',
    description: 'جینی نەرم بۆ ڕۆژانە',
    category: 'پیاوان',
    price: 48000,
    colors: ['شینی جین'],
    material: 'دینم',
    brand: 'قۆپچە',
    imageUrls: [
      'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800',
    ],
    sizeStocks: [
      { size: '30', quantity: 4 },
      { size: '32', quantity: 6 },
      { size: '34', quantity: 5 },
    ],
    isFeatured: false,
    productType: 'clothing',
  },
  {
    name: 'کراسی منداڵان',
    description: 'کراسی ڕەنگاوڕەنگ بۆ منداڵ',
    category: 'منداڵان',
    price: 22000,
    colors: ['زەرد', 'سەوز'],
    material: 'کاتن',
    brand: 'قۆپچە',
    imageUrls: [
      'https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=800',
    ],
    sizeStocks: [
      { size: '4-5', quantity: 9 },
      { size: '6-7', quantity: 8 },
    ],
    isFeatured: true,
    productType: 'clothing',
  },
  {
    name: 'کەپڵی وەرزشی',
    description: 'کەپڵی سووک بۆ ڕاهێنان',
    category: 'وەرزشی',
    price: 65000,
    colors: ['ڕەش', 'سپی'],
    material: 'مێش + کاتن',
    brand: 'قۆپچە',
    imageUrls: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
    ],
    sizeStocks: [
      { size: '40', quantity: 5 },
      { size: '41', quantity: 6 },
      { size: '42', quantity: 4 },
    ],
    isFeatured: false,
    productType: 'clothing',
  },
];

async function main() {
  console.log(`Seeding against ${BASE}`);
  await req('/api/health');

  const phone = '07501112233';
  const password = 'Shop123456';
  let token;
  let shopName = 'دووکانی نموونە';

  try {
    const reg = await req('/api/auth/register', {
      method: 'POST',
      body: {
        name: 'خاوەن دووکان',
        phone,
        password,
        role: 'shopOwner',
        shopName,
        shopDescription: 'بەرهەمی نموونە بۆ تاقیکردنەوە',
        shopAddress: 'هەولێر',
        shopTier: 'gold',
      },
    });
    token = reg.token;
    // Approve shop via direct store is not available — patch as self won't change role.
    console.log('Registered demo shop', phone);
  } catch (e) {
    console.log('Register skipped:', e.message);
    const login = await req('/api/auth/login', {
      method: 'POST',
      body: { phone, password },
    });
    token = login.token;
    shopName = login.user?.shopName || shopName;
    console.log('Logged in demo shop', phone);
  }

  // Admin approve shop if pending
  try {
    const admin = await req('/api/auth/login', {
      method: 'POST',
      body: { email: 'admin@qopcha.com', password: 'Admin123456' },
    });
    const users = await req('/api/users', { token: admin.token });
    const shop = (users.users || []).find((u) => u.phone === phone);
    if (shop && shop.approvalStatus !== 'approved') {
      await req(`/api/users/${shop.id}`, {
        method: 'PATCH',
        token: admin.token,
        body: { approvalStatus: 'approved', approvalNoticeSeen: true },
      });
      console.log('Approved demo shop');
      const login = await req('/api/auth/login', {
        method: 'POST',
        body: { phone, password },
      });
      token = login.token;
    }
  } catch (e) {
    console.log('Approve skipped:', e.message);
  }

  const existing = await req('/api/products');
  if ((existing.products || []).length > 0) {
    console.log(`Already have ${existing.products.length} products — done.`);
    return;
  }

  for (const p of products) {
    const created = await req('/api/products', {
      method: 'POST',
      token,
      body: {
        ...p,
        shopName,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
    });
    console.log('+', created.product?.name);
  }

  const final = await req('/api/products');
  console.log(`Done. ${final.products.length} products online.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
