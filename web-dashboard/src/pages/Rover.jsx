import { useState, useRef, useCallback, useEffect } from 'react'
import { useApp } from '../store'
import Icons from '../icons'

const MOTOR_LABELS = {
  IDLE: 'Idle',
  MOVING_FORWARD: 'Moving Forward',
  MOVING_BACKWARD: 'Moving Backward',
  MOVING_LEFT: 'Turning Left',
  MOVING_RIGHT: 'Turning Right',
}

function TacticalMap({ latitude, longitude, heading, path }) {
  const canvasRef = useRef()

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    const W = canvas.width, H = canvas.height

    ctx.clearRect(0, 0, W, H)

    // Background grid
    ctx.fillStyle = '#0a1a0f'
    ctx.fillRect(0, 0, W, H)
    ctx.strokeStyle = 'rgba(74,222,128,0.08)'
    ctx.lineWidth = 1
    for (let x = 0; x < W; x += 30) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke() }
    for (let y = 0; y < H; y += 30) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke() }

    if (path.length === 0) {
      // Draw center marker
      ctx.beginPath()
      ctx.arc(W / 2, H / 2, 10, 0, Math.PI * 2)
      ctx.fillStyle = 'rgba(74,222,128,0.3)'
      ctx.fill()
      ctx.strokeStyle = 'var(--accent-green)'
      ctx.lineWidth = 2
      ctx.stroke()
      return
    }

    // Compute bounding box
    const lats = path.map(p => p[0])
    const lons = path.map(p => p[1])
    const minLat = Math.min(...lats), maxLat = Math.max(...lats)
    const minLon = Math.min(...lons), maxLon = Math.max(...lons)
    const latRange = maxLat - minLat || 0.001
    const lonRange = maxLon - minLon || 0.001
    const pad = 40

    const toCanvas = ([lat, lon]) => ({
      x: pad + ((lon - minLon) / lonRange) * (W - 2 * pad),
      y: H - pad - ((lat - minLat) / latRange) * (H - 2 * pad),
    })

    // Draw path
    ctx.beginPath()
    ctx.strokeStyle = 'rgba(74,222,128,0.5)'
    ctx.lineWidth = 2
    ctx.setLineDash([4, 4])
    const first = toCanvas(path[0])
    ctx.moveTo(first.x, first.y)
    path.forEach(p => { const { x, y } = toCanvas(p); ctx.lineTo(x, y) })
    ctx.stroke()
    ctx.setLineDash([])

    // Draw rover
    const pos = toCanvas([latitude, longitude])
    const rad = heading * (Math.PI / 180)

    ctx.save()
    ctx.translate(pos.x, pos.y)
    ctx.rotate(rad)
    ctx.beginPath()
    ctx.moveTo(0, -14)
    ctx.lineTo(-9, 10)
    ctx.lineTo(9, 10)
    ctx.closePath()
    ctx.fillStyle = 'var(--accent-green, #4ade80)'
    ctx.fill()
    ctx.restore()

    // Glow ring
    ctx.beginPath()
    ctx.arc(pos.x, pos.y, 18, 0, Math.PI * 2)
    ctx.strokeStyle = 'rgba(74,222,128,0.25)'
    ctx.lineWidth = 2
    ctx.stroke()

    // Lat/Lon label
    ctx.fillStyle = 'rgba(74,222,128,0.7)'
    ctx.font = '11px Inter, sans-serif'
    ctx.fillText(`${latitude.toFixed(5)}, ${longitude.toFixed(5)}`, 10, H - 10)
  }, [latitude, longitude, heading, path])

  return (
    <canvas ref={canvasRef} width={600} height={340}
      style={{ width: '100%', height: '100%', borderRadius: 12 }} />
  )
}

