import { Link, useLocation } from 'react-router-dom'
import '../styles/Navigation.css'

function Navigation() {
  const location = useLocation()

  return (
    <nav className="navigation">
      <div className="nav-container">
        <div className="nav-brand">
          <Link to="/">🏥 TeleHeal</Link>
        </div>
        
        <div className="nav-links">
          <Link 
            to="/" 
            className={location.pathname === '/' ? 'nav-link active' : 'nav-link'}
          >
            🏠 Home
          </Link>
          <Link 
            to="/api-status" 
            className={location.pathname === '/api-status' ? 'nav-link active' : 'nav-link'}
          >
            📊 API Status
          </Link>
        </div>
      </div>
    </nav>
  )
}

export default Navigation
