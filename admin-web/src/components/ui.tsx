import { AlertTriangle, Search, X, type LucideIcon } from 'lucide-react'
import type { ReactNode } from 'react'
import { cn } from '../lib/utils'

type Tone = 'brand' | 'orange' | 'blue' | 'green' | 'red' | 'gold'

const iconTones: Record<Tone, string> = {
  brand: 'from-brand-500/15 to-brand-700/20 text-brand-700 ring-brand-500/15',
  orange: 'from-orange-400/15 to-orange-600/20 text-orange-600 ring-orange-500/15',
  blue: 'from-blue-400/15 to-blue-600/20 text-blue-600 ring-blue-500/15',
  green: 'from-emerald-400/15 to-emerald-600/20 text-emerald-600 ring-emerald-500/15',
  red: 'from-rose-400/15 to-rose-600/20 text-rose-600 ring-rose-500/15',
  gold: 'from-amber-400/15 to-amber-600/20 text-amber-600 ring-amber-500/15',
}

const barTones: Record<Tone, string> = {
  brand: 'bg-brand-600',
  orange: 'bg-orange-500',
  blue: 'bg-blue-500',
  green: 'bg-emerald-500',
  red: 'bg-rose-500',
  gold: 'bg-amber-500',
}

export function PageHeader({
  title,
  description,
  action,
  eyebrow,
}: {
  title: string
  description: string
  action?: ReactNode
  eyebrow?: string
}) {
  return (
    <div className="mb-6 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
      <div className="min-w-0">
        {eyebrow && (
          <p className="mb-1.5 text-[11px] font-extrabold tracking-wide text-brand-600">
            {eyebrow}
          </p>
        )}
        <h1 className="text-2xl font-black tracking-tight text-ink-900 sm:text-[28px]">
          {title}
        </h1>
        <div className="mt-2 h-1 w-14 rounded-full bg-gradient-to-l from-brand-600 to-brand-300" />
        <p className="mt-2.5 text-sm leading-6 text-ink-500">{description}</p>
      </div>
      {action}
    </div>
  )
}

export function StatCard({
  label,
  value,
  icon: Icon,
  tone = 'brand',
  hint,
}: {
  label: string
  value: string | number
  icon: LucideIcon
  tone?: Tone
  hint?: string
}) {
  return (
    <div className="panel panel-hover relative flex items-center gap-4 overflow-hidden p-4">
      <span
        className={cn(
          'absolute inset-y-3 right-0 w-1 rounded-full opacity-80',
          barTones[tone],
        )}
      />
      <div
        className={cn(
          'flex size-12 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br ring-1',
          iconTones[tone],
        )}
      >
        <Icon size={22} />
      </div>
      <div className="min-w-0">
        <p className="text-xs font-bold text-ink-500">{label}</p>
        <p className="mt-0.5 text-2xl font-black tracking-tight text-ink-900">{value}</p>
        {hint && <p className="mt-0.5 truncate text-[11px] text-slate-400">{hint}</p>}
      </div>
    </div>
  )
}

export function Badge({
  children,
  tone = 'gray',
  dot = false,
}: {
  children: ReactNode
  tone?: 'gray' | 'brand' | 'green' | 'orange' | 'blue' | 'red' | 'gold'
  dot?: boolean
}) {
  const tones = {
    gray: 'bg-slate-100 text-slate-600 ring-slate-200/70',
    brand: 'bg-brand-50 text-brand-700 ring-brand-200/70',
    green: 'bg-emerald-50 text-emerald-700 ring-emerald-200/70',
    orange: 'bg-orange-50 text-orange-700 ring-orange-200/70',
    blue: 'bg-blue-50 text-blue-700 ring-blue-200/70',
    red: 'bg-rose-50 text-rose-700 ring-rose-200/70',
    gold: 'bg-amber-50 text-amber-700 ring-amber-200/70',
  }
  const dots = {
    gray: 'bg-slate-400',
    brand: 'bg-brand-600',
    green: 'bg-emerald-500',
    orange: 'bg-orange-500',
    blue: 'bg-blue-500',
    red: 'bg-rose-500',
    gold: 'bg-amber-500',
  }
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-extrabold ring-1',
        tones[tone],
      )}
    >
      {dot && <i className={cn('size-1.5 rounded-full', dots[tone])} />}
      {children}
    </span>
  )
}

