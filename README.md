# ApoBasi: School Bus Tracking Platform for Africa

## Overview
ApoBasi is a modular, scalable school bus tracking and attendance platform designed for African schools, parents, and day scholars—starting in Uganda and Kenya. The system is built to work reliably in low-network environments and to empower schools and families with real-time, transparent, and safe student transport management.

## Why ApoBasi Matters
- **Safety & Peace of Mind:** Parents and schools can track buses and students in real time, reducing anxiety and improving accountability.
- **Designed for Africa:** Built for the realities of African connectivity, with offline-first features and robust sync for low-network areas.
- **Inclusive:** Supports all parents, day scholars, and school staff, regardless of device or location.
- **Modular Architecture:** Each module (parent app, minder/driver app, admin dashboard, backend) is loosely coupled, so updates or issues in one do not disrupt others.
- **Scalable Launch:** Simultaneous rollout in Uganda and Kenya, with a vision to expand across Africa.

## Technology Stack

### Backend
- **Django Rest Framework (DRF):**
  - Secure, modular REST API for all data and authentication.
  - Handles business logic, user management, trip/attendance records, and device sync.
- **PostgreSQL:**
  - Reliable, scalable relational database.
  - Optimized for transactional safety and offline sync patterns.

### Frontend
- **React Native + Expo:**
  - Cross-platform mobile app for parents, drivers, and minders.
  - Works on Android and iOS, with offline-first data and background sync.
- **React + Vite (Web Admin Dashboard):**
  - Fast, modern web dashboard for school admins.
  - Real-time monitoring, reporting, and management tools.

## Key Features
- **Role-based Apps:**
  - Parent, Driver, Minder, and Admin flows are separated for clarity and security.
- **Offline-First:**
  - Attendance and trip data can be captured offline and synced when network is available.
- **Live Location Tracking:**
  - Real-time bus and student location for parents and schools.
- **Attendance Management:**
  - Minder can mark attendance offline; data syncs automatically.
- **Admin Dashboard:**
  - Web-based, fast, and easy to use for school staff.
- **Modular Design:**
  - Each module can be updated or scaled independently, minimizing risk and downtime.

## Project Structure
- `server/` — Django DRF backend
- `client/apo_basi-client/` — React Native mobile app
- `client/web-admin/` — React + Vite web admin dashboard

## Testing Environment

Testing is a core part of ApoBasi's development to ensure reliability across all modules:

- **Backend (DRF):**
  - Uses Django's built-in test framework (`pytest` and `unittest` compatible).
  - Run tests with:
    ```bash
    python manage.py test
    ```
  - Coverage reports and CI integration recommended.

- **Mobile App (React Native):**
  - Uses Jest for unit and integration tests.
  - React Native Testing Library for UI/component tests.
  - Run tests with:
    ```bash
    cd client/apo_basi-client
    npm test
    ```

- **Web Admin (React + Vite):**
  - Uses Vitest or Jest for unit tests.
  - React Testing Library for UI/component tests.
  - Run tests with:
    ```bash
    cd client/web-admin
    npm test
    ```

All modules are designed for independent testing, so issues in one do not block others. Continuous Integration (CI) is recommended for automated testing and quality assurance.

## Getting Started
1. **Clone the repo:**
   ```bash
   git clone <repo-url>
   ```
2. **Backend:**
   - See `server/README.md` for setup (Python, DRF, PostgreSQL)
3. **Mobile App:**
   - See `client/apo_basi-client/README.md` for Expo/React Native setup
4. **Web Admin:**
   - See `client/web-admin/README.md` for Vite/React setup

## Contributing
We welcome contributions from African developers and educators! See `CONTRIBUTING.md` for guidelines.

## License
MIT License

---
ApoBasi: Empowering safe, transparent, and modern school transport for Africa.

---
Built with ❤️ for Africa
