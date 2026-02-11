# ApoBasi — Smart School Transport for East Africa

Real-time school bus tracking and attendance management for schools, parents, drivers, and bus minders. Built for Uganda and Kenya.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile Apps (Flutter)                   │
│   ParentsApp (iOS/Android)   DriversandMinders (iOS/Android)│
│   - Live bus tracking        - Background GPS broadcast     │
│   - Child attendance status  - Student attendance marking   │
│   - Supabase magic link auth - JWT auth                     │
└───────────────┬──────────────────────┬──────────────────────┘
                │ WebSocket            │ REST + WebSocket
                ▼                      ▼
┌─────────────────────────────────────────────────────────────┐
│          AWS Lightsail — Django Backend                     │
│   Django 5 + DRF  │  Django Channels (WebSocket/Daphne)    │
│   PostgreSQL       │  Redis (channels_redis)                │
│   JWT auth         │  Celery (background tasks)             │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ REST API
                          ▼
┌─────────────────────────────────────────────────────────────┐
│             Vercel — Web Admin Dashboard                    │
│   React 18 + TypeScript + Vite + TailwindCSS               │
│   Leaflet maps  │  JWT auth  │  PWA                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Django 5 + Django REST Framework |
| Real-time | Django Channels 4 (WebSocket via Daphne) |
| Channel layer | Redis + channels_redis |
| Database | PostgreSQL (prod), SQLite (dev) |
| Auth | JWT (admins/drivers/minders), Supabase magic link (parents) |
| Web dashboard | React 18, TypeScript, Vite, TailwindCSS |
| Mobile apps | Flutter / Dart |
| Maps (web) | Leaflet + React-Leaflet |
| Maps (mobile) | Flutter Map + Mapbox tiles |
| Containerization | Docker + Docker Compose |
| Backend hosting | AWS Lightsail |
| Web hosting | Vercel |

---

## Project Structure

```
Apo_Basi/
├── server/               # Django backend
│   ├── apo_basi/         # Project settings, ASGI config, URLs
│   ├── admins/           # Admin management
│   ├── parents/          # Parent users
│   ├── drivers/          # Driver users
│   ├── busminders/       # Bus minder users
│   ├── children/         # Student records
│   ├── buses/            # Bus management
│   ├── assignments/      # Bus/route assignments
│   ├── attendance/       # Attendance tracking
│   ├── trips/            # Trip management
│   ├── analytics/        # Reporting
│   └── notifications/    # Push notifications
│
├── client/               # React web admin dashboard
│   ├── src/
│   │   ├── pages/        # Route-level pages
│   │   ├── components/   # Reusable UI components
│   │   ├── contexts/     # Auth and app context
│   │   ├── services/     # API calls
│   │   └── types/        # TypeScript types
│   └── public/           # Static assets (logo, PWA icons)
│
├── ParentsApp/           # Flutter app for parents
│   └── lib/
│       ├── presentation/ # Screens and widgets
│       ├── services/     # API + WebSocket services
│       └── models/       # Data models
│
└── DriversandMinders/    # Flutter app for drivers and bus minders
    └── lib/
        ├── presentation/ # Screens and widgets
        ├── services/     # GPS broadcast + API services
        └── models/       # Data models
```

---

## Getting Started

### Backend (Django)

```bash
cd server
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # configure DB, Redis, JWT secret, Supabase
python manage.py migrate
python manage.py runserver
```

Requires Redis running locally for Django Channels:
```bash
docker run -d -p 6379:6379 redis:7-alpine
```

### Web Dashboard

```bash
cd client
npm install
cp .env.example .env   # set VITE_API_URL
npm run dev
```

### Mobile Apps

```bash
cd ParentsApp        # or DriversandMinders
cp .env.example .env
flutter pub get
flutter run
```

---

## Production Deployment

### Backend (AWS Lightsail)

The backend runs via Docker Compose with Daphne serving both HTTP and WebSocket traffic.

```bash
# On the Lightsail instance
git pull
docker compose build --no-cache django   # if settings changed
docker compose up -d
```

Key environment variables:
```
DATABASE_URL=postgres://...
REDIS_URL=redis://redis:6379/0
SECRET_KEY=...
ALLOWED_HOSTS=your-lightsail-ip,your-domain.com
SUPABASE_URL=...
SUPABASE_SERVICE_KEY=...
```

### Web Dashboard (Vercel)

Push to `main` — Vercel auto-deploys. Set environment variables in the Vercel project settings:
```
VITE_API_URL=https://your-backend-domain.com
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
```

---

## Real-Time Tracking

Drivers broadcast GPS coordinates via WebSocket. Django Channels fans out location updates to all connected parents tracking that bus. The channel layer uses Redis (`channels_redis`) so updates work across multiple Django worker processes.

WebSocket endpoint: `ws://<host>/ws/tracking/<trip_id>/`

---

## Authentication

- **Admins / Drivers / Bus Minders**: JWT tokens issued by Django (`/api/token/`)
- **Parents**: Supabase magic link (email OTP) — the Flutter app exchanges the Supabase session token with the Django backend for a scoped JWT

---

## License

MIT
