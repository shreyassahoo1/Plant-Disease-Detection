import { useState, useRef, useCallback, useEffect } from 'react'
import { useApp } from '../store'
import Icons from '../icons'

const GEMINI_MODEL = 'gemini-2.5-flash'
const MAX_DIMENSION = 800   // px — keeps detail while slashing payload size
const JPEG_QUALITY  = 0.72  // 0–1; 0.72 ≈ visually lossless for AI analysis

// API key comes from .env (VITE_GEMINI_API_KEY) — never exposed to the user
function getApiKey() {
  return import.meta.env.VITE_GEMINI_API_KEY || ''
}

/**
 * Resize + JPEG-compress an image File/Blob via an offscreen canvas.
 * Returns { base64, mimeType, originalKB, compressedKB }
 */
function compressImage(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file)
    const img = new Image()
    img.onload = () => {
      URL.revokeObjectURL(url)
      let { width, height } = img
      if (width > MAX_DIMENSION || height > MAX_DIMENSION) {
        if (width > height) { height = Math.round((height / width) * MAX_DIMENSION); width = MAX_DIMENSION }
        else { width = Math.round((width / height) * MAX_DIMENSION); height = MAX_DIMENSION }
      }
      const canvas = document.createElement('canvas')
      canvas.width = width
      canvas.height = height
      canvas.getContext('2d').drawImage(img, 0, 0, width, height)
      const dataUrl = canvas.toDataURL('image/jpeg', JPEG_QUALITY)
      const base64 = dataUrl.split(',')[1]
      resolve({
        base64,
        mimeType: 'image/jpeg',
        originalKB: Math.round(file.size / 1024),
        compressedKB: Math.round((base64.length * 3) / 4 / 1024),
      })
    }
    img.onerror = reject
    img.src = url
  })
}

// Model fallback chain — try fastest first, fall back on 503/429
const MODEL_CHAIN = [
  'gemini-2.5-flash',
  'gemini-1.5-flash',
  'gemini-1.5-flash-8b',
]

const PROMPT =
  'Analyze this plant image. Identify the plant and detect any diseases. ' +
  'Return the result purely as a JSON object with this exact schema: ' +
  '{ "diseaseName": "Name of disease or Healthy", "confidence": 95.5, "severity": "LOW", ' +
  '"precautions": ["Step 1", "Step 2"], "indianFertilizers": ["Fertilizer 1", "Fertilizer 2"] }. ' +
  'Severity must be exactly one of: LOW, MEDIUM, or HIGH. ' +
  'If healthy, provide care tips in precautions and general fertilizers. ' +
  'Do not include markdown formatting, just the raw JSON string.'

async function callModel(model, imageBase64, mimeType, apiKey) {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [
          { text: PROMPT },
          { inline_data: { mime_type: mimeType, data: imageBase64 } },
        ]}],
      }),
    }
  )
  if (!res.ok) {
    const errBody = await res.json().catch(() => ({}))
    const status = res.status
    const msg = errBody?.error?.message || `HTTP ${status}`
    const retryable = status === 503 || status === 429 || status === 500
    throw Object.assign(new Error(msg), { status, retryable })
  }
  const data = await res.json()
  let text = data.candidates?.[0]?.content?.parts?.[0]?.text || ''
  text = text.replace(/```json/g, '').replace(/```/g, '').trim()
  return JSON.parse(text)
}

/**
 * Retries across models with exponential backoff.
 * onStatus(msg) — called with human-readable status for the loading UI.
 */
async function analyzeWithGemini(imageBase64, mimeType = 'image/jpeg', onStatus) {
  const apiKey = getApiKey()
  if (!apiKey) throw new Error('VITE_GEMINI_API_KEY is not set in your .env file')

  const delays = [1000, 2500, 5000]
  let lastErr

  for (const model of MODEL_CHAIN) {
    for (let attempt = 0; attempt < delays.length; attempt++) {
      try {
        const label = model === 'gemini-2.5-flash' ? 'Gemini 2.5 Flash'
          : model === 'gemini-1.5-flash' ? 'Gemini 1.5 Flash' : 'Gemini Flash Lite'
        onStatus?.(`Analysing with ${label}${attempt > 0 ? ` (retry ${attempt})` : ''}…`)
        const result = await callModel(model, imageBase64, mimeType, apiKey)
        onStatus?.(null)
        return result
      } catch (err) {
        lastErr = err
        if (!err.retryable) throw err           // hard error — don't retry
        if (attempt < delays.length - 1) {
          onStatus?.(`High demand — retrying in ${delays[attempt] / 1000}s…`)
          await new Promise(r => setTimeout(r, delays[attempt]))
        }
      }
    }
    // All retries for this model exhausted, try next model
  }
  throw lastErr
}