function DPad({ onMove, onStop, disabled }) {
  const hold = useRef(null)

  const startHold = useCallback((dir) => {
    if (disabled) return
    onMove(dir)
    hold.current = setInterval(() => onMove(dir), 300)
  }, [onMove, disabled])

  const endHold = useCallback((dir) => {
    clearInterval(hold.current)
    if (dir !== 'STOP') onStop()
  }, [onStop])

  const Btn = ({ dir, children, danger }) => (
    <button
      className={`dpad-btn ${danger ? 'stop' : ''}`}
      onMouseDown={() => startHold(dir)}
      onMouseUp={() => endHold(dir)}
      onMouseLeave={() => endHold(dir)}
      onTouchStart={(e) => { e.preventDefault(); startHold(dir) }}
      onTouchEnd={() => endHold(dir)}
      disabled={disabled}
    >
      {children}
    </button>
  )

  return (
    <div className="dpad">
      <Btn dir="FORWARD"><Icons.ChevronUp /></Btn>
      <div className="dpad-row">
        <Btn dir="LEFT"><Icons.ChevronLeft /></Btn>
        <Btn dir="STOP" danger><Icons.Octagon /></Btn>
        <Btn dir="RIGHT"><Icons.ChevronRight /></Btn>
      </div>
      <Btn dir="BACKWARD"><Icons.ChevronDown /></Btn>
    </div>
  )
}

