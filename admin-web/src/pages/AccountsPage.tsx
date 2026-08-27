import { useMemo, useState } from 'react'
import { collection, query } from 'firebase/firestore'
import {
  Check,
  Clock3,
  MapPin,
  Search,
  ShieldX,
  Store,
  UserRound,
  Users,
} from 'lucide-react'
import { useCollection } from '../hooks/useCollection'
import { db } from '../lib/firebase'
import { setApproval, setShopTier } from '../lib/adminApi'
import type { ApprovalStatus, ManagedUser, ShopTier } from '../lib/types'
import { normalizeError, shortDate, statusLabel } from '../lib/utils'
import {
  Badge,
  EmptyState,
  ErrorState,
  LoadingState,
  Modal,
  PageHeader,
  StatCard,
} from '../components/ui'

type Filter = 'all' | ApprovalStatus

function statusTone(status: ApprovalStatus) {
  if (status === 'approved') return 'green' as const
  if (status === 'rejected') return 'red' as const
  return 'orange' as const
}

export function AccountsPage() {
  const source = useMemo(() => query(collection(db, 'users')), [])
  const { data, loading, error } = useCollection<ManagedUser>(source)
  const users = data.filter((user) => user.role !== 'admin')
  const [filter, setFilter] = useState<Filter>('pending')
  const [role, setRole] = useState<'all' | 'customer' | 'shopOwner'>('all')
  const [search, setSearch] = useState('')
  const [selected, setSelected] = useState<ManagedUser | null>(null)
  const [rejecting, setRejecting] = useState<ManagedUser | null>(null)
  const [reason, setReason] = useState('')
  const [busy, setBusy] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const visible = users.filter((user) => {
    if (filter !== 'all' && user.approvalStatus !== filter) return false
    if (role !== 'all' && user.role !== role) return false
    const needle = search.trim().toLowerCase()
    if (!needle) return true
    return [user.name, user.email, user.phone, user.shopName]
      .filter(Boolean)
      .some((value) => value!.toLowerCase().includes(needle))
  })

  async function approve(user: ManagedUser) {
    setBusy(user.id)
    setMessage(null)
    try {
      await setApproval(user.id, 'approved')
      setMessage('هەژمارەکە پەسەندکرا')
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(null)
    }
  }

  async function reject() {
    if (!rejecting) return
    setBusy(rejecting.id)
    try {
      await setApproval(rejecting.id, 'rejected', reason)
      setRejecting(null)
      setReason('')
      setMessage('هەژمارەکە ڕەتکرایەوە')
    } catch (value) {
      setMessage(normalizeError(value))
    } finally {
      setBusy(null)
    }
  }

  async function changeTier(user: ManagedUser, tier: ShopTier) {
    setBusy(user.id)
    try {
      await setShopTier(user.id, tier)
      setMessage('پلانی دووکان نوێکرایەوە')
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(null)
    }
  }

  return (
    <>
      <PageHeader
        title="بەڕێوەبردنی هەژمارەکان"
        description="پەسەندکردن و بەڕێوەبردنی کڕیار و خاوەن دووکانەکان"
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="هەموو هەژمارەکان" value={users.length} icon={Users} />
        <StatCard
          label="چاوەڕوان"
          value={users.filter((item) => item.approvalStatus === 'pending').length}
          icon={Clock3}
          tone="orange"
        />
        <StatCard
          label="خاوەن دووکان"
          value={users.filter((item) => item.role === 'shopOwner').length}
          icon={Store}
          tone="blue"
        />
        <StatCard
          label="کڕیار"
          value={users.filter((item) => item.role === 'customer').length}
          icon={UserRound}
          tone="green"
        />
      </div>

      <div className="panel mb-4 flex flex-col gap-3 p-3 xl:flex-row xl:items-center">
        <div className="relative flex-1">
          <Search
            size={17}
            className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400"
          />
          <input
            className="field pr-10"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="گەڕان بە ناو، ئیمەیڵ، ژمارە یان ناوی دووکان..."
          />
        </div>
        <div className="flex flex-wrap gap-2">
          {(['pending', 'approved', 'rejected', 'all'] as Filter[]).map((item) => (
            <button
              key={item}
              onClick={() => setFilter(item)}
              className={
                filter === item
                  ? 'btn-primary h-10'
                  : 'btn-secondary h-10'
              }
            >
              {item === 'all' ? 'هەموو' : statusLabel(item)}
            </button>
          ))}
          <select
            className="field h-10 w-auto"
            value={role}
            onChange={(event) => setRole(event.target.value as typeof role)}
          >
            <option value="all">هەموو جۆرەکان</option>
            <option value="customer">کڕیار</option>
            <option value="shopOwner">خاوەن دووکان</option>
          </select>
        </div>
      </div>

      {message && (
        <div
          className={
            message.includes('پەسەند') ||
            message.includes('ڕەتکرا') ||
            message.includes('نوێکرا')
              ? 'mb-4 rounded-xl border border-brand-200 bg-brand-50 px-4 py-3 text-sm font-bold text-brand-800'
              : 'mb-4 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-bold text-rose-700'
          }
        >
          {message}
        </div>
      )}
      {loading ? (
        <LoadingState />
      ) : error ? (
        <ErrorState message={error} />
      ) : visible.length === 0 ? (
        <EmptyState
          icon={Users}
          title="هیچ هەژمارێک نەدۆزرایەوە"
          description="فلتەرەکان بگۆڕە یان وشەیەکی تر بگەڕێ."
        />
      ) : (
        <div className="grid gap-3 xl:grid-cols-2">
          {visible.map((user) => (
            <article key={user.id} className="panel p-4">
              <div className="flex items-start gap-3">
                <button
                  onClick={() => setSelected(user)}
                  className="flex size-12 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-brand-50 font-black text-brand-700"
                >
                  {user.avatarUrl || user.shopLogoUrl ? (
                    <img
                      src={user.avatarUrl || user.shopLogoUrl || ''}
                      alt=""
                      className="size-full object-cover"
                    />
                  ) : (
                    user.name?.slice(0, 1) || <UserRound size={20} />
                  )}
                </button>
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <h3 className="truncate font-black text-slate-900">
                      {user.role === 'shopOwner' && user.shopName
                        ? user.shopName
                        : user.name}
                    </h3>
                    <Badge tone={user.role === 'shopOwner' ? 'blue' : 'brand'}>
                      {statusLabel(user.role)}
                    </Badge>
                    <Badge tone={statusTone(user.approvalStatus)}>
                      {statusLabel(user.approvalStatus)}
                    </Badge>
                  </div>
                  <p className="mt-1 truncate text-xs text-slate-500">
                    {user.email} · {user.phone}
                  </p>
                  <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-[11px] text-slate-400">
                    <span>{shortDate(user.createdAt)}</span>
                    {user.location && (
                      <span className="inline-flex items-center gap-1">
                        <MapPin size={12} /> {user.location}
                      </span>
                    )}
                    {user.approvalStatus === 'rejected' && user.rejectionReason && (
                      <span className="text-rose-600">{user.rejectionReason}</span>
                    )}
                  </div>
                </div>
              </div>

              {user.role === 'shopOwner' && user.approvalStatus === 'approved' && (
                <div className="mt-4 flex items-center justify-between rounded-xl bg-slate-50 p-2.5">
                  <span className="text-xs font-bold text-slate-500">پلانی دووکان</span>
                  <select
                    className="rounded-lg border border-line bg-card px-2.5 py-1.5 text-xs font-bold text-ink-900 outline-none"
                    value={user.shopTier ?? 'silver'}
                    disabled={busy === user.id}
                    onChange={(event) =>
                      changeTier(user, event.target.value as ShopTier)
                    }
                  >
                    <option value="silver">سیلڤەر</option>
                    <option value="gold">گۆڵد</option>
                    <option value="platinum">پلاتینیۆم</option>
                  </select>
                </div>
              )}

              <div className="mt-4 flex gap-2">
                <button className="btn-secondary h-10 flex-1" onClick={() => setSelected(user)}>
                  وردەکاری
                </button>
                {user.approvalStatus !== 'approved' && (
                  <button
                    className="btn-primary h-10 flex-1"
                    onClick={() => approve(user)}
                    disabled={busy === user.id}
                  >
                    <Check size={16} /> پەسەندکردن
                  </button>
                )}
                {user.approvalStatus !== 'rejected' && (
                  <button
                    className="inline-flex h-10 items-center justify-center rounded-xl bg-rose-50 px-3 text-sm font-bold text-rose-700"
                    onClick={() => setRejecting(user)}
                  >
                    <ShieldX size={16} />
                  </button>
                )}
              </div>
            </article>
          ))}
        </div>
      )}

      <Modal
        open={Boolean(selected)}
        title="وردەکاری هەژمار"
        onClose={() => setSelected(null)}
      >
        {selected && (
          <dl className="grid gap-4 sm:grid-cols-2">
            {[
              ['ناو', selected.name],
              ['ئیمەیڵ', selected.email],
              ['ژمارەی مۆبایل', selected.phone],
              ['جۆری هەژمار', statusLabel(selected.role)],
              ['دۆخ', statusLabel(selected.approvalStatus)],
              ['شوێن', selected.location || selected.shopAddress || '—'],
              ...(selected.role === 'shopOwner'
                ? [
                    ['ناوی دووکان', selected.shopName || '—'],
                    [
                      'پلانی دووکان',
                      statusLabel(selected.shopTier || 'silver'),
                    ],
                  ]
                : []),
            ].map(([label, value]) => (
              <div key={label} className="rounded-xl bg-slate-50 p-3">
                <dt className="text-[11px] font-bold text-slate-400">{label}</dt>
                <dd className="mt-1 break-words text-sm font-bold text-slate-800">
                  {value}
                </dd>
              </div>
            ))}
            {selected.latitude && selected.longitude && (
              <a
                className="sm:col-span-2 text-sm font-black text-brand-700 underline"
                href={`https://www.google.com/maps/search/?api=1&query=${selected.latitude},${selected.longitude}`}
                target="_blank"
                rel="noreferrer"
              >
                کردنەوە لە Google Maps
              </a>
            )}
          </dl>
        )}
      </Modal>

      <Modal
        open={Boolean(rejecting)}
        title="ڕەتکردنەوەی هەژمار"
        onClose={() => setRejecting(null)}
        footer={
          <div className="flex justify-end gap-2">
            <button className="btn-secondary" onClick={() => setRejecting(null)}>
              پاشگەزبوونەوە
            </button>
            <button
              className="inline-flex h-11 items-center rounded-xl bg-rose-600 px-4 text-sm font-bold text-white"
              onClick={reject}
              disabled={busy === rejecting?.id}
            >
              ڕەتکردنەوە
            </button>
          </div>
        }
      >
        <p className="mb-3 text-sm text-slate-500">
          هۆکاری ڕەتکردنەوە بۆ بەکارهێنەر دەردەکەوێت.
        </p>
        <textarea
          className="field min-h-28 resize-y py-3"
          value={reason}
          onChange={(event) => setReason(event.target.value)}
          placeholder="هۆکاری ڕەتکردنەوە..."
        />
      </Modal>
    </>
  )
}
