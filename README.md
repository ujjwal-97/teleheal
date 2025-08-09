# Virtual Consultation Platform — Mono-Repo

This repository contains the **frontend** (React) and **backend** (Spring Boot) modules for a Virtual Consultation Platform. The platform is designed to enable online doctor–patient consultations, prescription management, and secure medical history storage.

---

## 📂 Repository Structure

```
mono-repo-virtual-consultation/
├── teleheal-backend/     # Spring Boot backend service (Gradle project)
├── teleheal-ui/    # React frontend (Vite project)
├── .gitignore   # Global ignores (shared across modules)
└── README.md    # Project documentation
```

Both `teleheal-backend/` and `teleheal-ui/` also have their own `.gitignore` files for stack-specific ignores.

---

## 🚀 Getting Started

### Prerequisites

* **Java 24** & Gradle (for backend)
* **Node.js 16+** & npm/yarn (for frontend)

### Backend Setup

```bash
cd teleheal-backend
mvn spring-boot:run
```

The teleheal-backend will start at **[http://localhost:8080](http://localhost:8080)**.

### Frontend Setup

```bash
cd teleheal-ui
npm install
npm run dev
```

The teleheal-backend will start at **[http://localhost:9000](http://localhost:5173)** and proxy API calls to the backend.

---

## 🛠 Features

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


