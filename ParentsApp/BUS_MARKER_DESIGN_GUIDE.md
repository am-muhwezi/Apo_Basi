# Bus Marker Design Guide

This guide provides steps to create a custom yellow school bus marker for the live tracking feature.

## Current Implementation
- Uses the existing car.png image with a yellow color filter
- Yellow glow effect when moving
- LIVE badge and bus number display
- Located at: `lib/widgets/location/bus_marker_3d.dart`

## Steps to Create a Custom Bus Design

### Option 1: Using a Bus PNG Image (Recommended)

#### Step 1: Create or Find a Bus Image
1. **Option A - Design in a graphics tool:**
   - Use Figma, Adobe Illustrator, or Inkscape
   - Create a top-down view of a yellow school bus (512x512px)
   - Design elements:
     - Yellow/gold body (#FFD700)
     - Windows (blue tinted)
     - Black wheels
     - White headlights
     - Red tail lights
     - "SCHOOL BUS" text (optional)

2. **Option B - Use an existing icon:**
   - Search for "school bus top view icon" on:
     - https://flaticon.com
     - https://icons8.com
     - https://thenounproject.com
   - Look for yellow school bus in bird's eye view
   - Download in PNG format (512x512 or larger)

#### Step 2: Add to Project
```bash
# Save the bus image as:
ParentsApp/assets/images/bus.png
```

#### Step 3: Update the Widget
Edit `ParentsApp/lib/widgets/location/bus_marker_3d.dart`:

```dart
// Change line 77-84 from:
child: ColorFiltered(
  colorFilter: ColorFilter.mode(
    Color(0xFFFFD700), // Yellow color
    BlendMode.modulate,
  ),
  child: Image.asset(
    'assets/images/car.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
  ),
),

// To:
child: Image.asset(
  'assets/images/bus.png',  // Use bus image
  width: size,
  height: size,
  fit: BoxFit.contain,
),
```

#### Step 4: Test
```bash
cd ParentsApp
flutter clean
flutter pub get
flutter run
```

---

### Option 2: Using SVG for Scalability

#### Step 1: Create SVG Bus Icon
Create a file at `ParentsApp/assets/images/bus.svg` (already created in previous steps)

#### Step 2: Update the Widget
```dart
// Add import at top:
import 'package:flutter_svg/flutter_svg.dart';

// Change the car image section to:
child: SvgPicture.asset(
  'assets/images/bus.svg',
  width: size,
  height: size,
  fit: BoxFit.contain,
),
```

---

### Option 3: Custom Paint (Most Control)

For complete customization, use Flutter's CustomPaint widget.

#### Step 1: Create BusPainter Class
Add this class to `bus_marker_3d.dart`:

```dart
class BusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final busWidth = width * 0.7;
    final busHeight = height * 0.85;
    final left = (width - busWidth) / 2;
    final top = (height - busHeight) / 2;

    // Main bus body - yellow
    paint.color = Color(0xFFFFD700);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, busWidth, busHeight),
        Radius.circular(width * 0.08),
      ),
      paint,
    );

    // Add windows, wheels, lights, etc.
    // ... (see full implementation in git history)
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
```

#### Step 2: Use CustomPaint in Widget
```dart
child: CustomPaint(
  painter: BusPainter(),
  size: Size(size, size),
),
```

---

## Design Recommendations

### Color Scheme for School Bus
- **Body**: `#FFD700` (Gold) or `#FFBF00` (Amber)
- **Accents**: `#CC8800` (Dark Orange)
- **Windows**: `#87CEEB` (Sky Blue) with transparency
- **Wheels**: `#333333` (Dark Gray)
- **Highlights**: `#FFF8DC` (Cornsilk) for reflection effects

### Dimensions for Top-Down View
```
Bus proportions (relative to container):
- Body: 65-70% of container width
- Length: 80-85% of container height
- Windows: 15% height, 70% width (in rows)
- Wheels: 8-10% of width as radius
- Rounded corners: 6-8% of width
```

### Adding Details
1. **Front section**: Shorter, driver area
2. **Middle section**: Passenger windows (3-4 rows)
3. **Rear section**: Emergency door
4. **Side mirrors**: Small rectangles extending from sides
5. **Stop sign arm**: Red rectangle (optional, can animate)

---

## Testing Different Designs

### Quick Test Without Rebuilding
1. Replace `assets/images/bus.png` with your new design
2. Run `flutter run -r` (hot reload may work)
3. If not visible, run `flutter clean && flutter run`

### A/B Testing Multiple Designs
```dart
// In bus_marker_3d.dart, add a parameter:
final String? customBusImage;

// Use it:
child: Image.asset(
  customBusImage ?? 'assets/images/bus.png',
  ...
),
```

Then test different images:
```dart
BusMarker3D(
  customBusImage: 'assets/images/bus_variant_1.png',
  ...
)
```

---

## Resources

### Free Bus Icons
- **Flaticon**: https://www.flaticon.com/search?word=school%20bus
- **Icons8**: https://icons8.com/icons/set/school-bus
- **Noun Project**: https://thenounproject.com/search/?q=school+bus

### Design Tools
- **Figma** (Free): https://figma.com
- **Inkscape** (Free): https://inkscape.org
- **Adobe Illustrator** (Paid)

### Color Palette Tools
- **Coolors**: https://coolors.co
- **Adobe Color**: https://color.adobe.com

---

## Current File Structure

```
ParentsApp/
├── assets/
│   └── images/
│       ├── car.png          # Current blue car (used now)
│       ├── bus.svg          # Yellow bus SVG (created)
│       └── bus.png          # Add your custom bus here
├── lib/
│   └── widgets/
│       └── location/
│           └── bus_marker_3d.dart  # Main marker widget
```

---

## Quick Win: Use Emoji Bus 🚌

For rapid prototyping:

```dart
child: Text(
  '🚌',
  style: TextStyle(fontSize: size),
),
```

This gives you an instant bus icon while you design the custom one!

---

## Need Help?

If you want me to:
1. ✅ Create a specific bus design
2. ✅ Convert a reference image to a bus marker
3. ✅ Adjust colors or styling
4. ✅ Add animations (like flashing lights)

Just ask!
