import { useState } from 'react'
import { useApp } from '../store'
import Icons from '../icons'

const TYPE_ICONS = {
  SCAN: { icon: Icons.Scan, color: 'var(--accent-green)' },
  ALERT: { icon: Icons.Bell, color: 'var(--accent-orange)' },
  ROVER: { icon: Icons.Bot, color: 'var(--accent-blue)' },
  SENSOR: { icon: Icons.Activity, color: 'var(--accent-purple)' },
}

const SEVERITY_COLORS = {
  HIGH: 'var(--accent-red)',
  MEDIUM: 'var(--accent-orange)',
  LOW: 'var(--accent-green)',
  INFO: 'var(--accent-blue)',
}

const FILTERS = ['ALL', 'SCAN', 'ALERT', 'ROVER', 'SENSOR']

function formatDate(ts) {
  const d = new Date(ts)
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const yesterday = new Date(today - 86400000)
  const item = new Date(d.getFullYear(), d.getMonth(), d.getDate())
  const time = `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
  if (+item === +today) return `Today, ${time}`
  if (+item === +yesterday) return `Yesterday, ${time}`
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
  return `${months[d.getMonth()]} ${d.getDate()}, ${time}`
}

function DetailModal({ item, onClose }) {
  if (!item) return null
  const meta = item.metadata || {}
  const isHealthy = item.type === 'SCAN' && item.title?.toLowerCase().includes('healthy')
  const sc = SEVERITY_COLORS[item.severity] || 'var(--text-secondary)'

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" style={{ maxWidth: 600 }} onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <div>
            <div className="modal-title">{item.title}</div>
            <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>{formatDate(item.timestamp)}</div>
          </div>
          <button className="modal-close" onClick={onClose}><Icons.X /></button>
        </div>

        <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
          <span className={`badge ${item.type === 'SCAN' ? 'badge-green' : item.type === 'ALERT' ? 'badge-orange' : item.type === 'ROVER' ? 'badge-blue' : 'badge-cyan'}`}>{item.type}</span>
          <span className="badge" style={{ background: `${sc}18`, color: sc, border: `1px solid ${sc}33` }}>{item.severity}</span>
        </div>

        <p style={{ fontSize: 14, color: 'var(--text-secondary)', lineHeight: 1.6, marginBottom: 16 }}>{item.description}</p>

        {item.type === 'SCAN' && meta.diseaseName && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div className="glass-card" style={{ padding: 14 }}>
              <div style={{ fontSize: 18, fontWeight: 700, color: isHealthy ? 'var(--accent-green)' : 'var(--accent-red)', marginBottom: 6 }}>
                {isHealthy ? '🌿' : '🥀'} {meta.diseaseName}
              </div>
              <div style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Confidence: <strong style={{ color: 'var(--text-primary)' }}>{meta.confidence}%</strong></div>
            </div>
            {meta.precautions?.length > 0 && (
              <div className="glass-card" style={{ padding: 14 }}>
                <div style={{ fontWeight: 600, marginBottom: 8 }}>🛡️ Precautions</div>
                {meta.precautions.map((p, i) => <div key={i} style={{ fontSize: 13, padding: '4px 0', color: 'var(--text-secondary)', borderBottom: i < meta.precautions.length - 1 ? '1px solid var(--border-color)' : 'none' }}>• {p}</div>)}
              </div>
            )}
            {meta.indianFertilizers?.length > 0 && (
              <div className="glass-card" style={{ padding: 14 }}>
                <div style={{ fontWeight: 600, marginBottom: 8 }}>🌱 Fertilizers</div>
                {meta.indianFertilizers.map((f, i) => <div key={i} style={{ fontSize: 13, color: 'var(--accent-green)', padding: '3px 0' }}>• {f}</div>)}
              </div>
            )}
          </div>
        )}

        {item.type === 'SENSOR' && (
          <div className="grid-2" style={{ gap: 10 }}>
            {[
              { k: 'Temperature', v: meta.temperature?.toFixed(1), u: '°C', c: 'var(--accent-orange)' },
              { k: 'Humidity', v: meta.humidity?.toFixed(1), u: '%', c: 'var(--accent-blue)' },
              { k: 'Moisture', v: meta.moisture?.toFixed(1), u: '%', c: 'var(--accent-cyan)' },
              { k: 'Soil pH', v: meta.ph?.toFixed(2), u: '', c: 'var(--accent-purple)' },
            ].map(({ k, v, u, c }) => v && (
              <div key={k} className="glass-card" style={{ padding: 12, textAlign: 'center' }}>
                <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 4 }}>{k}</div>
                <div style={{ fontSize: 22, fontWeight: 700, color: c }}>{v}{u}</div>
              </div>
            ))}
          </div>
        )}

        {item.type === 'ROVER' && meta.latitude && (
          <div className="glass-card" style={{ padding: 14, fontSize: 14 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <span style={{ color: 'var(--text-muted)' }}>GPS</span>
              <span>{meta.latitude?.toFixed(5)}, {meta.longitude?.toFixed(5)}</span>
            </div>
            {meta.batteryStart !== undefined && (
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Battery</span>
                <span>{meta.batteryStart?.toFixed(0)}% → {meta.batteryEnd?.toFixed(0) || '—'}%</span>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

function CompareModal({ items, onClose }) {
  if (items.length !== 2) return null
  const [a, b] = items.sort((x, y) => new Date(x.timestamp) - new Date(y.timestamp))
  const isScan = a.type === 'SCAN' && b.type === 'SCAN'
  const isSensor = a.type === 'SENSOR' && b.type === 'SENSOR'

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" style={{ maxWidth: 680 }} onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title">🔀 Log Comparison</span>
          <button className="modal-close" onClick={onClose}><Icons.X /></button>
        </div>

        <div className="grid-2" style={{ gap: 12, marginBottom: 20 }}>
          {[a, b].map((item, i) => {
            const sc = SEVERITY_COLORS[item.severity] || 'var(--text-secondary)'
            return (
              <div key={i} className="glass-card" style={{ padding: 14 }}>
                <div style={{ fontSize: 10, color: 'var(--text-muted)', textTransform: 'uppercase', marginBottom: 4 }}>{i === 0 ? '① Older Record' : '② Newer Record'}</div>
                <div style={{ fontWeight: 700, fontSize: 14, marginBottom: 4 }}>{item.title}</div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 8 }}>{formatDate(item.timestamp)}</div>
                <span className="badge" style={{ background: `${sc}18`, color: sc, border: `1px solid ${sc}33` }}>{item.severity}</span>
              </div>
            )
          })}
        </div>

        {isSensor && (() => {
          const rows = [
            { label: 'Temperature', key: 'temperature', unit: '°C', lowerBetter: true },
            { label: 'Humidity', key: 'humidity', unit: '%', lowerBetter: null },
            { label: 'Soil Moisture', key: 'moisture', unit: '%', lowerBetter: false },
            { label: 'Soil pH', key: 'ph', unit: '', lowerBetter: null },
          ]
          return (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <div style={{ fontWeight: 700, marginBottom: 4, color: 'var(--text-secondary)', fontSize: 13, textTransform: 'uppercase' }}>Telemetry Delta</div>
              {rows.map(({ label, key, unit, lowerBetter }) => {
                const v1 = a.metadata?.[key] ?? 0, v2 = b.metadata?.[key] ?? 0
                const diff = v2 - v1
                const improved = lowerBetter === true ? diff < 0 : lowerBetter === false ? diff > 0 : null
                const dc = improved === true ? 'var(--accent-green)' : improved === false ? 'var(--accent-red)' : 'var(--accent-blue)'
                return (
                  <div key={key} className="glass-card" style={{ padding: '10px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontWeight: 600, flex: 2 }}>{label}</span>
                    <span style={{ flex: 2, textAlign: 'center', color: 'var(--text-secondary)' }}>{v1.toFixed(1)}{unit}</span>
                    <span style={{ flex: 1, textAlign: 'center', color: 'var(--text-muted)', fontSize: 18 }}>→</span>
                    <span style={{ flex: 2, textAlign: 'center' }}>{v2.toFixed(1)}{unit}</span>
                    <span className="badge" style={{ background: `${dc}18`, color: dc, border: `1px solid ${dc}33` }}>
                      {diff > 0 ? '+' : ''}{diff.toFixed(1)}{unit}
                    </span>
                  </div>
                )
              })}
            </div>
          )
        })()}

        {isScan && (() => {
          const d1 = a.metadata?.diseaseName || '—', d2 = b.metadata?.diseaseName || '—'
          const c1 = a.metadata?.confidence || 0, c2 = b.metadata?.confidence || 0
          const recovered = d2?.toLowerCase().includes('healthy') && !d1?.toLowerCase().includes('healthy')
          const worsened = !d2?.toLowerCase().includes('healthy') && d1?.toLowerCase().includes('healthy')
          const statusColor = recovered ? 'var(--accent-green)' : worsened ? 'var(--accent-red)' : 'var(--accent-orange)'
          const statusText = recovered ? '🎉 Full Recovery! Disease has cleared.' : worsened ? '⚠️ Deterioration detected. Review treatment.' : d1 === d2 ? '📋 Same condition persists.' : '🔄 New condition detected.'
          return (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div className="glass-card" style={{ padding: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 10 }}>
                  <span style={{ color: 'var(--text-muted)', fontSize: 13 }}>Diagnosis</span>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>{d1}</div>
                    <div style={{ fontSize: 12 }}>→ <strong style={{ color: d2?.toLowerCase().includes('healthy') ? 'var(--accent-green)' : 'var(--accent-red)' }}>{d2}</strong></div>
                  </div>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)', fontSize: 13 }}>Confidence</span>
                  <span>{c1}% → <strong>{c2}%</strong></span>
                </div>
              </div>
              <div className="glass-card" style={{ padding: 14, border: `1px solid ${statusColor}33`, background: `${statusColor}08` }}>
                <div style={{ fontWeight: 700, color: statusColor, marginBottom: 4 }}>Pathological Assessment</div>
                <div style={{ fontSize: 14 }}>{statusText}</div>
              </div>
            </div>
          )
        })()}
      </div>
    </div>
  )
}

export default function HistoryPage() {
  const { history, clearHistory, deleteHistoryItem } = useApp()
  const [filter, setFilter] = useState('ALL')
  const [selected, setSelected] = useState(null)
  const [compareMode, setCompareMode] = useState(false)
  const [compareItems, setCompareItems] = useState([])
  const [showCompare, setShowCompare] = useState(false)
  const [showClearConfirm, setShowClearConfirm] = useState(false)

  const filtered = history.filter(h => filter === 'ALL' || h.type === filter)

  const toggleCompare = (item) => {
    setCompareItems(prev => {
      if (prev.find(p => p.id === item.id)) return prev.filter(p => p.id !== item.id)
      if (prev.length >= 2) return prev
      return [...prev, item]
    })
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>📋 History Logs</h2>
          <div className="subtitle">{history.length} total entries</div>
        </div>
        <div className="header-actions">
          {history.length > 0 && (
            <>
              <button className={`btn ${compareMode ? 'btn-primary' : 'btn-secondary'}`} onClick={() => { setCompareMode(v => !v); setCompareItems([]) }}>
                {compareMode ? '✓ Done' : '⚖️ Compare'}
              </button>
              <button className="btn btn-danger" onClick={() => setShowClearConfirm(true)}>
                <span style={{ width: 14, height: 14, display: 'flex' }}><Icons.Trash /></span>
                Clear All
              </button>
            </>
          )}
        </div>
      </div>

      <div className="page-body">
        {/* Filters */}
        <div className="filter-chips">
          {FILTERS.map(f => (
            <button key={f} className={`chip ${filter === f ? 'active' : ''}`} onClick={() => { setFilter(f); setCompareItems([]) }}>
              {f === 'ALL' ? 'All' : f.charAt(0) + f.slice(1).toLowerCase()}s
            </button>
          ))}
        </div>

        {/* Compare Banner */}
        {compareMode && (
          <div className="glass-card" style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center', border: '1px solid rgba(96,165,250,0.2)', background: 'rgba(96,165,250,0.05)' }}>
            <span style={{ fontSize: 14 }}>Select 2 items to compare <strong style={{ color: 'var(--accent-blue)' }}>({compareItems.length}/2)</strong></span>
            <button className="btn btn-primary" disabled={compareItems.length !== 2} onClick={() => setShowCompare(true)}>
              Compare Now
            </button>
          </div>
        )}

        {filtered.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '80px 0', color: 'var(--text-muted)' }}>
            <span style={{ width: 56, height: 56, display: 'flex', margin: '0 auto 16px', opacity: 0.5 }}><Icons.ClipboardList /></span>
            <div style={{ fontSize: 16, fontWeight: 500 }}>No history logs found.</div>
            <div style={{ fontSize: 13, marginTop: 4 }}>Events from scans, alerts, and rover will appear here.</div>
          </div>
        ) : (
          filtered.map(item => {
            const typeInfo = TYPE_ICONS[item.type] || { icon: Icons.Info, color: 'var(--text-secondary)' }
            const sc = SEVERITY_COLORS[item.severity] || 'var(--text-secondary)'
            const IconComp = typeInfo.icon
            const isSelected = compareItems.find(c => c.id === item.id)

            return (
              <div key={item.id} className="history-item"
                style={{ border: isSelected ? '1px solid rgba(96,165,250,0.4)' : '1px solid var(--border-color)', background: isSelected ? 'rgba(96,165,250,0.06)' : 'var(--bg-card)' }}
                onClick={() => compareMode ? toggleCompare(item) : setSelected(item)}
              >
                {compareMode && (
                  <div style={{ width: 18, height: 18, borderRadius: 4, border: `2px solid ${isSelected ? 'var(--accent-blue)' : 'var(--border-color)'}`, background: isSelected ? 'var(--accent-blue)' : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    {isSelected && <span style={{ width: 10, height: 10, display: 'flex', color: '#fff' }}><Icons.Check /></span>}
                  </div>
                )}
                <div className="history-icon" style={{ background: `${typeInfo.color}15`, border: `1px solid ${typeInfo.color}25` }}>
                  <span style={{ width: 18, height: 18, display: 'flex', color: typeInfo.color }}><IconComp /></span>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 600, fontSize: 14, marginBottom: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 6, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.description}</div>
                  <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                    <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>{formatDate(item.timestamp)}</span>
                    <span className="badge" style={{ fontSize: 9, padding: '2px 6px', background: `${sc}15`, color: sc, border: `1px solid ${sc}25` }}>{item.severity}</span>
                  </div>
                </div>
                {!compareMode && (
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button className="btn-icon" style={{ padding: 6 }} onClick={e => { e.stopPropagation(); deleteHistoryItem(item.id) }} title="Delete">
                      <span style={{ width: 13, height: 13, display: 'flex', color: 'var(--accent-red)' }}><Icons.Trash /></span>
                    </button>
                    <span style={{ display: 'flex', alignItems: 'center', color: 'var(--text-muted)' }}><Icons.ChevronRight /></span>
                  </div>
                )}
              </div>
            )
          })
        )}
      </div>

      {selected && <DetailModal item={selected} onClose={() => setSelected(null)} />}
      {showCompare && <CompareModal items={compareItems} onClose={() => { setShowCompare(false); setCompareMode(false); setCompareItems([]) }} />}

      {showClearConfirm && (
        <div className="modal-overlay" onClick={() => setShowClearConfirm(false)}>
          <div className="modal" style={{ maxWidth: 400 }} onClick={e => e.stopPropagation()}>
            <div className="modal-title" style={{ marginBottom: 12 }}>🗑️ Clear All History?</div>
            <p style={{ fontSize: 14, color: 'var(--text-secondary)', marginBottom: 20 }}>This will permanently delete all {history.length} log entries. This action cannot be undone.</p>
            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
              <button className="btn btn-secondary" onClick={() => setShowClearConfirm(false)}>Cancel</button>
              <button className="btn btn-danger" onClick={() => { clearHistory(); setShowClearConfirm(false) }}>Delete All</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
