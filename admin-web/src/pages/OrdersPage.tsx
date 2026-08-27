import { useMemo, useState } from 'react'
import { collection, query } from 'firebase/firestore'
import {
  CheckCircle2,
  ClipboardList,
  Clock3,
  MapPin,
  Search,
  Store,
  Truck,
  UserRound,
} from 'lucide-react'
import { useCollection } from '../hooks/useCollection'
import { db } from '../lib/firebase'
import { DELIVERY_ZONES, setOrderDelivery, updateOrderStatus } from '../lib/adminApi'
import type { ManagedUser, Order, OrderStatus } from '../lib/types'
import {
  money,
  normalizeError,
  shortDateTime,
  statusLabel,
} from '../lib/utils'
import {
  Badge,
  EmptyState,
  ErrorState,
  LoadingState,
  Modal,
  PageHeader,
  StatCard,
} from '../components/ui'
import { PreparingBanner, PreparingItemMark } from '../components/PreparingBanner'

const statusTone: Record<OrderStatus, 'orange' | 'brand' | 'blue' | 'green' | 'red'> = {
  pending: 'orange',
  confirmed: 'brand',
  ready: 'green',
  shipped: 'blue',
  completed: 'green',
  cancelled: 'red',
}

const transitions: Record<OrderStatus, OrderStatus[]> = {
  pending: [],
  confirmed: [],
  ready: ['shipped'],
  shipped: ['completed'],
  completed: [],
  cancelled: [],
}

