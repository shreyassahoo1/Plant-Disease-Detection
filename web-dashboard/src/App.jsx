import { useState } from 'react'
import { AppProvider, useApp } from './store'
import Icons from './icons'
import Dashboard from './pages/Dashboard'
import ScanPage from './pages/Scan'
import RoverPage from './pages/Rover'
import SensorsPage from './pages/Sensors'
import HistoryPage from './pages/History'
import SettingsPage from './pages/Settings'

const NAV_ITEMS = [
  { id: 'dashboard', label: 'Dashboard', icon: Icons.Home },
  { id: 'sensors', label: 'Sensors', icon: Icons.Activity },
  { id: 'scan', label: 'Smart Scan', icon: Icons.Scan },
  { id: 'rover', label: 'Rover Control', icon: Icons.Bot },
  { id: 'history', label: 'History', icon: Icons.Clock },
]

function Sidebar({ sidebarOpen, setSidebarOpen }) {
  const { page, setPage, alerts, roverState } = useApp()
  const unread = alerts.filter(a => !a.isRead).length

  const navigate = (id) => { setPage(id); setSidebarOpen(false) }

  return (
    <>
      {/* Mobile overlay */}
      <div className={`sidebar-overlay ${sidebarOpen ? 'visible' : ''}`} onClick={() => setSidebarOpen(false)} />

      <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
        {/* Logo */}
        <div className="sidebar-logo">
          <h1>🌿 AgroNet AI</h1>
          <p>Farm Intelligence Platform</p>
        </div>

        {/* Nav */}
        <nav className="sidebar-nav">
          {NAV_ITEMS.map(({ id, label, icon: Icon }) => (
            <button
              key={id}
              className={`nav-item ${page === id ? 'active' : ''}`}
              onClick={() => navigate(id)}
            >
              <span style={{ width: 18, height: 18, display: 'flex' }}><Icon /></span>
              <span style={{ flex: 1 }}>{label}</span>
              {id === 'dashboard' && unread > 0 && (
                <span style={{ background: 'var(--accent-red)', color: '#fff', fontSize: 10, fontWeight: 700, borderRadius: 10, padding: '1px 5px', minWidth: 16, textAlign: 'center' }}>
                  {unread}
                </span>
              )}
              {id === 'rover' && (
                <span className={`badge ${roverState.isConnected ? 'badge-green' : 'badge-red'}`} style={{ fontSize: 9, padding: '1px 5px' }}>
                  {roverState.isConnected ? 'ON' : 'OFF'}
                </span>
              )}
            </button>
          ))}
        </nav>

        {/* Bottom settings */}
        <div style={{ padding: '12px', borderTop: '1px solid var(--border-color)' }}>
          <button
            className={`nav-item ${page === 'settings' ? 'active' : ''}`}
            onClick={() => navigate('settings')}
            style={{ width: '100%' }}
          >
            <span style={{ width: 18, height: 18, display: 'flex' }}><Icons.Settings /></span>
            Settings
          </button>

          {/* Rover quick status */}
          <div style={{ marginTop: 12, padding: '10px 12px', background: 'var(--bg-card)', borderRadius: 10, border: '1px solid var(--border-color)' }}>
            <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 6, letterSpacing: '0.5px' }}>Rover</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: roverState.isConnected ? 'var(--accent-green)' : 'var(--accent-red)', animation: roverState.isConnected ? 'pulse-dot 2s infinite' : 'none' }} />
              <span style={{ fontSize: 12, fontWeight: 600 }}>{roverState.isConnected ? 'Online' : 'Offline'}</span>
              <span style={{ marginLeft: 'auto', fontSize: 12, color: roverState.battery > 20 ? 'var(--accent-green)' : 'var(--accent-red)', fontWeight: 600 }}>
                🔋 {roverState.battery.toFixed(0)}%
              </span>
            </div>
          </div>
        </div>
      </aside>
    </>
  )
}

function AppContent() {
  const { page } = useApp()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const PAGE_MAP = {
    dashboard: Dashboard,
    scan: ScanPage,
    rover: RoverPage,
    sensors: SensorsPage,
    history: HistoryPage,
    settings: SettingsPage,
  }

  const CurrentPage = PAGE_MAP[page] || Dashboard

  return (
    <div className="app-layout">
      <Sidebar sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen} />

      <main className="main-content">
        {/* Mobile hamburger */}
        <div style={{ display: 'none', padding: '12px 16px', background: 'var(--bg-secondary)', borderBottom: '1px solid var(--border-color)', alignItems: 'center', gap: 12 }} className="mobile-header">
          <button className="btn-icon" onClick={() => setSidebarOpen(true)}>
            <Icons.Menu />
          </button>
          <span style={{ fontWeight: 700, fontSize: 16 }}>AgroNet AI</span>
        </div>

        <CurrentPage />
      </main>
    </div>
  )
}

export default function App() {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  )
}
