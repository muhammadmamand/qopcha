import { useEffect, useState, type FormEvent, type ReactNode } from 'react'
import { doc, onSnapshot } from 'firebase/firestore'
import { BellRing, FileText, Headphones, Home, Megaphone, Share2 } from 'lucide-react'
import { db } from '../lib/firebase'
import { saveAppContent, sendAnnouncement } from '../lib/adminApi'
import type { AppContent } from '../lib/types'
import { normalizeError } from '../lib/utils'
import { ErrorState, LoadingState, PageHeader } from '../components/ui'

const defaults: AppContent = {
  aboutBody: '',
  termsBody: '',
  privacyBody: '',
  supportPhone: '',
  supportWhatsapp: '',
  supportEmail: 'support@qopcha.com',
  supportHours: '٩:٠٠ — ٢١:٠٠',
  socialInstagram: '',
  socialFacebook: '',
  socialTikTok: '',
  socialTelegram: '',
  homeTagline: 'بازاڕی جلوبەرگ',
  homePromoTitle: 'داشکاندن بگرە تا',
  homePromoSubtitle: 'تەنها بۆ ماوەیەکی کەم',
  homeCta: 'ئیستا کڕین بکە',
  updatedAt: '',
}

type Section = 'home' | 'support' | 'social' | 'legal' | 'broadcast'

