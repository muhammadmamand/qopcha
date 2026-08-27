import { useMemo } from 'react'
import type { ReactNode } from 'react'
import { collection, query } from 'firebase/firestore'
import { BarChart3, CheckCircle2, CircleDollarSign, ShoppingBag, Store } from 'lucide-react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { PageHeader, StatCard, LoadingState, ErrorState } from '../components/ui'
import { useTheme } from '../contexts/ThemeContext'
import { useCollection } from '../hooks/useCollection'
import { db } from '../lib/firebase'
import type { ManagedUser, Order } from '../lib/types'
import { money, statusLabel } from '../lib/utils'

const colors = ['#d4a017', '#e67e22', '#116c71', '#3b82f6', '#2d9b6a', '#d64550']

export function ReportsPage() {
  const { theme } = useTheme()
  const dark = theme === 'dark'
  const gridColor = dark ? '#1f4147' : '#e2e8f0'
  const axisColor = dark ? '#8ba0a4' : '#64757a'
  const tooltipStyle = {
    borderRadius: 14,
    borderColor: gridColor,
    background: dark ? '#10262a' : '#ffffff',
    color: dark ? '#e9f1f2' : '#101f22',
  }

  const orderSource = useMemo(() => query(collection(db, 'orders')), [])
  const userSource = useMemo(() => query(collection(db, 'users')), [])
  const orders = useCollection<Order>(orderSource)
  const users = useCollection<ManagedUser>(userSource)

  const completed = orders.data.filter((order) => order.status === 'completed')
  const revenue = completed.reduce(
    (sum, order) => sum + (order.total || 0) + (order.deliveryFee || 0),
    0,
  )
  const average = completed.length ? revenue / completed.length : 0

  const monthData = Array.from({ length: 6 }, (_, index) => {
    const date = new Date()
    date.setMonth(date.getMonth() - (5 - index))
    const month = date.getMonth()
    const year = date.getFullYear()
    const rows = completed.filter((order) => {
      const value = new Date(order.createdAt)
      return value.getMonth() === month && value.getFullYear() === year
    })
    return {
      month: new Intl.DateTimeFormat('ku', { month: 'short' }).format(date),
      revenue: rows.reduce(
        (sum, order) => sum + (order.total || 0) + (order.deliveryFee || 0),
        0,
      ),
      orders: rows.length,
    }
  })

  const statusData = ['pending', 'confirmed', 'ready', 'shipped', 'completed', 'cancelled'].map(
    (status) => ({
      name: statusLabel(status),
      value: orders.data.filter((order) => order.status === status).length,
    }),
  )

  const shopSales = Array.from(
    completed.reduce((map, order) => {
      const name = order.shopName || 'بێ ناو'
      map.set(name, (map.get(name) || 0) + order.total)
      return map
    }, new Map<string, number>()),
  )
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 6)

  return (
    <>
      <PageHeader
        title="ڕاپۆرت و ئامار"
        description="پوختەی فرۆش، داواکاری و گەشەی پلاتفۆرم"
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="کۆی فرۆش" value={money(revenue)} icon={CircleDollarSign} />
        <StatCard
          label="داواکاری تەواو"
          value={completed.length}
          icon={CheckCircle2}
          tone="green"
        />
        <StatCard label="ناوەندی داواکاری" value={money(average)} icon={ShoppingBag} tone="blue" />
        <StatCard
          label="دووکانی پەسەندکراو"
          value={
            users.data.filter(
              (user) => user.role === 'shopOwner' && user.approvalStatus === 'approved',
            ).length
          }
          icon={Store}
          tone="orange"
        />
      </div>

      {orders.loading || users.loading ? (
        <LoadingState />
      ) : orders.error || users.error ? (
        <ErrorState message={orders.error || users.error || ''} />
      ) : (
        <div className="grid gap-5 xl:grid-cols-2">
          <ChartPanel title="فرۆشی ٦ مانگی ڕابردوو" icon={BarChart3}>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={monthData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={gridColor} />
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
                  width={60}
                  stroke={axisColor}
                />
                <Tooltip
                  formatter={(value) => money(Number(value))}
                  contentStyle={tooltipStyle}
                  cursor={{ fill: dark ? '#ffffff12' : '#0000000a' }}
                />
                <Bar
                  dataKey="revenue"
                  fill={dark ? '#42aaae' : '#116c71'}
                  radius={[8, 8, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          </ChartPanel>

          <ChartPanel title="دابەشبوونی دۆخی داواکاری" icon={ShoppingBag}>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={statusData}
                  dataKey="value"
                  nameKey="name"
                  innerRadius={70}
                  outerRadius={105}
                  paddingAngle={3}
                >
                  {statusData.map((item, index) => (
                    <Cell key={item.name} fill={colors[index]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={tooltipStyle} />
              </PieChart>
            </ResponsiveContainer>
            <div className="flex flex-wrap justify-center gap-3">
              {statusData.map((item, index) => (
                <span key={item.name} className="flex items-center gap-1.5 text-xs text-slate-500">
                  <i className="size-2 rounded-full" style={{ background: colors[index] }} />
                  {item.name} ({item.value})
                </span>
              ))}
            </div>
          </ChartPanel>

          <section className="panel overflow-hidden xl:col-span-2">
            <div className="border-b border-slate-100 p-4">
              <h2 className="font-black text-slate-900">فرۆش بەپێی دووکان</h2>
            </div>
            <div className="divide-y divide-slate-100">
              {shopSales.map((shop, index) => (
                <div key={shop.name} className="flex items-center gap-3 px-4 py-3">
                  <span className="flex size-8 items-center justify-center rounded-lg bg-brand-50 text-xs font-black text-brand-700">
                    {index + 1}
                  </span>
                  <p className="flex-1 truncate text-sm font-bold text-slate-700">{shop.name}</p>
                  <p className="text-sm font-black text-brand-700">{money(shop.value)}</p>
                </div>
              ))}
            </div>
          </section>
        </div>
      )}
    </>
  )
}

function ChartPanel({
  title,
  icon: Icon,
  children,
}: {
  title: string
  icon: typeof BarChart3
  children: ReactNode
}) {
  return (
    <section className="panel p-4">
      <div className="mb-4 flex items-center gap-2">
        <Icon size={18} className="text-brand-700" />
        <h2 className="font-black text-slate-900">{title}</h2>
      </div>
      {children}
    </section>
  )
}
