import { useEffect, useRef, useState } from 'react'
import { useApp } from '../store'
import Icons from '../icons'

const weatherDesc = (code) => {
  if (code === 0) return { label: 'Clear Sky', emoji: '☀️' }
  if (code <= 3) return { label: 'Partly Cloudy', emoji: '⛅' }
  if (code === 45 || code === 48) return { label: 'Foggy', emoji: '🌫️' }
  if (code >= 51 && code <= 57) return { label: 'Drizzle', emoji: '🌦️' }
  if (code >= 61 && code <= 67) return { label: 'Rainy', emoji: '🌧️' }
  if (code >= 80 && code <= 82) return { label: 'Rain Showers', emoji: '🌩️' }
  if (code >= 95) return { label: 'Thunderstorms', emoji: '⛈️' }
  return { label: 'Cloudy', emoji: '☁️' }
}

function StatCard({ label, value, icon: Icon, color, unit = '' }) {
  return (
    <div className="stat-card" style={{ '--card-accent': color }}>
      <div className="stat-icon" style={{ background: `${color}18` }}>
        <span style={{ color }}><Icon /></span>
      </div>
      <div className="stat-value">{value}<span style={{ fontSize: 16, fontWeight: 500, color: 'var(--text-secondary)' }}>{unit}</span></div>
      <div className="stat-label">{label}</div>
    </div>
  )
}

function MiniSparkline({ values, color }) {
  const max = Math.max(...values)
  const min = Math.min(...values)
  const range = max - min || 1
  return (
    <div className="mini-chart">
      {values.map((v, i) => (
        <div key={i} className="mini-bar" style={{ height: `${((v - min) / range) * 100}%`, background: color, minHeight: 4 }} />
      ))}
    </div>
  )
}