export function ContentPage() {
  const [form, setForm] = useState<AppContent>(defaults)
  const [section, setSection] = useState<Section>('home')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [announcement, setAnnouncement] = useState({
    title: '',
    body: '',
    category: 'system',
  })

  useEffect(
    () =>
      onSnapshot(
        doc(db, 'appContent', 'main'),
        (snapshot) => {
          setForm({ ...defaults, ...(snapshot.data() as Partial<AppContent>) })
          setLoading(false)
        },
        (reason) => {
          setError(normalizeError(reason))
          setLoading(false)
        },
      ),
    [],
  )

  function set(key: keyof AppContent, value: string) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  async function save(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setMessage(null)
    try {
      const { updatedAt: _, ...values } = form
      void _
      await saveAppContent(values)
      setMessage('ناوەڕۆکەکە پاشەکەوتکرا')
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(false)
    }
  }

  async function broadcast(event: FormEvent) {
    event.preventDefault()
    if (!announcement.title.trim() || !announcement.body.trim()) return
    setBusy(true)
    try {
      await sendAnnouncement(
        announcement.title,
        announcement.body,
        announcement.category,
      )
      setAnnouncement({ ...announcement, title: '', body: '' })
      setMessage('ئاگادارکردنەوەکە نێردرا')
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(false)
    }
  }

  const sections: { value: Section; label: string; icon: typeof Home }[] = [
    { value: 'home', label: 'پەڕەی سەرەکی', icon: Home },
    { value: 'support', label: 'پشتگیری', icon: Headphones },
    { value: 'social', label: 'تۆڕە کۆمەڵایەتییەکان', icon: Share2 },
    { value: 'legal', label: 'دەربارە و یاسا', icon: FileText },
    { value: 'broadcast', label: 'ئاگادارکردنەوە', icon: Megaphone },
  ]

  if (loading) return <LoadingState />
  if (error) return <ErrorState message={error} />

  return (
    <>
      <PageHeader
        title="ناوەڕۆکی ئەپ"
        description="دەقەکانی سەرەکی، پشتگیری، یاسا و ئاگادارکردنەوە"
      />

      <div className="grid gap-5 xl:grid-cols-[240px_1fr]">
        <aside className="panel h-fit p-2">
          {sections.map(({ value, label, icon: Icon }) => (
            <button
              key={value}
              onClick={() => setSection(value)}
              className={
                section === value
                  ? 'flex h-11 w-full items-center gap-3 rounded-xl bg-brand-700 px-3 text-sm font-bold text-white'
                  : 'flex h-11 w-full items-center gap-3 rounded-xl px-3 text-sm font-bold text-slate-500 hover:bg-slate-50'
              }
            >
              <Icon size={18} /> {label}
            </button>
          ))}
        </aside>

        <section className="panel p-5 sm:p-6">
          {message && (
            <div className="mb-5 rounded-xl border border-brand-200 bg-brand-50 px-4 py-3 text-sm font-bold text-brand-800">
              {message}
            </div>
          )}

          {section === 'broadcast' ? (
            <form onSubmit={broadcast}>
              <div className="mb-5 flex size-12 items-center justify-center rounded-2xl bg-brand-50 text-brand-700">
                <BellRing size={22} />
              </div>
              <h2 className="text-xl font-black text-slate-900">ناردنی ئاگادارکردنەوە</h2>
              <p className="mt-1 text-sm text-slate-500">
                نامەکە لە بەشی ئاگادارکردنەوە و Push Notification دەردەکەوێت.
              </p>
              <div className="mt-6 max-w-2xl space-y-4">
                <Field label="ناونیشان">
                  <input
                    className="field"
                    value={announcement.title}
                    onChange={(event) =>
                      setAnnouncement({ ...announcement, title: event.target.value })
                    }
                    required
                  />
                </Field>
                <Field label="دەقی ئاگادارکردنەوە">
                  <textarea
                    className="field min-h-32 resize-y py-3"
                    value={announcement.body}
                    onChange={(event) =>
                      setAnnouncement({ ...announcement, body: event.target.value })
                    }
                    required
                  />
                </Field>
                <Field label="جۆری ئاگادارکردنەوە">
                  <select
                    className="field"
                    value={announcement.category}
                    onChange={(event) =>
                      setAnnouncement({ ...announcement, category: event.target.value })
                    }
                  >
                    <option value="system">سیستەم</option>
                    <option value="discount">داشکاندن</option>
                    <option value="promo">ڕیکلام</option>
                  </select>
                </Field>
                <button className="btn-primary" disabled={busy}>
                  <Megaphone size={17} /> ناردنی ئاگادارکردنەوە
                </button>
              </div>
            </form>
          ) : (
            <form onSubmit={save}>
              <div className="max-w-3xl space-y-5">
                {section === 'home' && (
                  <>
                    <Title title="دەقی پەڕەی سەرەکی" />
                    <Field label="تاگڵاین">
                      <input className="field" value={form.homeTagline} onChange={(e) => set('homeTagline', e.target.value)} />
                    </Field>
                    <Field label="ناونیشانی ئۆفەر">
                      <input className="field" value={form.homePromoTitle} onChange={(e) => set('homePromoTitle', e.target.value)} />
                    </Field>
                    <Field label="ژێرنووسی ئۆفەر">
                      <input className="field" value={form.homePromoSubtitle} onChange={(e) => set('homePromoSubtitle', e.target.value)} />
                    </Field>
                    <Field label="دەقی دوگمە">
                      <input className="field" value={form.homeCta} onChange={(e) => set('homeCta', e.target.value)} />
                    </Field>
                  </>
                )}
                {section === 'support' && (
                  <>
                    <Title title="زانیاری پشتگیری" />
                    <div className="grid gap-4 sm:grid-cols-2">
                      <Field label="ژمارەی مۆبایل">
                        <input className="field" value={form.supportPhone} onChange={(e) => set('supportPhone', e.target.value)} />
                      </Field>
                      <Field label="WhatsApp">
                        <input className="field" value={form.supportWhatsapp} onChange={(e) => set('supportWhatsapp', e.target.value)} />
                      </Field>
                      <Field label="ئیمەیڵ">
                        <input className="field" value={form.supportEmail} onChange={(e) => set('supportEmail', e.target.value)} />
                      </Field>
                      <Field label="کاتی کارکردن">
                        <input className="field" value={form.supportHours} onChange={(e) => set('supportHours', e.target.value)} />
                      </Field>
                    </div>
                  </>
                )}
                {section === 'social' && (
                  <>
                    <Title title="تۆڕە کۆمەڵایەتییەکان" />
                    {([
                      ['socialInstagram', 'Instagram'],
                      ['socialFacebook', 'Facebook'],
                      ['socialTikTok', 'TikTok'],
                      ['socialTelegram', 'Telegram'],
                    ] as [keyof AppContent, string][]).map(([key, label]) => (
                      <Field key={key} label={label}>
                        <input className="field" value={form[key]} onChange={(e) => set(key, e.target.value)} placeholder="@username یان لینک" />
                      </Field>
                    ))}
                  </>
                )}
                {section === 'legal' && (
                  <>
                    <Title title="دەربارە و یاساکان" />
                    {([
                      ['aboutBody', 'دەربارەی ئێمە'],
                      ['termsBody', 'مەرجەکانی خزمەتگوزاری'],
                      ['privacyBody', 'سیاسەتی تایبەتمەندی'],
                    ] as [keyof AppContent, string][]).map(([key, label]) => (
                      <Field key={key} label={label}>
                        <textarea className="field min-h-36 resize-y py-3 leading-7" value={form[key]} onChange={(e) => set(key, e.target.value)} />
                      </Field>
                    ))}
                  </>
                )}
                <div className="border-t border-slate-100 pt-5">
                  <button className="btn-primary" disabled={busy}>
                    {busy ? 'چاوەڕوان بە...' : 'پاشەکەوتکردنی گۆڕانکارییەکان'}
                  </button>
                </div>
              </div>
            </form>
          )}
        </section>
      </div>
    </>
  )
}

function Title({ title }: { title: string }) {
  return <h2 className="text-xl font-black text-slate-900">{title}</h2>
}

function Field({
  label,
  children,
}: {
  label: string
  children: ReactNode
}) {
  return (
    <label className="block">
      <span className="mb-2 block text-xs font-black text-slate-600">{label}</span>
      {children}
    </label>
  )
}
