import { useMemo, useState } from 'react'
import { collection, query } from 'firebase/firestore'
import { Crown, Medal, ShoppingBag, Store, Trophy, UserRound } from 'lucide-react'
import { useCollection } from '../hooks/useCollection'
import { db } from '../lib/firebase'
import { setCustomerDiscount } from '../lib/adminApi'
import type { ManagedUser, Order } from '../lib/types'
import { money, normalizeError } from '../lib/utils'
import { Badge, ErrorState, LoadingState, Modal, PageHeader, StatCard } from '../components/ui'

type Range = 'all' | 'month' | 'week'

export function LeadersPage() {
  const usersSource = useMemo(() => query(collection(db, 'users')), [])
  const ordersSource = useMemo(() => query(collection(db, 'orders')), [])
  const users = useCollection<ManagedUser>(usersSource)
  const orders = useCollection<Order>(ordersSource)
  const [range, setRange] = useState<Range>('month')
  const [vipUser, setVipUser] = useState<ManagedUser | null>(null)
  const [productPercent, setProductPercent] = useState(0)
  const [deliveryPercent, setDeliveryPercent] = useState(0)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  const filteredOrders = orders.data.filter((order) => {
    if (range === 'all') return true
    const age = Date.now() - new Date(order.createdAt).getTime()
    return age <= (range === 'week' ? 7 : 30) * 86_400_000
  })
  const countable = filteredOrders.filter(
    (order) => order.status !== 'pending' && order.status !== 'cancelled',
  )
  const completed = countable.filter((order) => order.status === 'completed')

  const shopRows = Array.from(
    completed.reduce((map, order) => {
      const key = order.shopOwnerId || order.shopName || 'unknown'
      const current = map.get(key) ?? {
        id: key,
        name: order.shopName || 'دووکانی بێ ناو',
        orders: 0,
        revenue: 0,
      }
      current.orders += 1
      current.revenue += (order.total ?? 0) + (order.deliveryFee ?? 0)
      map.set(key, current)
      return map
    }, new Map<string, { id: string; name: string; orders: number; revenue: number }>()).values(),
  ).sort((a, b) => b.revenue - a.revenue)

  const customerRows = Array.from(
    countable.reduce((map, order) => {
      const current = map.get(order.userId) ?? {
        id: order.userId,
        name: order.customerName || 'کڕیار',
        orders: 0,
        spend: 0,
      }
      current.orders += 1
      current.spend += (order.total ?? 0) + (order.deliveryFee ?? 0)
      map.set(order.userId, current)
      return map
    }, new Map<string, { id: string; name: string; orders: number; spend: number }>()).values(),
  ).sort((a, b) => b.spend - a.spend)

  const approvedShops = users.data.filter(
    (user) => user.role === 'shopOwner' && user.approvalStatus === 'approved',
  ).length

  return (
    <>
      <PageHeader
        title="باشترینەکان"
        description="دووکان و کڕیارە چالاکەکان بە پێی فرۆش و داواکاری"
        action={
          <div className="panel flex gap-1 p-1">
            {([
              ['week', '٧ ڕۆژ'],
              ['month', '٣٠ ڕۆژ'],
              ['all', 'هەموو'],
            ] as [Range, string][]).map(([value, label]) => (
              <button
                key={value}
                onClick={() => setRange(value)}
                className={
                  range === value
                    ? 'rounded-xl bg-brand-700 px-3 py-2 text-xs font-bold text-white'
                    : 'rounded-xl px-3 py-2 text-xs font-bold text-slate-500 hover:bg-slate-50'
                }
              >
                {label}
              </button>
            ))}
          </div>
        }
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-3">
        <StatCard label="دووکانی چالاک" value={approvedShops} icon={Store} />
        <StatCard label="داواکاری تەواو" value={completed.length} icon={ShoppingBag} tone="green" />
        <StatCard
          label="کۆی فرۆش"
          value={money(completed.reduce((sum, order) => sum + order.total, 0))}
          icon={Trophy}
          tone="orange"
        />
      </div>

      {users.loading || orders.loading ? (
        <LoadingState />
      ) : users.error || orders.error ? (
        <ErrorState message={users.error || orders.error || ''} />
      ) : (
        <div className="grid gap-5 xl:grid-cols-2">
          <Ranking
            title="باشترین دووکانەکان"
            icon={Store}
            rows={shopRows.slice(0, 10).map((row) => ({
              id: row.id,
              name: row.name,
              meta: `${row.orders} داواکاری`,
              value: money(row.revenue),
            }))}
          />
          <Ranking
            title="باشترین کڕیارەکان"
            icon={UserRound}
            onSelect={(id) => {
              const user = users.data.find((item) => item.id === id)
              if (!user) return
              setVipUser(user)
              setProductPercent(user.productDiscountPercent || 0)
              setDeliveryPercent(user.deliveryDiscountPercent || 0)
            }}
            rows={customerRows.slice(0, 10).map((row) => {
              const user = users.data.find((item) => item.id === row.id)
              return {
                id: row.id,
                name: row.name,
                meta: `${row.orders} داواکاری`,
                value: money(row.spend),
                badges: [
                  (user?.productDiscountPercent || 0) > 0
                    ? `جل ${user?.productDiscountPercent}٪`
                    : '',
                  (user?.deliveryDiscountPercent || 0) > 0
                    ? `گەیاندن ${user?.deliveryDiscountPercent}٪`
                    : '',
                ].filter(Boolean),
              }
            })}
          />
        </div>
      )}

      {message && (
        <div className="mt-4 rounded-xl border border-brand-200 bg-brand-50 px-4 py-3 text-sm font-bold text-brand-800">
          {message}
        </div>
      )}

      <Modal
        open={Boolean(vipUser)}
        title={`داشکانی تایبەت · ${vipUser?.name || ''}`}
        onClose={() => setVipUser(null)}
        footer={
          <div className="flex justify-end gap-2">
            <button
              className="btn-secondary"
              onClick={async () => {
                if (!vipUser) return
                setBusy(true)
                try {
                  await setCustomerDiscount(vipUser.id, 0, 0)
                  setVipUser(null)
                  setMessage('داشکاندن لابرا')
                } catch (reason) {
                  setMessage(normalizeError(reason))
                } finally {
                  setBusy(false)
                }
              }}
            >
              لابردن
            </button>
            <button
              className="btn-primary"
              disabled={busy}
              onClick={async () => {
                if (!vipUser) return
                setBusy(true)
                try {
                  await setCustomerDiscount(vipUser.id, productPercent, deliveryPercent)
                  setVipUser(null)
                  setMessage('داشکاندنی تایبەت پاشەکەوتکرا')
                } catch (reason) {
                  setMessage(normalizeError(reason))
                } finally {
                  setBusy(false)
                }
              }}
            >
              پاشەکەوت
            </button>
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

function Ranking({
  title,
  icon: Icon,
  rows,
  onSelect,
}: {
  title: string
  icon: typeof Store
  rows: { id: string; name: string; meta: string; value: string; badges?: string[] }[]
  onSelect?: (id: string) => void
}) {
  return (
    <section className="panel overflow-hidden">
      <div className="flex items-center gap-3 border-b border-slate-100 p-4">
        <div className="flex size-10 items-center justify-center rounded-xl bg-brand-50 text-brand-700">
          <Icon size={19} />
        </div>
        <h2 className="font-black text-slate-900">{title}</h2>
      </div>
      <div className="divide-y divide-slate-100">
        {rows.length === 0 ? (
          <p className="p-8 text-center text-sm text-slate-400">داتا نییە</p>
        ) : (
          rows.map((row, index) => (
            <button
              key={row.id}
              type="button"
              className="flex w-full items-center gap-3 p-4 text-right disabled:cursor-default"
              onClick={() => onSelect?.(row.id)}
              disabled={!onSelect}
            >
              <div
                className={
                  index === 0
                    ? 'flex size-9 items-center justify-center rounded-xl bg-amber-50 text-amber-600'
                    : 'flex size-9 items-center justify-center rounded-xl bg-slate-50 text-slate-500'
                }
              >
                {index === 0 ? <Crown size={18} /> : index < 3 ? <Medal size={18} /> : index + 1}
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-black text-slate-800">{row.name}</p>
                <p className="text-xs text-slate-400">{row.meta}</p>
                {row.badges && row.badges.length > 0 && (
                  <div className="mt-1 flex flex-wrap gap-1">
                    {row.badges.map((badge) => (
                      <Badge key={badge} tone="brand">{badge}</Badge>
                    ))}
                  </div>
                )}
              </div>
              <p className="text-sm font-black text-brand-700">{row.value}</p>
            </button>
          ))
        )}
      </div>
    </section>
  )
}
