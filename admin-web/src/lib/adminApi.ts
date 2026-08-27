import {
  addDoc,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore'
import {
  deleteObject,
  getDownloadURL,
  ref,
  uploadBytes,
} from 'firebase/storage'
import { db, storage } from './firebase'
import type {
  ApprovalStatus,
  Banner,
  Order,
  OrderStatus,
  Product,
  ShopTier,
} from './types'
import { money } from './utils'

function nowIso() {
  return new Date().toISOString()
}

async function addNotification(data: {
  type:
    | 'account_approved'
    | 'admin_announcement'
    | 'discount_assigned'
    | 'order_delivered'
  title: string
  body: string
  category: string
  targetUserId?: string | null
  shopOwnerId?: string
  shopName?: string
  productId?: string
  productName?: string
  imageUrl?: string | null
}) {
  const targeted = Boolean(data.targetUserId)
  await addDoc(collection(db, 'notifications'), {
    type: data.type,
    title: data.title,
    body: data.body,
    shopOwnerId: data.shopOwnerId ?? '',
    shopName: data.shopName ?? 'قۆپچە',
    productId: data.productId ?? '',
    productName: data.productName ?? '',
    category: data.category,
    imageUrl: data.imageUrl ?? null,
    audience: targeted ? 'user' : 'all',
    createdAt: nowIso(),
    ...(targeted ? { targetUserId: data.targetUserId } : {}),
  })
}

export async function setApproval(
  userId: string,
  status: ApprovalStatus,
  rejectionReason?: string,
) {
  const payload: Record<string, unknown> = { approvalStatus: status }
  if (status === 'rejected') {
    payload.rejectionReason =
      rejectionReason?.trim() || 'هەژمارەکەت لەلایەن ئەدمینەوە ڕەتکرایەوە'
  } else {
    payload.rejectionReason = deleteField()
  }
  if (status === 'approved') payload.approvalNoticeSeen = false
  await setDoc(doc(db, 'users', userId), payload, { merge: true })

  if (status === 'approved') {
    try {
      const snap = await getDoc(doc(db, 'users', userId))
      const user = snap.data()
      const name = String(user?.name || '').trim() || 'هاوڕێ'
      const shop = String(user?.shopName || '').trim()
      const isShop = user?.role === 'shopOwner'
      await addNotification({
        type: 'account_approved',
        title: isShop ? 'دووکانەکەت پەسەند کرا' : 'هەژمارەکەت پەسەند کرا',
        body: isShop
          ? shop
            ? `${name}، دووکانی «${shop}» قبوڵ کرا. ئێستا دەتوانیت بەرهەم زیاد بکەیت و فرۆش بکەیت.`
            : `${name}، هەژماری دووکانەکەت قبوڵ کرا. ئێستا دەتوانیت بەرهەم زیاد بکەیت و فرۆش بکەیت.`
          : `${name}، هەژمارەکەت قبوڵ کرا. ئێستا دەتوانیت داواکاری بکەیت.`,
        category: 'account',
        targetUserId: userId,
        shopOwnerId: isShop ? userId : '',
        shopName: shop,
      })
    } catch {
      // Approval itself succeeded; notification is best-effort.
    }
  }
}

export async function setShopTier(userId: string, shopTier: ShopTier) {
  await setDoc(doc(db, 'users', userId), { shopTier }, { merge: true })
}

export const DELIVERY_ZONES = [
  { id: 'insideCity', label: 'ناو شار', fee: 3000 },
  { id: 'outside120m', label: 'دەرەوەی شەقامی ١٢٠ مەتری', fee: 4000 },
  { id: 'outside150m', label: 'دەرەوەی شەقامی ١٥٠ مەتری', fee: 5000 },
] as const

export async function setCustomerDiscount(
  userId: string,
  productDiscountPercent: number,
  deliveryDiscountPercent: number,
) {
  const product = Math.min(70, Math.max(0, Number(productDiscountPercent) || 0))
  const delivery = Math.min(100, Math.max(0, Number(deliveryDiscountPercent) || 0))
  await setDoc(
    doc(db, 'users', userId),
    { productDiscountPercent: product, deliveryDiscountPercent: delivery },
    { merge: true },
  )
  if (product > 0 || delivery > 0) {
    try {
      await addNotification({
        type: 'discount_assigned',
        title: 'داشکاندنی تایبەتت بۆ دانرا',
        body: `داشکاندنی بەرهەم ${product}٪، داشکاندنی گەیاندن ${delivery}٪`,
        category: 'discount',
        targetUserId: userId,
      })
    } catch {
      // Discount saved even if the notice fails.
    }
  }
}

export async function updateOrderStatus(orderId: string, status: OrderStatus) {
  const orderRef = doc(db, 'orders', orderId)
  const before = status === 'completed' ? await getDoc(orderRef) : null
  await updateDoc(orderRef, {
    status,
    statusUpdatedAt: nowIso(),
  })
  if (status === 'completed') {
    try {
      const data = (before?.data() ?? (await getDoc(orderRef)).data()) as
        | Record<string, unknown>
        | undefined
      if (data) {
        await announceOrderDelivered({ id: orderId, ...data } as Order)
      }
    } catch {
      // Delivery status is authoritative; the inbox notice is best-effort.
    }
  }
}

async function announceOrderDelivered(order: Order) {
  const target = (order.userId || '').trim()
  if (!target) return
  const name = (order.customerName || '').trim() || 'کڕیار'
  const shops = Array.from(
    new Set(
      [
        order.shopName,
        ...(order.items || []).map((item) => item.shopName),
      ].filter((value): value is string => Boolean(value && value.trim())),
    ),
  )
  const shopLabel = shops.join('، ') || 'دووکان'
  const itemNames = (order.items || [])
    .map((item) => (item.name || '').trim())
    .filter(Boolean)
    .slice(0, 3)
  const extra =
    (order.items?.length || 0) > 3 ? ` و ${(order.items?.length || 0) - 3}ی تر` : ''
  const itemCount = (order.items || []).reduce(
    (sum, item) => sum + (item.quantity || 0),
    0,
  )
  const address =
    (order.deliveryAddressLabel || '').trim() ||
    (order.deliveryAddress || '').trim()
  const shortId = order.id.replace(/[^a-zA-Z0-9]/g, '').slice(0, 6).toUpperCase()
  const lines = [
    `بەڕێز ${name}، کاڵاکە گەیشت. دەتوانن لە شۆفێری گەیاندنەکە وەری بگرن.`,
    '',
    `داواکاری #${shortId || order.id.slice(0, 6).toUpperCase()}`,
    `دووکان: ${shopLabel}`,
    itemNames.length
      ? `بەرهەم: ${itemCount} دانە — ${itemNames.join('، ')}${extra}`
      : `بەرهەم: ${itemCount} دانە`,
  ]
  if (address) lines.push(`ناونیشان: ${address}`)
  lines.push(`کۆی گشتی: ${money((order.total || 0) + (order.deliveryFee || 0))}`)

  const id = `order_delivered_${order.id}`
  await setDoc(doc(db, 'notifications', id), {
    id,
    type: 'order_delivered',
    title: 'کاڵاکە گەیشت',
    body: lines.join('\n'),
    shopOwnerId: order.shopOwnerId || '',
    shopName: shopLabel,
    productId: order.id,
    productName: itemNames.join('، '),
    category: 'order',
    imageUrl: order.items?.[0]?.imageUrl || null,
    audience: 'user',
    targetUserId: target,
    createdAt: nowIso(),
  })
}

export async function setOrderDelivery(
  orderId: string,
  zoneId: string,
  fee: number,
) {
  await updateDoc(doc(db, 'orders', orderId), {
    deliveryZone: zoneId,
    deliveryFee: Math.max(0, Number(fee) || 0),
    deliveryUpdatedAt: nowIso(),
  })
}

export async function setProductDiscount(
  product: Product,
  discountPercent: number,
  discountForAllCustomers: boolean,
  discountCustomerIds: string[],
) {
  const amount = Math.min(70, Math.max(0, Number(discountPercent) || 0))
  const forAll = Boolean(discountForAllCustomers) || amount <= 0
  const customerIds = forAll ? [] : discountCustomerIds.filter(Boolean)
  await updateDoc(doc(db, 'products', product.id), {
    discountPercent: amount,
    discountAmount: 0,
    discountType: 'percent',
    discountForAllCustomers: forAll,
    discountCustomerIds: customerIds,
    discountSetBy: amount > 0 ? 'admin' : '',
    updatedAt: nowIso(),
  })
  if (amount > 0) {
    const targets = forAll ? [null] : customerIds
    try {
      await Promise.all(
        targets.map((targetUserId) =>
          addNotification({
            type: 'discount_assigned',
            title: 'داشکاندنی نوێ',
            body: `${product.name || 'بەرهەم'} بە ${amount}٪ داشکاندن`,
            category: 'discount',
            shopOwnerId: product.shopOwnerId || '',
            shopName: product.shopName || 'دووکان',
            productId: product.id,
            productName: product.name || '',
            imageUrl: product.imageUrls?.[0] ?? null,
            targetUserId,
          }),
        ),
      )
    } catch {
      // Discount saved even if the notice fails.
    }
  }
}

export function deleteProduct(productId: string) {
  return deleteDoc(doc(db, 'products', productId))
}

export function setProductFeatured(productId: string, isFeatured: boolean) {
  return updateDoc(doc(db, 'products', productId), {
    isFeatured,
    updatedAt: nowIso(),
  })
}

export async function saveBanner(
  values: Omit<Banner, 'id' | 'createdAt'>,
  id?: string,
) {
  const refDoc = id
    ? doc(db, 'banners', id)
    : doc(collection(db, 'banners'))
  await setDoc(
    refDoc,
    id ? values : { ...values, createdAt: nowIso() },
    { merge: true },
  )
}

export function setBannerActive(id: string, active: boolean) {
  return updateDoc(doc(db, 'banners', id), { active })
}

export function deleteBanner(id: string) {
  return deleteDoc(doc(db, 'banners', id))
}

const ALLOWED_BANNER_TYPES = new Set(['image/jpeg', 'image/jpg', 'image/png', 'image/webp'])
const MAX_BANNER_BYTES = 8 * 1024 * 1024

export async function uploadBannerImage(file: File) {
  if (!ALLOWED_BANNER_TYPES.has(file.type)) {
    throw new Error('تەنها وێنەی JPG، PNG یان WebP ڕێگەپێدراوە')
  }
  if (file.size > MAX_BANNER_BYTES) {
    throw new Error('قەبارەی وێنە نابێت لە ٨ مێگابایت زیاتر بێت')
  }
  const cleanName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_')
  const object = ref(
    storage,
    `banner_images/${Date.now()}_${crypto.randomUUID()}_${cleanName}`,
  )
  await uploadBytes(object, file, { contentType: file.type })
  return getDownloadURL(object)
}

export async function deleteStorageUrl(url: string) {
  if (!url) return
  try {
    await deleteObject(ref(storage, url))
  } catch {
    // Old external URLs or already-deleted files need no cleanup.
  }
}

export function saveAppContent(values: Record<string, string>) {
  return setDoc(
    doc(db, 'appContent', 'main'),
    { ...values, updatedAt: nowIso() },
    { merge: true },
  )
}

export async function sendAnnouncement(
  title: string,
  body: string,
  category: string,
) {
  const trimmedTitle = title.trim()
  const trimmedBody = body.trim()
  if (!trimmedTitle || !trimmedBody) {
    throw new Error('ناونیشان و دەق پێویستن')
  }
  await addNotification({
    type: 'admin_announcement',
    title: trimmedTitle,
    body: trimmedBody,
    category: category.trim() || 'system',
  })
}
