import { useState, type FormEvent } from 'react'
import {
  Eye,
  EyeOff,
  LockKeyhole,
  Mail,
  Moon,
  ShieldCheck,
  Sun,
} from 'lucide-react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { useTheme } from '../contexts/ThemeContext'
import { normalizeError } from '../lib/utils'

export function LoginPage() {
  const { login, user, authorized, loading: authLoading } = useAuth()
  const { theme, toggle } = useTheme()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (!authLoading && user && authorized) return <Navigate to="/admin" replace />

  async function submit(event: FormEvent) {
    event.preventDefault()
    setSubmitting(true)
    setError(null)
    try {
      await login(email, password)
    } catch (reason) {
      setError(normalizeError(reason))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div
      dir="rtl"
      className="grid min-h-screen lg:grid-cols-[1.05fr_0.95fr]"
    >
      <section className="relative hidden overflow-hidden bg-[linear-gradient(160deg,#0e474b_0%,#0a373a_50%,#062326_100%)] p-12 text-white lg:flex lg:flex-col lg:justify-between">
        <div className="absolute -left-28 -top-28 size-96 rounded-full bg-brand-400/25 blur-3xl" />
        <div className="absolute -bottom-36 -right-20 size-[30rem] rounded-full bg-cyan-300/12 blur-3xl" />
        <div className="relative flex items-center gap-3">
          <img src="/qopcha_logo.png" alt="قۆپچە" className="size-12 rounded-2xl bg-white shadow-xl object-contain" />
          <div>
            <p className="text-xl font-black">قۆپچە</p>
            <p className="text-xs font-bold tracking-wide text-white/50">
              Admin Console
            </p>
          </div>
        </div>

        <div className="relative max-w-xl">
          <div className="mb-6 flex size-14 items-center justify-center rounded-2xl bg-white/10 text-brand-200 ring-1 ring-white/15">
            <ShieldCheck size={28} />
          </div>
          <h1 className="text-4xl font-black leading-[1.35]">
            هەموو بەشەکانی بازاڕەکەت
            <br />
            لە یەک شوێنی سادەدا
          </h1>
          <p className="mt-5 max-w-md text-sm leading-7 text-white/55">
            هەژمار، داواکاری، بەرهەم، گەیاندن و ناوەڕۆکی ئەپ بە شێوەیەکی
            خێرا و پارێزراو بەڕێوەببە.
          </p>

          <div className="mt-8 flex flex-wrap gap-2.5">
            {['هەژمارەکان', 'داواکاری و گەیاندن', 'داشکاندن', 'ڕاپۆرت'].map((item) => (
              <span
                key={item}
                className="rounded-full bg-white/10 px-3.5 py-1.5 text-[11px] font-bold text-white/75 ring-1 ring-white/12"
              >
                {item}
              </span>
            ))}
          </div>
        </div>

        <p className="relative text-xs text-white/35">© 2026 Qopcha</p>
      </section>

      <section className="relative flex items-center justify-center p-5 sm:p-10">
        <button
          onClick={toggle}
          className="icon-btn absolute left-5 top-5"
          aria-label={theme === 'dark' ? 'دۆخی ڕووناک' : 'دۆخی تاریک'}
        >
          {theme === 'dark' ? (
            <Moon size={18} className="text-brand-300" />
          ) : (
            <Sun size={18} className="text-amber-500" />
          )}
        </button>

        <div className="panel w-full max-w-md animate-rise p-7 sm:p-9">
          <div className="mb-8 lg:hidden">
            <img src="/qopcha_logo.png" alt="قۆپچە" className="size-12 rounded-2xl shadow-lg object-contain" />
          </div>
          <p className="text-sm font-extrabold text-brand-700">بەخێربێیتەوە</p>
          <h2 className="mt-2 text-3xl font-black tracking-tight text-ink-900">
            چوونەژوورەوەی ئەدمین
          </h2>
          <div className="mt-3 h-1 w-14 rounded-full bg-gradient-to-l from-brand-600 to-brand-300" />
          <p className="mt-3 text-sm leading-6 text-ink-500">
            تەنها هەژماری ڕێگەپێدراوی بەڕێوەبەر دەتوانێت بچێتە ژوورەوە
            {' '}
            <span className="font-extrabold text-ink-700" dir="ltr">
              admin@qopcha.com
            </span>
          </p>

          <form className="mt-8 space-y-4" onSubmit={submit}>
            <label className="block">
              <span className="mb-2 block text-xs font-extrabold text-slate-600">
                ئیمەیڵ
              </span>
              <div className="relative">
                <Mail
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                  size={18}
                />
                <input
                  className="field pr-11"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  type="email"
                  autoComplete="username"
                  placeholder="admin@qopcha.com"
                  autoFocus
                  required
                />
              </div>
            </label>
            <label className="block">
              <span className="mb-2 block text-xs font-extrabold text-slate-600">
                وشەی نهێنی
              </span>
              <div className="relative">
                <LockKeyhole
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                  size={18}
                />
                <input
                  className="field px-11"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
                  onClick={() => setShowPassword((value) => !value)}
                  aria-label="نیشاندانی وشەی نهێنی"
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </label>

            {error && (
              <div className="animate-pop rounded-xl border border-rose-500/30 bg-rose-500/10 px-4 py-3 text-sm font-bold text-rose-600 dark:text-rose-300">
                {error}
              </div>
            )}

            <button className="btn-primary mt-2 w-full" disabled={submitting}>
              {submitting ? 'چاوەڕوان بە...' : 'چوونەژوورەوە'}
            </button>
          </form>
        </div>
      </section>
    </div>
  )
}
