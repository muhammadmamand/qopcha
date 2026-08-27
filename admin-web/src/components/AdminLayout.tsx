import { useState } from 'react'
import {
  BadgePercent,
  Boxes,
  ChevronLeft,
  ClipboardList,
  FileText,
  Image,
  LayoutDashboard,
  LogOut,
  Menu,
  Moon,
  PanelRightClose,
  Sun,
  Trophy,
  Truck,
  Users,
  X,
} from 'lucide-react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { useTheme } from '../contexts/ThemeContext'
import { cn } from '../lib/utils'

const links = [
  { to: '/admin', label: 'هەژمارەکان', icon: Users, end: true, group: 'بەڕێوەبردن' },
  { to: '/admin/leaders', label: 'باشترینەکان', icon: Trophy, group: 'بەڕێوەبردن' },
  { to: '/admin/orders', label: 'داواکارییەکان', icon: ClipboardList, group: 'فرۆشتن' },
  { to: '/admin/delivery', label: 'گەیاندن', icon: Truck, group: 'فرۆشتن' },
  { to: '/admin/reports', label: 'ڕاپۆرتەکان', icon: LayoutDashboard, group: 'فرۆشتن' },
  { to: '/admin/products', label: 'بەرهەمەکان', icon: Boxes, group: 'کاتالۆگ' },
  { to: '/admin/discounts', label: 'داشکاندن', icon: BadgePercent, group: 'کاتالۆگ' },
  { to: '/admin/banners', label: 'بانەرەکان', icon: Image, group: 'ناوەڕۆک' },
  { to: '/admin/content', label: 'ناوەڕۆک', icon: FileText, group: 'ناوەڕۆک' },
]

const groups = [...new Set(links.map((link) => link.group))]

function ThemeToggle() {
  const { theme, toggle } = useTheme()
  const dark = theme === 'dark'

  return (
    <button
      onClick={toggle}
      className="icon-btn relative overflow-hidden"
      aria-label={dark ? 'گۆڕین بۆ دۆخی ڕووناک' : 'گۆڕین بۆ دۆخی تاریک'}
      title={dark ? 'دۆخی ڕووناک' : 'دۆخی تاریک'}
    >
      <Sun
        size={18}
        className={cn(
          'absolute transition-all duration-400',
          dark
            ? 'rotate-90 scale-50 opacity-0'
            : 'rotate-0 scale-100 text-amber-500 opacity-100',
        )}
      />
      <Moon
        size={18}
        className={cn(
          'absolute transition-all duration-400',
          dark
            ? 'rotate-0 scale-100 text-brand-300 opacity-100'
            : '-rotate-90 scale-50 opacity-0',
        )}
      />
    </button>
  )
}

function Sidebar({
  compact,
  onNavigate,
}: {
  compact: boolean
  onNavigate?: () => void
}) {
  const { logout, user } = useAuth()
  const initial = (user?.email ?? 'A').trim().slice(0, 1).toUpperCase()

  return (
    <div className="relative flex h-full flex-col overflow-hidden">
      <div className="pointer-events-none absolute -right-16 -top-20 size-64 animate-glow rounded-full bg-brand-400/20 blur-3xl" />
      <div
        className="pointer-events-none absolute -bottom-24 -left-16 size-72 animate-glow rounded-full bg-cyan-300/10 blur-3xl"
        style={{ animationDelay: '1.4s' }}
      />

      <div
        className={cn(
          'relative flex h-20 items-center border-b border-white/10',
          compact ? 'justify-center' : 'px-5',
        )}
      >
        <img src="/qopcha_logo.png" alt="قۆپچە" className="size-11 shrink-0 rounded-2xl bg-white shadow-[0_10px_24px_-10px_rgb(0_0_0/0.6)] object-contain" />
        {!compact && (
          <div className="mr-3 min-w-0">
            <p className="text-lg font-black text-white">قۆپچە</p>
            <p className="text-[11px] font-bold tracking-wide text-white/50">
              Admin Console
            </p>
          </div>
        )}
      </div>

      <nav className="relative flex-1 overflow-y-auto px-3 py-4">
        {groups.map((group) => (
          <div key={group} className="mb-5 last:mb-0">
            {!compact && (
              <p className="mb-2 px-3 text-[10px] font-extrabold tracking-[0.14em] text-white/35">
                {group}
              </p>
            )}
            <div className="space-y-1">
              {links
                .filter((link) => link.group === group)
                .map(({ to, label, icon: Icon, end }, index) => (
                  <NavLink
                    key={to}
                    to={to}
                    end={end}
                    onClick={onNavigate}
                    style={{ animationDelay: `${index * 45}ms` }}
                    className={({ isActive }) =>
                      cn(
                        'group relative flex h-11 animate-slide-in items-center rounded-xl text-sm font-bold transition duration-200',
                        compact ? 'justify-center px-0' : 'gap-3 px-3',
                        isActive
                          ? 'bg-white text-brand-800 shadow-[0_10px_22px_-12px_rgb(0_0_0/0.75)]'
                          : 'text-white/60 hover:bg-white/10 hover:text-white',
                      )
                    }
                    title={compact ? label : undefined}
                  >
                    {({ isActive }) => (
                      <>
                        {isActive && !compact && (
                          <span className="absolute -right-3 top-1/2 h-6 w-1 -translate-y-1/2 rounded-full bg-brand-300" />
                        )}
                        <Icon
                          size={19}
                          className="shrink-0 transition-transform duration-300 group-hover:scale-110"
                        />
                        {!compact && <span className="truncate">{label}</span>}
                      </>
                    )}
                  </NavLink>
                ))}
            </div>
          </div>
        ))}
      </nav>

      <div className="relative border-t border-white/10 p-3">
        {!compact && (
          <div className="mb-2 flex items-center gap-2.5 rounded-xl bg-white/8 px-3 py-2.5 ring-1 ring-white/10">
            <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-brand-300/20 text-xs font-black text-brand-100">
              {initial}
            </span>
            <div className="min-w-0">
              <p className="truncate text-xs font-bold text-white">{user?.email}</p>
              <p className="mt-0.5 text-[10px] text-white/45">بەڕێوەبەری سیستەم</p>
            </div>
          </div>
        )}
        <button
          onClick={() => logout()}
          className={cn(
            'flex h-11 w-full items-center rounded-xl text-sm font-bold text-white/60 transition hover:bg-rose-500/18 hover:text-rose-200',
            compact ? 'justify-center' : 'gap-3 px-3',
          )}
          title="چوونەدەرەوە"
        >
          <LogOut size={19} />
          {!compact && <span>چوونەدەرەوە</span>}
        </button>
      </div>
    </div>
  )
}

