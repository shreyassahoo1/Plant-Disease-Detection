import { useApp } from '../store'
import Icons from '../icons'

const LANGUAGES = [
  { code: 'en', label: 'English', native: 'English' },
  { code: 'hi', label: 'Hindi', native: 'हिन्दी' },
  { code: 'te', label: 'Telugu', native: 'తెలుగు' },
  { code: 'ta', label: 'Tamil', native: 'தமிழ்' },
  { code: 'kn', label: 'Kannada', native: 'ಕನ್ನಡ' },
]


export default function SettingsPage() {
  const {
    language, setLanguage, theme, toggleTheme, history, clearHistory,
    roverUrl, setRoverUrl,
    sensorUrl, setSensorUrl,
    camStreamUrl, setCamStreamUrl,
    camCaptureUrl, setCamCaptureUrl,
  } = useApp()
  const apiKey = localStorage.getItem('gemini_api_key') || ''

  const currentLang = LANGUAGES.find(l => l.code === language) || LANGUAGES[0]

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>⚙️ Settings</h2>
          <div className="subtitle">Customize AgroNet AI preferences</div>
        </div>
      </div>

      <div className="page-body" style={{ maxWidth: 700 }}>

        {/* Appearance */}
        <div className="glass-card" style={{ marginBottom: 20 }}>
          <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ width: 18, height: 18, display: 'flex', color: 'var(--accent-purple)' }}>{theme === 'dark' ? <Icons.Moon /> : <Icons.Sun />}</span>
            Appearance
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 0' }}>
            <div>
              <div style={{ fontWeight: 500 }}>Dark Theme</div>
              <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>Enable futuristic dark mode</div>
            </div>
            <label className="toggle-switch">
              <input type="checkbox" checked={theme === 'dark'} onChange={toggleTheme} />
              <div className="toggle-track">
                <div className="toggle-knob" />
              </div>
            </label>
          </div>
        </div>

        {/* Language */}
        <div className="glass-card" style={{ marginBottom: 20 }}>
          <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ width: 18, height: 18, display: 'flex', color: 'var(--accent-cyan)' }}><Icons.Globe /></span>
            Language
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {LANGUAGES.map(lang => (
              <div key={lang.code}
                onClick={() => setLanguage(lang.code)}
                style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  padding: '12px 14px', borderRadius: 10, cursor: 'pointer',
                  background: language === lang.code ? 'var(--accent-green-dim)' : 'transparent',
                  border: `1px solid ${language === lang.code ? 'rgba(74,222,128,0.25)' : 'transparent'}`,
                  transition: 'all 0.2s'
                }}
              >
                <div>
                  <div style={{ fontWeight: language === lang.code ? 600 : 400, color: language === lang.code ? 'var(--accent-green)' : 'var(--text-primary)' }}>{lang.native}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>{lang.label}</div>
                </div>
                {language === lang.code && (
                  <span style={{ width: 18, height: 18, display: 'flex', color: 'var(--accent-green)' }}><Icons.Check /></span>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* AI Config — read-only info, key is set in .env */}
        <div className="glass-card" style={{ marginBottom: 20 }}>
          <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 18 }}>✨</span>
            Gemini AI
          </div>
          <div style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.7, padding: '10px 14px', background: 'rgba(255,255,255,0.03)', borderRadius: 10 }}>
            <div style={{ marginBottom: 6 }}>Model: <strong style={{ color: 'var(--accent-green)' }}>gemini-2.5-flash</strong></div>
            <div>The API key is configured via the <code style={{ color: 'var(--accent-cyan)' }}>VITE_GEMINI_API_KEY</code> environment variable in{' '}<code style={{ color: 'var(--accent-cyan)' }}>web-dashboard/.env</code>.</div>
            <div style={{ marginTop: 6, color: 'var(--text-muted)', fontSize: 12 }}>Plant disease analysis starts automatically after any photo is uploaded — no extra steps needed.</div>
          </div>
        </div>

        {/* Connectivity */}
        <div className="glass-card" style={{ marginBottom: 20 }}>
          <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 4, display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ width: 18, height: 18, display: 'flex', color: 'var(--accent-green)' }}><Icons.Wifi /></span>
            ESP32 Connectivity
          </div>
          <div style={{ fontSize: 13, color: 'var(--text-muted)', marginBottom: 16 }}>Configure via environment variables or .env file</div>
          {[
            { label: 'Rover Control URL', key: 'VITE_ROVER_URL', value: roverUrl, onChange: setRoverUrl },
            { label: 'Sensor Data URL', key: 'VITE_ESP32_SENSOR_URL', value: sensorUrl, onChange: setSensorUrl },
            { label: 'Camera Stream URL', key: 'VITE_ESP32_CAM_URL', value: camStreamUrl, onChange: setCamStreamUrl },
            { label: 'Camera Capture URL', key: 'VITE_ESP32_CAM_CAPTURE_URL', value: camCaptureUrl, onChange: setCamCaptureUrl },
          ].map(item => (
            <div key={item.key} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid var(--border-color)', gap: 16 }}>
              <div style={{ minWidth: 160 }}>
                <div style={{ fontWeight: 500, fontSize: 14 }}>{item.label}</div>
                <div style={{ fontSize: 11, fontFamily: 'monospace', color: 'var(--text-muted)', marginTop: 2 }}>{item.key}</div>
              </div>
              <input
                className="input-field"
                style={{ fontFamily: 'monospace', fontSize: 13, color: 'var(--accent-cyan)', margin: 0, padding: '6px 10px', width: '60%', textAlign: 'left' }}
                value={item.value}
                onChange={e => item.onChange(e.target.value)}
              />
            </div>
          ))}
          <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 12, padding: '8px 12px', background: 'rgba(255,255,255,0.03)', borderRadius: 8 }}>
            Create a <code style={{ color: 'var(--accent-green)' }}>web-dashboard/.env</code> file to override these values
          </div>
        </div>

        {/* Data */}
        <div className="glass-card">
          <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ width: 18, height: 18, display: 'flex', color: 'var(--accent-red)' }}><Icons.Trash /></span>
            Data Management
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <div style={{ fontWeight: 500 }}>History Logs</div>
              <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 2 }}>{history.length} entries stored in localStorage</div>
            </div>
            <button className="btn btn-danger" onClick={() => { if (confirm('Clear all history? This cannot be undone.')) clearHistory() }}>
              Clear History
            </button>
          </div>
        </div>

        {/* About */}
        <div style={{ marginTop: 28, padding: '20px 0', borderTop: '1px solid var(--border-color)', textAlign: 'center' }}>
          <div style={{ fontSize: 22, marginBottom: 8 }}>🌿</div>
          <div style={{ fontWeight: 700, fontSize: 18, background: 'linear-gradient(135deg, var(--accent-green), var(--accent-cyan))', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
            AgroNet AI
          </div>
          <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>
            Web Dashboard v1.0.0 • Built with React + Vite
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 4 }}>
            Powered by Gemini 2.5 Flash • Open-Meteo Weather API • ESP32 Hardware
          </div>
        </div>
      </div>
    </div>
  )
}
