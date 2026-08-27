import { useMemo, useState, type FormEvent } from 'react'
import { collection, query } from 'firebase/firestore'
import { Eye, EyeOff, Image, ImagePlus, Pencil, Plus, Trash2 } from 'lucide-react'
import { useCollection } from '../hooks/useCollection'
import { db } from '../lib/firebase'
import {
  deleteBanner,
  saveBanner,
  setBannerActive,
  uploadBannerImage,
} from '../lib/adminApi'
import type { Banner } from '../lib/types'
import { normalizeError } from '../lib/utils'
import {
  Badge,
  EmptyState,
  ErrorState,
  LoadingState,
  Modal,
  PageHeader,
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

export function BannersPage() {
  const source = useMemo(() => query(collection(db, 'banners')), [])
  const { data, loading, error } = useCollection<Banner>(source)
  const banners = [...data].sort((a, b) => a.order - b.order)
  const [editing, setEditing] = useState<Banner | 'new' | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [file, setFile] = useState<File | null>(null)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

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
      if (!imageUrl) throw new Error('وێنەی بانەر هەڵبژێرە')
      await saveBanner({ ...form, imageUrl }, editing === 'new' ? undefined : editing?.id)
      setEditing(null)
      setMessage('بانەرەکە پاشەکەوتکرا')
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
      setMessage('بانەرەکە سڕایەوە')
    } catch (reason) {
      setMessage(normalizeError(reason))
    }
  }

  return (
    <>
      <PageHeader
        title="بانەرەکانی سەرەکی"
        description="وێنە و ڕیکلامەکانی سلایدەری پەڕەی سەرەکی"
        action={
          <button className="btn-primary" onClick={() => open()}>
            <Plus size={17} /> زیادکردنی بانەر
          </button>
        }
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-3">
        <StatCard label="هەموو بانەرەکان" value={banners.length} icon={Image} />
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
        <div className="mb-4 rounded-xl border border-brand-200 bg-brand-50 px-4 py-3 text-sm font-bold text-brand-800">
          {message}
        </div>
      )}

      {loading ? (
        <LoadingState />
      ) : error ? (
        <ErrorState message={error} />
      ) : banners.length === 0 ? (
        <EmptyState
          icon={ImagePlus}
          title="هێشتا بانەر نییە"
          description="یەکەم بانەرت زیاد بکە بۆ سلایدەری پەڕەی سەرەکی."
        />
      ) : (
        <div className="grid gap-4 lg:grid-cols-2">
          {banners.map((item) => (
            <article key={item.id} className="panel overflow-hidden">
              <div className="relative aspect-[16/7] bg-slate-100">
                <img src={item.imageUrl} alt={item.title} className="size-full object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-slate-950/70 via-transparent to-transparent" />
                <div className="absolute bottom-4 right-4 left-4 text-white">
                  <div className="mb-2 flex items-center gap-2">
                    <Badge tone={item.active ? 'green' : 'gray'}>
                      {item.active ? 'چالاک' : 'ناچالاک'}
                    </Badge>
                    <Badge tone="brand">ڕیز {item.order}</Badge>
                  </div>
                  <h3 className="text-lg font-black">{item.title}</h3>
                  <p className="mt-1 text-xs text-white/70">{item.subtitle}</p>
                </div>
              </div>
              <div className="flex items-center gap-2 p-3">
                <button className="btn-secondary h-10 flex-1" onClick={() => open(item)}>
                  <Pencil size={15} /> دەستکاری
                </button>
                <button className="icon-btn" onClick={() => toggle(item)}>
                  {item.active ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
                <button
                  className="inline-flex size-10 items-center justify-center rounded-xl bg-rose-50 text-rose-600"
                  onClick={() => remove(item)}
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </article>
          ))}
        </div>
      )}

      <Modal
        open={Boolean(editing)}
        title={editing === 'new' ? 'بانەری نوێ' : 'دەستکاری بانەر'}
        onClose={() => setEditing(null)}
        wide
      >
        <form onSubmit={submit} className="grid gap-5 md:grid-cols-2">
          <label className="flex min-h-72 cursor-pointer flex-col items-center justify-center overflow-hidden rounded-2xl border-2 border-dashed border-slate-200 bg-slate-50 text-center">
            {file || form.imageUrl ? (
              <img
                src={file ? URL.createObjectURL(file) : form.imageUrl}
                alt=""
                className="size-full object-cover"
              />
            ) : (
              <>
                <ImagePlus size={30} className="text-brand-700" />
                <span className="mt-3 text-sm font-black text-slate-700">وێنە هەڵبژێرە</span>
                <span className="mt-1 text-xs text-slate-400">پێشنیار: 1080 × 980</span>
              </>
            )}
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              className="hidden"
              onChange={(event) => setFile(event.target.files?.[0] ?? null)}
            />
          </label>

          <div className="space-y-4">
            {[
              ['title', 'ناونیشان'],
              ['highlight', 'دەقی دیار'],
              ['subtitle', 'ژێرنووس'],
              ['cta', 'دەقی دوگمە'],
              ['tag', 'تاگ'],
            ].map(([key, label]) => (
              <label key={key} className="block">
                <span className="mb-2 block text-xs font-black text-slate-600">{label}</span>
                <input
                  className="field"
                  value={form[key as keyof typeof form] as string}
                  onChange={(event) => setForm({ ...form, [key]: event.target.value })}
                  required={key === 'title'}
                />
              </label>
            ))}
            <div className="grid grid-cols-2 gap-3">
              <label>
                <span className="mb-2 block text-xs font-black text-slate-600">ڕیز</span>
                <input
                  className="field"
                  type="number"
                  value={form.order}
                  onChange={(event) => setForm({ ...form, order: Number(event.target.value) })}
                />
              </label>
              <label className="flex items-end">
                <span className="flex h-11 w-full items-center gap-3 rounded-xl bg-slate-50 px-3 text-sm font-bold text-slate-700">
                  <input
                    type="checkbox"
                    checked={form.active}
                    onChange={(event) => setForm({ ...form, active: event.target.checked })}
                  />
                  چالاک
                </span>
              </label>
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <button type="button" className="btn-secondary" onClick={() => setEditing(null)}>
                پاشگەزبوونەوە
              </button>
              <button className="btn-primary" disabled={busy}>
                {busy ? 'چاوەڕوان بە...' : 'پاشەکەوتکردن'}
              </button>
            </div>
          </div>
        </form>
      </Modal>
    </>
  )
}
