# Virtual Consultation Platform — Mono-Repo

This repository contains the **frontend** (React) and **backend** (Spring Boot) modules for a Virtual Consultation Platform. The platform is designed to enable online doctor–patient consultations, prescription management, and secure medical history storage.

---

## 📂 Repository Structure

```
mono-repo-virtual-consultation/
├── backend/     # Spring Boot backend service (Maven project)
├── frontend/    # React frontend (Vite project)
├── .gitignore   # Global ignores (shared across modules)
└── README.md    # Project documentation
```

Both `backend/` and `frontend/` also have their own `.gitignore` files for stack-specific ignores.

---

## 🚀 Getting Started

### Prerequisites

* **Java 17+** & Maven (for backend)
* **Node.js 16+** & npm/yarn (for frontend)

### Backend Setup

```bash
cd backend
mvn spring-boot:run
```

The backend will start at **[http://localhost:8080](http://localhost:8080)**.

### Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

The frontend will start at **[http://localhost:5173](http://localhost:5173)** and proxy API calls to the backend.

---

## 🛠 Features (POC)

* Basic health check endpoint (`/api/health`)
* Simple frontend page calling backend
* CORS enabled for local development
* Modular `.gitignore` for frontend & backend

---

## 📦 Running with Docker Compose

```bash
docker-compose up --build
```

This will start both backend and frontend containers.

---

## 📄 License

This project is licensed under the MIT License — see the LICENSE file for details.

---

## 📝 Next Steps

* Add authentication & user management
* Implement consultation flows (chat/video)
* Add prescription creation & S3 storage
* Build patient/doctor dashboards
