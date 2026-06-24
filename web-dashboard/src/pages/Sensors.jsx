import { useEffect, useState, useRef, Component } from 'react'
import { useApp } from '../store'
import Icons from '../icons'

class ErrorBoundary extends Component {
  constructor(props) { super(props); this.state = { hasError: false, error: null } }
  static getDerivedStateFromError(error) { return { hasError: true, error } }
  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: 24, color: 'var(--accent-red)', background: 'rgba(248,113,113,0.06)', borderRadius: 12, border: '1px solid rgba(248,113,113,0.2)', margin: 16 }}>
          <strong>⚠️ Render Error:</strong> {this.state.error?.message}
          <br /><button style={{ marginTop: 12, padding: '6px 14px', background: 'var(--bg-card)', border: '1px solid var(--border-color)', borderRadius: 8, color: 'var(--text-primary)', cursor: 'pointer' }} onClick={() => this.setState({ hasError: false, error: null })}>Retry</button>
        </div>
      )
    }
    return this.props.children
  }
}

function Gauge({ value, max, label, unit, color, low, high }) {
  const pct = Math.min(100, (value / max) * 100)
  const status = value < low ? 'low' : value > high ? 'high' : 'normal'
  const statusColors = { low: 'var(--accent-blue)', normal: color, high: 'var(--accent-red)' }
  const sc = statusColors[status]

  return (
    <div className="glass-card" style={{ textAlign: 'center', position: 'relative' }}>
      {/* Circular gauge */}
      <div style={{ position: 'relative', width: 100, height: 100, margin: '0 auto 14px' }}>
        <svg viewBox="0 0 100 100" style={{ transform: 'rotate(-90deg)' }}>
          <circle cx="50" cy="50" r="42" fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="10" />
          <circle cx="50" cy="50" r="42" fill="none" stroke={sc} strokeWidth="10"
            strokeDasharray={`${pct * 2.638} 263.8`} strokeLinecap="round"
            style={{ transition: 'stroke-dasharray 0.5s ease' }}
          />
        </svg>
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ fontSize: 18, fontWeight: 800, color: sc, lineHeight: 1 }}>{value.toFixed(1)}</div>
          <div style={{ fontSize: 10, color: 'var(--text-muted)' }}>{unit}</div>
        </div>
      </div>
      <div style={{ fontWeight: 600, fontSize: 14, marginBottom: 4 }}>{label}</div>
      <div style={{ fontSize: 11, padding: '2px 8px', borderRadius: 10, display: 'inline-block', background: `${sc}18`, color: sc, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
        {status}
      </div>
    </div>
  )
}

// Resolve a CSS variable like 'var(--accent-orange)' to a real color string
const CSS_COLOR_MAP = {
  'var(--accent-orange)': '#fb923c',
  'var(--accent-blue)':   '#60a5fa',
  'var(--accent-cyan)':   '#22d3ee',
  'var(--accent-purple)': '#a78bfa',
  'var(--accent-green)':  '#4ade80',
  'var(--accent-red)':    '#f87171',
}

function resolveColor(c) {
  return CSS_COLOR_MAP[c] || c
}

