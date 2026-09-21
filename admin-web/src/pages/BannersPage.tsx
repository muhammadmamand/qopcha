import { useMemo, useState, type FormEvent } from 'react'
import { collection, query } from 'firebase/firestore'
import {
  Eye,
  EyeOff,
  Image,
  ImagePlus,
  Maximize2,
  Pencil,
  Plus,
  Trash2,
  X,
  ZoomIn,
} from 'lucide-react'
import { useCollection } from '../hooks/useCollection'
import { db } from '../lib/firebase'
import {
  deleteBanner,
  saveBanner,
  setBannerActive,
  uploadBannerImage,
} from '../lib/adminApi'
import type { Banner } from '../lib/types'
import { cn, normalizeError } from '../lib/utils'
import {
  Badge,
  EmptyState,
  ErrorState,
  LoadingState,
  Modal,
  PageHeader,
  SearchField,
  StatCard,
} from '../components/ui'

const emptyForm = {
  title: '',
  highlight: '',
  subtitle: '',
  cta: 'بینین',
  tag: 'AD',
  imageUrl: '',
  active: true,
  order: 0,
}

function ImageLightbox({
  src,
  alt,
  onClose,
}: {
  src: string
  alt: string
  onClose: () => void
}) {
  return (
    <div
      className="fixed inset-0 z-[80] flex animate-fade items-center justify-center bg-ink-900/80 p-4 backdrop-blur-md"
      onMouseDown={(event) => {
        if (event.currentTarget === event.target) onClose()
      }}
      role="dialog"
      aria-modal="true"
      aria-label="پێشبینینی وێنە"
    >
      <button
        type="button"
        className="absolute top-4 left-4 z-10 flex size-11 items-center justify-center rounded-full bg-white/10 text-white ring-1 ring-white/20 transition hover:bg-white/20"
        onClick={onClose}
        aria-label="داخستن"
      >
        <X size={20} />
      </button>
      <img
        src={src}
        alt={alt}
        className="max-h-[88vh] max-w-[min(960px,94vw)] animate-pop rounded-2xl object-contain shadow-float ring-1 ring-white/15"
      />
    </div>
  )
}

function ThumbPreview({
  src,
  alt,
  onOpen,
  className,
}: {
  src: string
  alt: string
  onOpen: () => void
  className?: string
}) {
  return (
    <button
      type="button"
      onClick={onOpen}
      title="کردنەوەی وێنە بە قەبارەی گەورە"
      className={cn(
        'group relative shrink-0 overflow-hidden rounded-2xl bg-subtle ring-1 ring-line transition',
        'hover:ring-brand-400/50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500',
        className,
      )}
    >
      <img src={src} alt={alt} className="size-full object-cover" />
      <span className="absolute inset-0 flex items-center justify-center bg-ink-900/0 transition group-hover:bg-ink-900/35">
        <span className="flex size-9 translate-y-1 items-center justify-center rounded-full bg-white/90 text-brand-800 opacity-0 shadow-lg transition group-hover:translate-y-0 group-hover:opacity-100">
          <ZoomIn size={16} />
        </span>
      </span>
    </button>
  )
}

