import { useMemo, useState } from 'react'
import { collection, query } from 'firebase/firestore'
import {
  Boxes,
  ImageOff,
  PackageCheck,
  Search,
  Star,
  Store,
  Trash2,
  TriangleAlert,
} from 'lucide-react'
import { useCollection } from '../hooks/useCollection'
import { db } from '../lib/firebase'
import { deleteProduct, setProductFeatured } from '../lib/adminApi'
import type { Product } from '../lib/types'
import { money, normalizeError, shortDate } from '../lib/utils'
import {
  Badge,
  EmptyState,
  ErrorState,
  LoadingState,
  Modal,
  PageHeader,
  StatCard,
} from '../components/ui'

export function ProductsPage() {
  const source = useMemo(() => query(collection(db, 'products')), [])
  const { data, loading, error } = useCollection<Product>(source)
  const products = [...data].sort(
    (a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime(),
  )
  const categories = Array.from(new Set(products.map((item) => item.category).filter(Boolean)))
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState('all')
  const [stock, setStock] = useState<'all' | 'in' | 'out'>('all')
  const [selected, setSelected] = useState<Product | null>(null)
  const [deleting, setDeleting] = useState<Product | null>(null)
  const [busy, setBusy] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const visible = products.filter((product) => {
    const totalStock = product.sizeStocks?.reduce((sum, item) => sum + item.quantity, 0) ?? 0
    if (category !== 'all' && product.category !== category) return false
    if (stock === 'in' && totalStock <= 0) return false
    if (stock === 'out' && totalStock > 0) return false
    const needle = search.trim().toLowerCase()
    if (!needle) return true
    return [product.name, product.shopName, product.brand, product.category]
      .some((value) => value?.toLowerCase().includes(needle))
  })

  async function toggleFeatured(product: Product) {
    setBusy(product.id)
    try {
      await setProductFeatured(product.id, !product.isFeatured)
      setMessage(product.isFeatured ? 'لە تایبەتەکان لابرا' : 'کرا بە بەرهەمی تایبەت')
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(null)
    }
  }

  async function remove() {
    if (!deleting) return
    setBusy(deleting.id)
    try {
      await deleteProduct(deleting.id)
      setDeleting(null)
      setMessage('بەرهەمەکە سڕایەوە')
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(null)
    }
  }

  return (
    <>
      <PageHeader
        title="بەرهەمەکان"
        description="چاودێری بەرهەم، کۆگا و بەرهەمە تایبەتەکان"
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="هەموو بەرهەمەکان" value={products.length} icon={Boxes} />
        <StatCard
          label="لە کۆگادایە"
          value={products.filter((item) => item.sizeStocks?.some((size) => size.quantity > 0)).length}
          icon={PackageCheck}
          tone="green"
        />
        <StatCard
          label="تەواوبوو"
          value={products.filter((item) => !item.sizeStocks?.some((size) => size.quantity > 0)).length}
          icon={TriangleAlert}
          tone="red"
        />
        <StatCard
          label="تایبەت"
          value={products.filter((item) => item.isFeatured).length}
          icon={Star}
          tone="orange"
        />
      </div>

      <div className="panel mb-4 flex flex-col gap-3 p-3 xl:flex-row">
        <div className="relative flex-1">
          <Search
            size={17}
            className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400"
          />
          <input
            className="field pr-10"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="گەڕان بە ناو، دووکان، براند یان پۆل..."
          />
        </div>
        <select className="field xl:w-48" value={category} onChange={(event) => setCategory(event.target.value)}>
          <option value="all">هەموو پۆلەکان</option>
          {categories.map((value) => (
            <option key={value} value={value}>{value}</option>
          ))}
        </select>
        <select className="field xl:w-40" value={stock} onChange={(event) => setStock(event.target.value as typeof stock)}>
          <option value="all">هەموو کۆگا</option>
          <option value="in">بەردەستە</option>
          <option value="out">تەواوبوو</option>
        </select>
      </div>

      {message && (
        <div className="mb-4 rounded-xl border border-brand-200 bg-brand-50 px-4 py-3 text-sm font-bold text-brand-800">
          {message}
        </div>
      )}

      {loading ? (
        <LoadingState />
      ) : error ? (
        <ErrorState message={error} />
      ) : visible.length === 0 ? (
        <EmptyState icon={Boxes} title="هیچ بەرهەمێک نەدۆزرایەوە" description="فلتەرەکان بگۆڕە." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
          {visible.map((product) => {
            const totalStock =
              product.sizeStocks?.reduce((sum, item) => sum + item.quantity, 0) ?? 0
            return (
              <article key={product.id} className="panel overflow-hidden">
                <button
                  className="relative block aspect-[4/3] w-full overflow-hidden bg-slate-100"
                  onClick={() => setSelected(product)}
                >
                  {product.imageUrls?.[0] ? (
                    <img
                      src={product.imageUrls[0]}
                      alt={product.name}
                      className="size-full object-cover transition duration-300 hover:scale-105"
                    />
                  ) : (
                    <ImageOff className="absolute inset-0 m-auto text-slate-300" />
                  )}
                  <div className="absolute right-3 top-3 flex gap-2">
                    {product.discountPercent > 0 && (
                      <Badge tone="red">{Math.round(product.discountPercent)}٪-</Badge>
                    )}
                    {product.isFeatured && <Badge tone="gold">تایبەت</Badge>}
                  </div>
                </button>
                <div className="p-4">
                  <h3 className="truncate font-black text-slate-900">{product.name}</h3>
                  <p className="mt-1 flex items-center gap-1 truncate text-xs text-slate-400">
                    <Store size={12} /> {product.shopName}
                  </p>
                  <div className="mt-4 flex items-end justify-between">
                    <div>
                      <p className="text-lg font-black text-brand-700">{money(product.price)}</p>
                      <p className={totalStock > 0 ? 'text-xs font-bold text-emerald-600' : 'text-xs font-bold text-rose-600'}>
                        {totalStock > 0 ? `${totalStock} دانە` : 'تەواوبوو'}
                      </p>
                    </div>
                    <p className="text-[11px] text-slate-400">{shortDate(product.updatedAt)}</p>
                  </div>
                  <div className="mt-4 flex gap-2 border-t border-slate-100 pt-3">
                    <button
                      className="btn-secondary h-10 flex-1"
                      onClick={() => toggleFeatured(product)}
                      disabled={busy === product.id}
                    >
                      <Star size={15} fill={product.isFeatured ? 'currentColor' : 'none'} />
                      {product.isFeatured ? 'لابردن' : 'تایبەت'}
                    </button>
                    <button
                      className="inline-flex size-10 items-center justify-center rounded-xl bg-rose-50 text-rose-600"
                      onClick={() => setDeleting(product)}
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
              </article>
            )
          })}
        </div>
      )}

      <Modal open={Boolean(selected)} title="وردەکاری بەرهەم" onClose={() => setSelected(null)} wide>
        {selected && (
          <div className="grid gap-5 md:grid-cols-2">
            <div className="aspect-square overflow-hidden rounded-2xl bg-slate-100">
              {selected.imageUrls?.[0] && (
                <img src={selected.imageUrls[0]} alt="" className="size-full object-cover" />
              )}
            </div>
            <div>
              <h3 className="text-xl font-black text-slate-900">{selected.name}</h3>
              <p className="mt-2 text-sm leading-7 text-slate-500">{selected.description}</p>
              <dl className="mt-5 grid grid-cols-2 gap-2">
                {[
                  ['نرخ', money(selected.price)],
                  ['پۆل', selected.category],
                  ['براند', selected.brand],
                  ['مادە', selected.material],
                  ['ڕەنگ', selected.colors?.join('، ') || '—'],
                  ['داشکاندن', `${selected.discountPercent || 0}٪`],
                ].map(([label, value]) => (
                  <div key={label} className="rounded-xl bg-slate-50 p-3">
                    <dt className="text-[11px] text-slate-400">{label}</dt>
                    <dd className="mt-1 text-sm font-black text-slate-800">{value}</dd>
                  </div>
                ))}
              </dl>
            </div>
          </div>
        )}
      </Modal>

      <Modal
        open={Boolean(deleting)}
        title="سڕینەوەی بەرهەم"
        onClose={() => setDeleting(null)}
        footer={
          <div className="flex justify-end gap-2">
            <button className="btn-secondary" onClick={() => setDeleting(null)}>پاشگەزبوونەوە</button>
            <button
              className="inline-flex h-11 items-center rounded-xl bg-rose-600 px-4 text-sm font-bold text-white"
              onClick={remove}
              disabled={busy === deleting?.id}
            >
              سڕینەوە
            </button>
          </div>
        }
      >
        <p className="text-sm leading-7 text-slate-600">
          دڵنیایت لە سڕینەوەی «{deleting?.name}»؟ ئەم کردارە ناگەڕێتەوە.
        </p>
      </Modal>
    </>
  )
}