export function AdminLayout() {
  const [compact, setCompact] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const location = useLocation()
  const current = links.find(({ to, end }) =>
    end ? location.pathname === to : location.pathname.startsWith(to),
  )

  const sidebarSurface =
    'bg-[linear-gradient(180deg,#0e474b_0%,#0a373a_45%,#072a2d_100%)]'

  return (
    <div dir="rtl" className="min-h-screen">
      <aside
        className={cn(
          'fixed inset-y-0 right-0 z-30 hidden transition-[width] duration-300 lg:block',
          sidebarSurface,
          compact ? 'w-[76px]' : 'w-64',
        )}
      >
        <Sidebar compact={compact} />
      </aside>

      {mobileOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <button
            className="absolute inset-0 animate-fade bg-ink-900/50 backdrop-blur-md"
            onClick={() => setMobileOpen(false)}
            aria-label="داخستنی مێنیو"
          />
          <aside
            className={cn(
              'absolute inset-y-0 right-0 w-72 shadow-2xl',
              sidebarSurface,
            )}
          >
            <button
              className="absolute left-3 top-5 z-10 text-white/60 transition hover:text-white"
              onClick={() => setMobileOpen(false)}
              aria-label="داخستنی مێنیو"
            >
              <X size={22} />
            </button>
            <Sidebar compact={false} onNavigate={() => setMobileOpen(false)} />
          </aside>
        </div>
      )}

      <div
        className={cn(
          'min-h-screen transition-[margin] duration-300',
          compact ? 'lg:mr-[76px]' : 'lg:mr-64',
        )}
      >
        <header
          className="sticky top-0 z-20 flex h-16 items-center gap-3 border-b px-4 backdrop-blur-xl sm:px-6"
          style={{
            borderColor: 'var(--t-line)',
            background: 'var(--t-header-bg)',
            boxShadow: '0 1px 20px -12px var(--t-shadow-2)',
          }}
        >
          <button
            className="icon-btn lg:hidden"
            onClick={() => setMobileOpen(true)}
            aria-label="کردنەوەی مێنیو"
          >
            <Menu size={19} />
          </button>
          <button
            className="icon-btn hidden lg:inline-flex"
            onClick={() => setCompact((value) => !value)}
            aria-label="گۆڕینی قەبارەی مێنیو"
          >
            {compact ? <ChevronLeft size={19} /> : <PanelRightClose size={19} />}
          </button>

          {current && (
            <span className="flex size-9 items-center justify-center rounded-xl bg-gradient-to-br from-brand-500/14 to-brand-700/20 text-brand-700 ring-1 ring-brand-500/15">
              <current.icon size={18} />
            </span>
          )}
          <div className="min-w-0">
            <p className="truncate text-sm font-black text-ink-900">
              {current?.label ?? 'ئەدمین'}
            </p>
            <p className="text-[11px] text-ink-500">بەڕێوەبردنی قۆپچە</p>
          </div>

          <div className="mr-auto flex items-center gap-2">
            <span className="hidden items-center gap-1.5 rounded-full bg-emerald-500/12 px-3 py-1.5 text-[11px] font-extrabold text-emerald-700 ring-1 ring-emerald-500/25 sm:inline-flex dark:text-emerald-300">
              <i className="size-1.5 animate-pulse rounded-full bg-emerald-500" />
              پەیوەندی چالاک
            </span>
            <ThemeToggle />
          </div>
        </header>

        <main
          key={location.pathname}
          className="mx-auto max-w-[1500px] animate-rise p-4 sm:p-6 lg:p-8"
        >
          <Outlet />
        </main>
      </div>
    </div>
  )
}
