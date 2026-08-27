import { useMemo, useState } from 'react'
import { collection, query } from 'firebase/firestore'
import {
  BadgePercent,
  Package,
  Search,
  Sparkles,
  Store,
  Truck,
  UserRound,
} from 'lucide-react'
import { useCollection } from '../hooks/useCollection'
import { db } from '../lib/firebase'
import { setCustomerDiscount, setProductDiscount } from '../lib/adminApi'
import type { ManagedUser, Product } from '../lib/types'
import { money, normalizeError } from '../lib/utils'
import {
  Badge,
  EmptyState,
  ErrorState,
  LoadingState,
  Modal,
  PageHeader,
  StatCard,
} from '../components/ui'

function isProductDiscounted(item: Product) {
  if (item.discountType === 'amount') return (item.discountAmount || 0) > 0
  return (item.discountPercent || 0) > 0
}

function productDiscountLabel(item: Product) {
  if (item.discountType === 'amount' && (item.discountAmount || 0) > 0) {
    return `${money(item.discountAmount)}-`
  }
  if ((item.discountPercent || 0) > 0) {
    return `${Math.round(item.discountPercent)}٪-`
  }
  return ''
}

export function DiscountsPage() {
  const productSource = useMemo(() => query(collection(db, 'products')), [])
  const userSource = useMemo(() => query(collection(db, 'users')), [])
  const products = useCollection<Product>(productSource)
  const users = useCollection<ManagedUser>(userSource)
  const customers = users.data.filter(
    (user) => user.role === 'customer' && user.approvalStatus === 'approved',
  )
  const [tab, setTab] = useState<'products' | 'customers'>('products')
  const [productView, setProductView] = useState<'discounted' | 'shop' | 'all'>(
    'discounted',
  )
  const [search, setSearch] = useState('')
  const [product, setProduct] = useState<Product | null>(null)
  const [customer, setCustomer] = useState<ManagedUser | null>(null)
  const [percent, setPercent] = useState(0)
  const [forAll, setForAll] = useState(true)
  const [targetIds, setTargetIds] = useState<string[]>([])
  const [productPercent, setProductPercent] = useState(0)
  const [deliveryPercent, setDeliveryPercent] = useState(0)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  const needle = search.trim().toLowerCase()
  const shopDiscounts = products.data.filter(
    (item) => isProductDiscounted(item) && item.discountSetBy === 'shop',
  )
  const visibleProducts = products.data
    .filter((item) => {
      if (productView === 'discounted' && !isProductDiscounted(item)) return false
      if (productView === 'shop' && !(item.discountSetBy === 'shop' && isProductDiscounted(item))) {
        return false
      }
      if (!needle) return true
      return [item.name, item.shopName].some((value) =>
        value?.toLowerCase().includes(needle),
      )
    })
    .sort((a, b) => {
      const shopA = a.discountSetBy === 'shop' && isProductDiscounted(a) ? 1 : 0
      const shopB = b.discountSetBy === 'shop' && isProductDiscounted(b) ? 1 : 0
      if (shopB !== shopA) return shopB - shopA
      return (b.discountPercent || 0) - (a.discountPercent || 0)
    })
  const visibleCustomers = customers.filter((item) =>
    !needle || [item.name, item.email, item.phone].some((value) => value.toLowerCase().includes(needle)),
  )

  function editProduct(item: Product) {
    setProduct(item)
    setPercent(item.discountPercent || 0)
    setForAll(item.discountForAllCustomers ?? true)
    setTargetIds(item.discountCustomerIds || [])
  }

  function editCustomer(item: ManagedUser) {
    setCustomer(item)
    setProductPercent(item.productDiscountPercent || 0)
    setDeliveryPercent(item.deliveryDiscountPercent || 0)
  }

  async function saveProduct() {
    if (!product) return
    if (!forAll && percent > 0 && targetIds.length === 0) {
      setMessage('لانیکەم کڕیارێک هەڵبژێرە')
      return
    }
    setBusy(true)
    try {
      await setProductDiscount(product, percent, forAll, targetIds)
      setProduct(null)
      setMessage('داشکاندنی بەرهەم نوێکرایەوە')
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(false)
    }
  }

  async function saveCustomer() {
    if (!customer) return
    setBusy(true)
    try {
      await setCustomerDiscount(customer.id, productPercent, deliveryPercent)
      setCustomer(null)
      setMessage('داشکاندنی تایبەتی کڕیار نوێکرایەوە')
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(false)
    }
  }

  const discountedProducts = products.data.filter((item) => isProductDiscounted(item))
  const vipCustomers = customers.filter(
    (item) => (item.productDiscountPercent || 0) > 0 || (item.deliveryDiscountPercent || 0) > 0,
  )

  return (
    <>
      <PageHeader
        title="بەڕێوەبردنی داشکاندن"
        description="داشکاندنی دووکانەکان و ئۆفەری ئەدمین — کاتێک خاوەن دووکان داشکاندن دابنێت لێرە دەردەکەوێت"
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="بەرهەمی داشکاندراو" value={discountedProducts.length} icon={Package} />
        <StatCard
          label="داشکاندنی دووکان"
          value={shopDiscounts.length}
          icon={Store}
          tone="orange"
        />
        <StatCard label="کڕیاری VIP" value={vipCustomers.length} icon={Sparkles} tone="blue" />
        <StatCard
          label="داشکاندنی گەیاندن"
          value={customers.filter((item) => (item.deliveryDiscountPercent || 0) > 0).length}
          icon={Truck}
          tone="green"
        />
      </div>

      <div className="panel mb-4 p-3">
        <div className="flex flex-col gap-3 sm:flex-row">
          <div className="flex rounded-xl bg-slate-100 p-1">
            <button
              className={tab === 'products' ? 'rounded-lg bg-card px-4 py-2 text-xs font-black text-brand-700 shadow-sm transition dark:text-brand-300' : 'px-4 py-2 text-xs font-bold text-slate-500 transition'}
              onClick={() => setTab('products')}
            >
              ئۆفەری بەرهەم
            </button>
            <button
              className={tab === 'customers' ? 'rounded-lg bg-card px-4 py-2 text-xs font-black text-brand-700 shadow-sm transition dark:text-brand-300' : 'px-4 py-2 text-xs font-bold text-slate-500 transition'}
              onClick={() => setTab('customers')}
            >
              داشکاندنی کڕیار
            </button>
          </div>
          <div className="relative flex-1">
            <Search size={17} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <input className="field pr-10" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="گەڕان..." />
          </div>
          {tab === 'products' && (
            <div className="flex flex-wrap gap-2">
              {(
                [
                  ['discounted', 'داشکاندراو'],
                  ['shop', 'لەلایەن دووکان'],
                  ['all', 'هەموو بەرهەم'],
                ] as const
              ).map(([id, label]) => (
                <button
                  key={id}
                  onClick={() => setProductView(id)}
                  className={
                    productView === id ? 'btn-primary h-10' : 'btn-secondary h-10'
                  }
                >
                  {label}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {message && (
        <div className="mb-4 rounded-xl border border-brand-200 bg-brand-50 px-4 py-3 text-sm font-bold text-brand-800">
          {message}
        </div>
      )}

      {products.loading || users.loading ? (
        <LoadingState />
      ) : products.error || users.error ? (
        <ErrorState message={products.error || users.error || ''} />
      ) : tab === 'products' ? (
        visibleProducts.length === 0 ? (
          <EmptyState
            icon={Package}
            title={productView === 'shop' ? 'داشکاندنی دووکان نییە' : 'بەرهەم نییە'}
            description={
              productView === 'shop'
                ? 'کاتێک خاوەن دووکان داشکاندن دابنێت، لێرە دەردەکەوێت.'
                : 'هیچ بەرهەمێک نەدۆزرایەوە.'
            }
          />
        ) : (
          <div className="grid gap-3 xl:grid-cols-2">
            {visibleProducts.map((item) => {
              const shopSet = item.discountSetBy === 'shop' && isProductDiscounted(item)
              return (
              <article key={item.id} className="panel flex items-center gap-4 p-4">
                <div className="size-16 shrink-0 overflow-hidden rounded-2xl bg-slate-100">
                  {item.imageUrls?.[0] && <img src={item.imageUrls[0]} alt="" className="size-full object-cover" />}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <h3 className="truncate font-black text-slate-900">{item.name}</h3>
                    {isProductDiscounted(item) && (
                      <Badge tone="red">{productDiscountLabel(item)}</Badge>
                    )}
                    {shopSet && <Badge tone="orange">لەلایەن دووکان</Badge>}
                    {isProductDiscounted(item) && item.discountSetBy === 'admin' && (
                      <Badge tone="brand">لەلایەن ئەدمین</Badge>
                    )}
                  </div>
                  <p className="mt-1 truncate text-xs text-slate-400">{item.shopName} · {money(item.price)}</p>
                  {isProductDiscounted(item) && (
                    <p className="mt-1 text-[11px] font-bold text-brand-700">
                      {item.discountType === 'amount'
                        ? `بڕی ${money(item.discountAmount || 0)} لە نرخ کەمکراوەتەوە`
                        : item.discountForAllCustomers ? 'بۆ هەموو کڕیارەکان' : `بۆ ${item.discountCustomerIds.length} کڕیار`}
                      {shopSet ? ' · خاوەن دووکان داناوەتی' : ''}
                    </p>
                  )}
                </div>
                <button className="btn-secondary h-10 shrink-0" onClick={() => editProduct(item)}>
                  <BadgePercent size={16} /> ڕێکخستن
                </button>
              </article>
              )
            })}
          </div>
        )
      ) : visibleCustomers.length === 0 ? (
        <EmptyState icon={UserRound} title="کڕیار نییە" description="هیچ کڕیارێک نەدۆزرایەوە." />
      ) : (
        <div className="grid gap-3 xl:grid-cols-2">
          {visibleCustomers.map((item) => (
            <article key={item.id} className="panel flex items-center gap-4 p-4">
              <div className="flex size-12 shrink-0 items-center justify-center rounded-2xl bg-brand-50 font-black text-brand-700">
                {item.name.slice(0, 1)}
              </div>
              <div className="min-w-0 flex-1">
                <h3 className="truncate font-black text-slate-900">{item.name}</h3>
                <p className="mt-1 truncate text-xs text-slate-400">{item.email}</p>
                <div className="mt-2 flex gap-2">
                  {(item.productDiscountPercent || 0) > 0 && <Badge tone="brand">بەرهەم {item.productDiscountPercent}٪</Badge>}
                  {(item.deliveryDiscountPercent || 0) > 0 && <Badge tone="green">گەیاندن {item.deliveryDiscountPercent}٪</Badge>}
                </div>
              </div>
              <button className="btn-secondary h-10 shrink-0" onClick={() => editCustomer(item)}>
                ڕێکخستن
              </button>
            </article>
          ))}
        </div>
      )}

      <Modal
        open={Boolean(product)}
        title={`داشکاندنی ${product?.name || ''}`}
        onClose={() => setProduct(null)}
        footer={
          <div className="flex justify-end gap-2">
            <button className="btn-secondary" onClick={() => setProduct(null)}>پاشگەزبوونەوە</button>
            <button className="btn-primary" onClick={saveProduct} disabled={busy}>پاشەکەوتکردن</button>
          </div>
        }
      >
        <label className="block">
          <span className="mb-2 block text-xs font-black text-slate-600">ڕێژەی داشکاندن (تا ٧٠٪)</span>
          <input className="field" type="number" min="0" max="70" value={percent} onChange={(event) => setPercent(Number(event.target.value))} />
        </label>
        <label className="mt-4 flex items-center gap-3 rounded-xl bg-slate-50 p-3 text-sm font-bold text-slate-700">
          <input type="checkbox" checked={forAll} onChange={(event) => setForAll(event.target.checked)} />
          بۆ هەموو کڕیارەکان
        </label>
        {!forAll && (
          <div className="mt-4 max-h-56 space-y-2 overflow-y-auto rounded-xl border border-slate-200 p-2">
            {customers.map((item) => (
              <label key={item.id} className="flex items-center gap-3 rounded-lg p-2 hover:bg-slate-50">
                <input
                  type="checkbox"
                  checked={targetIds.includes(item.id)}
                  onChange={(event) =>
                    setTargetIds((ids) =>
                      event.target.checked ? [...ids, item.id] : ids.filter((id) => id !== item.id),
                    )
                  }
                />
                <span className="text-sm font-bold text-slate-700">{item.name}</span>
              </label>
            ))}
          </div>
        )}
      </Modal>

      <Modal
        open={Boolean(customer)}
        title={`داشکاندنی ${customer?.name || ''}`}
        onClose={() => setCustomer(null)}
        footer={
          <div className="flex justify-end gap-2">
            <button className="btn-secondary" onClick={() => setCustomer(null)}>پاشگەزبوونەوە</button>
            <button className="btn-primary" onClick={saveCustomer} disabled={busy}>پاشەکەوتکردن</button>
          </div>
        }
      >
        <div className="grid gap-4 sm:grid-cols-2">
          <label>
            <span className="mb-2 block text-xs font-black text-slate-600">داشکاندنی بەرهەم ٪ (تا ٧٠)</span>
            <input className="field" type="number" min="0" max="70" value={productPercent} onChange={(event) => setProductPercent(Number(event.target.value))} />
          </label>
          <label>
            <span className="mb-2 block text-xs font-black text-slate-600">داشکاندنی گەیاندن ٪</span>
            <input className="field" type="number" min="0" max="100" value={deliveryPercent} onChange={(event) => setDeliveryPercent(Number(event.target.value))} />
          </label>
        </div>
      </Modal>
    </>
  )
}