export default function RoverPage() {
  const { roverState, setRoverState, moveRover, stopRover, addHistory, roverUrl, setRoverUrl, camStreamUrl, setCamStreamUrl } = useApp()
  const [view, setView] = useState('camera') // 'camera' | 'map'

  const toggleAuto = () => {
    const next = !roverState.isAutoMode
    setRoverState(p => ({ ...p, isAutoMode: next, motorStatus: next ? 'MOVING_FORWARD' : 'IDLE' }))
    addHistory({
      id: `rover_patrol_${next ? 'start' : 'stop'}_${Date.now()}`,
      type: 'ROVER',
      timestamp: new Date().toISOString(),
      title: next ? 'Rover Auto-Patrol Started' : 'Rover Auto-Patrol Completed',
      description: next ? 'Rover initiated autonomous field grid patrol.' : 'Patrol finished. Rover placed in standby.',
      severity: 'INFO',
      metadata: { battery: roverState.battery, latitude: roverState.latitude, longitude: roverState.longitude }
    })
  }

  const batteryColor = roverState.battery > 50 ? 'var(--accent-green)' : roverState.battery > 20 ? 'var(--accent-orange)' : 'var(--accent-red)'

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>🤖 Rover Control</h2>
          <div className="subtitle">
            {roverState.isConnected ? (
              <><span className="live-dot" style={{ marginRight: 6 }} />Connected — {MOTOR_LABELS[roverState.motorStatus] || roverState.motorStatus}</>
            ) : 'Connecting to rover…'}
          </div>
        </div>
      </div>

      <div className="page-body">
        {/* View Toggle */}
        <div className="segment-control" style={{ marginBottom: 20, maxWidth: 360 }}>
          <button className={`segment-btn ${view === 'camera' ? 'active' : ''}`} onClick={() => setView('camera')}>
            <span style={{ width: 16, height: 16, display: 'flex' }}><Icons.Camera /></span> Camera Feed
          </button>
          <button className={`segment-btn ${view === 'map' ? 'active' : ''}`} onClick={() => setView('map')}>
            <span style={{ width: 16, height: 16, display: 'flex' }}><Icons.Map /></span> Tactical Map
          </button>
        </div>

        <div className="grid-2" style={{ gap: 24 }}>
          {/* Left: Camera / Map */}
          <div>
            <div className="cam-feed" style={{ marginBottom: 16, aspectRatio: view === 'map' ? '16/9' : '4/3', minHeight: 280 }}>
              {view === 'map' ? (
                <TacticalMap {...roverState} />
              ) : roverState.cameraActive ? (
                <>
                  {roverState.isConnected ? (
                    <img src={camStreamUrl} alt="Rover stream" style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      onError={e => { e.target.style.display = 'none' }} />
                  ) : null}
                  <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)' }}>
                    <span style={{ fontSize: 40, marginBottom: 8 }}>📷</span>
                    <div style={{ fontSize: 13 }}>Stream: {camStreamUrl}</div>
                    <div style={{ fontSize: 11, marginTop: 4, color: 'var(--text-muted)' }}>Connect rover to view live feed</div>
                  </div>
                  <div className="rec-badge">● REC</div>
                </>
              ) : (
                <div style={{ textAlign: 'center', color: 'var(--text-muted)' }}>
                  <span style={{ width: 48, height: 48, display: 'flex', margin: '0 auto 12px' }}><Icons.CameraOff /></span>
                  <div>Camera offline</div>
                  <div style={{ fontSize: 12, marginTop: 4 }}>Press "Start Cam" to enable</div>
                </div>
              )}
            </div>

            {/* Actions row */}
            <div style={{ display: 'flex', gap: 10, marginBottom: 16, flexWrap: 'wrap' }}>
              <button className="btn btn-secondary" style={{ flex: 1 }} onClick={() => setRoverState(p => ({ ...p, cameraActive: !p.cameraActive }))}>
                <span style={{ width: 16, height: 16, display: 'flex' }}>{roverState.cameraActive ? <Icons.CameraOff /> : <Icons.Camera />}</span>
                {roverState.cameraActive ? 'Stop Cam' : 'Start Cam'}
              </button>
              <button
                className={`btn ${roverState.isAutoMode ? 'btn-primary' : 'btn-secondary'}`}
                style={{ flex: 1 }}
                onClick={toggleAuto}
                disabled={!roverState.isConnected}
              >
                <span style={{ width: 16, height: 16, display: 'flex' }}><Icons.Bot /></span>
                Auto: {roverState.isAutoMode ? 'ON' : 'OFF'}
              </button>
            </div>

            {/* Telemetry row */}
            <div className="grid-2" style={{ gap: 12 }}>
              <div className="glass-card" style={{ padding: 14, textAlign: 'center' }}>
                <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 6 }}>Battery</div>
                <div style={{ fontSize: 22, fontWeight: 700, color: batteryColor }}>{roverState.battery.toFixed(0)}%</div>
                <div className="progress-bar"><div className="progress-fill" style={{ width: `${roverState.battery}%`, background: batteryColor }} /></div>
              </div>
              <div className="glass-card" style={{ padding: 14, textAlign: 'center' }}>
                <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 6 }}>Speed</div>
                <div style={{ fontSize: 22, fontWeight: 700, color: 'var(--accent-cyan)' }}>{roverState.speed.toFixed(0)}%</div>
                <div className="progress-bar"><div className="progress-fill" style={{ width: `${roverState.speed}%`, background: 'var(--accent-cyan)' }} /></div>
              </div>
            </div>

            {/* GPS */}
            <div className="glass-card" style={{ padding: 12, marginTop: 12, fontSize: 12, color: 'var(--text-secondary)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>📍 GPS: <strong style={{ color: 'var(--text-primary)' }}>{roverState.latitude.toFixed(5)}, {roverState.longitude.toFixed(5)}</strong></span>
                <span>🧭 Heading: <strong style={{ color: 'var(--text-primary)' }}>{roverState.heading.toFixed(0)}°</strong></span>
              </div>
            </div>
          </div>

          {/* Right: Controls */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
            <div className="glass-card" style={{ textAlign: 'center' }}>
              <div style={{ fontWeight: 700, marginBottom: 20 }}>D-Pad Control</div>
              <DPad
                onMove={moveRover}
                onStop={stopRover}
                disabled={!roverState.isConnected}
              />
              <div style={{ marginTop: 20, fontSize: 13, color: 'var(--text-muted)' }}>
                {!roverState.isConnected ? '⚠️ Rover not connected' : `Status: ${MOTOR_LABELS[roverState.motorStatus] || roverState.motorStatus}`}
              </div>
            </div>

            {/* Speed Slider */}
            <div className="glass-card">
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                <span style={{ fontWeight: 600 }}>Speed</span>
                <span style={{ color: 'var(--accent-cyan)', fontWeight: 700 }}>{roverState.speed.toFixed(0)}%</span>
              </div>
              <input type="range" min="0" max="100" step="10"
                value={roverState.speed}
                onChange={e => setRoverState(p => ({ ...p, speed: +e.target.value }))}
                disabled={!roverState.isConnected}
              />
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: 'var(--text-muted)', marginTop: 4 }}>
                <span>Slow</span><span>Fast</span>
              </div>
            </div>

            {/* ESP32-CAM URL config */}
            <div className="glass-card">
              <div style={{ fontWeight: 600, marginBottom: 10, fontSize: 13 }}>🤖 Rover Control URL</div>
              <input className="input-field" style={{ fontSize: 12, marginBottom: 12 }} placeholder="http://192.168.x.x"
                value={roverUrl} onChange={e => setRoverUrl(e.target.value)} />
              
              <div style={{ fontWeight: 600, marginBottom: 10, fontSize: 13 }}>🎥 Camera Stream URL</div>
              <input className="input-field" style={{ fontSize: 12 }} placeholder="http://192.168.x.x:81/stream"
                value={camStreamUrl} onChange={e => setCamStreamUrl(e.target.value)} />
              <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 6 }}>
                Enter local IP addresses for your ESP32 boards
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
