import { useState, useEffect } from 'react'
import { API_URLS, getApiConfig } from '../config/api'
import '../styles/ApiStatus.css'

function ApiStatus() {
  const [status, setStatus] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [lastUpdated, setLastUpdated] = useState(null)

  const fetchStatus = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await fetch(API_URLS.status)
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      setStatus(data)
      setLastUpdated(new Date().toLocaleTimeString())
    } catch (err) {
      setError(err.message)
      console.error('Failed to fetch status:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchStatus()
    // Auto-refresh every 30 seconds
    const interval = setInterval(fetchStatus, 30000)
    return () => clearInterval(interval)
  }, [])

  const formatMemory = (mb) => {
    if (mb > 1024) {
      return `${(mb / 1024).toFixed(1)} GB`
    }
    return `${mb} MB`
  }

  return (
    <div className="api-status">
      <header className="api-status-header">
        <h1>📊 API Status Monitor</h1>
        <p>Real-time Backend System Status</p>
        <div className="api-config-info">
          <small>API: {getApiConfig().baseUrl} | Environment: {getApiConfig().environment}</small>
        </div>
      </header>

      <main className="status-dashboard">
        {loading && !status && (
          <div className="loading">
            <div className="spinner"></div>
            <p>Loading backend status...</p>
          </div>
        )}

        {error && (
          <div className="error-card">
            <h3>❌ Connection Error</h3>
            <p>{error}</p>
            <button onClick={fetchStatus} className="retry-btn">
              🔄 Retry Connection
            </button>
          </div>
        )}

        {status && (
          <>
            <div className="status-header">
              <div className="status-indicator">
                <span className={`status-dot ${status.status.toLowerCase()}`}></span>
                <h2>{status.service}</h2>
                <span className="status-text">{status.status}</span>
              </div>
              <div className="last-updated">
                Last updated: {lastUpdated}
                <button onClick={fetchStatus} className="refresh-btn" disabled={loading}>
                  {loading ? '⏳' : '🔄'}
                </button>
              </div>
            </div>

            <div className="stats-grid">
              <div className="stat-card">
                <h3>🚀 Service Info</h3>
                <div className="stat-item">
                  <span className="label">Version:</span>
                  <span className="value">{status.version}</span>
                </div>
                <div className="stat-item">
                  <span className="label">Port:</span>
                  <span className="value">{status.port}</span>
                </div>
                <div className="stat-item">
                  <span className="label">Environment:</span>
                  <span className="value">{status.environment}</span>
                </div>
                <div className="stat-item">
                  <span className="label">Timestamp:</span>
                  <span className="value">{new Date(status.timestamp).toLocaleString()}</span>
                </div>
              </div>

              <div className="stat-card">
                <h3>💾 Memory Usage</h3>
                <div className="memory-bar">
                  <div 
                    className="memory-used" 
                    style={{width: `${(status.memory.used_mb / status.memory.max_mb) * 100}%`}}
                  ></div>
                </div>
                <div className="stat-item">
                  <span className="label">Used:</span>
                  <span className="value">{formatMemory(status.memory.used_mb)}</span>
                </div>
                <div className="stat-item">
                  <span className="label">Free:</span>
                  <span className="value">{formatMemory(status.memory.free_mb)}</span>
                </div>
                <div className="stat-item">
                  <span className="label">Total:</span>
                  <span className="value">{formatMemory(status.memory.total_mb)}</span>
                </div>
                <div className="stat-item">
                  <span className="label">Max:</span>
                  <span className="value">{formatMemory(status.memory.max_mb)}</span>
                </div>
              </div>

              <div className="stat-card">
                <h3>🖥️ System Info</h3>
                <div className="stat-item">
                  <span className="label">Java Version:</span>
                  <span className="value">{status.system.java_version}</span>
                </div>
                <div className="stat-item">
                  <span className="label">Java Vendor:</span>
                  <span className="value">{status.system.java_vendor}</span>
                </div>
                <div className="stat-item">
                  <span className="label">OS:</span>
                  <span className="value">{status.system.os_name}</span>
                </div>
                <div className="stat-item">
                  <span className="label">OS Version:</span>
                  <span className="value">{status.system.os_version}</span>
                </div>
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  )
}

export default ApiStatus