export function LoadingState({ label = 'بارکردن...' }: { label?: string }) {
  return (
    <div className="panel flex min-h-64 flex-col items-center justify-center gap-3">
      <div className="relative size-10">
        <div className="absolute inset-0 rounded-full border-4 border-brand-100" />
        <div className="absolute inset-0 animate-spin rounded-full border-4 border-transparent border-t-brand-700" />
      </div>
      <p className="text-xs font-bold text-ink-500">{label}</p>
    </div>
  )
}

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
}: {
  icon: LucideIcon
  title: string
  description: string
  action?: ReactNode
}) {
  return (
    <div className="panel flex min-h-72 flex-col items-center justify-center px-6 py-10 text-center">
      <div className="flex size-16 items-center justify-center rounded-3xl bg-gradient-to-br from-brand-500/12 to-brand-700/18 text-brand-700 ring-1 ring-brand-500/15">
        <Icon size={28} />
      </div>
      <h3 className="mt-4 text-base font-black text-ink-900">{title}</h3>
      <p className="mt-1.5 max-w-sm text-sm leading-6 text-ink-500">{description}</p>
      {action && <div className="mt-5">{action}</div>}
    </div>
  )
}

export function ErrorState({ message }: { message: string }) {
  return (
    <div className="flex animate-pop items-start gap-3 rounded-2xl border border-rose-500/30 bg-rose-500/10 p-4 text-sm font-bold text-rose-600 dark:text-rose-300">
      <AlertTriangle size={18} className="mt-0.5 shrink-0" />
      <span className="leading-6">{message}</span>
    </div>
  )
}

export function Modal({
  open,
  title,
  onClose,
  children,
  footer,
  wide = false,
}: {
  open: boolean
  title: string
  onClose: () => void
  children: ReactNode
  footer?: ReactNode
  wide?: boolean
}) {
  if (!open) return null
  return (
    <div
      className="fixed inset-0 z-50 flex animate-fade items-center justify-center bg-ink-900/50 p-4 backdrop-blur-md"
      onMouseDown={(event) => {
        if (event.currentTarget === event.target) onClose()
      }}
    >
      <div
        className={cn(
          'max-h-[90vh] w-full animate-pop overflow-hidden rounded-3xl bg-card shadow-[0_40px_90px_-30px_var(--t-shadow-3)]',
          wide ? 'max-w-4xl' : 'max-w-lg',
        )}
        role="dialog"
        aria-modal="true"
      >
        <div className="flex items-center justify-between gap-4 border-b border-line bg-gradient-to-l from-brand-500/10 to-transparent px-5 py-4">
          <h2 className="text-lg font-black text-ink-900">{title}</h2>
          <button className="icon-btn" onClick={onClose} aria-label="داخستن">
            <X size={18} />
          </button>
        </div>
        <div className="max-h-[calc(90vh-9rem)] overflow-y-auto p-5">{children}</div>
        {footer && <div className="border-t border-line bg-subtle/50 p-4">{footer}</div>}
      </div>
    </div>
  )
}

export function SearchField({
  value,
  onChange,
  placeholder = 'گەڕان...',
}: {
  value: string
  onChange: (value: string) => void
  placeholder?: string
}) {
  return (
    <div className="relative w-full max-w-sm">
      <Search
        size={17}
        className="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400"
      />
      <input
        className="field pl-9 pr-10"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
      />
      {value && (
        <button
          type="button"
          className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 transition hover:text-rose-600"
          onClick={() => onChange('')}
          aria-label="سڕینەوەی گەڕان"
        >
          <X size={15} />
        </button>
      )}
    </div>
  )
}
