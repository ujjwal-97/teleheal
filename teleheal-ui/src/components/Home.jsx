import { useState } from 'react'
import reactLogo from '../assets/react.svg'
import viteLogo from '/vite.svg'
import '../styles/Home.css'

function Home() {
  const [count, setCount] = useState(0)

  return (
    <div className="home">
      <div className="logos">
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      
      <h1>🏥 TeleHeal</h1>
      <p className="subtitle">Modern Healthcare Management Platform</p>
      
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Edit <code>src/components/Home.jsx</code> and save to test HMR
        </p>
      </div>
      
      <div className="features">
        <div className="feature-card">
          <h3>🩺 Patient Management</h3>
          <p>Comprehensive patient records and appointment scheduling</p>
        </div>
        <div className="feature-card">
          <h3>📊 Health Analytics</h3>
          <p>Real-time health monitoring and data visualization</p>
        </div>
        <div className="feature-card">
          <h3>💊 Prescription Management</h3>
          <p>Digital prescriptions and medication tracking</p>
        </div>
      </div>
      
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </div>
  )
}

export default Home
