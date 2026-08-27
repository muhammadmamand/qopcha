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
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth'
import { doc, getDoc, setDoc } from 'firebase/firestore'
import { httpsCallable } from 'firebase/functions'
import { FirebaseError } from 'firebase/app'
import { auth, db, functions } from '../lib/firebase'

const IDLE_MS = 15 * 60 * 1000
const ALLOWED_ADMIN_EMAILS = new Set(['admin@qopcha.com', 'admin@shikposh.com'])

interface AuthValue {
  user: User | null
  loading: boolean
  authorized: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthValue | null>(null)

async function hasAdminClaim(user: User, force = false) {
  const token = await user.getIdTokenResult(force)
  return token.claims.admin === true
}

function adminErrorMessage(error: unknown) {
  if (error instanceof FirebaseError) {
    const text = error.message.replace(/^Firebase:\s*/i, '').trim()
    if (text.includes('permission-denied') || error.code.includes('permission-denied')) {
      return 'ئەم ئیمەیڵە ڕێگەپێدراوی ئەدمین نییە. بە admin@qopcha.com بچۆ ژوورەوە.'
    }
    if (text) return text
  }
  if (error instanceof Error && error.message.trim()) return error.message
  return 'ئەم هەژمارە مۆڵەتی ئەدمینی نییە'
}

async function hasAdminRole(user: User) {
  const snap = await getDoc(doc(db, 'users', user.uid))
  return snap.exists() && snap.data()?.role === 'admin'
}

async function promoteAllowlistedAdmin(user: User) {
  const email = user.email?.trim().toLowerCase() ?? ''
  await setDoc(
    doc(db, 'users', user.uid),
    {
      role: 'admin',
      email,
      approvalStatus: 'approved',
      approvalNoticeSeen: true,
    },
    { merge: true },
  )
}

async function ensureAdminClaim(user: User) {
  const email = user.email?.trim().toLowerCase() ?? ''
  if (!ALLOWED_ADMIN_EMAILS.has(email)) {
    throw new Error(
      'ئەم هەژمارە مۆڵەتی ئەدمینی نییە. تەنها admin@qopcha.com دەتوانێت بچێتە ژوورەوە.',
    )
  }
  if (await hasAdminClaim(user)) return true
  try {
    const bootstrap = httpsCallable(functions, 'bootstrapAdminClaim')
    await bootstrap()
    await user.getIdToken(true)
    if (await hasAdminClaim(user, true)) return true
  } catch {
    // No Cloud Functions on Spark — fall back to Firestore role.
  }
  if (await hasAdminRole(user)) return true
  try {
    await promoteAllowlistedAdmin(user)
    if (await hasAdminRole(user)) return true
  } catch (error) {
    throw new Error(adminErrorMessage(error))
  }
  throw new Error(
    'ئەم هەژمارە مۆڵەتی ئەدمینی نییە. تەنها admin@qopcha.com دەتوانێت بچێتە ژوورەوە.',
  )
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [authorized, setAuthorized] = useState(false)
  const timer = useRef<number | null>(null)

  useEffect(
    () =>
      onAuthStateChanged(auth, async (nextUser) => {
        setLoading(true)
        setUser(nextUser)
        if (!nextUser) {
          setAuthorized(false)
          setLoading(false)
          return
        }
        try {
          await ensureAdminClaim(nextUser)
          setAuthorized(true)
        } catch {
          await signOut(auth)
          setUser(null)
          setAuthorized(false)
        }
        setLoading(false)
      }),
    [],
  )

  useEffect(() => {
    if (!user || !authorized) return

    const bump = () => {
      if (timer.current) window.clearTimeout(timer.current)
      timer.current = window.setTimeout(() => {
        void signOut(auth)
      }, IDLE_MS)
    }

    bump()
    const events: Array<keyof WindowEventMap> = [
      'mousemove',
      'keydown',
      'click',
      'scroll',
      'touchstart',
    ]
    for (const event of events) window.addEventListener(event, bump)
    return () => {
      if (timer.current) window.clearTimeout(timer.current)
      for (const event of events) window.removeEventListener(event, bump)
    }
  }, [authorized, user])

  const value = useMemo<AuthValue>(
    () => ({
      user,
      loading,
      authorized,
      login: async (email, password) => {
        const credential = await signInWithEmailAndPassword(
          auth,
          email.trim().toLowerCase(),
          password,
        )
        try {
          await ensureAdminClaim(credential.user)
        } catch (error) {
          await signOut(auth)
          throw error instanceof Error
            ? error
            : new Error(adminErrorMessage(error))
        }
      },
      logout: () => signOut(auth),
    }),
    [authorized, loading, user],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const value = useContext(AuthContext)
  if (!value) throw new Error('useAuth must be used inside AuthProvider')
  return value
}
