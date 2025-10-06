# 🚀 Quick Start - Real-Time Bus Tracking

## Start the Server (ONE COMMAND!)

```bash
cd server
uvicorn apo_basi.asgi:application --reload --host 0.0.0.0 --port 8000
```

⚠️ **Important:** Don't use `python manage.py runserver` - it doesn't support WebSockets!

## Create Test Data

```bash
# 1. Create superuser
python manage.py createsuperuser

# 2. Visit Django admin
http://localhost:8000/admin/

# 3. Create:
#    - User (driver) with user_type='driver'
#    - User (parent) with user_type='parent'
#    - Bus with number_plate='ABC123'
#    - Driver profile linked to driver user
#    - Assign bus to driver
#    - Child linked to parent
#    - Assign child to bus
```

## Test It Works

```bash
# Terminal 1: Start server
uvicorn apo_basi.asgi:application --reload

# Terminal 2: Run test
python test_realtime_tracking.py
```

You should see:
- ✅ Driver sending GPS updates
- ✅ Parent receiving real-time updates via WebSocket
- ✅ Location displayed on both sides

## View API Docs

Open browser: http://localhost:8000/docs

## Common Issues

**"Module not found: fastapi"**
```bash
pip install -r requirements.txt
```

**"Connection refused"**
```bash
# Make sure server is running with uvicorn, not manage.py runserver
uvicorn apo_basi.asgi:application --reload
```

**"403 Forbidden"**
- Check driver is assigned to bus in Django admin
- Verify parent has child assigned to bus

## Files Created

```
server/
├── buses/
│   ├── models.py                      # ✅ Added GPS fields
│   └── realtime.py                    # ✅ FastAPI app (NEW!)
├── apo_basi/
│   └── asgi.py                        # ✅ Mounts FastAPI + Django
├── requirements.txt                    # ✅ Added FastAPI deps
├── test_realtime_tracking.py          # ✅ Test script (NEW!)
├── REALTIME_TRACKING_SETUP.md         # ✅ Full guide (NEW!)
└── QUICK_START.md                     # ✅ This file (NEW!)
```

## What's Next?

1. **Mobile Integration** - See client examples in REALTIME_TRACKING_SETUP.md
2. **Production Deploy** - Use Redis for scaling, SSL for WebSocket
3. **Add Features** - ETA calculation, route history, geofencing

Happy tracking! 🚌📍