export function OrdersPage({ delivery = false }: { delivery?: boolean }) {
  const source = useMemo(() => query(collection(db, 'orders')), [])
  const usersSource = useMemo(() => query(collection(db, 'users')), [])
  const { data, loading, error } = useCollection<Order>(source)
  const users = useCollection<ManagedUser>(usersSource)
  const orders = [...data].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
  )
  const [filter, setFilter] = useState<'all' | OrderStatus>(
    delivery ? 'confirmed' : 'pending',
  )
  const [search, setSearch] = useState('')
  const [selected, setSelected] = useState<Order | null>(null)
  const [zoneOrder, setZoneOrder] = useState<Order | null>(null)
  const [busy, setBusy] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const base = delivery
    ? orders.filter((order) =>
        ['confirmed', 'ready', 'shipped', 'completed'].includes(order.status),
      )
    : orders.filter((order) => ['pending', 'cancelled'].includes(order.status))
  const visible = base.filter((order) => {
    if (filter !== 'all' && order.status !== filter) return false
    const needle = search.trim().toLowerCase()
    if (!needle) return true
    return [
      order.id,
      order.customerName,
      order.shopName,
      order.deliveryAddress,
      order.deliveryAddressLabel,
    ]
      .filter(Boolean)
      .some((value) => value!.toLowerCase().includes(needle))
  })

  function customerOf(order: Order) {
    return users.data.find((user) => user.id === order.userId)
  }

  async function setStatus(order: Order, status: OrderStatus) {
    if (status === 'shipped' && !(order.deliveryFee && order.deliveryFee > 0)) {
      setZoneOrder(order)
      return
    }
    setBusy(order.id)
    setMessage(null)
    try {
      await updateOrderStatus(order.id, status)
      setMessage(`دۆخی داواکاری گۆڕدرا بۆ ${statusLabel(status)}`)
      setSelected(null)
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(null)
    }
  }

  async function assignZone(zoneId: string, fee: number) {
    if (!zoneOrder) return
    const vip = customerOf(zoneOrder)?.deliveryDiscountPercent ?? 0
    const charged = Math.round(fee * (1 - Math.min(100, Math.max(0, vip)) / 100))
    setBusy(zoneOrder.id)
    try {
      await setOrderDelivery(zoneOrder.id, zoneId, charged)
      if (zoneOrder.status === 'ready') {
        await updateOrderStatus(zoneOrder.id, 'shipped')
        setMessage('دەستی بە گەیاندن کرد')
      } else {
        setMessage('کرێی گەیاندن نوێکرایەوە')
      }
      setZoneOrder(null)
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(null)
    }
  }

  return (
    <>
      <PageHeader
        title={delivery ? 'گەیاندن' : 'داواکارییەکان'}
        description={
          delivery
            ? 'ئامادەیە → نێردراو → گەیشتوو'
            : 'داواکاریی نوێ چاوەڕوانی قبوڵکردنی دووکانن — ئەدمین قبوڵیان ناکات'
        }
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="هەموو" value={base.length} icon={ClipboardList} />
        <StatCard
          label={delivery ? 'ئامادەیە' : 'چاوەڕوان'}
          value={
            base.filter((item) =>
              delivery ? item.status === 'ready' : item.status === 'pending',
            ).length
          }
          icon={Clock3}
          tone="orange"
        />
        <StatCard
          label="لە گەیاندندا"
          value={base.filter((item) => item.status === 'shipped').length}
          icon={Truck}
          tone="blue"
        />
        <StatCard
          label="تەواوکراو"
          value={base.filter((item) => item.status === 'completed').length}
          icon={CheckCircle2}
          tone="green"
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
            placeholder="گەڕان بە کۆد، ناوی کڕیار، دووکان یان ناونیشان..."
          />
        </div>
        <div className="flex gap-2 overflow-x-auto">
          {(
            delivery
              ? (['all', 'confirmed', 'ready', 'shipped', 'completed'] as const)
              : (['all', 'pending', 'cancelled'] as const)
          ).map((status) => (
            <button
              key={status}
              className={filter === status ? 'btn-primary h-11 shrink-0' : 'btn-secondary h-11 shrink-0'}
              onClick={() => setFilter(status)}
            >
              {status === 'all' ? 'هەموو' : statusLabel(status)}
            </button>
          ))}
        </div>
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
        <EmptyState
          icon={delivery ? Truck : ClipboardList}
          title="هیچ داواکارییەک نییە"
          description="لە ئێستادا هیچ داواکارییەک لەم دۆخەدا نییە."
        />
      ) : (
        <div className="grid gap-3 xl:grid-cols-2">
          {visible.map((order) => (
            <article key={order.id} className="panel p-4">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="font-black text-slate-900">
                    #{order.id.replace(/[^a-zA-Z0-9]/g, '').slice(0, 8).toUpperCase()}
                  </p>
                  <p className="mt-1 text-xs text-slate-400">
                    {shortDateTime(order.createdAt)}
                  </p>
                </div>
                <Badge tone={statusTone[order.status]}>{statusLabel(order.status)}</Badge>
              </div>

              <div className="mt-4 grid grid-cols-2 gap-2">
                <div className="rounded-xl bg-slate-50 p-3">
                  <p className="flex items-center gap-1 text-[11px] font-bold text-slate-400">
                    <UserRound size={12} /> کڕیار
                  </p>
                  <p className="mt-1 truncate text-sm font-black text-slate-800">
                    {order.customerName || 'کڕیار'}
                  </p>
                </div>
                <div className="rounded-xl bg-slate-50 p-3">
                  <p className="flex items-center gap-1 text-[11px] font-bold text-slate-400">
                    <Store size={12} /> دووکان
                  </p>
                  <p className="mt-1 truncate text-sm font-black text-slate-800">
                    {order.shopName || '—'}
                  </p>
                </div>
              </div>

              <div className="mt-3 flex items-end justify-between">
                <div>
                  <p className="text-xs text-slate-400">
                    {order.items?.reduce((sum, item) => sum + (item.quantity || 0), 0)} بەرهەم
                  </p>
                  <p className="mt-1 text-lg font-black text-brand-700">
                    {money((order.total || 0) + (order.deliveryFee || 0))}
                  </p>
                </div>
                <button className="btn-secondary h-10" onClick={() => setSelected(order)}>
                  وردەکاری
                </button>
              </div>

              {order.status === 'pending' && (
                <p className="mt-3 border-t border-slate-100 pt-3 text-xs font-bold text-amber-700">
                  چاوەڕوانی قبوڵکردنی دووکان — ئەدمین ئەم داواکارییە قبوڵ ناکات
                </p>
              )}

              {order.status === 'confirmed' && (
                <>
                  <PreparingBanner shopName={order.shopName} />
                  {order.items?.length > 0 && (
                    <div className="mt-3 flex flex-wrap gap-2">
                      {order.items.map((item, index) => (
                        <div
                          key={`${item.productId}-${index}`}
                          className="relative size-14 overflow-hidden rounded-xl bg-slate-100"
                        >
                          {item.imageUrl && (
                            <img src={item.imageUrl} alt="" className="size-full object-cover" />
                          )}
                          <div className="absolute inset-0 flex items-center justify-center bg-white/75">
                            <PreparingItemMark />
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </>
              )}

              {transitions[order.status].length > 0 && (
                <div className="mt-3 flex gap-2 border-t border-slate-100 pt-3">
                  {(order.status === 'ready' || order.status === 'shipped') && (
                    <button
                      className="btn-secondary h-10 flex-1 text-xs"
                      onClick={() => setZoneOrder(order)}
                    >
                      کرێی گەیاندن
                    </button>
                  )}
                  {transitions[order.status].map((status) => (
                    <button
                      key={status}
                      className={
                        status === 'cancelled'
                          ? 'inline-flex h-10 flex-1 items-center justify-center rounded-xl bg-rose-50 text-xs font-bold text-rose-700'
                          : 'btn-primary h-10 flex-1 text-xs'
                      }
                      disabled={busy === order.id}
                      onClick={() => setStatus(order, status)}
                    >
                      {status === 'shipped'
                        ? 'دەستپێکردنی گەیاندن'
                        : status === 'completed'
                          ? 'گەیاندن تەواو بوو'
                          : status === 'confirmed'
                            ? 'قبوڵکردن'
                            : 'ڕەتکردنەوە'}
                    </button>
                  ))}
                </div>
              )}
            </article>
          ))}
        </div>
      )}

      <Modal
        open={Boolean(selected)}
        title="وردەکاری داواکاری"
        onClose={() => setSelected(null)}
        wide
      >
        {selected && (
          <div className="space-y-5">
            <div className="grid gap-3 sm:grid-cols-3">
              <Info label="کڕیار" value={selected.customerName || '—'} />
              <Info label="دووکان" value={selected.shopName || '—'} />
              <Info
                label="کۆی گشتی"
                value={money((selected.total || 0) + (selected.deliveryFee || 0))}
              />
            </div>
            {selected.status === 'confirmed' && (
              <PreparingBanner shopName={selected.shopName} />
            )}
            {(selected.deliveryAddress || selected.deliveryAddressLabel) && (
              <div className="rounded-2xl border border-brand-100 bg-brand-50 p-4">
                <p className="flex items-center gap-2 text-xs font-black text-brand-800">
                  <MapPin size={15} /> ناونیشانی گەیاندن
                </p>
                <p className="mt-2 text-sm text-brand-900">
                  {selected.deliveryAddressLabel || selected.deliveryAddress}
                </p>
                {selected.deliveryLatitude && selected.deliveryLongitude ? (
                  <a
                    className="mt-3 inline-flex text-xs font-black text-brand-700 underline"
                    href={`https://www.google.com/maps/search/?api=1&query=${selected.deliveryLatitude},${selected.deliveryLongitude}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    کردنەوە لە نەخشە
                  </a>
                ) : selected.deliveryAddress ? (
                  <a
                    className="mt-3 inline-flex text-xs font-black text-brand-700 underline"
                    href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(selected.deliveryAddress)}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    کردنەوە لە نەخشە
                  </a>
                ) : null}
                {customerOf(selected)?.phone && (
                  <a
                    className="mt-3 mr-4 inline-flex text-xs font-black text-brand-700 underline"
                    href={`tel:${customerOf(selected)?.phone}`}
                  >
                    پەیوەندی
                  </a>
                )}
              </div>
            )}
            <div className="overflow-hidden rounded-2xl border border-slate-200">
              <div className="border-b border-slate-100 bg-slate-50 px-4 py-3 text-xs font-black text-slate-500">
                بەرهەمەکان
              </div>
              <div className="divide-y divide-slate-100">
                {selected.items?.map((item, index) => (
                  <div key={`${item.productId}-${index}`} className="flex items-center gap-3 p-3">
                    <div className="relative size-12 overflow-hidden rounded-xl bg-slate-100">
                      {item.imageUrl && (
                        <img src={item.imageUrl} alt="" className="size-full object-cover" />
                      )}
                      {selected.status === 'confirmed' && (
                        <div className="absolute inset-0 flex items-center justify-center bg-white/75">
                          <PreparingItemMark />
                        </div>
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-black text-slate-800">{item.name}</p>
                      <p className="mt-1 text-xs text-slate-400">
                        {item.size || '—'} · {item.color || '—'} · ×{item.quantity}
                      </p>
                    </div>
                    <p className="text-sm font-black text-slate-700">
                      {money(item.lineTotal ?? item.price * item.quantity)}
                    </p>
                  </div>
                ))}
              </div>
            </div>
            {selected.customerMeasurements &&
              Object.keys(selected.customerMeasurements).length > 0 && (
                <div>
                  <h3 className="mb-3 font-black text-slate-800">قیاسەکانی کڕیار</h3>
                  <div className="grid gap-2 sm:grid-cols-3">
                    {Object.entries(selected.customerMeasurements).map(([key, value]) => (
                      <Info key={key} label={key} value={String(value ?? '—')} />
                    ))}
                  </div>
                </div>
              )}
          </div>
        )}
      </Modal>

      <Modal
        open={Boolean(zoneOrder)}
        title="ناوچەی گەیاندن هەڵبژێرە"
        onClose={() => setZoneOrder(null)}
      >
        {zoneOrder && (
          <div className="space-y-3">
            {(customerOf(zoneOrder)?.deliveryDiscountPercent || 0) > 0 && (
              <p className="rounded-xl bg-brand-50 px-3 py-2 text-xs font-bold text-brand-800">
                داشکاندنی گەیاندنی کڕیار: {customerOf(zoneOrder)?.deliveryDiscountPercent}٪
              </p>
            )}
            {DELIVERY_ZONES.map((zone) => {
              const vip = customerOf(zoneOrder)?.deliveryDiscountPercent ?? 0
              const charged = Math.round(zone.fee * (1 - Math.min(100, Math.max(0, vip)) / 100))
              return (
                <button
                  key={zone.id}
                  className="flex w-full items-center justify-between rounded-2xl border border-slate-200 p-4 text-right hover:border-brand-300 hover:bg-brand-50"
                  disabled={busy === zoneOrder.id}
                  onClick={() => assignZone(zone.id, zone.fee)}
                >
                  <span>
                    <span className="block text-sm font-black text-slate-800">{zone.label}</span>
                    {charged !== zone.fee && (
                      <span className="mt-1 block text-xs text-slate-400 line-through">
                        {money(zone.fee)}
                      </span>
                    )}
                  </span>
                  <span className="text-sm font-black text-brand-700">{money(charged)}</span>
                </button>
              )
            })}
          </div>
        )}
      </Modal>
    </>
  )
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl bg-slate-50 p-3">
      <p className="text-[11px] font-bold text-slate-400">{label}</p>
      <p className="mt-1 text-sm font-black text-slate-800">{value}</p>
    </div>
  )
}
