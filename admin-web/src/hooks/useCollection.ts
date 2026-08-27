import { useEffect, useState } from 'react'
import {
  onSnapshot,
  type DocumentData,
  type Query,
} from 'firebase/firestore'
import { normalizeError, withId } from '../lib/utils'

export function useCollection<T>(source: Query<DocumentData>) {
  const [data, setData] = useState<T[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setLoading(true)
    return onSnapshot(
      source,
      (snapshot) => {
        setData(snapshot.docs.map((item) => withId<T>(item)))
        setError(null)
        setLoading(false)
      },
      (reason) => {
        setError(normalizeError(reason))
        setLoading(false)
      },
    )
  }, [source])

  return { data, loading, error }
}
