import { useState, useEffect, useRef, createContext, useContext, useCallback } from 'react'

// ─── App Store (simple context-based state) ─────────────────────────────────

const AppContext = createContext(null)

export const useApp = () => useContext(AppContext)

export function AppProvider({ children }) {
  const [page, setPage] = useState('dashboard')
  const [theme, setTheme] = useState('dark')
  const [language, setLanguage] = useState('en')
  const [alerts, setAlerts] = useState([])
  const [history, setHistory] = useState(() => {
    try { return JSON.parse(localStorage.getItem('agronet_history') || '[]') } catch { return [] }
  })
  const [sensorData, setSensorData] = useState({
    temperature: 28.4, humidity: 62.3, moisture: 41.5, ph: 6.8, timestamp: new Date()
  })
  const [roverState, setRoverState] = useState({
    isConnected: false, battery: 98, motorStatus: 'IDLE',
    cameraActive: false, isAutoMode: false, speed: 60,
    latitude: 12.9233643, longitude: 77.5008269, heading: 45, path: []
  })
  const [weatherData, setWeatherData] = useState(null)
  const [weatherLoading, setWeatherLoading] = useState(true)

  // Simulate sensor updates
  useEffect(() => {
    const interval = setInterval(() => {
      setSensorData(prev => ({
        temperature: +(prev.temperature + (Math.random() - 0.5) * 0.8).toFixed(1),
        humidity: +Math.max(20, Math.min(95, prev.humidity + (Math.random() - 0.5) * 1.5)).toFixed(1),
        moisture: +Math.max(10, Math.min(95, prev.moisture + (Math.random() - 0.5) * 1)).toFixed(1),
        ph: +Math.max(5.5, Math.min(8.0, prev.ph + (Math.random() - 0.5) * 0.05)).toFixed(2),
        timestamp: new Date()
      }))
    }, 3000)
    return () => clearInterval(interval)
  }, [])

  // Connect rover after delay
  useEffect(() => {
    const t = setTimeout(() => {
      setRoverState(p => ({ ...p, isConnected: true }))
    }, 2000)
    return () => clearTimeout(t)
  }, [])

  // Rover battery drain
  useEffect(() => {
    const interval = setInterval(() => {
      setRoverState(p => p.isConnected ? { ...p, battery: Math.max(0, +(p.battery - 0.1).toFixed(1)) } : p)
    }, 10000)
    return () => clearInterval(interval)
  }, [])

  // Fetch weather
  useEffect(() => {
    const fetchWeather = async () => {
      try {
        const res = await fetch(
          `https://api.open-meteo.com/v1/forecast?latitude=12.9233643&longitude=77.5008269&current=temperature_2m,relative_humidity_2m,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto&forecast_days=1`
        )
        if (res.ok) {
          const d = await res.json()
          const cur = d.current || {}
          const daily = d.daily || {}
          setWeatherData({
            temperature: cur.temperature_2m ?? 27.5,
            humidity: cur.relative_humidity_2m ?? 58,
            weatherCode: cur.weather_code ?? 2,
            rainProbability: (daily.precipitation_probability_max || [15])[0],
            tempMax: (daily.temperature_2m_max || [31])[0],
            tempMin: (daily.temperature_2m_min || [22])[0],
          })
        }
      } catch {
        setWeatherData({ temperature: 27.5, humidity: 58, weatherCode: 2, rainProbability: 15, tempMax: 31, tempMin: 22 })
      } finally {
        setWeatherLoading(false)
      }
    }
    fetchWeather()
  }, [])

  // Auto-generate alerts from sensors
  useEffect(() => {
    if (sensorData.temperature > 35) {
      addAlert({ id: 'temp_' + Date.now(), title: 'High Temperature Detected', message: `Temperature is ${sensorData.temperature}°C. Crop heat stress risk.`, type: 'WARNING' })
    }
    if (sensorData.moisture < 25) {
      addAlert({ id: 'moist_' + Date.now(), title: 'Low Soil Moisture', message: `Moisture critical at ${sensorData.moisture}%. Irrigation recommended.`, type: 'ERROR' })
    }
  }, [sensorData])

  const addAlert = useCallback((alert) => {
    setAlerts(prev => {
      const recent = prev.find(a => a.title === alert.title && (Date.now() - new Date(a.timestamp || 0)) < 5 * 60 * 1000)
      if (recent) return prev
      return [{ ...alert, isRead: false, timestamp: new Date() }, ...prev].slice(0, 50)
    })
  }, [])

  const addHistory = useCallback((item) => {
    setHistory(prev => {
      const next = [item, ...prev].slice(0, 200)
      try { localStorage.setItem('agronet_history', JSON.stringify(next)) } catch { }
      return next
    })
  }, [])

  const clearHistory = useCallback(() => {
    setHistory([])
    try { localStorage.removeItem('agronet_history') } catch { }
  }, [])

  const deleteHistoryItem = useCallback((id) => {
    setHistory(prev => {
      const next = prev.filter(h => h.id !== id)
      try { localStorage.setItem('agronet_history', JSON.stringify(next)) } catch { }
      return next
    })
  }, [])

  const moveRover = useCallback(async (direction) => {
    if (!roverState.isConnected) return
    const step = 0.00004
    setRoverState(prev => {
      const rad = prev.heading * (Math.PI / 180)
      let nextLat = prev.latitude, nextLon = prev.longitude, nextHeading = prev.heading
      if (direction === 'FORWARD') { nextLat += step * Math.cos(rad); nextLon += step * Math.sin(rad) }
      else if (direction === 'BACKWARD') { nextLat -= step * Math.cos(rad); nextLon -= step * Math.sin(rad) }
      else if (direction === 'LEFT') nextHeading = ((nextHeading - 15) + 360) % 360
      else if (direction === 'RIGHT') nextHeading = (nextHeading + 15) % 360
      const nextPath = [...prev.path, [nextLat, nextLon]].slice(-50)
      return { ...prev, motorStatus: `MOVING_${direction}`, latitude: nextLat, longitude: nextLon, heading: nextHeading, path: nextPath }
    })
    try {
      const roverUrl = import.meta.env.VITE_ROVER_URL || 'http://172.23.128.15'
      await fetch(`${roverUrl}/${direction.toLowerCase()}`, { signal: AbortSignal.timeout(2000) })
    } catch { }
  }, [roverState.isConnected])

  const stopRover = useCallback(async () => {
    if (!roverState.isConnected) return
    setRoverState(p => ({ ...p, motorStatus: 'IDLE' }))
    try {
      const roverUrl = import.meta.env.VITE_ROVER_URL || 'http://172.23.128.15'
      await fetch(`${roverUrl}/stop`, { signal: AbortSignal.timeout(2000) })
    } catch { }
  }, [roverState.isConnected])

  const ctx = {
    page, setPage,
    theme, toggleTheme: () => setTheme(t => t === 'dark' ? 'light' : 'dark'),
    language, setLanguage,
    alerts, addAlert, markAlertRead: (id) => setAlerts(p => p.map(a => a.id === id ? { ...a, isRead: true } : a)),
    clearAlerts: () => setAlerts([]),
    history, addHistory, clearHistory, deleteHistoryItem,
    sensorData,
    roverState, setRoverState, moveRover, stopRover,
    weatherData, weatherLoading,
  }

  return <AppContext.Provider value={ctx}>{children}</AppContext.Provider>
}
