# UI Design System Documentation

## Color Palette

### Primary Colors
- **Primary**: `#2E7D96` - Main brand color (teal blue)
- **Secondary**: `#4CAF50` - Success/active state (green)
- **Accent**: `#FF9800` - Warning/attention (orange)

### Status Colors
- **Success**: `#81C784` - Light green for positive states
- **Warning**: `#FFB74D` - Light orange for warnings
- **Error**: `#E57373` - Light red for errors

### Background Colors
- **Light Background**: `#F5F7FA` - Main background
- **Card Background**: `#FFFFFF` - Card/container background
- **Dark Background**: `#1A1A1A` - Dark theme main background
- **Dark Card**: `#2D2D2D` - Dark theme card background

### Text Colors
- **Primary Text**: `#2C3E50` - Main text color
- **Secondary Text**: `#7F8C8D` - Subtitle/secondary text
- **Light Text**: `#ECF0F1` - Text on dark backgrounds

## Typography

### Font Family
- **Primary**: Poppins
  - Regular (400)
  - Medium (500)
  - Semi-Bold (600)
  - Bold (700)

### Text Styles

#### Headers
- **Display Large**: 32px, Bold - Page titles
- **Display Medium**: 28px, Semi-Bold - Section headers
- **Headline Large**: 24px, Semi-Bold - Card titles
- **Headline Medium**: 20px, Medium - Subsection headers

#### Body Text
- **Body Large**: 16px, Regular - Main content
- **Body Medium**: 14px, Regular - Secondary content
- **Label Large**: 14px, Medium - Button labels, important labels

## Component Guidelines

### Buttons

#### Primary Button
- Background: Primary color (`#2E7D96`)
- Text: White
- Border Radius: 12px
- Padding: 16px horizontal, 12px vertical
- Elevation: 2dp

#### Secondary Button
- Border: Primary color outline
- Text: Primary color
- Background: Transparent
- Border Radius: 12px

#### Danger Button
- Background: Error color (`#E57373`)
- Text: White
- Use for destructive actions

### Cards
- Background: Card background color
- Border Radius: 12px
- Elevation: 4dp
- Padding: 16px
- Margin: 8px between cards

### Text Fields
- Border Radius: 12px
- Border: Outline color
- Focus Border: Primary color (2px width)
- Error Border: Error color (2px width)
- Padding: 16px horizontal, 16px vertical

### Navigation
- App Bar: Primary color background
- Drawer: White background with primary color accents
- Tab Bar: Primary color indicators

## Icons

### Icon Guidelines
- Use Material Icons for consistency
- Size: 24dp for standard icons, 20dp for small icons
- Color: Follow text color guidelines
- Consistent visual weight

### Key Icons
- **Bus**: `directions_bus` - Main app icon
- **Location**: `location_on` - Location markers
- **Family**: `family_restroom` - Children/family features
- **Notifications**: `notifications` - Alert system
- **Phone**: `phone` - Emergency contacts
- **Route**: `route` - Bus routes
- **Settings**: `settings` - App configuration

## Layout Guidelines

### Spacing System
- **Small**: 8dp - Between related elements
- **Medium**: 16dp - Between sections
- **Large**: 24dp - Between major components
- **Extra Large**: 32dp - Top-level spacing

### Grid System
- **Container Padding**: 16dp on mobile, 24dp on tablet
- **Card Margins**: 12dp between cards
- **List Item Height**: Minimum 56dp for touch targets

### Responsive Design
- **Mobile**: Single column layout
- **Tablet**: Adaptive layouts with more content per row
- **Landscape**: Horizontal layout optimizations

## Animation Guidelines

### Duration
- **Short**: 200ms - Small transitions
- **Medium**: 400ms - Screen transitions
- **Long**: 600ms - Complex animations

### Easing
- **Standard**: Ease-in-out for most transitions
- **Decelerate**: For incoming elements
- **Accelerate**: For outgoing elements

### Motion Principles
- Use consistent animation curves
- Provide visual feedback for user actions
- Keep animations subtle and purposeful
- Respect accessibility settings

## Accessibility

### Color Contrast
- Minimum 4.5:1 ratio for normal text
- Minimum 3:1 ratio for large text
- Test with color blindness simulators

### Touch Targets
- Minimum 44dp x 44dp for interactive elements
- Adequate spacing between touch targets
- Clear visual feedback for interactions

### Text Accessibility
- Scalable text sizes
- High contrast options
- Screen reader support

## Dark Theme

### Color Adaptations
- Use dark background colors
- Maintain sufficient contrast
- Adapt primary colors for dark backgrounds
- Use elevation and surface colors effectively

### Component Variations
- Cards: Dark card background with subtle elevation
- Text: Light text colors with appropriate opacity
- Icons: Light colored icons with consistent visual weight

## Implementation Notes

### Flutter Theme Configuration
```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  ),
  fontFamily: 'Poppins',
  // ... theme configurations
)
```

### Custom Widget Guidelines
- Follow Material Design 3 principles
- Maintain consistent styling across components
- Use theme colors instead of hardcoded values
- Implement proper state management for interactive elements