'use strict';

/**
 * Seed starter clothing products on the live API using admin login.
 * Usage:
 *   node scripts/seed_products_admin.js [baseUrl]
 *   ADMIN_EMAIL=admin@qopcha.com ADMIN_PASSWORD=... node scripts/seed_products_admin.js
 */
const BASE = (process.argv[2] || 'https://169-58-230-144.sslip.io').replace(/\/$/, '');
const ADMIN_EMAIL = (process.env.ADMIN_EMAIL || 'admin@qopcha.com').toLowerCase();
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Admin123456';

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
    description: 'شەرتی نەرم و ڕۆژانە',
    category: 'پۆشاک',
    price: 35000,
    colors: ['سپی', 'ڕەش'],
    material: 'کاتن',
    brand: 'قۆپچە',
    imageUrls: ['https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800'],
    sizeStocks: [{ size: 'M', quantity: 8 }, { size: 'L', quantity: 10 }],
    isFeatured: true,
    productType: 'clothing',
    shopName: 'قۆپچە',
  },
  {
    name: 'جلکی هاوینەی ئافرەتان',
    description: 'جلکی سووک و مۆدێرن',
    category: 'کراس',
    price: 55000,
    colors: ['پەمەیی', 'سپی'],
    material: 'لینن',
    brand: 'قۆپچە',
    imageUrls: ['https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=800'],
    sizeStocks: [{ size: 'S', quantity: 5 }, { size: 'M', quantity: 7 }],
    isFeatured: true,
    discountPercent: 15,
    discountType: 'percent',
    discountForAllCustomers: true,
    discountSetBy: 'shop',
    productType: 'clothing',
    shopName: 'قۆپچە',
  },
  {
    name: 'پانتۆڵی جین',
    description: 'جینی نەرم بۆ ڕۆژانە',
    category: 'پانتۆڵ',
    price: 48000,
    colors: ['شینی جین'],
    material: 'دینم',
    brand: 'قۆپچە',
    imageUrls: ['https://images.unsplash.com/photo-1542272604-787c3835535d?w=800'],
    sizeStocks: [{ size: '32', quantity: 6 }, { size: '34', quantity: 5 }],
    isFeatured: false,
    productType: 'clothing',
    shopName: 'قۆپچە',
  },
  {
    name: 'کۆتی زستانە',
    description: 'کۆتی گەرم و مۆدێرن',
    category: 'کۆت',
    price: 89000,
    colors: ['ڕەش', 'قاوەیی'],
    material: 'وۆڵ',
    brand: 'قۆپچە',
    imageUrls: ['https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=800'],
    sizeStocks: [{ size: 'L', quantity: 4 }, { size: 'XL', quantity: 3 }],
    isFeatured: true,
    productType: 'clothing',
    shopName: 'قۆپچە',
  },
];

async function main() {
  console.log(`Seeding products on ${BASE}`);
  await req('/api/health');

  const existing = await req('/api/products');
  if ((existing.products || []).length > 0) {
    console.log(`Already have ${existing.products.length} products — done.`);
    return;
  }

  const login = await req('/api/auth/login', {
    method: 'POST',
    body: { email: ADMIN_EMAIL, password: ADMIN_PASSWORD },
  });
  const token = login.token;
  if (!token) throw new Error('Admin login failed — check ADMIN_EMAIL / ADMIN_PASSWORD');

  for (const product of products) {
    const created = await req('/api/products', {
      method: 'POST',
      token,
      body: {
        ...product,
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
  console.error(err.message || err);
  process.exit(1);
});
