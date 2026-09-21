/* oxlint-disable react/only-export-components */
import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'

const IDLE_MS = 15 * 60 * 1000
const ADMIN_PHONE = '07503727574'
const API_BASE =
  import.meta.env.VITE_API_BASE || 'https://169-58-230-144.sslip.io'
const TOKEN_KEY = 'qopcha_admin_token'
const USER_KEY = 'qopcha_admin_user'

export interface AdminSessionUser {
  id: string
  name: string
  phone: string
  email?: string
  role: string
}

interface AuthValue {
  user: AdminSessionUser | null
  loading: boolean
  authorized: boolean
  token: string | null
  login: (phone: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthValue | null>(null)

function normalizePhone(phone: string) {
  let value = phone.trim().replace(/[\s\-()]/g, '')
  if (value.startsWith('+964')) value = `0${value.slice(4)}`
  else if (value.startsWith('964')) value = `0${value.slice(3)}`
  return value
}

function readStoredUser(): AdminSessionUser | null {
  try {
    const raw = sessionStorage.getItem(USER_KEY)
    if (!raw) return null
    return JSON.parse(raw) as AdminSessionUser
  } catch {
    return null
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminSessionUser | null>(() => readStoredUser())
  const [token, setToken] = useState<string | null>(
    () => sessionStorage.getItem(TOKEN_KEY),
  )
  const [loading, setLoading] = useState(true)
  const idleTimer = useRef<number | null>(null)

  const authorized = Boolean(
    user &&
      user.role === 'admin' &&
      normalizePhone(user.phone) === ADMIN_PHONE &&
      token,
  )

  function clearSession() {
    sessionStorage.removeItem(TOKEN_KEY)
    sessionStorage.removeItem(USER_KEY)
    setToken(null)
    setUser(null)
  }

  function bumpIdle() {
    if (idleTimer.current) window.clearTimeout(idleTimer.current)
    if (!token) return
    idleTimer.current = window.setTimeout(() => {
      clearSession()
    }, IDLE_MS)
  }

  useEffect(() => {
    setLoading(false)
  }, [])

  useEffect(() => {
    if (!authorized) return
    const onActivity = () => bumpIdle()
    bumpIdle()
    window.addEventListener('mousemove', onActivity)
    window.addEventListener('keydown', onActivity)
    window.addEventListener('touchstart', onActivity)
    return () => {
      if (idleTimer.current) window.clearTimeout(idleTimer.current)
      window.removeEventListener('mousemove', onActivity)
      window.removeEventListener('keydown', onActivity)
      window.removeEventListener('touchstart', onActivity)
    }
  }, [authorized, token])

  const value = useMemo<AuthValue>(
    () => ({
      user,
      loading,
      authorized,
      token,
      login: async (phone, password) => {
        const normalized = normalizePhone(phone)
        if (normalized !== ADMIN_PHONE) {
          throw new Error(
            `ئەم ژمارەیە مۆڵەتی ئەدمینی نییە. بە ${ADMIN_PHONE} بچۆ ژوورەوە.`,
          )
        }
        const res = await fetch(`${API_BASE}/api/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ phone: normalized, password }),
        })
        const data = await res.json().catch(() => ({}))
        if (!res.ok) {
          throw new Error(
            typeof data.error === 'string'
              ? data.error
              : 'ژمارەی مۆبایل یان وشەی نهێنی هەڵەیە',
          )
        }
        const nextUser = data.user as AdminSessionUser
        if (!nextUser || nextUser.role !== 'admin') {
          throw new Error('ئەم هەژمارە مۆڵەتی ئەدمینی نییە')
        }
        const nextToken = String(data.token || '')
        sessionStorage.setItem(TOKEN_KEY, nextToken)
        sessionStorage.setItem(USER_KEY, JSON.stringify(nextUser))
        setToken(nextToken)
        setUser(nextUser)
      },
      logout: async () => {
        clearSession()
      },
    }),
    [authorized, loading, token, user],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const value = useContext(AuthContext)
  if (!value) throw new Error('useAuth must be used inside AuthProvider')
  return value
}