export default function ScanPage() {
  const { addHistory, addAlert } = useApp()
  const [image, setImage] = useState(null)      // { url, base64, mimeType }
  const [dragging, setDragging] = useState(false)
  const [status, setStatus] = useState('idle')  // idle | loading | result | error
  const [retryStatus, setRetryStatus] = useState('')  // human-readable retry message
  const [result, setResult] = useState(null)
  const [error, setError] = useState('')
  const fileRef = useRef()

  // NOTE: analysis is now triggered directly from handleFile to avoid double-fire

  const runAnalysis = useCallback(async (img) => {
    setStatus('loading')
    setRetryStatus('')
    setError('')
    setResult(null)

    try {
      const data = await analyzeWithGemini(
        img.base64,
        img.mimeType,
        (msg) => setRetryStatus(msg || '')
      )
      setResult(data)
      setStatus('result')
      setRetryStatus('')

      addHistory({
        id: Date.now().toString(),
        type: 'SCAN',
        timestamp: new Date().toISOString(),
        title: data.diseaseName,
        description: `AI Analysis confidence: ${Number(data.confidence).toFixed(1)}%`,
        severity: data.severity || 'LOW',
        metadata: data,
      })

      if (data.severity === 'HIGH') {
        addAlert({
          id: 'scan_' + Date.now(),
          title: `Disease Detected: ${data.diseaseName}`,
          message: 'High severity disease detected. Immediate action required.',
          type: 'ERROR',
        })
      }
    } catch (e) {
      setStatus('error')
      setRetryStatus('')
      setError(e.message)
    }
  }, [addHistory, addAlert])

  const handleFile = useCallback(async (file) => {
    if (!file || !file.type.startsWith('image/')) return
    setStatus('loading')
    setRetryStatus('Compressing image…')
    setResult(null)
    setError('')
    try {
      const compressed = await compressImage(file)
      // Keep the original URL for display, use compressed base64 for API
      const displayUrl = URL.createObjectURL(file)
      const img = { url: displayUrl, base64: compressed.base64, mimeType: 'image/jpeg' }
      setImage(img)
      // runAnalysis will be triggered by useEffect watching `image`,
      // but we already have it here — call directly to avoid double fire
      setRetryStatus('')
      await runAnalysis(img)
    } catch (e) {
      setStatus('error')
      setRetryStatus('')
      setError(e.message || 'Failed to process image')
    }
  }, [runAnalysis])

  const handleDrop = (e) => {
    e.preventDefault()
    setDragging(false)
    handleFile(e.dataTransfer.files[0])
  }

  const handlePaste = useCallback((e) => {
    const item = Array.from(e.clipboardData.items).find(i => i.type.startsWith('image/'))
    if (item) handleFile(item.getAsFile())
  }, [handleFile])

  const reset = () => {
    setImage(null)
    setResult(null)
    setStatus('idle')
    setRetryStatus('')
    setError('')
  }

  const isHealthy = result?.diseaseName?.toLowerCase().includes('healthy')

  return (
    <div onPaste={handlePaste}>
      <div className="page-header">
        <div>
          <h2>🌿 Smart Scan</h2>
          <div className="subtitle">AI-powered plant disease detection — just upload a photo</div>
        </div>
      </div>

      <div className="page-body">

        {/* ── Drop Zone (idle, no image yet) ── */}
        {!image && status === 'idle' && (
          <div
            className={`scan-drop-zone ${dragging ? 'dragging' : ''}`}
            onDragOver={e => { e.preventDefault(); setDragging(true) }}
            onDragLeave={() => setDragging(false)}
            onDrop={handleDrop}
            onClick={() => fileRef.current.click()}
          >
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <span style={{ width: 56, height: 56, color: 'var(--text-muted)', display: 'flex', marginBottom: 16 }}>
                <Icons.Upload />
              </span>
              <div style={{ fontWeight: 700, fontSize: 20, marginBottom: 8 }}>
                Drop a plant photo here
              </div>
              <div style={{ fontSize: 14, color: 'var(--text-secondary)', marginBottom: 20 }}>
                or click to browse · paste from clipboard (Ctrl+V) · JPEG / PNG / WEBP
              </div>
              <button
                className="btn btn-primary"
                style={{ fontSize: 15, padding: '10px 28px' }}
                onClick={e => { e.stopPropagation(); fileRef.current.click() }}
              >
                <span style={{ width: 18, height: 18, display: 'flex' }}><Icons.Camera /></span>
                Choose Image
              </button>
              <div style={{ marginTop: 20, fontSize: 12, color: 'var(--text-muted)' }}>
                Analysis starts automatically after upload ✨
              </div>
            </div>
            <input
              ref={fileRef}
              type="file"
              accept="image/*"
              style={{ display: 'none' }}
              onChange={e => handleFile(e.target.files[0])}
            />
          </div>
        )}

        {/* ── Loading (image visible + spinner) ── */}
        {status === 'loading' && image && (
          <div className="grid-2" style={{ gap: 24 }}>
            <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
              <img
                src={image.url}
                alt="Plant"
                style={{ width: '100%', maxHeight: 420, objectFit: 'contain', display: 'block', background: '#000' }}
              />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 20 }}>
              <div className="spinner" style={{ width: 56, height: 56, borderWidth: 5, borderTopColor: 'var(--accent-green)' }} />
              <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--accent-green)', textAlign: 'center' }}>
                {retryStatus.includes('retry') || retryStatus.includes('demand')
                  ? '🔄 Retrying…'
                  : 'AI is analysing the scan…'}
              </div>
              <div style={{ fontSize: 14, color: retryStatus.includes('demand') ? 'var(--accent-orange)' : 'var(--text-secondary)', textAlign: 'center', lineHeight: 1.6, minHeight: 40 }}>
                {retryStatus || 'Identifying plant species, diseases,\nprecautions & fertilizer recommendations.'}
              </div>
            </div>
          </div>
        )}

        {/* ── Error ── */}
        {status === 'error' && (
          <div style={{ maxWidth: 600 }}>
            {image && (
              <div className="glass-card" style={{ padding: 0, overflow: 'hidden', marginBottom: 20 }}>
                <img src={image.url} alt="Plant" style={{ width: '100%', maxHeight: 280, objectFit: 'contain', display: 'block', background: '#000' }} />
              </div>
            )}
            <div className="glass-card" style={{ border: '1px solid rgba(248,113,113,0.3)', background: 'rgba(248,113,113,0.06)' }}>
              <div style={{ fontWeight: 700, color: 'var(--accent-red)', marginBottom: 8, fontSize: 16 }}>
                ❌ Analysis Failed
              </div>
              <div style={{ fontSize: 14, color: 'var(--text-secondary)', marginBottom: 16, lineHeight: 1.6 }}>
                {error}
              </div>
              {error.includes('VITE_GEMINI_API_KEY') && (
                <div style={{ fontSize: 13, padding: '10px 14px', background: 'rgba(255,255,255,0.04)', borderRadius: 8, color: 'var(--text-muted)', marginBottom: 16 }}>
                  Add <code style={{ color: 'var(--accent-green)' }}>VITE_GEMINI_API_KEY=your_key</code> to{' '}
                  <code style={{ color: 'var(--accent-cyan)' }}>web-dashboard/.env</code> and restart the server.
                  <br />
                  Get a free key at{' '}
                  <a href="https://aistudio.google.com/app/apikey" target="_blank" rel="noreferrer" style={{ color: 'var(--accent-cyan)' }}>
                    Google AI Studio
                  </a>.
                </div>
              )}
              <div style={{ display: 'flex', gap: 10 }}>
                <button className="btn btn-secondary" onClick={reset}>
                  <span style={{ width: 14, height: 14, display: 'flex' }}><Icons.X /></span>
                  Choose New Image
                </button>
                <button className="btn btn-primary" onClick={() => runAnalysis(image)}>
                  <span style={{ width: 14, height: 14, display: 'flex' }}><Icons.Sparkles /></span>
                  Retry Analysis
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ── Result ── */}
        {status === 'result' && result && (
          <div className="grid-2" style={{ gap: 24 }}>
            {image && (
              <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
                <img
                  src={image.url}
                  alt="Plant"
                  style={{ width: '100%', maxHeight: 480, objectFit: 'contain', display: 'block', background: '#000' }}
                />
                <div style={{ padding: '10px 16px', background: 'rgba(0,0,0,0.4)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 13 }}>
                  <span style={{ color: 'var(--text-secondary)' }}>Analysed by Gemini 2.5 Flash</span>
                  <button className="btn btn-secondary" style={{ fontSize: 12, padding: '5px 12px' }} onClick={reset}>
                    Scan Another
                  </button>
                </div>
              </div>
            )}

            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              {/* Result Header */}
              <div className={`result-card ${isHealthy ? 'healthy' : 'disease'}`}>
                <div style={{ fontSize: 44, textAlign: 'center', marginBottom: 12 }}>
                  {isHealthy ? '🌿' : '🥀'}
                </div>
                <div style={{ fontSize: 22, fontWeight: 800, textAlign: 'center', marginBottom: 6,
                  color: isHealthy ? 'var(--accent-green)' : 'var(--accent-red)' }}>
                  {result.diseaseName}
                </div>
                <div style={{ textAlign: 'center', color: 'var(--text-secondary)', marginBottom: 14, fontSize: 14 }}>
                  Confidence: <strong style={{ color: 'var(--text-primary)', fontSize: 18 }}>{result.confidence}%</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'center', gap: 8 }}>
                  <span className={`badge ${result.severity === 'HIGH' ? 'badge-red' : result.severity === 'MEDIUM' ? 'badge-orange' : 'badge-green'}`}
                    style={{ fontSize: 13, padding: '4px 12px' }}>
                    {result.severity} Severity
                  </span>
                  {isHealthy && <span className="badge badge-green" style={{ fontSize: 13, padding: '4px 12px' }}>✅ Healthy</span>}
                </div>
              </div>

              {/* Precautions */}
              {result.precautions?.length > 0 && (
                <div className="glass-card">
                  <div style={{ fontWeight: 700, marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8, fontSize: 15 }}>
                    <span style={{ width: 18, height: 18, display: 'flex', color: isHealthy ? 'var(--accent-green)' : 'var(--accent-orange)' }}>
                      <Icons.Shield />
                    </span>
                    {isHealthy ? 'Care Tips' : 'Precautions & Treatment'}
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    {result.precautions.map((p, i) => (
                      <div key={i} style={{ display: 'flex', gap: 10, fontSize: 14, alignItems: 'flex-start',
                        padding: '8px 12px', background: isHealthy ? 'rgba(74,222,128,0.06)' : 'rgba(251,146,60,0.06)',
                        borderRadius: 8, border: `1px solid ${isHealthy ? 'rgba(74,222,128,0.15)' : 'rgba(251,146,60,0.15)'}` }}>
                        <span style={{ width: 16, height: 16, display: 'flex', flexShrink: 0, marginTop: 1,
                          color: isHealthy ? 'var(--accent-green)' : 'var(--accent-orange)' }}>
                          {isHealthy ? <Icons.CheckCircle /> : <Icons.Shield />}
                        </span>
                        {p}
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Fertilizers */}
              {result.indianFertilizers?.length > 0 && (
                <div className="glass-card">
                  <div style={{ fontWeight: 700, marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8, fontSize: 15 }}>
                    <span style={{ width: 18, height: 18, display: 'flex', color: 'var(--accent-green)' }}><Icons.Leaf /></span>
                    Recommended Indian Fertilizers
                  </div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                    {result.indianFertilizers.map((f, i) => (
                      <div key={i} style={{ padding: '7px 14px', background: 'var(--accent-green-dim)',
                        borderRadius: 20, fontSize: 13, color: 'var(--accent-green)',
                        border: '1px solid rgba(74,222,128,0.2)', fontWeight: 500 }}>
                        🌱 {f}
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <button
                className="btn btn-primary"
                style={{ width: '100%', justifyContent: 'center', padding: '14px 0', fontSize: 15 }}
                onClick={reset}
              >
                <span style={{ width: 18, height: 18, display: 'flex' }}><Icons.Scan /></span>
                Scan Another Crop
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
