import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Navigation from './components/Navigation'
import Home from './components/Home'
import ApiStatus from './components/ApiStatus'
import './App.css'

function App() {
  return (
    <Router>
      <div className="app">
        <Navigation />
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/api-status" element={<ApiStatus />} />
        </Routes>
      </div>
    </Router>
  )
}

export default App
