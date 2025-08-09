// API Configuration
const API_CONFIG = {
  baseUrl: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080',
  endpoints: {
    status: import.meta.env.VITE_API_STATUS_ENDPOINT || '/api/status',
    health: import.meta.env.VITE_API_HEALTH_ENDPOINT || '/api/health'
  },
  environment: import.meta.env.VITE_APP_ENV || 'development'
}

// Helper function to build full API URLs
export const buildApiUrl = (endpoint) => {
  return `${API_CONFIG.baseUrl}${endpoint}`
}

// Predefined API URLs
export const API_URLS = {
  status: buildApiUrl(API_CONFIG.endpoints.status),
  health: buildApiUrl(API_CONFIG.endpoints.health)
}

// Export configuration for debugging
export const getApiConfig = () => {
  return {
    ...API_CONFIG,
    urls: API_URLS
  }
}

export default API_CONFIG
