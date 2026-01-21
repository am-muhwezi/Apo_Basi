# ApoBasi - School Bus Tracking Platform
## Comprehensive App Overview for UI/UX Design

---

## 📱 **App Ecosystem**

ApoBasi consists of **3 mobile applications**:
1. **ParentsApp** - For parents to track their children
2. **DriversandMinders** - For bus drivers and bus minders/attendants
3. **Admin Dashboard** (Web) - React-based admin panel

---

## 🎯 **Core Purpose**

**Problem:** Parents worry about their children's safety during school bus transportation.

**Solution:** ApoBasi provides real-time GPS tracking, attendance confirmation, and instant notifications for school bus journeys.

**Value Proposition:** "Safe journeys, happy parents"

---

## 👥 **User Types & Their Needs**

### **1. Parents** (Primary Focus)
**Goals:**
- Know when the bus is coming to pick up/drop off their child
- Confirm child was picked up and dropped off safely
- See real-time bus location on map
- Get instant notifications for trip events
- View child's attendance history

**Pain Points:**
- Anxiety about child safety during transit
- Uncertainty about bus arrival times
- Lack of visibility into daily transportation

**Key Screens:**
1. Login (Email magic link)
2. Dashboard (Children overview, active trips)
3. Live Bus Tracking Map
4. Child Detail (Bus info, attendance, contact details)
5. Notifications Center
6. Profile & Settings

---

### **2. Bus Drivers**
**Goals:**
- Start/end trips easily
- Mark children as picked up/dropped off
- View assigned route and children
- Navigate route efficiently
- Communicate delays