function LineChart({ data, color, label, unit }) {
  const canvasRef = useRef()
  const resolvedColor = resolveColor(color)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    if (!data || data.length < 2) return

    const ctx = canvas.getContext('2d')
    const W = canvas.offsetWidth || canvas.width
    const H = canvas.height
    canvas.width = W  // sync logical px to physical
    if (!W || !H) return

    const values = data.map(d => (typeof d.value === 'number' && isFinite(d.value)) ? d.value : 0)
    const max = Math.max(...values)
    const min = Math.min(...values)
    const range = (max - min) || 1

    ctx.clearRect(0, 0, W, H)

    const toX = (i) => (i / (values.length - 1)) * W
    const toY = (v) => H - ((v - min) / range) * H * 0.75 - H * 0.1

    // Gradient fill
    const grad = ctx.createLinearGradient(0, 0, 0, H)
    grad.addColorStop(0, resolvedColor + '66')
    grad.addColorStop(1, resolvedColor + '00')

    ctx.beginPath()
    ctx.moveTo(toX(0), H)
    values.forEach((v, i) => ctx.lineTo(toX(i), toY(v)))
    ctx.lineTo(toX(values.length - 1), H)
    ctx.closePath()
    ctx.fillStyle = grad
    ctx.fill()

    // Line
    ctx.beginPath()
    values.forEach((v, i) => {
      const x = toX(i), y = toY(v)
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
    })
    ctx.strokeStyle = resolvedColor
    ctx.lineWidth = 2.5
    ctx.lineJoin = 'round'
    ctx.stroke()

    // Last point dot
    const lx = toX(values.length - 1), ly = toY(values[values.length - 1])
    ctx.beginPath()
    ctx.arc(lx, ly, 5, 0, Math.PI * 2)
    ctx.fillStyle = resolvedColor
    ctx.fill()
  }, [data, resolvedColor])

  const last = data?.[data.length - 1]
  const lastVal = typeof last?.value === 'number' && isFinite(last.value) ? last.value.toFixed(1) : '—'

  return (
    <div className="glass-card">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <span style={{ fontWeight: 600, fontSize: 14 }}>{label}</span>
        <span style={{ fontWeight: 700, color: resolvedColor, fontSize: 18 }}>{lastVal}{unit}</span>
      </div>
      {data && data.length >= 2 ? (
        <canvas ref={canvasRef} height={100} style={{ width: '100%', height: 100, display: 'block' }} />
      ) : (
        <div style={{ height: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)', fontSize: 13 }}>Collecting data…</div>
      )}
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 11, color: 'var(--text-muted)' }}>
        <span>{data?.[0]?.time}</span>
        <span>{last?.time}</span>
      </div>
    </div>
  )
}

const MAX_HISTORY = 30

