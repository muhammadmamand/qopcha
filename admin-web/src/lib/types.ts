export type UserRole = 'customer' | 'shopOwner' | 'admin'
export type ApprovalStatus = 'pending' | 'approved' | 'rejected'
export type ShopTier = 'silver' | 'gold' | 'platinum'
export type OrderStatus =
  | 'pending'
  | 'confirmed'
  | 'ready'
  | 'shipped'
  | 'completed'
  | 'cancelled'

export interface ManagedUser {
  id: string
  name: string
  email: string
  phone: string
  role: UserRole
  approvalStatus: ApprovalStatus
  rejectionReason?: string | null
  approvalNoticeSeen?: boolean
  location?: string | null
  latitude?: number | null
  longitude?: number | null
  shopName?: string | null
  shopDescription?: string | null
  shopAddress?: string | null
  avatarUrl?: string | null
  shopLogoUrl?: string | null
  shopCoverUrl?: string | null
  shopTier?: ShopTier | null
  productDiscountPercent?: number
  deliveryDiscountPercent?: number
  createdAt: string
}

export interface SizeStock {
  size: string
  quantity: number
}

export interface Product {
  id: string
  shopOwnerId: string
  shopName: string
  name: string
  description: string
  category: string
  price: number
  colors: string[]
  material: string
  brand: string
  imageUrls: string[]
  sizeStocks: SizeStock[]
  isFeatured: boolean
  discountPercent: number
  discountAmount?: number
  discountType?: 'percent' | 'amount'
  discountForAllCustomers: boolean
  discountCustomerIds: string[]
  discountSetBy?: 'shop' | 'admin' | ''
  createdAt: string
  updatedAt: string
}

export interface OrderItem {
  productId?: string
  name: string
  imageUrl?: string
  shopName?: string
  shopOwnerId?: string
  size?: string
  color?: string
  quantity: number
  price: number
  lineTotal?: number
}

export interface Order {
  id: string
  userId: string
  customerName: string
  createdAt: string
  items: OrderItem[]
  total: number
  status: OrderStatus
  shopOwnerId?: string
  shopName?: string
  deliveryZone?: string
  deliveryFee?: number
  deliveryAddress?: string
  deliveryAddressLabel?: string
  deliveryLatitude?: number
  deliveryLongitude?: number
  customerPreferredSize?: string
  customerMeasurements?: Record<string, number | string | null>
}

export interface Banner {
  id: string
  title: string
  highlight: string
  subtitle: string
  cta: string
  tag: string
  imageUrl: string
  active: boolean
  order: number
  createdAt: string
}

export interface AppContent {
  aboutBody: string
  termsBody: string
  privacyBody: string
  supportPhone: string
  supportWhatsapp: string
  supportEmail: string
  supportHours: string
  socialInstagram: string
  socialFacebook: string
  socialTikTok: string
  socialTelegram: string
  homeTagline: string
  homePromoTitle: string
  homePromoSubtitle: string
  homeCta: string
  updatedAt: string
}

export interface AppNotification {
  id?: string
  title: string
  body: string
  type: string
  audience?: string
  targetUserId?: string | null
  productId?: string | null
  createdAt: string
  readBy?: string[]
}
