import { useMemo, useState, type ReactNode } from 'react'
import { collection, query } from 'firebase/firestore'
import {
  BarChart3,
  Boxes,
  CheckCircle2,
  ChevronDown,
  Download,
  LayoutDashboard,
  Package,
  ReceiptText,
  Search,
  ShoppingBag,
  Store,
  Truck,
} from 'lucide-react'
import {
  Bar,
  CartesianGrid,
  Cell,
  ComposedChart,
  Legend,
  Line,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import {
  EmptyState,
  ErrorState,
  LoadingState,
  PageHeader,
  StatCard,
} from '../components/ui'
import { useTheme } from '../contexts/ThemeContext'
import { useCollection } from '../hooks/useCollection'
import { db } from '../lib/firebase'
import type { ManagedUser, Order } from '../lib/types'
import { cn, money, statusLabel } from '../lib/utils'

type Range = '6' | '12' | 'all'
type Tab = 'overview' | 'monthly' | 'shops'

interface ProductReport {
  key: string
  name: string
  imageUrl?: string
  quantity: number
  revenue: number
  unitPrice: number
}

interface ShopReport {
  key: string
  name: string
  orders: number
  quantity: number
  revenue: number
  delivery: number
  total: number
  products: ProductReport[]
}

interface MonthReport {
  key: string
  month: string
  orders: number
  sales: number
  delivery: number
  total: number
}

const statusColors = [
  '#d4a017',
  '#e67e22',
  '#116c71',
  '#3b82f6',
  '#2d9b6a',
  '#d64550',
]

function dateOf(order: Order) {
  const value = new Date(order.createdAt)
  return Number.isNaN(value.getTime()) ? new Date(0) : value
}

function monthKey(date: Date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`
}

function monthsFor(completed: Order[], range: Range) {
  const now = new Date()
  const first =
    range === 'all' && completed.length
      ? new Date(
          Math.min(
            ...completed
              .map((order) => dateOf(order).getTime())
              .filter((value) => value > 0),
          ),
        )
      : new Date(now.getFullYear(), now.getMonth() - (Number(range) - 1), 1)
  const start = Number.isNaN(first.getTime())
    ? new Date(now.getFullYear(), now.getMonth(), 1)
    : new Date(first.getFullYear(), first.getMonth(), 1)
  const months: Date[] = []
  const cursor = new Date(start)
  while (cursor <= now) {
    months.push(new Date(cursor))
    cursor.setMonth(cursor.getMonth() + 1)
  }
  return months
}

export function ReportsPage() {
  const { theme } = useTheme()
  const dark = theme === 'dark'
  const [range, setRange] = useState<Range>('6')
  const [tab, setTab] = useState<Tab>('overview')
  const [shopSearch, setShopSearch] = useState('')
  const [expandedShop, setExpandedShop] = useState<string | null>(null)
  const orderSource = useMemo(() => query(collection(db, 'orders')), [])
  const userSource = useMemo(() => query(collection(db, 'users')), [])
  const orders = useCollection<Order>(orderSource)
  const users = useCollection<ManagedUser>(userSource)

  const completed = useMemo(
    () => orders.data.filter((order) => order.status === 'completed'),
    [orders.data],
  )

  const reportMonths = useMemo(() => monthsFor(completed, range), [completed, range])
  const firstMonth = reportMonths[0]
  const rangeOrders = useMemo(
    () =>
      completed.filter((order) => {
        if (!firstMonth) return true
        const date = dateOf(order)
        return (
          date >= new Date(firstMonth.getFullYear(), firstMonth.getMonth(), 1)
        )
      }),
    [completed, firstMonth],
  )

  const monthly = useMemo<MonthReport[]>(
    () =>
      reportMonths.map((date) => {
        const key = monthKey(date)
        const rows = rangeOrders.filter((order) => monthKey(dateOf(order)) === key)
        const sales = rows.reduce((sum, order) => sum + (order.total || 0), 0)
        const delivery = rows.reduce(
          (sum, order) => sum + (order.deliveryFee || 0),
          0,
        )
        return {
          key,
          month: new Intl.DateTimeFormat('ku', {
            month: 'short',
            year: '2-digit',
          }).format(date),
          orders: rows.length,
          sales,
          delivery,
          total: sales + delivery,
        }
      }),
    [rangeOrders, reportMonths],
  )

  const shops = useMemo<ShopReport[]>(() => {
    const map = new Map<
      string,
      Omit<ShopReport, 'products'> & { products: Map<string, ProductReport> }
    >()
    for (const order of rangeOrders) {
      const key = order.shopOwnerId || order.shopName || 'unknown'
      const name = order.shopName?.trim() || 'دووکانی بێ ناو'
      const shop = map.get(key) ?? {
        key,
        name,
        orders: 0,
        quantity: 0,
        revenue: 0,
        delivery: 0,
        total: 0,
        products: new Map<string, ProductReport>(),
      }
      shop.orders += 1
      shop.delivery += order.deliveryFee || 0
      for (const item of order.items || []) {
        const quantity = Math.max(0, Number(item.quantity) || 0)
        const revenue =
          Number(item.lineTotal) || (Number(item.price) || 0) * quantity
        const productKey = item.productId || `${item.name}-${item.price}`
        const product = shop.products.get(productKey) ?? {
          key: productKey,
          name: item.name || 'کاڵای بێ ناو',
          imageUrl: item.imageUrl,
          quantity: 0,
          revenue: 0,
          unitPrice: 0,
        }
        product.quantity += quantity
        product.revenue += revenue
        product.unitPrice =
          product.quantity > 0 ? product.revenue / product.quantity : 0
        shop.products.set(productKey, product)
        shop.quantity += quantity
        shop.revenue += revenue
      }
      shop.total = shop.revenue + shop.delivery
      map.set(key, shop)
    }
    return Array.from(map.values())
      .map((shop) => ({
        ...shop,
        products: Array.from(shop.products.values()).sort(
          (a, b) => b.revenue - a.revenue,
        ),
      }))
      .sort((a, b) => b.revenue - a.revenue)
  }, [rangeOrders])

  const visibleShops = shops.filter((shop) =>
    shop.name.toLowerCase().includes(shopSearch.trim().toLowerCase()),
  )
  const productRevenue = rangeOrders.reduce(
    (sum, order) => sum + (order.total || 0),
    0,
  )
  const deliveryRevenue = rangeOrders.reduce(
    (sum, order) => sum + (order.deliveryFee || 0),
    0,
  )
  const soldUnits = rangeOrders.reduce(
    (sum, order) =>
      sum +
      (order.items || []).reduce(
        (itemSum, item) => itemSum + (Number(item.quantity) || 0),
        0,
      ),
    0,
  )
  const average = rangeOrders.length ? productRevenue / rangeOrders.length : 0
  const grandTotal = productRevenue + deliveryRevenue
  const approvedShops = users.data.filter(
    (user) => user.role === 'shopOwner' && user.approvalStatus === 'approved',
  ).length
  const statusData = [
    'pending',
    'confirmed',
    'ready',
    'shipped',
    'completed',
    'cancelled',
  ].map((status) => ({
    name: statusLabel(status),
    value: orders.data.filter((order) => order.status === status).length,
  }))

  const gridColor = dark ? '#1f4147' : '#e2e8f0'
  const axisColor = dark ? '#8ba0a4' : '#64757a'
  const tooltipStyle = {
    borderRadius: 14,
    borderColor: gridColor,
    background: dark ? '#10262a' : '#ffffff',
    color: dark ? '#e9f1f2' : '#101f22',
  }

  function exportCsv() {
    const rows = [
      ['دووکان', 'کاڵا', 'دانەی فرۆشراو', 'نرخی یەک دانە', 'کۆی کاڵا'],
      ...visibleShops.flatMap((shop) =>
        shop.products.map((product) => [
          shop.name,
          product.name,
          product.quantity,
          Math.round(product.unitPrice),
          Math.round(product.revenue),
        ]),
      ),
    ]
    const csv = `\uFEFF${rows
      .map((row) => row.map((cell) => `"${String(cell).replaceAll('"', '""')}"`).join(','))
      .join('\n')}`
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
    const link = document.createElement('a')
    link.href = url
    link.download = `shik-posh-report-${range}.csv`
    link.click()
    URL.revokeObjectURL(url)
  }

  return (
    <>
      <PageHeader
        title="ڕاپۆرتەکان"
        description="پوختە، ڕاپۆرتی مانگانە، و فرۆشی هەر دووکانێک — هەمووی بەپێی ماوەی هەڵبژێردراو"
      />

      <div className="panel mb-5 p-2 sm:p-3">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center">
          <SectionTabs tab={tab} onChange={setTab} />
          <div className="flex flex-1 flex-wrap items-center gap-2 lg:justify-end">
            <RangePills range={range} onChange={setRange} />
            {tab === 'shops' && (
              <>
                <div className="relative min-w-[200px] flex-1 sm:max-w-xs">
                  <Search
                    size={17}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                  />
                  <input
                    className="field pr-10"
                    value={shopSearch}
                    onChange={(event) => setShopSearch(event.target.value)}
                    placeholder="گەڕان بە ناوی دووکان..."
                  />
                </div>
                <button className="btn-secondary h-11 shrink-0" onClick={exportCsv}>
                  <Download size={17} /> CSV
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      {orders.loading || users.loading ? (
        <LoadingState />
      ) : orders.error || users.error ? (
        <ErrorState message={orders.error || users.error || ''} />
      ) : (
        <div key={tab} className="animate-rise space-y-5">
          {tab === 'overview' && (
            <>
              <div className="grid gap-3 lg:grid-cols-3">
                <section className="panel relative overflow-hidden p-5">
                  <span className="absolute inset-y-4 right-0 w-1 rounded-full bg-brand-600" />
                  <p className="text-xs font-extrabold text-ink-500">کۆی داهات</p>
                  <p className="mt-1 text-3xl font-black tracking-tight text-ink-900">
                    {money(grandTotal)}
                  </p>
                  <div className="mt-4 grid grid-cols-2 gap-2">
                    <div className="rounded-xl bg-brand-500/10 px-3 py-2.5">
                      <p className="text-[11px] font-bold text-brand-700 dark:text-brand-300">
                        فرۆشی کاڵا
                      </p>
                      <p className="mt-0.5 text-sm font-black text-ink-900">
                        {money(productRevenue)}
                      </p>
                    </div>
                    <div className="rounded-xl bg-orange-500/10 px-3 py-2.5">
                      <p className="text-[11px] font-bold text-orange-600 dark:text-orange-300">
                        گەیاندن
                      </p>
                      <p className="mt-0.5 text-sm font-black text-ink-900">
                        {money(deliveryRevenue)}
                      </p>
                    </div>
                  </div>
                </section>
                <div className="grid gap-3 sm:grid-cols-2 lg:col-span-2">
                  <StatCard
                    label="داواکاری تەواو"
                    value={rangeOrders.length}
                    icon={CheckCircle2}
                    tone="green"
                    hint={`${approvedShops} دووکانی پەسەندکراو`}
                  />
                  <StatCard
                    label="دانەی فرۆشراو"
                    value={soldUnits}
                    icon={Boxes}
                    tone="blue"
                    hint={`${shops.length} دووکان لەم ماوەیە`}
                  />
                  <StatCard
                    label="ناوەندی داواکاری"
                    value={money(average)}
                    icon={ReceiptText}
                    tone="gold"
                  />
                  <StatCard
                    label="دووکانی پەسەندکراو"
                    value={approvedShops}
                    icon={Store}
                    tone="orange"
                  />
                </div>
              </div>

              <div className="grid gap-5 xl:grid-cols-[1.45fr_0.75fr]">
                <ChartPanel
                  title="فرۆش بەپێی مانگ"
                  subtitle="فرۆشی کاڵا، گەیاندن و کۆی گشتی"
                  icon={BarChart3}
                >
                  <ResponsiveContainer width="100%" height={330}>
                    <ComposedChart data={monthly}>
                      <CartesianGrid
                        strokeDasharray="3 3"
                        vertical={false}
                        stroke={gridColor}
                      />
                      <XAxis
                        dataKey="month"
                        axisLine={false}
                        tickLine={false}
                        fontSize={11}
                        stroke={axisColor}
                      />
                      <YAxis
                        axisLine={false}
                        tickLine={false}
                        fontSize={10}
                        width={72}
                        stroke={axisColor}
                        tickFormatter={(value) =>
                          new Intl.NumberFormat('en', {
                            notation: 'compact',
                          }).format(value)
                        }
                      />
                      <Tooltip
                        formatter={(value, name) => [
                          money(Number(value)),
                          name === 'sales'
                            ? 'فرۆشی کاڵا'
                            : name === 'delivery'
                              ? 'گەیاندن'
                              : 'کۆی گشتی',
                        ]}
                        contentStyle={tooltipStyle}
                        cursor={{ fill: dark ? '#ffffff0a' : '#00000008' }}
                      />
                      <Legend
                        formatter={(value) =>
                          value === 'sales'
                            ? 'فرۆشی کاڵا'
                            : value === 'delivery'
                              ? 'گەیاندن'
                              : 'کۆی گشتی'
                        }
                      />
                      <Bar
                        dataKey="sales"
                        fill={dark ? '#42aaae' : '#116c71'}
                        radius={[7, 7, 0, 0]}
                      />
                      <Bar
                        dataKey="delivery"
                        fill="#e67e22"
                        radius={[7, 7, 0, 0]}
                      />
                      <Line
                        type="monotone"
                        dataKey="total"
                        stroke="#3b82f6"
                        strokeWidth={3}
                        dot={{ r: 3, fill: '#3b82f6' }}
                      />
                    </ComposedChart>
                  </ResponsiveContainer>
                </ChartPanel>

                <ChartPanel
                  title="دۆخی داواکارییەکان"
                  subtitle="هەموو داواکارییەکان — نەک تەنها تەواوکراوەکان"
                  icon={ShoppingBag}
                >
                  <ResponsiveContainer width="100%" height={260}>
                    <PieChart>
                      <Pie
                        data={statusData}
                        dataKey="value"
                        nameKey="name"
                        innerRadius={65}
                        outerRadius={98}
                        paddingAngle={3}
                      >
                        {statusData.map((item, index) => (
                          <Cell key={item.name} fill={statusColors[index]} />
                        ))}
                      </Pie>
                      <Tooltip contentStyle={tooltipStyle} />
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="flex flex-wrap justify-center gap-2">
                    {statusData.map((item, index) => (
                      <span
                        key={item.name}
                        className="flex items-center gap-1.5 rounded-full bg-subtle px-2.5 py-1 text-[11px] font-bold text-ink-500"
                      >
                        <i
                          className="size-2 rounded-full"
                          style={{ background: statusColors[index] }}
                        />
                        {item.name} ({item.value})
                      </span>
                    ))}
                  </div>
                </ChartPanel>
              </div>
            </>
          )}

          {tab === 'monthly' && <MonthlyDeliveryTable rows={monthly} />}

          {tab === 'shops' && (
            <section className="panel overflow-hidden">
              <div className="panel-head">
                <span className="flex size-10 items-center justify-center rounded-xl bg-brand-500/12 text-brand-700 dark:text-brand-300">
                  <Store size={20} />
                </span>
                <div>
                  <h2 className="font-black text-ink-900">فرۆش بەپێی دووکان</h2>
                  <p className="text-xs text-ink-500">
                    {visibleShops.length} دووکان · {soldUnits} دانە کاڵا · کلیک
                    بۆ کاڵاکان
                  </p>
                </div>
              </div>

              {visibleShops.length === 0 ? (
                <div className="p-4">
                  <EmptyState
                    icon={Store}
                    title="دووکان نەدۆزرایەوە"
                    description="لە ماوەی هەڵبژێردراودا هیچ فرۆشتنێکی تەواو نییە."
                  />
                </div>
              ) : (
                <div className="divide-y divide-line">
                  {visibleShops.map((shop, index) => (
                    <ShopSalesCard
                      key={shop.key}
                      shop={shop}
                      rank={index + 1}
                      expanded={expandedShop === shop.key}
                      onToggle={() =>
                        setExpandedShop((current) =>
                          current === shop.key ? null : shop.key,
                        )
                      }
                    />
                  ))}
                </div>
              )}
            </section>
          )}
        </div>
      )}
    </>
  )
}

function MonthlyDeliveryTable({ rows }: { rows: MonthReport[] }) {
  const totals = rows.reduce(
    (sum, row) => ({
      orders: sum.orders + row.orders,
      sales: sum.sales + row.sales,
      delivery: sum.delivery + row.delivery,
      total: sum.total + row.total,
    }),
    { orders: 0, sales: 0, delivery: 0, total: 0 },
  )

  if (rows.length === 0) {
    return (
      <section className="panel p-4">
        <EmptyState
          icon={BarChart3}
          title="ڕاپۆرتی مانگانە نییە"
          description="لەم ماوەیەدا هیچ داواکارییەکی تەواو نییە."
        />
      </section>
    )
  }

  return (
    <section className="panel overflow-hidden">
      <div className="panel-head">
        <span className="flex size-10 items-center justify-center rounded-xl bg-orange-500/12 text-orange-600 dark:text-orange-300">
          <Truck size={20} />
        </span>
        <div>
          <h2 className="font-black text-ink-900">ڕاپۆرتی مانگانە</h2>
          <p className="text-xs text-ink-500">
            فرۆش، گەیاندن و کۆی گشتی بۆ هەر مانگێک
          </p>
        </div>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[720px] text-right">
          <thead className="bg-subtle/70 text-[11px] font-extrabold text-ink-500">
            <tr>
              <th className="px-5 py-3">مانگ</th>
              <th className="px-4 py-3">داواکاری</th>
              <th className="px-4 py-3">فرۆشی کاڵا</th>
              <th className="px-4 py-3">پارەی گەیاندن</th>
              <th className="px-5 py-3">کۆی گشتی</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-line">
            {[...rows].reverse().map((row) => (
              <tr key={row.key} className="transition hover:bg-brand-500/5">
                <td className="px-5 py-3.5 text-sm font-black text-ink-900">
                  {row.month}
                </td>
                <td className="px-4 py-3.5 text-sm font-bold text-ink-700">
                  {row.orders}
                </td>
                <td className="px-4 py-3.5 text-sm font-bold text-ink-700">
                  {money(row.sales)}
                </td>
                <td className="px-4 py-3.5 text-sm font-black text-orange-600 dark:text-orange-300">
                  {money(row.delivery)}
                </td>
                <td className="px-5 py-3.5 text-sm font-black text-brand-700 dark:text-brand-300">
                  {money(row.total)}
                </td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr className="bg-subtle/80 text-sm font-black">
              <td className="px-5 py-3.5 text-ink-900">کۆی گشتی</td>
              <td className="px-4 py-3.5 text-ink-900">{totals.orders}</td>
              <td className="px-4 py-3.5 text-ink-900">{money(totals.sales)}</td>
              <td className="px-4 py-3.5 text-orange-600 dark:text-orange-300">
                {money(totals.delivery)}
              </td>
              <td className="px-5 py-3.5 text-brand-700 dark:text-brand-300">
                {money(totals.total)}
              </td>
            </tr>
          </tfoot>
        </table>
      </div>
    </section>
  )
}

function ShopSalesCard({
  shop,
  rank,
  expanded,
  onToggle,
}: {
  shop: ShopReport
  rank: number
  expanded: boolean
  onToggle: () => void
}) {
  return (
    <article>
      <button
        onClick={onToggle}
        className="flex w-full items-center gap-3 px-5 py-4 text-right transition hover:bg-brand-500/5"
      >
        <span
          className={cn(
            'flex size-10 shrink-0 items-center justify-center rounded-xl text-sm font-black',
            rank <= 3
              ? 'bg-amber-500/12 text-amber-600 dark:text-amber-300'
              : 'bg-subtle text-ink-500',
          )}
        >
          {rank}
        </span>
        <div className="min-w-0 flex-1">
          <h3 className="truncate font-black text-ink-900">{shop.name}</h3>
          <p className="mt-0.5 text-xs text-ink-500">
            {shop.orders} داواکاری · {shop.products.length} جۆر · {shop.quantity}{' '}
            دانە
          </p>
        </div>
        <div className="hidden gap-6 md:flex">
          <Metric label="فرۆشی کاڵا" value={money(shop.revenue)} />
          <Metric label="گەیاندن" value={money(shop.delivery)} orange />
          <Metric label="کۆی گشتی" value={money(shop.total)} brand />
        </div>
        <ChevronDown
          size={20}
          className={cn(
            'mr-2 shrink-0 text-ink-500 transition-transform duration-300',
            expanded && 'rotate-180 text-brand-600',
          )}
        />
      </button>

      <div
        className={cn(
          'grid transition-[grid-template-rows] duration-300',
          expanded ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]',
        )}
      >
        <div className="overflow-hidden">
          <div className="border-t border-line bg-subtle/35 p-4 sm:p-5">
            <div className="mb-4 grid grid-cols-3 gap-2 md:hidden">
              <Metric label="فرۆش" value={money(shop.revenue)} />
              <Metric label="گەیاندن" value={money(shop.delivery)} orange />
              <Metric label="گشتی" value={money(shop.total)} brand />
            </div>
            <div className="overflow-x-auto rounded-2xl border border-line bg-card">
              <table className="w-full min-w-[680px] text-right">
                <thead className="bg-subtle/70 text-[11px] font-extrabold text-ink-500">
                  <tr>
                    <th className="px-4 py-3">کاڵا</th>
                    <th className="px-4 py-3">دانەی فرۆشراو</th>
                    <th className="px-4 py-3">نرخی یەک دانە</th>
                    <th className="px-4 py-3">کۆی فرۆش</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-line">
                  {shop.products.map((product) => (
                    <tr
                      key={product.key}
                      className="transition hover:bg-brand-500/5"
                    >
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="flex size-11 shrink-0 items-center justify-center overflow-hidden rounded-xl bg-subtle text-ink-500">
                            {product.imageUrl ? (
                              <img
                                src={product.imageUrl}
                                alt=""
                                className="size-full object-cover"
                              />
                            ) : (
                              <Package size={18} />
                            )}
                          </div>
                          <span className="max-w-[280px] truncate text-sm font-black text-ink-900">
                            {product.name}
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm font-black text-ink-700">
                        {product.quantity}
                      </td>
                      <td className="px-4 py-3 text-sm font-bold text-ink-700">
                        {money(product.unitPrice)}
                      </td>
                      <td className="px-4 py-3 text-sm font-black text-brand-700 dark:text-brand-300">
                        {money(product.revenue)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </article>
  )
}

function Metric({
  label,
  value,
  brand = false,
  orange = false,
}: {
  label: string
  value: string
  brand?: boolean
  orange?: boolean
}) {
  return (
    <div className="min-w-0 text-center md:text-right">
      <p className="text-[10px] font-bold text-ink-500">{label}</p>
      <p
        className={cn(
          'mt-0.5 truncate text-xs font-black text-ink-900',
          brand && 'text-brand-700 dark:text-brand-300',
          orange && 'text-orange-600 dark:text-orange-300',
        )}
      >
        {value}
      </p>
    </div>
  )
}

function ChartPanel({
  title,
  subtitle,
  icon: Icon,
  children,
}: {
  title: string
  subtitle: string
  icon: typeof BarChart3
  children: ReactNode
}) {
  return (
    <section className="panel p-4 sm:p-5">
      <div className="mb-4 flex items-center gap-3">
        <span className="flex size-10 items-center justify-center rounded-xl bg-brand-500/12 text-brand-700 dark:text-brand-300">
          <Icon size={19} />
        </span>
        <div>
          <h2 className="font-black text-ink-900">{title}</h2>
          <p className="text-xs text-ink-500">{subtitle}</p>
        </div>
      </div>
      {children}
    </section>
  )
}

function SectionTabs({
  tab,
  onChange,
}: {
  tab: Tab
  onChange: (value: Tab) => void
}) {
  const items = [
    { id: 'overview' as const, label: 'پوختە', icon: LayoutDashboard },
    { id: 'monthly' as const, label: 'مانگانە', icon: BarChart3 },
    { id: 'shops' as const, label: 'دووکانەکان', icon: Store },
  ]
  return (
    <div className="flex rounded-xl bg-subtle p-1">
      {items.map(({ id, label, icon: Icon }) => (
        <button
          key={id}
          onClick={() => onChange(id)}
          className={cn(
            'inline-flex h-10 items-center gap-2 rounded-lg px-3.5 text-xs font-extrabold transition',
            tab === id
              ? 'bg-card text-brand-700 shadow-sm dark:text-brand-300'
              : 'text-ink-500 hover:text-ink-900',
          )}
        >
          <Icon size={15} />
          {label}
        </button>
      ))}
    </div>
  )
}

function RangePills({
  range,
  onChange,
}: {
  range: Range
  onChange: (value: Range) => void
}) {
  return (
    <div className="flex rounded-xl bg-subtle p-1">
      {(
        [
          ['6', '٦ مانگ'],
          ['12', '١٢ مانگ'],
          ['all', 'هەموو کات'],
        ] as const
      ).map(([value, label]) => (
        <button
          key={value}
          onClick={() => onChange(value)}
          className={cn(
            'h-10 rounded-lg px-3 text-xs font-extrabold transition',
            range === value
              ? 'bg-brand-700 text-white shadow-sm'
              : 'text-ink-500 hover:text-ink-900',
          )}
        >
          {label}
        </button>
      ))}
    </div>
  )
}