export default function SensorsPage() {
  const { sensorData, addHistory } = useApp()
  const [histories, setHistories] = useState({
    temperature: [], humidity: [], moisture: [], ph: []
  })
  const snapshotTimer = useRef()

  const fmt = (d) => `${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}`

  useEffect(() => {
    const now = new Date()
    const point = { time: fmt(now), ...sensorData }
    setHistories(prev => ({
      temperature: [...prev.temperature, { time: fmt(now), value: sensorData.temperature }].slice(-MAX_HISTORY),
      humidity: [...prev.humidity, { time: fmt(now), value: sensorData.humidity }].slice(-MAX_HISTORY),
      moisture: [...prev.moisture, { time: fmt(now), value: sensorData.moisture }].slice(-MAX_HISTORY),
      ph: [...prev.ph, { time: fmt(now), value: sensorData.ph }].slice(-MAX_HISTORY),
    }))
  }, [sensorData])

  // Log sensor snapshot every 30 seconds
  useEffect(() => {
    snapshotTimer.current = setInterval(() => {
      addHistory({
        id: `sensor_${Date.now()}`,
        type: 'SENSOR',
        timestamp: new Date().toISOString(),
        title: `Sensor Reading — ${fmt(new Date())}`,
        description: `Temp: ${sensorData.temperature.toFixed(1)}°C | Moisture: ${sensorData.moisture.toFixed(1)}% | pH: ${sensorData.ph.toFixed(1)}`,
        severity: sensorData.temperature > 35 || sensorData.moisture < 25 ? 'HIGH' : sensorData.moisture < 35 ? 'MEDIUM' : 'LOW',
        metadata: { ...sensorData }
      })
    }, 30000)
    return () => clearInterval(snapshotTimer.current)
  }, [sensorData, addHistory])

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>📊 Sensor Analytics</h2>
          <div className="subtitle">
            <span className="live-dot" style={{ marginRight: 6 }} />
            Real-time ESP32 telemetry — polling every 3s
          </div>
        </div>
        <div className="header-actions">
          <span className="badge badge-green">
            <span className="live-dot" style={{ width: 6, height: 6 }} />
            Live
          </span>
        </div>
      </div>

      <div className="page-body">
        {/* Gauge Row */}
        <div className="section-header"><span className="section-title">Live Readings</span></div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 28 }}>
          <ErrorBoundary><Gauge value={sensorData.temperature} max={50} label="Temperature" unit="°C" color="var(--accent-orange)" low={10} high={35} /></ErrorBoundary>
          <ErrorBoundary><Gauge value={sensorData.humidity} max={100} label="Humidity" unit="%" color="var(--accent-blue)" low={20} high={85} /></ErrorBoundary>
          <ErrorBoundary><Gauge value={sensorData.moisture} max={100} label="Soil Moisture" unit="%" color="var(--accent-cyan)" low={25} high={80} /></ErrorBoundary>
          <ErrorBoundary><Gauge value={sensorData.ph} max={14} label="Soil pH" unit="pH" color="var(--accent-purple)" low={5.5} high={7.5} /></ErrorBoundary>
        </div>

        {/* Charts */}
        <div className="section-header"><span className="section-title">Trend Analysis</span></div>
        <div className="grid-2" style={{ marginBottom: 28 }}>
          <ErrorBoundary><LineChart data={histories.temperature} color="var(--accent-orange)" label="Temperature" unit="°C" /></ErrorBoundary>
          <ErrorBoundary><LineChart data={histories.humidity} color="var(--accent-blue)" label="Humidity" unit="%" /></ErrorBoundary>
        </div>
        <div className="grid-2" style={{ marginBottom: 28 }}>
          <ErrorBoundary><LineChart data={histories.moisture} color="var(--accent-cyan)" label="Soil Moisture" unit="%" /></ErrorBoundary>
          <ErrorBoundary><LineChart data={histories.ph} color="var(--accent-purple)" label="Soil pH" unit="" /></ErrorBoundary>
        </div>

        {/* Advisory table */}
        <div className="section-header"><span className="section-title">Agronomic Advisory</span></div>
        <div className="glass-card">
          {[
            { param: 'Temperature', value: `${sensorData.temperature.toFixed(1)}°C`, optimal: '15 – 35°C', status: sensorData.temperature > 35 ? '⚠️ High' : sensorData.temperature < 10 ? '❄️ Low' : '✅ Optimal', color: sensorData.temperature > 35 || sensorData.temperature < 10 ? 'var(--accent-orange)' : 'var(--accent-green)' },
            { param: 'Humidity', value: `${sensorData.humidity.toFixed(1)}%`, optimal: '40 – 80%', status: sensorData.humidity < 20 ? '⚠️ Very Dry' : sensorData.humidity > 90 ? '💧 Too Humid' : '✅ Optimal', color: sensorData.humidity < 20 || sensorData.humidity > 90 ? 'var(--accent-orange)' : 'var(--accent-green)' },
            { param: 'Soil Moisture', value: `${sensorData.moisture.toFixed(1)}%`, optimal: '35 – 70%', status: sensorData.moisture < 25 ? '🚨 Irrigate!' : sensorData.moisture < 35 ? '⚠️ Low' : sensorData.moisture > 80 ? '💧 Waterlogged' : '✅ Optimal', color: sensorData.moisture < 25 ? 'var(--accent-red)' : sensorData.moisture < 35 ? 'var(--accent-orange)' : 'var(--accent-green)' },
            { param: 'Soil pH', value: sensorData.ph.toFixed(2), optimal: '6.0 – 7.5', status: sensorData.ph < 5.5 ? '⚠️ Too Acidic' : sensorData.ph > 7.8 ? '⚠️ Too Alkaline' : '✅ Optimal', color: sensorData.ph < 5.5 || sensorData.ph > 7.8 ? 'var(--accent-orange)' : 'var(--accent-green)' },
          ].map((row, i) => (
            <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: i < 3 ? '1px solid var(--border-color)' : 'none' }}>
              <span style={{ fontWeight: 600, flex: 1 }}>{row.param}</span>
              <span style={{ flex: 1, textAlign: 'center', fontWeight: 700, fontSize: 16 }}>{row.value}</span>
              <span style={{ flex: 1, textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}>{row.optimal}</span>
              <span style={{ flex: 1, textAlign: 'right', color: row.color, fontWeight: 600 }}>{row.status}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
