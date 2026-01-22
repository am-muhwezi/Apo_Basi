
# ApoBasi Comprehensive Testing Guide

**Quick Reference: How to Run All Tests**

---

## Flutter Apps (ParentsApp, DriversandMinders)
```bash
# ParentsApp
cd Apo_Basi/ParentsApp
flutter pub get
flutter test

# DriversandMinders
cd Apo_Basi/DriversandMinders
flutter pub get
flutter test
```

## Django Backend
```bash
cd Apo_Basi/server
pip install -r ../requirements.txt
python manage.py test
# Or, for coverage:
pip install coverage
coverage run --source='.' manage.py test
coverage report
```

## React/Vite Admin Dashboard
```bash
cd Apo_Basi/client
npm install
npm run lint
npm run typecheck
# (No automated tests yet; add with Vitest/Jest if needed)
```

---

For troubleshooting, coverage, and advanced usage, see the detailed sections below.

---

# Comprehensive Testing Guide - ApoBasi Platform

<div align="center">

**Complete Testing Suite for ParentsApp, DriversandMinders, and Admin Dashboard**

Version 1.0 | Last Updated: 2026-01-19

</div>

---

## Table of Contents

1. [Overview](#overview)
2. [Testing Environment Setup](#testing-environment-setup)
3. [Backend Testing Prerequisites](#backend-testing-prerequisites)
4. [ParentsApp Testing](#parentsapp-testing)
5. [DriversandMinders Testing](#driversandminders-testing)
6. [Admin Dashboard Testing](#admin-dashboard-testing)
7. [Integration Testing](#integration-testing)
8. [Security Testing](#security-testing)
9. [Performance Testing](#performance-testing)
10. [Edge Cases & Error Scenarios](#edge-cases--error-scenarios)
11. [Test Data Setup](#test-data-setup)
12. [Bug Reporting Template](#bug-reporting-template)

---

## Overview

This document provides comprehensive testing procedures for all three ApoBasi platform applications:

- **ParentsApp**: Flutter mobile app for parents/guardians
- **DriversandMinders**: Flutter mobile app for drivers and bus minders
- **Admin Dashboard** (client): React/TypeScript web application for administrators

### Testing Objectives

- Verify all features work as expected
- Identify and document bugs
- Test edge cases and error scenarios
- Validate security measures
- Assess performance and UX
- Ensure data consistency across apps

---

## Testing Environment Setup

### Prerequisites for All Apps

1. **Backend Server Running**
   ```bash
   cd /home/m/work/Apo_Basi/server
   python manage.py runserver 0.0.0.0:8000
   ```

2. **Socket.IO Server Running** (for real-time features)
   ```bash
   cd /home/m/work/Apo_Basi/socketio-server
   npm install
   npm start  # Should run on port 4000
   ```

3. **Database Setup**
   ```bash
   cd /home/m/work/Apo_Basi/server
   python manage.py migrate
   python manage.py createsuperuser  # Create admin account
   ```

4. **Network Configuration**
   - Get your local IP address:
     ```bash
     # Linux/macOS
     ifconfig | grep "inet " | grep -v 127.0.0.1

     # Windows
     ipconfig | findstr IPv4
     ```
   - Use this IP in all app configurations (e.g., `http://192.168.1.100:8000`)

### Device Requirements

| App | Platform | Minimum Requirements |
|-----|----------|---------------------|
| ParentsApp | Android | Android 6.0+, GPS enabled |
| ParentsApp | iOS | iOS 12.0+, Location services |
| DriversandMinders | Android | Android 6.0+, GPS enabled, Good GPS signal |
| DriversandMinders | iOS | iOS 12.0+, Location services |
| Admin Dashboard | Web | Modern browser (Chrome 90+, Firefox 88+, Safari 14+) |

---

## Backend Testing Prerequisites

### 1. Create Test Users

Before testing the apps, create test users via Django admin or API:

```bash
# Access Django admin
# Navigate to: http://localhost:8000/admin

# Or use Django shell
cd /home/m/work/Apo_Basi/server
python manage.py shell
```

```python
from django.contrib.auth import get_user_model
from parents.models import Parent
from drivers.models import Driver
from busminders.models import BusMinder
from buses.models import Bus
from children.models import Child

User = get_user_model()

# Create Parent User
parent_user = User.objects.create_user(
    username='parent_test',
    password='Test@123',
    first_name='John',
    last_name='Doe',
    user_type='parent',
    phone_number='0700123456'
)
parent = Parent.objects.create(
    user=parent_user,
    contact_number='0700123456',
    address='Kampala, Uganda'
)

# Create Driver User
driver_user = User.objects.create_user(
    username='driver_test',
    password='Test@123',
    first_name='Michael',
    last_name='Driver',
    user_type='driver',
    phone_number='0700234567'
)
driver = Driver.objects.create(
    user=driver_user,
    phone_number='0700234567',
    license_number='DL12345',
    license_expiry='2026-12-31',
    status='active'
)

# Create BusMinder User
minder_user = User.objects.create_user(
    username='minder_test',
    password='Test@123',
    first_name='Sarah',
    last_name='Minder',
    user_type='busminder',
    phone_number='0700345678'
)
minder = BusMinder.objects.create(
    user=minder_user,
    phone_number='0700345678',
    status='active'
)

# Create Test Bus
bus = Bus.objects.create(
    bus_number='BUS001',
    number_plate='UAH 123X',
    capacity=40,
    model='Toyota Coaster',
    year=2022,
    is_active=True
)

# Create Test Child
child = Child.objects.create(
    first_name='Alice',
    last_name='Doe',
    date_of_birth='2015-05-15',
    class_grade='Grade 5',
    parent=parent
)
```

### 2. Verify API Endpoints

Test that all endpoints are accessible:

```bash
# Test authentication
curl -X POST http://localhost:8000/api/users/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "parent_test", "password": "Test@123"}'

# Test parent phone login
curl -X POST http://localhost:8000/api/parents/login/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "0700123456"}'

# Test driver phone login
curl -X POST http://localhost:8000/api/drivers/phone-login/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "0700234567"}'

# Test bus minder phone login
curl -X POST http://localhost:8000/api/busminders/phone-login/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "0700345678"}'
```

### 3. Verify Unique Phone Number Constraint

```python
# Test in Django shell
from django.contrib.auth import get_user_model
User = get_user_model()

# Try to create duplicate phone numbers (should fail after fix)
try:
    user1 = User.objects.create(username='test1', phone_number='0114810107', user_type='parent')
    user2 = User.objects.create(username='test2', phone_number='0114810107', user_type='driver')
    print("ERROR: Duplicate phone numbers allowed!")
except Exception as e:
    print(f"SUCCESS: Duplicate prevented - {e}")
```

---

## ParentsApp Testing

### Setup

1. **Configure API Endpoints**
   ```dart
   // lib/services/api_service.dart
   static const String baseUrl = 'http://YOUR_LOCAL_IP:8000/api';
   static const String socketUrl = 'http://YOUR_LOCAL_IP:4000';
   ```

2. **Install and Run**
   ```bash
   cd /home/m/work/Apo_Basi/ParentsApp
   flutter pub get
   flutter run
   ```

### Test Cases

#### TC-PA-001: Login with Phone Number

**Test Scenario**: Parent logs in using phone number

**Preconditions**:
- Parent account exists with phone number 0700123456
- App is installed and launched

**Steps**:
1. Open ParentsApp
2. Enter phone number: `0700123456`
3. Click "Login"

**Expected Results**:
- ✅ Login successful
- ✅ Redirected to Dashboard
- ✅ JWT token stored in local storage
- ✅ User information displayed correctly

**Edge Cases**:
- ❌ Invalid phone number format (e.g., "abc123") → Show error message
- ❌ Non-existent phone number → Show "Parent not found" error
- ❌ Empty phone number → Show "Phone number required" error
- ❌ Phone number with special characters (e.g., "+256-700-123-456") → Should accept or normalize
- ❌ Network timeout → Show connection error with retry option
- ❌ Backend down → Show "Cannot connect to server" error

---

#### TC-PA-002: View Dashboard with All Children

**Test Scenario**: Parent views all their children on dashboard

**Preconditions**:
- Parent is logged in
- Parent has 1+ children assigned

**Steps**:
1. After login, observe dashboard screen
2. Scroll through children list

**Expected Results**:
- ✅ All children displayed with photos
- ✅ Each child shows current status (on_bus, at_school, dropped_off, etc.)
- ✅ Bus information displayed for each child
- ✅ "Track Bus" button visible for each child

**Edge Cases**:
- 🔸 Parent has 0 children → Show "No children assigned" message
- 🔸 Parent has 20+ children → List should scroll smoothly
- 🔸 Child has no photo → Show placeholder image
- 🔸 Child not assigned to any bus → Show "Not assigned to bus" message
- 🔸 Bus information incomplete → Handle gracefully with "N/A"

---

#### TC-PA-003: Real-Time GPS Tracking

**Test Scenario**: Parent tracks child's bus in real-time

**Preconditions**:
- Parent logged in
- Child assigned to bus
- Driver app broadcasting GPS location

**Steps**:
1. Select a child from dashboard
2. Click "Track Bus" button
3. Observe map loading
4. Watch bus marker updates

**Expected Results**:
- ✅ Map loads with bus location marker
- ✅ Bus marker updates every 5 seconds
- ✅ Map centers on bus location
- ✅ Zoom controls work
- ✅ Bus number and status displayed

**Edge Cases**:
- ❌ Driver not broadcasting GPS → Show "Bus location not available"
- ❌ GPS signal lost → Show last known location with timestamp
- ❌ Network disconnected → Show offline message
- ❌ Google Maps API key invalid → Show error message
- 🔸 Bus moving very fast → Marker animation should be smooth
- 🔸 Multiple parents tracking same bus → All receive updates simultaneously

---

#### TC-PA-004: View Attendance History

**Test Scenario**: Parent views child's attendance records

**Preconditions**:
- Parent logged in
- Child has attendance records

**Steps**:
1. Select a child
2. Navigate to "Attendance" screen
3. Scroll through attendance records

**Expected Results**:
- ✅ Attendance records displayed chronologically
- ✅ Each record shows: date, status, pickup time, dropoff time, notes
- ✅ Status color-coded (present=green, absent=red)
- ✅ Filter by date range works

**Edge Cases**:
- 🔸 No attendance records → Show "No attendance data available"
- 🔸 Very old records (1+ years) → Pagination or lazy loading
- 🔸 Partial attendance data (only pickup, no dropoff) → Show partial data
- 🔸 Notes field very long → Truncate with "Read more" option

---

#### TC-PA-005: Child Status Updates

**Test Scenario**: Parent sees child status changes in real-time

**Preconditions**:
- Parent logged in
- Bus minder marking attendance for child

**Steps**:
1. View dashboard
2. Have bus minder change child status from "not_on_bus" → "on_bus"
3. Observe status update on parent app

**Expected Results**:
- ✅ Status updates automatically without refresh
- ✅ Status badge color changes (gray → blue)
- ✅ Timestamp shows when status changed

**Edge Cases**:
- 🔸 Multiple rapid status changes → Should show latest status
- 🔸 Network delay → Status updates when connection restored
- ❌ WebSocket disconnected → App should attempt reconnection

---

#### TC-PA-006: Multiple Children Management

**Test Scenario**: Parent with multiple children manages all profiles

**Preconditions**:
- Parent has 3+ children
- Children on different buses

**Steps**:
1. View dashboard
2. Switch between children
3. Track different buses
4. View attendance for each child

**Expected Results**:
- ✅ Can easily switch between children
- ✅ Each child's data loads correctly
- ✅ No data mixing between children
- ✅ Correct bus tracked for each child

**Edge Cases**:
- 🔸 Two children on same bus → Should show same GPS location
- 🔸 One child on bus, one at school → Statuses different and correct
- 🔸 Rapidly switching between children → No crashes or data corruption

---

#### TC-PA-007: Offline Mode & Data Caching

**Test Scenario**: App functions with limited connectivity

**Preconditions**:
- Parent logged in with internet
- Data loaded successfully

**Steps**:
1. Load dashboard with all children
2. Disable internet connection
3. Navigate through app
4. Re-enable internet

**Expected Results**:
- ✅ Cached data still visible offline
- ✅ "No connection" indicator shown
- ✅ Cannot track bus in real-time (expected)
- ✅ Can view cached attendance records
- ✅ Auto-syncs when connection restored

**Edge Cases**:
- 🔸 Login attempted offline → Show "Internet required to login"
- 🔸 No cached data → Show appropriate message
- 🔸 Partial cache → Show what's available

---

#### TC-PA-008: Push Notifications (If Implemented)

**Test Scenario**: Parent receives notifications

**Preconditions**:
- Notifications enabled
- Parent logged in

**Steps**:
1. Have bus minder mark child as "on_bus"
2. Observe notification

**Expected Results**:
- ✅ Notification received promptly
- ✅ Notification shows child name and status
- ✅ Tapping notification opens app to relevant screen

**Edge Cases**:
- 🔸 Notifications disabled → No notification sent
- 🔸 App in background → Notification still received
- 🔸 Multiple rapid notifications → Should not spam

---

#### TC-PA-009: UI/UX Testing

**Test Scenario**: App is user-friendly and intuitive

**Steps**:
1. Navigate through all screens
2. Test all buttons and interactions
3. Check text readability
4. Test on different screen sizes

**Expected Results**:
- ✅ All text readable (not too small)
- ✅ Colors contrast well
- ✅ Buttons large enough to tap
- ✅ No overlapping UI elements
- ✅ Loading indicators show during waits
- ✅ Error messages are clear and helpful
- ✅ Responsive on tablets and phones

**Edge Cases**:
- 🔸 Very small phone screen → UI should adapt
- 🔸 Very large tablet → UI should use space well
- 🔸 Landscape orientation → Should work properly
- 🔸 Dark mode (if supported) → All elements visible

---

#### TC-PA-010: Logout & Session Management

**Test Scenario**: Parent logs out and session expires properly

**Steps**:
1. Login successfully
2. Click logout button
3. Try to access protected screens

**Expected Results**:
- ✅ Logout successful
- ✅ Tokens cleared from storage
- ✅ Redirected to login screen
- ✅ Cannot access protected screens without re-login

**Edge Cases**:
- 🔸 Token expired while app open → Auto-logout or refresh token
- 🔸 Multiple logout clicks → Should not crash
- 🔸 Logout with pending requests → Requests canceled

---

## DriversandMinders Testing

### Setup

1. **Configure API Endpoints**
   ```dart
   // lib/services/api_service.dart
   static const String baseUrl = 'http://YOUR_LOCAL_IP:8000/api';
   static const String socketUrl = 'http://YOUR_LOCAL_IP:4000';
   ```

2. **Install and Run**
   ```bash
   cd /home/m/work/Apo_Basi/DriversandMinders
   flutter pub get
   flutter run
   ```

### Test Cases

#### TC-DM-001: Login with Phone Number (Driver)

**Test Scenario**: Driver logs in using phone number

**Preconditions**:
- Driver account exists with phone number 0700234567

**Steps**:
1. Open DriversandMinders app
2. Enter phone number: `0700234567`
3. Click "Login"

**Expected Results**:
- ✅ Login successful
- ✅ Redirected to Driver Dashboard
- ✅ User type correctly identified as "driver"

**Edge Cases**:
- ❌ Invalid phone number → Error message
- ❌ Non-existent driver → "Driver not found"
- ❌ Inactive driver account → "Account inactive" message

---

#### TC-DM-002: Login with Phone Number (Bus Minder)

**Test Scenario**: Bus minder logs in using phone number

**Preconditions**:
- BusMinder account exists with phone number 0700345678

**Steps**:
1. Open DriversandMinders app
2. Enter phone number: `0700345678`
3. Click "Login"

**Expected Results**:
- ✅ Login successful
- ✅ Redirected to Bus Minder Dashboard
- ✅ User type correctly identified as "busminder"

**Edge Cases**:
- ❌ Driver phone number entered → Should login as driver (correct user type)
- ❌ Non-existent minder → "Bus minder not found"

---

#### TC-DM-003: Driver - View Assigned Bus

**Test Scenario**: Driver views their assigned bus details

**Preconditions**:
- Driver logged in
- Driver assigned to a bus

**Steps**:
1. View dashboard
2. Observe bus information

**Expected Results**:
- ✅ Bus number plate displayed
- ✅ Bus model shown
- ✅ Capacity information visible
- ✅ Route information accessible

**Edge Cases**:
- 🔸 Driver not assigned to bus → Show "No bus assigned" message
- 🔸 Bus information incomplete → Show available fields only

---

#### TC-DM-004: Driver - GPS Broadcasting

**Test Scenario**: Driver broadcasts GPS location

**Preconditions**:
- Driver logged in
- Assigned to bus
- GPS permissions granted
- Good GPS signal

**Steps**:
1. Navigate to "Start Shift" or GPS tracking screen
2. Click "Start Broadcasting"
3. Move location (simulate or physically move)
4. Verify on parent app that location updates

**Expected Results**:
- ✅ GPS broadcasting starts successfully
- ✅ Location sent every 5 seconds
- ✅ Green indicator shows "Broadcasting"
- ✅ Parents can see bus location in real-time

**Edge Cases**:
- ❌ GPS permissions denied → Prompt to enable
- ❌ GPS signal weak → Show warning "Poor GPS signal"
- ❌ Network disconnected → Queue locations and send when connected
- 🔸 Battery saver mode → GPS might be less accurate
- 🔸 Driver moves very fast → Location should still update smoothly
- ❌ Socket.IO disconnected → Attempt reconnection

---

#### TC-DM-005: Driver - View Route & Children

**Test Scenario**: Driver views all children on their route

**Preconditions**:
- Driver logged in
- Bus assigned with children

**Steps**:
1. Navigate to "Route" or "Children" screen
2. View list of children

**Expected Results**:
- ✅ All children on route displayed
- ✅ Child name, photo, class grade shown
- ✅ Parent contact information visible
- ✅ Click to call parent works

**Edge Cases**:
- 🔸 No children assigned → Show "No children on this route"
- 🔸 50+ children → List should scroll smoothly
- 🔸 Parent has no phone number → Show "Contact not available"
- ❌ Call button clicked without phone permission → Request permission

---

#### TC-DM-006: Driver - Start/End Shift

**Test Scenario**: Driver marks shift start and end

**Steps**:
1. Click "Start Shift" button
2. Perform duties
3. Click "End Shift" button

**Expected Results**:
- ✅ Shift status recorded
- ✅ GPS broadcasting starts with shift
- ✅ GPS broadcasting stops with shift end
- ✅ Shift times logged

**Edge Cases**:
- 🔸 Start shift without GPS → Warn driver
- 🔸 Battery low → Warn about GPS drain
- 🔸 Forget to end shift → Should not broadcast forever (timeout?)

---

#### TC-DM-007: Bus Minder - View Assigned Buses

**Test Scenario**: Bus minder views all assigned buses

**Preconditions**:
- Bus minder logged in
- Assigned to 2+ buses

**Steps**:
1. View dashboard
2. Observe bus list

**Expected Results**:
- ✅ All assigned buses listed
- ✅ Each bus shows number plate, capacity
- ✅ Children count shown for each bus
- ✅ Can select a bus to manage

**Edge Cases**:
- 🔸 Not assigned to any bus → Show "No buses assigned"
- 🔸 Assigned to 10+ buses → List should scroll

---

#### TC-DM-008: Bus Minder - View Children on Bus

**Test Scenario**: Minder views children for selected bus

**Steps**:
1. Select a bus
2. View children list

**Expected Results**:
- ✅ All children on bus displayed
- ✅ Current attendance status shown
- ✅ Parent contact visible
- ✅ Can mark attendance

**Edge Cases**:
- 🔸 No children on bus → Show "No children assigned"
- 🔸 Child status outdated → Show last update timestamp

---

#### TC-DM-009: Bus Minder - Mark Attendance (Online)

**Test Scenario**: Minder marks child present while online

**Preconditions**:
- Bus minder logged in
- Viewing children list
- Internet connected

**Steps**:
1. Find child "Alice Doe"
2. Click "Mark Present" button
3. Select status: "on_bus"
4. Add note: "Boarded at Gate 2"
5. Submit

**Expected Results**:
- ✅ Attendance marked successfully
- ✅ Status updates immediately in UI
- ✅ Success message shown
- ✅ Parent app shows updated status
- ✅ Timestamp recorded

**Edge Cases**:
- 🔸 Network error during submission → Show error, allow retry
- 🔸 Multiple minders marking same child → Last update wins
- 🔸 Change status multiple times rapidly → All updates recorded

---

#### TC-DM-010: Bus Minder - Mark Attendance (Offline)

**Test Scenario**: Minder marks attendance without internet

**Preconditions**:
- Bus minder logged in
- Internet disconnected

**Steps**:
1. Disable internet on device
2. Mark child as "on_bus"
3. Mark another child as "absent"
4. Re-enable internet
5. Wait for auto-sync

**Expected Results**:
- ✅ Attendance marked locally
- ✅ "Offline" indicator shown
- ✅ "Pending sync" badge displayed
- ✅ Auto-syncs when internet restored
- ✅ Success confirmation after sync

**Edge Cases**:
- 🔸 50+ offline attendance records → All should sync
- 🔸 Internet restored briefly then lost → Partial sync handled
- 🔸 Conflicting online updates → Server timestamp wins
- 🔸 App closed before sync → Queue persists, syncs on next open

---

#### TC-DM-011: Bus Minder - Update Child Status

**Test Scenario**: Minder updates child through daily journey

**Steps**:
1. Morning: Mark child "on_bus"
2. Arrival: Mark child "at_school"
3. Afternoon: Mark child "on_way_home"
4. Evening: Mark child "dropped_off"

**Expected Results**:
- ✅ Each status change recorded with timestamp
- ✅ Parent sees status updates in real-time
- ✅ Attendance history shows all transitions

**Edge Cases**:
- 🔸 Skip a status (on_bus → dropped_off) → Should be allowed
- 🔸 Mark backward (dropped_off → on_bus) → Should be allowed (rare but possible)

---

#### TC-DM-012: Bus Minder - Bulk Attendance

**Test Scenario**: Mark all children present at once

**Steps**:
1. View children list
2. Click "Mark All Present" button
3. Confirm action

**Expected Results**:
- ✅ All children marked "on_bus"
- ✅ Single timestamp for all
- ✅ Success message shown
- ✅ All parents notified

**Edge Cases**:
- 🔸 Some children already marked → Skip or overwrite with confirmation
- 🔸 Network fails mid-bulk → Some marked, some pending

---

#### TC-DM-013: GPS Background Service (Driver)

**Test Scenario**: GPS continues broadcasting when app in background

**Preconditions**:
- Driver started shift
- GPS broadcasting active

**Steps**:
1. Start GPS broadcasting
2. Switch to another app or lock screen
3. Verify location updates continue

**Expected Results**:
- ✅ Background service keeps GPS active
- ✅ Location updates continue
- ✅ Persistent notification shown
- ✅ Battery usage reasonable

**Edge Cases**:
- ❌ OS kills background service → App should detect and warn driver
- 🔸 Battery optimization enabled → May affect GPS frequency
- ❌ App force-closed → GPS stops (expected, but warn driver)

---

#### TC-DM-014: Permission Handling

**Test Scenario**: App requests necessary permissions

**Steps**:
1. Fresh install app
2. Login
3. Observe permission requests

**Expected Results**:
- ✅ Location permission requested (driver)
- ✅ Camera permission requested (if attendance photo feature)
- ✅ Clear explanation why permission needed
- ✅ Can still use app with limited features if denied

**Edge Cases**:
- ❌ All permissions denied → Show warning but allow basic functions
- 🔸 Permission revoked mid-session → Detect and re-request

---

#### TC-DM-015: Logout & Session Management

**Test Scenario**: User logs out properly

**Steps**:
1. Login
2. Start GPS broadcasting (if driver)
3. Logout

**Expected Results**:
- ✅ GPS broadcasting stops
- ✅ Tokens cleared
- ✅ Redirected to login
- ✅ Cannot access protected screens

**Edge Cases**:
- 🔸 Logout while offline attendance pending → Warn before logout
- 🔸 Logout during GPS broadcast → Stop broadcasting first

---

## Admin Dashboard Testing

### Setup

1. **Configure API Endpoint**
   ```typescript
   // src/services/api.ts
   const API_BASE_URL = 'http://localhost:8000/api';
   ```

2. **Install and Run**
   ```bash
   cd /home/m/work/Apo_Basi/client
   npm install
   npm run dev
   # Navigate to http://localhost:5173
   ```

### Test Cases

#### TC-AD-001: Admin Login

**Test Scenario**: Admin logs in to dashboard

**Preconditions**:
- Admin user exists

**Steps**:
1. Navigate to http://localhost:5173
2. Enter username: `admin`
3. Enter password: `admin_password`
4. Click "Login"

**Expected Results**:
- ✅ Login successful
- ✅ Redirected to dashboard
- ✅ JWT tokens stored
- ✅ Sidebar navigation visible

**Edge Cases**:
- ❌ Wrong credentials → "Invalid credentials" error
- ❌ Empty fields → Validation errors
- ❌ Backend down → Connection error message

---

#### TC-AD-002: Dashboard Overview

**Test Scenario**: Admin views dashboard metrics

**Steps**:
1. Login successfully
2. View dashboard

**Expected Results**:
- ✅ Total buses count displayed
- ✅ Active drivers count
- ✅ Total children count
- ✅ Today's attendance rate
- ✅ Recent activities list
- ✅ All numbers accurate

**Edge Cases**:
- 🔸 No data in system → Show zeros
- 🔸 Very large numbers (1000+) → Format properly

---

#### TC-AD-003: Bus Management - Create Bus

**Test Scenario**: Admin creates a new bus

**Steps**:
1. Navigate to "Buses" page
2. Click "Add Bus" button
3. Fill form:
   - Bus Number: BUS002
   - Number Plate: UAH 456Y
   - Model: Nissan Civilian
   - Capacity: 30
   - Year: 2023
4. Click "Save"

**Expected Results**:
- ✅ Bus created successfully
- ✅ Success message shown
- ✅ New bus appears in list
- ✅ All fields saved correctly

**Edge Cases**:
- ❌ Duplicate number plate → "Number plate already exists" error
- ❌ Invalid capacity (negative number) → Validation error
- ❌ Invalid year (future year) → Validation error
- ❌ Empty required fields → Field-specific errors
- 🔸 Very long bus number (50+ chars) → Should truncate or limit

---

#### TC-AD-004: Bus Management - Edit Bus

**Test Scenario**: Admin updates bus details

**Steps**:
1. View bus list
2. Click edit icon for a bus
3. Change capacity from 30 to 35
4. Click "Save"

**Expected Results**:
- ✅ Bus updated successfully
- ✅ Changes reflected immediately
- ✅ Success message shown

**Edge Cases**:
- 🔸 Edit bus while driver using it → Should still work
- ❌ Change to duplicate number plate → Error

---

#### TC-AD-005: Bus Management - Delete Bus

**Test Scenario**: Admin deletes a bus

**Steps**:
1. View bus list
2. Click delete icon for a bus
3. Confirm deletion

**Expected Results**:
- ✅ Confirmation dialog shown
- ✅ Bus deleted from database
- ✅ Removed from list
- ✅ Success message shown

**Edge Cases**:
- ❌ Bus has active assignments → Warn before delete or prevent
- ❌ Bus currently broadcasting GPS → Warn admin
- 🔸 Cancel deletion → No changes made

---

#### TC-AD-006: User Management - Create Parent

**Test Scenario**: Admin creates parent account

**Steps**:
1. Navigate to "Users" page
2. Select "Parents" tab
3. Click "Add Parent"
4. Fill form:
   - First Name: Jane
   - Last Name: Smith
   - Phone Number: 0701234567
   - Email: jane@example.com
   - Address: Kampala
5. Click "Save"

**Expected Results**:
- ✅ Parent created successfully
- ✅ User account auto-generated
- ✅ Credentials displayed to admin
- ✅ Parent appears in list
- ✅ Phone number unique check passed

**Edge Cases**:
- ❌ **Duplicate phone number** → ERROR: "Phone number already in use"
- ❌ **Phone number used by driver** → ERROR: "Phone number already in use"
- ❌ **Phone number used by bus minder** → ERROR: "Phone number already in use"
- ❌ Invalid phone format → Validation error
- ❌ Invalid email format → Validation error
- 🔸 Parent with no email → Should be optional

---

#### TC-AD-007: User Management - Create Driver

**Test Scenario**: Admin creates driver account

**Steps**:
1. Navigate to "Users" → "Drivers"
2. Click "Add Driver"
3. Fill form:
   - First Name: John
   - Last Name: Driver
   - Phone Number: 0702345678
   - License Number: DL67890
   - License Expiry: 2027-06-30
4. Click "Save"

**Expected Results**:
- ✅ Driver created successfully
- ✅ Credentials displayed
- ✅ Driver appears in list
- ✅ Phone number unique check passed

**Edge Cases**:
- ❌ **Duplicate phone number (any user type)** → ERROR: "Phone number already in use"
- ❌ Duplicate license number → Error
- ❌ Expired license → Validation warning
- 🔸 No license expiry → Should prompt for date

---

#### TC-AD-008: User Management - Create Bus Minder

**Test Scenario**: Admin creates bus minder account

**Steps**:
1. Navigate to "Users" → "Bus Minders"
2. Click "Add Bus Minder"
3. Fill form:
   - First Name: Sarah
   - Last Name: Minder
   - Phone Number: 0703456789
4. Click "Save"

**Expected Results**:
- ✅ Bus minder created successfully
- ✅ Credentials displayed
- ✅ Appears in list
- ✅ Phone number unique check passed

**Edge Cases**:
- ❌ **Duplicate phone number (any user type)** → ERROR: "Phone number already in use"

---

#### TC-AD-009: User Management - Duplicate Phone Number Prevention

**Test Scenario**: System prevents duplicate phone numbers across all user types

**Preconditions**:
- Database has phone number constraint fix applied

**Steps**:
1. Create parent with phone: 0114810107
2. Try to create driver with phone: 0114810107
3. Try to create bus minder with phone: 0114810107
4. Try to create another parent with phone: 0114810107

**Expected Results**:
- ✅ First creation (parent) succeeds
- ❌ Driver creation FAILS: "Phone number 0114810107 already in use"
- ❌ Bus minder creation FAILS: "Phone number 0114810107 already in use"
- ❌ Second parent creation FAILS: "Phone number 0114810107 already in use"

**This is the PRIMARY BUG FIX TEST**

---

#### TC-AD-010: Child Management - Create Child

**Test Scenario**: Admin creates child profile

**Steps**:
1. Navigate to "Children"
2. Click "Add Child"
3. Fill form:
   - First Name: Bob
   - Last Name: Smith
   - Date of Birth: 2016-03-20
   - Class/Grade: Grade 4
   - Parent: Select "Jane Smith"
5. Click "Save"

**Expected Results**:
- ✅ Child created successfully
- ✅ Linked to parent
- ✅ Appears in list

**Edge Cases**:
- ❌ Future date of birth → Error
- 🔸 Very young child (< 3 years) → Warning but allow
- 🔸 No parent selected → Should require parent

---

#### TC-AD-011: Assignment Management - Assign Driver to Bus

**Test Scenario**: Admin assigns driver to bus

**Steps**:
1. Navigate to "Assignments"
2. Click "Assign Driver"
3. Select Driver: "John Driver"
4. Select Bus: "BUS002"
5. Click "Assign"

**Expected Results**:
- ✅ Assignment created
- ✅ Driver linked to bus
- ✅ Driver can now see bus in their app
- ✅ Previous driver assignment removed (if any)

**Edge Cases**:
- ❌ Driver already assigned to another bus → Confirm reassignment
- ❌ Bus already has driver → Confirm replacement
- 🔸 Assign same driver to same bus → Should handle gracefully

---

#### TC-AD-012: Assignment Management - Assign Bus Minder to Bus

**Test Scenario**: Admin assigns bus minder to bus

**Steps**:
1. Navigate to "Assignments"
2. Click "Assign Bus Minder"
3. Select Minder: "Sarah Minder"
4. Select Bus: "BUS001"
5. Click "Assign"

**Expected Results**:
- ✅ Assignment created
- ✅ Minder can manage this bus
- ✅ Minder can mark attendance for children on this bus

**Edge Cases**:
- 🔸 Assign multiple minders to same bus → Should be allowed
- 🔸 Assign same minder to multiple buses → Should be allowed

---

#### TC-AD-013: Assignment Management - Assign Child to Bus

**Test Scenario**: Admin assigns child to bus route

**Steps**:
1. Navigate to "Assignments"
2. Click "Assign Child"
3. Select Child: "Bob Smith"
4. Select Bus: "BUS001"
5. Click "Assign"

**Expected Results**:
- ✅ Child assigned to bus
- ✅ Parent can now track this bus
- ✅ Child appears in driver's route list
- ✅ Minder can mark attendance for this child

**Edge Cases**:
- ❌ Child already on another bus → Confirm reassignment
- 🔸 Child assigned to same bus twice → Prevent duplicate
- ❌ Bus at capacity → Warn admin or prevent

---

#### TC-AD-014: Attendance Reports

**Test Scenario**: Admin views attendance reports

**Steps**:
1. Navigate to "Attendance"
2. Select date range: Last 7 days
3. Select bus: "BUS001"
4. Click "Generate Report"

**Expected Results**:
- ✅ Attendance data displayed in table
- ✅ Shows all children on bus
- ✅ Shows presence/absence for each day
- ✅ Calculates attendance percentage
- ✅ Can export to CSV/PDF

**Edge Cases**:
- 🔸 No attendance data for date range → Show "No data"
- 🔸 Very large date range (1 year) → Paginate or limit

---

#### TC-AD-015: Analytics & Reports

**Test Scenario**: Admin views analytics

**Steps**:
1. Navigate to "Analytics"
2. View various charts and graphs

**Expected Results**:
- ✅ Charts render properly
- ✅ Data accurate
- ✅ Interactive filters work
- ✅ Export functionality works

**Edge Cases**:
- 🔸 No data → Show empty state
- 🔸 Very large dataset → Performance should be acceptable

---

#### TC-AD-016: Live Bus Tracking

**Test Scenario**: Admin views all buses in real-time

**Steps**:
1. Navigate to "Tracking"
2. View map with all buses

**Expected Results**:
- ✅ Map loads successfully
- ✅ All active buses shown as markers
- ✅ Markers update in real-time
- ✅ Click marker shows bus details
- ✅ Bus trail/route shown

**Edge Cases**:
- 🔸 No buses broadcasting → Show "No active buses"
- 🔸 100+ buses → Map should handle performance
- ❌ Socket.IO disconnected → Show offline warning

---

#### TC-AD-017: Search & Filter Functionality

**Test Scenario**: Admin searches and filters data

**Steps**:
1. On any list page (buses, users, children)
2. Use search box
3. Apply filters

**Expected Results**:
- ✅ Search returns relevant results
- ✅ Filters work correctly
- ✅ Can combine search and filters
- ✅ Results update instantly

**Edge Cases**:
- 🔸 Search with no results → Show "No results found"
- 🔸 Special characters in search → Handle properly

---

#### TC-AD-018: Pagination

**Test Scenario**: Admin navigates through paginated lists

**Steps**:
1. View a list with 50+ items
2. Navigate through pages

**Expected Results**:
- ✅ Pages load correctly
- ✅ Page numbers accurate
- ✅ Can jump to specific page
- ✅ Items per page selector works

**Edge Cases**:
- 🔸 Last page partially filled → Display correctly
- 🔸 Jump to page beyond max → Go to last page

---

#### TC-AD-019: Form Validation

**Test Scenario**: All forms have proper validation

**Steps**:
1. Try to submit forms with invalid data
2. Try to submit empty required fields

**Expected Results**:
- ✅ Validation errors shown
- ✅ Error messages clear and helpful
- ✅ Fields highlighted in red
- ✅ Cannot submit until valid

**Edge Cases**:
- 🔸 Fix one error, others still shown → Progressive validation
- 🔸 Server-side validation different → Show server errors

---

#### TC-AD-020: Responsive Design

**Test Scenario**: Dashboard works on all screen sizes

**Steps**:
1. Resize browser window
2. Test on tablet simulation
3. Test on mobile simulation

**Expected Results**:
- ✅ Layout adapts to screen size
- ✅ All features accessible on mobile
- ✅ Tables scroll horizontally if needed
- ✅ Buttons appropriately sized

**Edge Cases**:
- 🔸 Very small screen (320px) → Should still be usable
- 🔸 Very wide screen (4K) → Should use space well

---

## Integration Testing

### End-to-End Scenarios

#### INT-001: Complete Parent Journey

**Scenario**: Parent tracks child from pickup to dropoff

**Steps**:
1. **Morning**: Bus minder marks child "on_bus" → Parent receives notification
2. **In Transit**: Parent opens app, tracks bus in real-time
3. **At School**: Bus minder marks child "at_school" → Parent sees status update
4. **Afternoon**: Bus minder marks child "on_way_home"
5. **Evening**: Bus minder marks child "dropped_off" → Parent confirms safe arrival

**Expected Results**:
- ✅ All status changes reflected across apps
- ✅ Real-time GPS tracking works throughout
- ✅ Attendance record created for the day
- ✅ Admin can see attendance in reports

---

#### INT-002: Complete Admin Workflow

**Scenario**: Admin sets up new bus service

**Steps**:
1. Admin creates new bus (BUS003)
2. Admin creates new driver
3. Admin assigns driver to BUS003
4. Admin creates bus minder
5. Admin assigns minder to BUS003
6. Admin creates 5 children
7. Admin assigns children to BUS003
8. Driver logs in, starts GPS broadcast
9. Parents log in, see children assigned to BUS003
10. Bus minder marks attendance

**Expected Results**:
- ✅ All assignments work correctly
- ✅ Driver sees bus and route
- ✅ Parents can track bus
- ✅ Minder can mark attendance
- ✅ Data consistency across all apps

---

#### INT-003: Offline-Online Synchronization

**Scenario**: Bus minder works offline then syncs

**Steps**:
1. Bus minder starts day online
2. Internet connection lost
3. Minder marks 20 children attendance offline
4. Internet restored
5. Observe auto-sync

**Expected Results**:
- ✅ All 20 attendance records sync successfully
- ✅ Parents receive delayed status updates
- ✅ Admin sees all attendance in reports
- ✅ No data loss or corruption

---

#### INT-004: Multi-Device Real-Time Updates

**Scenario**: Multiple devices receive same updates

**Steps**:
1. Parent1 tracks bus on Phone A
2. Parent2 tracks same bus on Phone B
3. Admin tracks bus on web dashboard
4. Driver moves bus
5. Bus minder updates child status

**Expected Results**:
- ✅ All devices see GPS updates simultaneously
- ✅ All devices see status updates simultaneously
- ✅ No lag > 2 seconds
- ✅ No device crashes or freezes

---

## Security Testing

### SEC-001: Authentication Security

**Test**: Attempt unauthorized access

**Steps**:
1. Try to access protected API endpoints without token
2. Try to use expired token
3. Try to use invalid token

**Expected Results**:
- ❌ All attempts rejected with 401 Unauthorized
- ❌ No sensitive data exposed

---

### SEC-002: Phone Number Uniqueness Enforcement

**Test**: Verify bug fix for duplicate phone numbers

**Steps**:
1. Attempt to register parent with phone: 0111222333
2. Attempt to register driver with phone: 0111222333
3. Attempt to register minder with phone: 0111222333

**Expected Results**:
- ✅ First registration succeeds
- ❌ Second registration FAILS with clear error
- ❌ Third registration FAILS with clear error

**This validates the primary bug fix**

---

### SEC-003: SQL Injection Prevention

**Test**: Attempt SQL injection attacks

**Steps**:
1. In search fields, enter: `' OR '1'='1`
2. In phone number field, enter: `'; DROP TABLE users; --`

**Expected Results**:
- ✅ No database errors
- ✅ Inputs treated as strings
- ✅ No data compromised

---

### SEC-004: XSS Prevention

**Test**: Attempt cross-site scripting

**Steps**:
1. Create child with name: `<script>alert('XSS')</script>`
2. Create bus with name: `<img src=x onerror=alert('XSS')>`

**Expected Results**:
- ✅ Scripts not executed
- ✅ HTML escaped properly
- ✅ Data displayed safely

---

### SEC-005: Authorization Checks

**Test**: Users can only access their own data

**Steps**:
1. Parent1 tries to access Parent2's children
2. Driver1 tries to access Driver2's bus
3. BusMinder tries to mark attendance for unassigned bus

**Expected Results**:
- ❌ All unauthorized attempts blocked
- ❌ No data leakage

---

## Performance Testing

### PERF-001: GPS Update Frequency

**Test**: Measure GPS broadcast performance

**Steps**:
1. Driver starts broadcasting
2. Monitor update frequency
3. Measure network usage

**Expected Results**:
- ✅ Updates every 5 seconds (±1 second)
- ✅ Each update < 500 bytes
- ✅ Battery drain acceptable (< 10% per hour)

---

### PERF-002: App Launch Time

**Test**: Measure cold start time

**Steps**:
1. Force close app
2. Clear from memory
3. Launch app
4. Measure time to interactive

**Expected Results**:
- ✅ ParentsApp: < 3 seconds
- ✅ DriversandMinders: < 3 seconds
- ✅ Admin Dashboard: < 2 seconds

---

### PERF-003: Large Data Handling

**Test**: App handles large datasets

**Steps**:
1. Create 100 buses
2. Create 200 children
3. Create 1000 attendance records
4. View in admin dashboard

**Expected Results**:
- ✅ Lists load within 2 seconds
- ✅ Pagination works smoothly
- ✅ Search remains fast
- ✅ No UI freezing

---

### PERF-004: Concurrent Users

**Test**: System handles multiple simultaneous users

**Steps**:
1. 50 parents tracking buses simultaneously
2. 10 drivers broadcasting GPS
3. 5 bus minders marking attendance

**Expected Results**:
- ✅ All GPS updates delivered
- ✅ All attendance updates saved
- ✅ No server timeouts
- ✅ Response time < 1 second

---

## Edge Cases & Error Scenarios

### Edge Case Matrix

| Scenario | Expected Behavior | Critical? |
|----------|-------------------|-----------|
| User submits form twice rapidly | Prevent duplicate submission | High |
| GPS signal lost mid-journey | Show last known location with timestamp | High |
| App killed by OS during GPS broadcast | Detect and restart on next open | Medium |
| Phone number with spaces/dashes | Normalize before validation | Medium |
| Child assigned to non-existent bus | Validation error | High |
| Token expires during operation | Refresh token or re-login | High |
| Very long names (100+ chars) | Truncate or set limits | Low |
| Special characters in names (émile, josé) | Support Unicode properly | Medium |
| Date of birth in future | Validation error | High |
| Negative bus capacity | Validation error | High |
| Zero capacity bus | Warning but allow | Low |
| Delete parent with children | Cascade delete or prevent | High |
| Delete bus with active driver | Warn and confirm | High |
| Upload very large profile photo | Compress or limit size | Medium |
| Network switches (WiFi to 4G) | Maintain connections | High |
| Low battery with GPS active | Warn user | Medium |
| Device time wrong | Use server time | Medium |
| Multiple devices same account | Last login wins or allow both | Medium |

---

## Test Data Setup

### Quick Setup Script

```python
# Run in Django shell: python manage.py shell

from django.contrib.auth import get_user_model
from parents.models import Parent
from drivers.models import Driver
from busminders.models import BusMinder
from buses.models import Bus
from children.models import Child
from datetime import date

User = get_user_model()

# Create 3 Buses
buses = []
for i in range(1, 4):
    bus = Bus.objects.create(
        bus_number=f'BUS00{i}',
        number_plate=f'UAH {100+i}X',
        capacity=40,
        model='Toyota Coaster',
        year=2022,
        is_active=True
    )
    buses.append(bus)

# Create 5 Parents with Children
for i in range(1, 6):
    parent_user = User.objects.create_user(
        username=f'parent{i}',
        password='Test@123',
        first_name=f'Parent{i}',
        last_name='Test',
        user_type='parent',
        phone_number=f'070010000{i}'
    )
    parent = Parent.objects.create(
        user=parent_user,
        contact_number=f'070010000{i}',
        address=f'Address {i}, Kampala'
    )

    # Create 2 children per parent
    for j in range(1, 3):
        Child.objects.create(
            first_name=f'Child{i}{j}',
            last_name='Test',
            date_of_birth=date(2015, 1, i),
            class_grade=f'Grade {i}',
            parent=parent
        )

# Create 3 Drivers
for i in range(1, 4):
    driver_user = User.objects.create_user(
        username=f'driver{i}',
        password='Test@123',
        first_name=f'Driver{i}',
        last_name='Test',
        user_type='driver',
        phone_number=f'070020000{i}'
    )
    Driver.objects.create(
        user=driver_user,
        phone_number=f'070020000{i}',
        license_number=f'DL{10000+i}',
        license_expiry=date(2027, 12, 31),
        status='active'
    )

# Create 3 Bus Minders
for i in range(1, 4):
    minder_user = User.objects.create_user(
        username=f'minder{i}',
        password='Test@123',
        first_name=f'Minder{i}',
        last_name='Test',
        user_type='busminder',
        phone_number=f'070030000{i}'
    )
    BusMinder.objects.create(
        user=minder_user,
        phone_number=f'070030000{i}',
        status='active'
    )

print("Test data created successfully!")
print("Parent logins: parent1/Test@123 through parent5/Test@123")
print("Parent phones: 0700100001 through 0700100005")
print("Driver phones: 0700200001 through 0700200003")
print("Minder phones: 0700300001 through 0700300003")
```

---

## Bug Reporting Template

When reporting bugs, use this format:

### Bug Report Template

```markdown
## Bug ID: [Unique ID]

### Title
Brief description of the bug

### Severity
- Critical / High / Medium / Low

### Application
- [ ] ParentsApp
- [ ] DriversandMinders
- [ ] Admin Dashboard
- [ ] Backend API

### Environment
- OS Version:
- App Version:
- Device:
- Network: WiFi / 4G / 3G

### Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

### Expected Result
What should happen

### Actual Result
What actually happened

### Screenshots/Videos
[Attach if available]

### Console Logs/Errors
```
Paste error logs here
```

### Frequency
- Always / Sometimes / Rarely

### Additional Notes
Any other relevant information
```

---

## Testing Checklist

### Pre-Release Checklist

Before any release, ensure:

#### Backend
- [ ] All migrations applied
- [ ] Phone number uniqueness enforced
- [ ] API endpoints tested
- [ ] JWT authentication working
- [ ] CORS configured properly
- [ ] Socket.IO server running

#### ParentsApp
- [ ] Login works (phone number)
- [ ] Dashboard loads all children
- [ ] GPS tracking functional
- [ ] Attendance history visible
- [ ] Status updates in real-time
- [ ] Offline mode tested
- [ ] No crashes in 30-minute session

#### DriversandMinders
- [ ] Driver login works
- [ ] Bus minder login works
- [ ] GPS broadcasting works
- [ ] Offline attendance queues
- [ ] Auto-sync works
- [ ] Background GPS service tested
- [ ] Permissions handled properly

#### Admin Dashboard
- [ ] Login works
- [ ] All CRUD operations work
- [ ] Duplicate phone numbers prevented
- [ ] Assignments work correctly
- [ ] Reports generate properly
- [ ] Live tracking functional
- [ ] Responsive on mobile browser

#### Integration
- [ ] End-to-end parent journey works
- [ ] Real-time updates across all apps
- [ ] Offline sync works properly
- [ ] No data inconsistencies

#### Security
- [ ] Authentication required everywhere
- [ ] No unauthorized access
- [ ] SQL injection prevented
- [ ] XSS prevented
- [ ] Phone numbers unique across all users

#### Performance
- [ ] GPS updates every 5 seconds
- [ ] App launch < 3 seconds
- [ ] Lists load < 2 seconds
- [ ] No memory leaks observed

---

## Conclusion

This comprehensive testing guide covers all aspects of the ApoBasi platform. Follow these test cases systematically to ensure quality and reliability across all applications.

### Testing Priority

1. **Critical** (Must pass before release):
   - Phone number uniqueness bug fix
   - Authentication and authorization
   - GPS broadcasting and tracking
   - Attendance marking and sync
   - Data consistency

2. **High** (Should pass before release):
   - All CRUD operations
   - Real-time updates
   - Offline functionality
   - Error handling

3. **Medium** (Nice to have):
   - UI/UX polish
   - Performance optimizations
   - Edge case handling

4. **Low** (Can be addressed post-release):
   - Minor visual issues
   - Non-critical features
   - Future enhancements

---

**Document Version**: 1.0
**Last Updated**: 2026-01-19
**Maintained By**: ApoBasi Development Team

For questions or clarifications, contact the development team.
