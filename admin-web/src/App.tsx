import { lazy, Suspense } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import { AdminLayout } from './components/AdminLayout'
import { LoadingState } from './components/ui'
import { useAuth } from './contexts/AuthContext'
import { LoginPage } from './pages/LoginPage'

const AccountsPage = lazy(() =>
  import('./pages/AccountsPage').then((module) => ({ default: module.AccountsPage })),
)
const LeadersPage = lazy(() =>
  import('./pages/LeadersPage').then((module) => ({ default: module.LeadersPage })),
)
const OrdersPage = lazy(() =>
  import('./pages/OrdersPage').then((module) => ({ default: module.OrdersPage })),
)
const ReportsPage = lazy(() =>
  import('./pages/AdvancedReportsPage').then((module) => ({
    default: module.ReportsPage,
  })),
)
const ProductsPage = lazy(() =>
  import('./pages/ProductsPage').then((module) => ({ default: module.ProductsPage })),
)
const DiscountsPage = lazy(() =>
  import('./pages/DiscountsPage').then((module) => ({ default: module.DiscountsPage })),
)
const BannersPage = lazy(() =>
  import('./pages/BannersPage').then((module) => ({ default: module.BannersPage })),
)
const ContentPage = lazy(() =>
  import('./pages/ContentPage').then((module) => ({ default: module.ContentPage })),
)

function ProtectedAdmin() {
  const { user, loading, authorized } = useAuth()
  if (loading) {
    return (
      <div dir="rtl" className="min-h-screen p-6">
        <LoadingState />
      </div>
    )
  }
  if (!user || !authorized) return <Navigate to="/staff-console" replace />
  return <AdminLayout />
}

function App() {
  return (
    <Routes>
      <Route path="/staff-console" element={<LoginPage />} />
      <Route element={<ProtectedAdmin />}>
        <Route path="/admin" element={<Suspense fallback={<LoadingState />}><AccountsPage /></Suspense>} />
        <Route path="/admin/leaders" element={<Suspense fallback={<LoadingState />}><LeadersPage /></Suspense>} />
        <Route path="/admin/orders" element={<Suspense fallback={<LoadingState />}><OrdersPage /></Suspense>} />
        <Route path="/admin/delivery" element={<Suspense fallback={<LoadingState />}><OrdersPage delivery /></Suspense>} />
        <Route path="/admin/reports" element={<Suspense fallback={<LoadingState />}><ReportsPage /></Suspense>} />
        <Route path="/admin/products" element={<Suspense fallback={<LoadingState />}><ProductsPage /></Suspense>} />
        <Route path="/admin/discounts" element={<Suspense fallback={<LoadingState />}><DiscountsPage /></Suspense>} />
        <Route path="/admin/banners" element={<Suspense fallback={<LoadingState />}><BannersPage /></Suspense>} />
        <Route path="/admin/content" element={<Suspense fallback={<LoadingState />}><ContentPage /></Suspense>} />
      </Route>
      <Route path="/" element={<Navigate to="/admin" replace />} />
      <Route path="*" element={<Navigate to="/admin" replace />} />
    </Routes>
  )
}

export default App
