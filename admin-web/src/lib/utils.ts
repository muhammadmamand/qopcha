import type { DocumentData, QueryDocumentSnapshot } from 'firebase/firestore'
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function withId<T>(snapshot: QueryDocumentSnapshot<DocumentData>): T {
  return { id: snapshot.id, ...snapshot.data() } as T
}

export function money(value: number | undefined) {
  return `${new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 }).format(
    value ?? 0,
  )} IQD`
}

export function shortDate(value: string | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('ku', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date)
}

export function shortDateTime(value: string | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('ku', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)
}

export function percent(value: number | undefined) {
  return `${Math.round(value ?? 0)}٪`
}

export function statusLabel(status: string) {
  const labels: Record<string, string> = {
    pending: 'چاوەڕوان',
    approved: 'پەسەندکراو',
    rejected: 'ڕەتکراوە',
    confirmed: 'قبوڵکراو',
    ready: 'ئامادەیە',
    shipped: 'نێردراو',
    completed: 'گەیشتوو',
    cancelled: 'هەڵوەشاوە',
    customer: 'کڕیار',
    shopOwner: 'خاوەن دووکان',
    admin: 'ئەدمین',
    silver: 'سیلڤەر',
    gold: 'گۆڵد',
    platinum: 'پلاتینیۆم',
  }
  return labels[status] ?? status
}

export function normalizeError(error: unknown) {
  if (error instanceof Error) {
    const text = error.message.replace(/^Firebase:\s*/i, '').trim()
    const code =
      typeof error === 'object' && error && 'code' in error
        ? String((error as { code?: string }).code)
        : ''
    if (
      !text ||
      text === 'internal' ||
      code.includes('internal') ||
      code.includes('not-found')
    ) {
      return 'نەتوانرا کارەکە تەواو بکرێت. دووبارە هەوڵبدەرەوە.'
    }
    return text
  }
  return 'هەڵەیەکی نەناسراو ڕوویدا'
}