export default function Dashboard() {
  const { sensorData, roverState, alerts, weatherData, weatherLoading, setPage, stopRover, addAlert } = useApp()
  const [showAlerts, setShowAlerts] = useState(false)
  const { markAlertRead, clearAlerts } = useApp()

  const [tempHistory, setTempHistory] = useState([28, 28.2, 27.9, 28.5, 28.4])
  const [moistHistory, setMoistHistory] = useState([42, 41, 43, 41.5, 41.5])

  useEffect(() => {
    setTempHistory(h => [...h.slice(-9), sensorData.temperature])
    setMoistHistory(h => [...h.slice(-9), sensorData.moisture])
  }, [sensorData])

  const unreadCount = alerts.filter(a => !a.isRead).length

  const irrigationVerdict = () => {
    if (sensorData.moisture >= 35) return { text: '✅ Watering Not Required', sub: `Soil moisture is optimal (${sensorData.moisture.toFixed(1)}%). Environment is well-hydrated.`, color: 'var(--accent-green)' }
    if (weatherData && weatherData.rainProbability >= 60) return { text: '🌧️ Hold Irrigation (Rain Forecast)', sub: `Moisture low (${sensorData.moisture.toFixed(1)}%), but ${weatherData.rainProbability.toFixed(0)}% rain chance. Save water.`, color: 'var(--accent-orange)' }
    return { text: '💧 Watering Recommended', sub: `Soil moisture critical at ${sensorData.moisture.toFixed(1)}%. No precipitation forecast. Turn on irrigation.`, color: 'var(--accent-cyan)' }
  }

  const advisory = irrigationVerdict()
  const weather = weatherData ? weatherDesc(weatherData.weatherCode) : null

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div>
          <h2>AgroNet AI</h2>
          <div className="subtitle">
            <span className="live-dot" style={{ marginRight: 6 }} />
            Sector 4 — Active
          </div>
        </div>
        <div className="header-actions">
          <button className="notif-btn" onClick={() => setShowAlerts(true)}>
            <span style={{ width: 18, height: 18, display: 'flex' }}><Icons.Bell /></span>
            {unreadCount > 0 && <span className="notif-badge">{unreadCount}</span>}
          </button>
          <button className="btn btn-secondary" onClick={() => setPage('settings')}>
            <span style={{ width: 16, height: 16, display: 'flex' }}><Icons.Settings /></span>
            Settings
          </button>
        </div>
      </div>

      <div className="page-body">
        {/* Live Telemetry */}
        <div className="section-header">
          <span className="section-title">Live Telemetry</span>
          <span className="badge badge-green"><span className="live-dot" style={{ width: 6, height: 6 }} />Live</span>
        </div>
        <div className="stats-grid" style={{ marginBottom: 28 }}>
          <StatCard label="Temperature" value={sensorData.temperature.toFixed(1)} unit="°C" icon={Icons.Thermometer} color="var(--accent-orange)" />
          <StatCard label="Humidity" value={sensorData.humidity.toFixed(1)} unit="%" icon={Icons.Droplet} color="var(--accent-blue)" />
          <StatCard label="Soil Moisture" value={sensorData.moisture.toFixed(1)} unit="%" icon={Icons.Waves} color="var(--accent-cyan)" />
          <StatCard label="Soil pH" value={sensorData.ph.toFixed(1)} icon={Icons.Flask} color="var(--accent-purple)" />
        </div>

        {/* Row: Weather + Irrigation Advisory */}
        <div className="grid-2" style={{ marginBottom: 28 }}>
          {/* Weather Card */}
          <div className="glass-card">
            <div className="section-header" style={{ marginBottom: 14 }}>
              <span className="section-title">Weather Forecast</span>
              {weather && <span style={{ fontSize: 22 }}>{weather.emoji}</span>}
            </div>
            {weatherLoading ? (
              <div style={{ display: 'flex', justifyContent: 'center', padding: 20 }}><div className="spinner" /></div>
            ) : weatherData ? (
              <div>
                <div style={{ fontSize: 40, fontWeight: 800, color: 'var(--text-primary)', lineHeight: 1 }}>
                  {weatherData.temperature.toFixed(1)}°C
                </div>
                <div style={{ color: 'var(--text-secondary)', marginTop: 4, fontSize: 14 }}>{weather?.label}</div>
                <hr className="divider" />
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Min / Max</span>
                  <span style={{ fontWeight: 600 }}>{weatherData.tempMin.toFixed(0)}° / {weatherData.tempMax.toFixed(0)}°</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginTop: 8 }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Rain Probability</span>
                  <span style={{ fontWeight: 600, color: weatherData.rainProbability > 60 ? 'var(--accent-blue)' : 'var(--text-primary)' }}>{weatherData.rainProbability.toFixed(0)}%</span>
                </div>
                <div className="progress-bar" style={{ marginTop: 8 }}>
                  <div className="progress-fill" style={{ width: `${weatherData.rainProbability}%`, background: 'var(--accent-blue)' }} />
                </div>
              </div>
            ) : null}
          </div>

          {/* Irrigation Advisory */}
          <div className="glass-card">
            <div className="section-title" style={{ marginBottom: 14 }}>Smart Irrigation Advisory</div>
            <div className="advisory-card">
              <div className="advisory-icon-wrap" style={{ background: `${advisory.color}18`, fontSize: 24 }}>
                {advisory.text.split(' ')[0]}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, color: advisory.color, fontSize: 15, marginBottom: 6 }}>
                  {advisory.text.slice(2)}
                </div>
                <div style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.5 }}>{advisory.sub}</div>
                {weatherData && (
                  <>
                    <hr className="divider" />
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--text-muted)' }}>
                      <span>Humidity: {weatherData.humidity.toFixed(0)}%</span>
                      <span>Rain: {weatherData.rainProbability.toFixed(0)}%</span>
                    </div>
                  </>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Rover Status */}
        <div className="section-header"><span className="section-title">Rover Status</span></div>
        <div className="glass-card clickable" style={{ marginBottom: 28 }} onClick={() => setPage('rover')}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{ width: 52, height: 52, borderRadius: '50%', background: roverState.isConnected ? 'var(--accent-green-dim)' : 'var(--accent-red-dim)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, flexShrink: 0 }}>
              <span style={{ color: roverState.isConnected ? 'var(--accent-green)' : 'var(--accent-red)' }}><Icons.Bot /></span>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 4 }}>
                {roverState.isConnected ? 'Connected' : 'Connecting…'}
              </div>
              <div style={{ fontSize: 13, color: 'var(--text-secondary)', display: 'flex', gap: 16 }}>
                <span>Battery: <strong style={{ color: roverState.battery > 20 ? 'var(--accent-green)' : 'var(--accent-red)' }}>{roverState.battery.toFixed(0)}%</strong></span>
                <span>Status: <strong style={{ color: roverState.motorStatus === 'IDLE' ? 'var(--text-secondary)' : 'var(--accent-cyan)' }}>{roverState.motorStatus}</strong></span>
                <span>GPS: <strong>{roverState.latitude.toFixed(4)}, {roverState.longitude.toFixed(4)}</strong></span>
              </div>
            </div>
            <span style={{ color: 'var(--text-muted)', display: 'flex' }}><Icons.ChevronRight /></span>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="section-header"><span className="section-title">Quick Actions</span></div>
        <div className="scroll-row">
          <button className="action-chip accent" onClick={() => setPage('scan')}>
            <span style={{ width: 16, height: 16, display: 'flex' }}><Icons.Scan /></span>
            Smart Scan
          </button>
          <button className="action-chip" onClick={() => setPage('rover')}>
            <span style={{ width: 16, height: 16, display: 'flex' }}><Icons.Move /></span>
            Manual Control
          </button>
          <button className="action-chip" onClick={() => setPage('sensors')}>
            <span style={{ width: 16, height: 16, display: 'flex' }}><Icons.Activity /></span>
            Sensor Analytics
          </button>
          <button className="action-chip" onClick={() => setPage('history')}>
            <span style={{ width: 16, height: 16, display: 'flex' }}><Icons.Clock /></span>
            View History
          </button>
          <button className="action-chip danger" onClick={() => { stopRover(); alert('🛑 Rover stopped!') }}>
            <span style={{ width: 16, height: 16, display: 'flex' }}><Icons.Octagon /></span>
            Emergency Stop
          </button>
        </div>

        {/* Sensor charts */}
        <div className="grid-2" style={{ marginTop: 28 }}>
          <div className="glass-card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <span className="section-title">Temperature Trend</span>
              <span style={{ fontSize: 13, color: 'var(--accent-orange)', fontWeight: 600 }}>{sensorData.temperature.toFixed(1)}°C</span>
            </div>
            <MiniSparkline values={tempHistory} color="var(--accent-orange)" />
          </div>
          <div className="glass-card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <span className="section-title">Moisture Trend</span>
              <span style={{ fontSize: 13, color: 'var(--accent-cyan)', fontWeight: 600 }}>{sensorData.moisture.toFixed(1)}%</span>
            </div>
            <MiniSparkline values={moistHistory} color="var(--accent-cyan)" />
          </div>
        </div>
      </div>

      {/* Alerts Modal */}
      {showAlerts && (
        <div className="modal-overlay" onClick={() => setShowAlerts(false)}>
          <div className="modal" style={{ maxWidth: 500 }} onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <span className="modal-title">🔔 System Alerts</span>
              <button className="modal-close" onClick={() => setShowAlerts(false)}><Icons.X /></button>
            </div>
            {alerts.length > 0 && (
              <div style={{ textAlign: 'right', marginBottom: 10 }}>
                <button className="btn btn-danger" style={{ fontSize: 12 }} onClick={clearAlerts}>Clear All</button>
              </div>
            )}
            {alerts.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '32px 0', color: 'var(--text-muted)' }}>
                <div style={{ fontSize: 40, marginBottom: 12 }}>🔕</div>
                No active alerts at this time.
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10, maxHeight: '60vh', overflowY: 'auto' }}>
                {alerts.map(a => (
                  <div key={a.id} className={`alert-item ${a.type === 'ERROR' ? 'error' : a.type === 'WARNING' ? 'warning' : 'info'}`}>
                    <span style={{ color: a.type === 'ERROR' ? 'var(--accent-red)' : a.type === 'WARNING' ? 'var(--accent-orange)' : 'var(--accent-blue)', width: 18, height: 18, display: 'flex', flexShrink: 0, marginTop: 2 }}>
                      {a.type === 'ERROR' ? <Icons.XCircle /> : a.type === 'WARNING' ? <Icons.AlertTriangle /> : <Icons.Info />}
                    </span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 600, fontSize: 14, textDecoration: a.isRead ? 'line-through' : 'none', opacity: a.isRead ? 0.5 : 1 }}>{a.title}</div>
                      <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>{a.message}</div>
                    </div>
                    {!a.isRead && (
                      <button className="btn-icon" style={{ padding: 4 }} onClick={() => markAlertRead(a.id)} title="Mark read">
                        <span style={{ width: 14, height: 14, display: 'flex' }}><Icons.Check /></span>
                      </button>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
