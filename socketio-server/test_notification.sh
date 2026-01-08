#!/bin/bash

# Test Notification Script
# Sends test notifications to the Socket.IO server

SOCKETIO_URL="http://localhost:3000"

echo "🧪 Testing Notification System"
echo "================================"
echo ""

# Function to send notification
send_notification() {
    local endpoint=$1
    local data=$2
    local description=$3

    echo "📤 Sending: $description"
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$SOCKETIO_URL$endpoint")

    if [ $? -eq 0 ]; then
        echo "   ✅ Response: $response"
    else
        echo "   ❌ Failed to send"
    fi
    echo ""
}

# Test 1: Trip Start Notification
send_notification \
    "/api/notify/trip-start" \
    '{
        "busId": 13,
        "busNumber": "BUS-013",
        "tripType": "morning",
        "tripId": 1,
        "routeName": "North Route"
    }' \
    "Trip Start"

sleep 2

# Test 2: Child Pickup Notification
send_notification \
    "/api/notify/child-status" \
    '{
        "busId": 13,
        "busNumber": "BUS-013",
        "childId": 1,
        "childName": "John Doe",
        "status": "on_bus",
        "parentUserIds": [29, 30],
        "location": "123 Main Street"
    }' \
    "Child Picked Up"

sleep 2

# Test 3: Child Dropped Off Notification
send_notification \
    "/api/notify/child-status" \
    '{
        "busId": 13,
        "busNumber": "BUS-013",
        "childId": 1,
        "childName": "John Doe",
        "status": "dropped_off",
        "parentUserIds": [29, 30],
        "location": "School"
    }' \
    "Child Dropped Off"

sleep 2

# Test 4: Trip End Notification
send_notification \
    "/api/notify/trip-end" \
    '{
        "busId": 13,
        "busNumber": "BUS-013",
        "tripType": "morning",
        "tripId": 1,
        "totalStudents": 25,
        "droppedOff": 25
    }' \
    "Trip End"

echo "================================"
echo "✅ All test notifications sent!"
echo ""
echo "Check your ParentsApp notifications screen to see if they appeared."
