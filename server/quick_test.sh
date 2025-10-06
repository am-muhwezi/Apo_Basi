#!/bin/bash

# Quick Test Script for Real-Time Tracking
# Usage: ./quick_test.sh <latitude> <longitude>

if [ $# -eq 0 ]; then
    echo ""
    echo "📍 Quick Real-Time Tracking Test"
    echo ""
    echo "Usage: ./quick_test.sh <latitude> <longitude>"
    echo ""
    echo "Example:"
    echo "  ./quick_test.sh 6.5244 3.3792    # Lagos, Nigeria"
    echo "  ./quick_test.sh 37.7749 -122.4194  # San Francisco"
    echo ""
    echo "Get your coordinates from:"
    echo "  https://www.google.com/maps (right-click → coordinates)"
    echo ""
    exit 1
fi

LAT=$1
LON=$2

echo ""
echo "=========================================="
echo "  Testing Real-Time Bus Tracking"
echo "=========================================="
echo ""
echo "📍 Location: $LAT, $LON"
echo "🚌 Bus: ABC123 (ID: 1)"
echo ""

# Login as driver
echo "🔐 Logging in as driver..."
TOKEN=$(curl -s -X POST http://localhost:8000/api/users/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "testdriver", "password": "testpass123"}' | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['access'])")

if [ -z "$TOKEN" ]; then
    echo "❌ Login failed! Is the server running?"
    echo "   Start with: uvicorn apo_basi.asgi:application --reload"
    exit 1
fi

echo "✅ Login successful!"
echo ""

# Update location
echo "📡 Updating bus location..."
RESULT=$(curl -s -X POST http://localhost:8000/api/realtime/buses/1/location \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"latitude\": $LAT, \"longitude\": $LON, \"speed\": 0.0, \"heading\": 0.0}")

echo "$RESULT" | python3 -m json.tool

echo ""
echo "=========================================="
echo "  ✅ Location Updated Successfully!"
echo "=========================================="
echo ""
echo "📍 Your bus is now at: $LAT, $LON"
echo "🗺️  View on map:"
echo "   https://www.google.com/maps?q=$LAT,$LON"
echo ""
echo "🧪 Next steps:"
echo "   1. Run: python test_realtime_tracking.py"
echo "   2. Open http://localhost:8000/docs to see API docs"
echo ""