**Key Screens:**
1. Login
2. Dashboard (Today's trips)
3. Active Trip (Route map, child list)
4. Child Pickup/Dropoff Confirmation
5. Profile

---

### **3. Bus Minders/Attendants**
**Goals:**
- Assist driver with attendance
- Mark children attendance
- Ensure all children are accounted for
- Contact parents if needed

**Key Screens:**
1. Login
2. Dashboard
3. Attendance Marking
4. Child List
5. Profile

---

## 🎨 **Brand Identity**

### **Colors (Adaptive Safety Palette)**
```
Primary (Trust Blue):   #2B5CE6 (Light) / #5B7FE8 (Dark)
Secondary (Success):    #34C759 (Green)
Accent (Attention):     #FF9500 (Orange)
Error/Alert:            #FF3B30 (Red)
Warning:                #FFCC02 (Yellow)

Backgrounds:
Light Mode:             #FAFAFA (Background) / #FFFFFF (Surface)
Dark Mode:              #000000 (Background) / #1C1C1E (Surface)

Text:
Primary:                #1C1C1E (Light) / #FFFFFF (Dark)
Secondary:              #8E8E93 (Gray)
```

### **Typography**
- **Font Family:** Inter (Google Fonts)
- **Headings:** 28-34pt, Bold (700)
- **Body:** 15-17pt, Regular (400) / Medium (500)
- **Captions:** 12-13pt, Medium (500)

### **Design Principles**
1. **Clean & Spacious** - Ample white space, breathing room
2. **Safety First** - Clear visual hierarchy, prominent CTAs
3. **Apple HIG Compliant** - 44pt minimum touch targets, iOS standards
4. **Purposeful Color** - Blue (trust), Green (safe), Red (alert), Orange (attention)
5. **Material Design 3** - For Android consistency

---

## 📐 **ParentsApp - Screen Structure**

### **1. Login Screen (Current Focus)**
**Purpose:** Passwordless authentication via email magic link

**Elements:**
- ApoBasi logo (use: `assets/AB_no_bg_logo.png`)
- App name + tagline: "Safe journeys, happy parents"
- Email input field
- "Send Magic Link" button
- Success state: Email sent confirmation

**Flow:**
1. User enters email
2. System checks if email is registered
3. If registered → Send magic link → Show success
4. User clicks link in email → Auto-login → Dashboard
5. If not registered → Error: "Contact school administrator"

**Design References:** Uber, Airbnb (clean, minimal, one action)

---

### **2. Parent Dashboard**
**Purpose:** Overview of all children and active trips

**Elements:**
- Header: "Welcome, [Parent Name]" + Profile icon
- Active Trip Banner (if bus is on route)
  - Child name + photo
  - "Bus is [X] minutes away"
  - Bus number, driver info
  - "Track Live" CTA button
- Children Cards (for each child)
  - Child name + photo + grade
  - Bus number + status
  - Last attendance: "Picked up at 7:30 AM"
  - Quick actions: Track, View Details
- Bottom Navigation:
  - Home (active)
  - Notifications
  - Profile

**Status Indicators:**
- 🟢 Green: Safe / On time
- 🟡 Yellow: Delayed / Approaching
- 🔴 Red: Emergency / Issue
- ⚪ Gray: Not started

---

### **3. Live Bus Tracking Map**
**Purpose:** Real-time GPS tracking of child's bus

**Elements:**
- Full-screen map (Mapbox)
- Bus marker (moving icon with direction)
- Child's pickup/dropoff points
- Route polyline
- Bottom Sheet (Uber-style):
  - Child name + bus number
  - ETA: "Arriving in 5 minutes"
  - Current status: "On route to school"
  - Driver info: Name, phone
  - Minder info: Name, phone
  - Action buttons: Call Driver, Call Minder
- Back button to Dashboard

**Real-time Updates:**
- Bus location updates every 5 seconds via WebSocket
- ETA recalculates based on traffic
- Notifications for proximity: "Bus is 2 stops away"

---

### **4. Child Detail Screen**
**Purpose:** Detailed information about specific child

**Elements:**
- Header: Child name + photo
- Info Cards:
  - Bus Assignment
    - Bus number + photo
    - Driver name + phone
    - Minder name + phone
  - School Info
    - Grade, class, student ID
  - Pickup/Dropoff Locations
    - Home address
    - School address
  - Attendance History
    - Calendar view
    - List of past trips with timestamps
- Actions:
  - Track Live (if trip active)
  - Call Driver
  - Call Minder
  - Update Info

---

### **5. Notifications Center**
**Purpose:** All notifications and alerts

**Elements:**
- Header: "Notifications" + Clear all
- Notification Types:
  - 🚌 Trip Started: "[Child] pickup trip has started"
  - ✅ Picked Up: "[Child] was picked up at 7:30 AM"
  - 🏫 Arrived: "[Child] reached school safely"
  - 🏠 Dropped Off: "[Child] was dropped off at 3:45 PM"
  - ⚠️ Delays: "Bus [#] is delayed by 10 minutes"
  - 🚨 Emergencies: "Emergency alert for Bus [#]"
- Each notification:
  - Icon + color coded by type
  - Timestamp
  - Expandable for details
  - Mark as read

---

### **6. Profile & Settings**
**Purpose:** Parent account management

**Elements:**
- Profile Header:
  - Parent name + email
  - Home location
- Settings Sections:
  - Children Information (list)
  - Notification Preferences
    - Push notifications ON/OFF
    - Email notifications ON/OFF
  - App Settings
    - Dark mode toggle
    - Language
  - Account
    - Update email
    - Privacy policy
    - Terms of service
  - Logout button (red)

---

## 📐 **DriversandMinders App - Screen Structure**

### **1. Login Screen**
Similar to ParentsApp but with:
- Different hero message: "Drive safely, track efficiently"
- Driver/Minder role selection (if applicable)

---

### **2. Driver Dashboard**
**Elements:**
- Today's Trips:
  - Morning Pickup Trip: 7:00 AM - 8:30 AM
  - Afternoon Dropoff Trip: 3:00 PM - 4:30 PM
- Trip Cards:
  - Route name
  - Start time
  - Number of children: "15 children assigned"
  - Status: Not Started / In Progress / Completed
  - Start Trip / End Trip CTA
- Bus Info:
  - Bus number, license plate
  - Minder assigned (if any)

---

### **3. Active Trip Screen**
**Purpose:** Manage trip in real-time

**Elements:**
- Top Bar:
  - Trip type: "Pickup Trip"
  - Timer: "Started 15 minutes ago"
  - End Trip button
- Map View:
  - Route polyline
  - Child pickup points (pins)
  - Current location (moving)
- Bottom Sheet:
  - Child List:
    - Each child card:
      - Name + photo + address
      - Status: ⚪ Pending / 🟢 Picked Up / 🔴 Absent
      - Tap to mark attendance
  - Mark All as Picked Up (batch action)
- Floating Action Button: Emergency Alert

---

### **4. Child Attendance Marking**
**Purpose:** Confirm pickup/dropoff

**Elements:**
- Child info: Name, photo, parent contact
- Status buttons:
  - ✅ Present (Green)
  - ❌ Absent (Red)
  - 📝 Notes field
- Timestamp: Auto-captured on mark
- Photo capture (optional): Take photo as proof
- Parent notification: Auto-sent on mark

---

## 🔄 **Key User Flows**

### **Parent Flow: Track Morning Pickup**
1. Login via magic link
2. See dashboard with "Bus approaching" banner
3. Tap "Track Live"
4. View real-time bus on map
5. Receive notification: "Child picked up at 7:30 AM"
6. Return to dashboard - card shows "On way to school"

---

### **Driver Flow: Morning Pickup Trip**
1. Login
2. Dashboard shows "Morning Pickup - Start at 7:00 AM"
3. Tap "Start Trip"
4. GPS tracking starts
5. Navigate to first pickup point
6. Arrive → Tap child card → Mark as "Picked Up"
7. Photo capture (optional)
8. Parent receives notification automatically
9. Continue to next pickup
10. After all pickups → Arrive at school
11. Tap "End Trip"
12. All parents notified: "Child arrived at school"

---

## 🛠️ **Technical Details**

### **Current Tech Stack**
- **Frontend:** Flutter (iOS & Android)
- **Backend:** Django REST + Django Channels (WebSocket)
- **Database:** PostgreSQL
- **Real-time:** Redis + WebSocket
- **Maps:** Mapbox
- **Authentication:** Supabase (Email magic links)
- **Push Notifications:** Firebase Cloud Messaging

### **Key Features Implemented**
✅ Email magic link authentication
✅ Real-time GPS tracking via WebSocket
✅ Push notifications
✅ Role-based access (Parent, Driver, Minder)
✅ Attendance marking
✅ Trip management
✅ Deep linking for magic links (iOS & Android)

---

## 📱 **Design References**

### **Apps to Reference:**
1. **Uber** - Clean login, live tracking, bottom sheets
2. **Airbnb** - Card-based layouts, imagery
3. **Apple Maps** - Map UI, smooth animations
4. **Slack** - Notifications center
5. **Robinhood** - Bold typography, spacious layouts

### **Key Design Patterns:**
- **Bottom Sheets** - For contextual actions over maps
- **Card-Based UI** - For children list, trips
- **Floating Action Buttons** - For primary actions
- **Status Badges** - Color-coded indicators
- **Pull-to-Refresh** - For dashboard updates
- **Skeleton Screens** - For loading states

---

## 🎯 **Design Priorities**

### **Must Have:**
1. **Trust & Safety** - Parents must feel confident
2. **Speed** - Load fast, update in real-time
3. **Clarity** - Clear status, no confusion
4. **Accessibility** - Large touch targets, high contrast
5. **Delightful** - Smooth animations, haptic feedback

### **Design for:**
- **Outdoor Use** - High contrast for sunlight
- **One-Handed Use** - Bottom navigation, reachable CTAs
- **Quick Glances** - Parents check app frequently for updates
- **Stress Situations** - Emergency alerts must be prominent

---

## 📊 **Metrics to Consider**

**Parent App:**
- Time to see "Child picked up" status: < 5 seconds
- Notification delivery: < 2 seconds
- Map load time: < 3 seconds
- Login success rate: > 95%

**Driver App:**
- Time to start trip: < 10 seconds
- Time to mark attendance per child: < 5 seconds
- GPS accuracy: < 10 meters

---

## 🚀 **For Uizard / AI Designer**

### **Prompt Template:**
```
Design a modern, clean mobile app for school bus tracking called "ApoBasi".

Target Users: Parents tracking their children's school bus in real-time.

Design Style:
- Uber-inspired: Clean, spacious, minimal
- Apple HIG compliant: 44pt touch targets
- Color scheme: Primary blue (#2B5CE6), success green (#34C759), white backgrounds
- Typography: Inter font, bold headings (34pt), body (17pt)

Key Screens to Design:
1. Login Screen - Email input with magic link
2. Parent Dashboard - Children cards, active trip banner
3. Live Tracking Map - Full map with bottom sheet (Uber-style)
4. Child Detail - Info cards, bus assignment, attendance
5. Notifications Center - List of alerts

Reference Apps: Uber (tracking), Airbnb (cards), Apple Maps (map UI)

Brand: Trust, safety, modern, friendly
```

---

## 📝 **Next Steps**

1. **Use Uizard/AI Designer** with this overview
2. **Generate wireframes** for all key screens
3. **Review & iterate** on designs
4. **Share designs** for implementation
5. **I'll implement** the approved designs in Flutter

---

## 📧 **Questions for Designer?**

- Should we add onboarding screens (tutorial)?
- Do we need empty states (no children, no trips)?
- Should map have day/night modes?
- Any gamification elements (streaks, badges)?
- Do we need parent-to-driver chat?

Let me know when you have the designs! 🎨