export function BannersPage() {
  const source = useMemo(() => query(collection(db, 'banners')), [])
  const { data, loading, error } = useCollection<Banner>(source)
  const banners = [...data].sort((a, b) => a.order - b.order)
  const [editing, setEditing] = useState<Banner | 'new' | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [file, setFile] = useState<File | null>(null)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [queryText, setQueryText] = useState('')
  const [lightbox, setLightbox] = useState<{ src: string; alt: string } | null>(
    null,
  )

  const filtered = useMemo(() => {
    const q = queryText.trim().toLowerCase()
    if (!q) return banners
    return banners.filter((item) =>
      [item.title, item.highlight, item.subtitle, item.cta, item.tag]
        .join(' ')
        .toLowerCase()
        .includes(q),
    )
  }, [banners, queryText])

  const previewUrl = file ? URL.createObjectURL(file) : form.imageUrl

  function open(item?: Banner) {
    setEditing(item ?? 'new')
    setFile(null)
    setForm(
      item
        ? {
            title: item.title,
            highlight: item.highlight,
            subtitle: item.subtitle,
            cta: item.cta,
            tag: item.tag,
            imageUrl: item.imageUrl,
            active: item.active,
            order: item.order,
          }
        : emptyForm,
    )
  }

  async function submit(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setMessage(null)
    try {
      const imageUrl = file ? await uploadBannerImage(file) : form.imageUrl
      if (!imageUrl) throw new Error('وێنەی ڕیکلام هەڵبژێرە')
      await saveBanner(
        { ...form, imageUrl },
        editing === 'new' ? undefined : editing?.id,
      )
      setEditing(null)
      setMessage('ڕیکلامەکە پاشەکەوتکرا')
    } catch (reason) {
      setMessage(normalizeError(reason))
    } finally {
      setBusy(false)
    }
  }

  async function toggle(item: Banner) {
    try {
      await setBannerActive(item.id, !item.active)
    } catch (reason) {
      setMessage(normalizeError(reason))
    }
  }

  async function remove(item: Banner) {
    if (!window.confirm(`دڵنیایت لە سڕینەوەی «${item.title}»؟`)) return
    try {
      await deleteBanner(item.id)
      setMessage('ڕیکلامەکە سڕایەوە')
    } catch (reason) {
      setMessage(normalizeError(reason))
    }
  }

  return (
    <>
      <PageHeader
        eyebrow="ناوەڕۆک"
        title="ڕیکلامەکان"
        description="سلایدەری پەڕەی سەرەکی — وێنە، ناونیشان و دوگمەی بانەرەکان"
        action={
          <button className="btn-primary" onClick={() => open()}>
            <Plus size={17} /> زیادکردنی ڕیکلام
          </button>
        }
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-3">
        <StatCard label="هەموو ڕیکلامەکان" value={banners.length} icon={Image} />
        <StatCard
          label="چالاک"
          value={banners.filter((item) => item.active).length}
          icon={Eye}
          tone="green"
        />
        <StatCard
          label="ناچالاک"
          value={banners.filter((item) => !item.active).length}
          icon={EyeOff}
          tone="orange"
        />
      </div>

      {message && (
        <div className="mb-4 rounded-2xl border border-brand-200/70 bg-brand-50 px-4 py-3 text-sm font-bold text-brand-800 dark:border-brand-500/25 dark:bg-brand-500/10 dark:text-brand-200">
          {message}
        </div>
      )}

      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <SearchField
          value={queryText}
          onChange={setQueryText}
          placeholder="گەڕان لە ڕیکلامەکان..."
        />
        <p className="text-xs font-bold text-ink-500">
          {filtered.length} لە {banners.length} ڕیکلام
        </p>
      </div>

      {loading ? (
        <LoadingState label="بارکردنی ڕیکلامەکان..." />
      ) : error ? (
        <ErrorState message={error} />
      ) : banners.length === 0 ? (
        <EmptyState
          icon={ImagePlus}
          title="هێشتا ڕیکلام نییە"
          description="یەکەم ڕیکلام زیاد بکە بۆ سلایدەری پەڕەی سەرەکی ئەپەکە."
          action={
            <button className="btn-primary" onClick={() => open()}>
              <Plus size={16} /> زیادکردنی ڕیکلام
            </button>
          }
        />
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={Image}
          title="هیچ ئەنجامێک نەدۆزرایەوە"
          description="گەڕانەکەت بگۆڕە یان فلتەرەکان پاک بکەرەوە."
        />
      ) : (
        <div className="panel overflow-hidden p-0">
          <div className="hidden border-b border-line bg-subtle/60 px-4 py-3 text-[11px] font-extrabold text-ink-500 sm:grid sm:grid-cols-[88px_1fr_110px_150px] sm:gap-4">
            <span>وێنە</span>
            <span>زانیاری ڕیکلام</span>
            <span>دۆخ</span>
            <span className="text-left">کردارەکان</span>
          </div>

          <ul className="divide-y divide-line">
            {filtered.map((item, index) => (
              <li
                key={item.id}
                className="animate-rise grid gap-4 p-4 transition hover:bg-brand-500/[0.04] sm:grid-cols-[88px_1fr_110px_150px] sm:items-center sm:gap-4"
                style={{ animationDelay: `${Math.min(index, 8) * 40}ms` }}
              >
                <ThumbPreview
                  src={item.imageUrl}
                  alt={item.title}
                  onOpen={() =>
                    setLightbox({ src: item.imageUrl, alt: item.title })
                  }
                  className="h-20 w-full sm:size-[76px]"
                />

                <div className="min-w-0">
                  <div className="mb-1.5 flex flex-wrap items-center gap-2">
                    <Badge tone="brand">ڕیز {item.order}</Badge>
                    {item.tag && <Badge tone="gray">{item.tag}</Badge>}
                  </div>
                  <h3 className="truncate text-[15px] font-black text-ink-900">
                    {item.title || 'بێ ناونیشان'}
                  </h3>
                  {item.highlight && (
                    <p className="mt-0.5 truncate text-sm font-bold text-brand-700 dark:text-brand-300">
                      {item.highlight}
                    </p>
                  )}
                  {item.subtitle && (
                    <p className="mt-1 line-clamp-2 text-xs leading-5 text-ink-500">
                      {item.subtitle}
                    </p>
                  )}
                  {item.cta && (
                    <span className="mt-2 inline-flex rounded-full bg-white px-2.5 py-1 text-[10px] font-extrabold text-ink-900 ring-1 ring-ink-900/80 dark:bg-card">
                      {item.cta}
                    </span>
                  )}
                </div>

                <div>
                  <Badge tone={item.active ? 'green' : 'gray'} dot>
                    {item.active ? 'چالاک' : 'ناچالاک'}
                  </Badge>
                </div>

                <div className="flex items-center justify-start gap-2 sm:justify-end">
                  <button
                    type="button"
                    className="icon-btn"
                    title="پێشبینینی وێنە"
                    onClick={() =>
                      setLightbox({ src: item.imageUrl, alt: item.title })
                    }
                  >
                    <Maximize2 size={15} />
                  </button>
                  <button
                    type="button"
                    className="icon-btn"
                    title={item.active ? 'ناچالاککردن' : 'چالاککردن'}
                    onClick={() => toggle(item)}
                  >
                    {item.active ? <EyeOff size={15} /> : <Eye size={15} />}
                  </button>
                  <button
                    type="button"
                    className="icon-btn"
                    title="دەستکاری"
                    onClick={() => open(item)}
                  >
                    <Pencil size={15} />
                  </button>
                  <button
                    type="button"
                    className="inline-flex size-10 items-center justify-center rounded-xl bg-rose-500/10 text-rose-600 transition hover:bg-rose-500/15 dark:text-rose-300"
                    title="سڕینەوە"
                    onClick={() => remove(item)}
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}

      <Modal
        open={Boolean(editing)}
        title={editing === 'new' ? 'ڕیکلامی نوێ' : 'دەستکاری ڕیکلام'}
        onClose={() => setEditing(null)}
        wide
      >
        <form onSubmit={submit} className="grid gap-6 lg:grid-cols-[1.05fr_1fr]">
          <div className="space-y-3">
            <div className="relative overflow-hidden rounded-[28px] bg-subtle ring-1 ring-line">
              <div className="relative aspect-[4/5] max-h-[420px] w-full sm:aspect-[5/4]">
                {previewUrl ? (
                  <>
                    <img
                      src={previewUrl}
                      alt=""
                      className="size-full object-cover"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/65 via-black/10 to-transparent" />
                    <div className="absolute inset-x-0 bottom-0 p-5 text-white">
                      <p className="text-xl font-black leading-tight">
                        {form.highlight || form.title || 'ناونیشانی ڕیکلام'}
                      </p>
                      {(form.subtitle || form.title) && (
                        <p className="mt-1 line-clamp-2 text-xs text-white/80">
                          {form.subtitle || form.title}
                        </p>
                      )}
                      <span className="mt-4 inline-flex rounded-full bg-white px-3.5 py-2 text-xs font-extrabold text-black shadow-[3px_3px_0_#000] ring-1 ring-black">
                        {form.cta || 'بینین'}
                      </span>
                    </div>
                    <button
                      type="button"
                      className="absolute top-3 left-3 flex size-10 items-center justify-center rounded-full bg-black/40 text-white ring-1 ring-white/25 backdrop-blur-sm transition hover:bg-black/55"
                      onClick={() =>
                        setLightbox({
                          src: previewUrl,
                          alt: form.title || 'ڕیکلام',
                        })
                      }
                      title="کردنەوەی وێنە بە قەبارەی گەورە"
                    >
                      <ZoomIn size={16} />
                    </button>
                  </>
                ) : (
                  <div className="flex size-full flex-col items-center justify-center gap-2 text-ink-500">
                    <ImagePlus size={32} className="text-brand-600" />
                    <p className="text-sm font-bold">هێشتا وێنە نییە</p>
                  </div>
                )}
              </div>
            </div>

            <label className="flex cursor-pointer items-center justify-center gap-2 rounded-2xl border border-dashed border-brand-300/70 bg-brand-50/60 px-4 py-3 text-sm font-extrabold text-brand-800 transition hover:bg-brand-50 dark:border-brand-500/30 dark:bg-brand-500/10 dark:text-brand-200">
              <ImagePlus size={16} />
              {previewUrl ? 'گۆڕینی وێنە' : 'هەڵبژاردنی وێنە'}
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="hidden"
                onChange={(event) => setFile(event.target.files?.[0] ?? null)}
              />
            </label>
            <p className="text-center text-[11px] font-bold text-ink-500">
              پێشنیار: 1080 × 980 — کلیک لەسەر وێنە بکە بۆ قەبارەی گەورە
            </p>
          </div>

          <div className="space-y-4">
            {(
              [
                ['title', 'ناونیشان'],
                ['highlight', 'دەقی دیار'],
                ['subtitle', 'ژێرنووس'],
                ['tag', 'تاگ'],
              ] as const
            ).map(([key, label]) => (
              <label key={key} className="block">
                <span className="mb-2 block text-xs font-black text-ink-700">
                  {label}
                </span>
                <input
                  className="field"
                  value={form[key]}
                  onChange={(event) =>
                    setForm({ ...form, [key]: event.target.value })
                  }
                  required={key === 'title'}
                />
              </label>
            ))}

            <div className="grid grid-cols-2 gap-3">
              <label>
                <span className="mb-2 block text-xs font-black text-ink-700">
                  ڕیز
                </span>
                <input
                  className="field"
                  type="number"
                  value={form.order}
                  onChange={(event) =>
                    setForm({ ...form, order: Number(event.target.value) })
                  }
                />
              </label>
              <label className="flex items-end">
                <span className="flex h-11 w-full items-center gap-3 rounded-xl bg-subtle px-3 text-sm font-bold text-ink-700 ring-1 ring-line">
                  <input
                    type="checkbox"
                    checked={form.active}
                    onChange={(event) =>
                      setForm({ ...form, active: event.target.checked })
                    }
                  />
                  چالاک
                </span>
              </label>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <button
                type="button"
                className="btn-secondary"
                onClick={() => setEditing(null)}
              >
                پاشگەزبوونەوە
              </button>
              <button className="btn-primary" disabled={busy}>
                {busy ? 'چاوەڕوان بە...' : 'پاشەکەوتکردن'}
              </button>
            </div>
          </div>
        </form>
      </Modal>

      {lightbox && (
        <ImageLightbox
          src={lightbox.src}
          alt={lightbox.alt}
          onClose={() => setLightbox(null)}
        />
      )}
    </>
  )
}
