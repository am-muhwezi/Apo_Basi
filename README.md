# Apo Basi - Bus Tracking Mobile App

A comprehensive real-time bus tracking mobile application designed to provide parents with peace of mind by tracking their children's school bus location in real-time.

## Features

### For Parents
- **Real-time Bus Tracking**: Live GPS tracking of school buses
- **Multiple Children Support**: Track multiple children across different buses
- **Push Notifications**: Automatic alerts for bus arrival/departure
- **Route Information**: Complete bus route details and schedules
- **Emergency Contact**: Quick access to emergency services and school administration
- **Secure Authentication**: Safe and secure login system

### For Drivers
- **Simple Interface**: Easy-to-use location broadcasting
- **Route Management**: View assigned routes and stops
- **Emergency Alerts**: Quick emergency notification system
- **Navigation Support**: Built-in navigation assistance

## Architecture

This app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                 # Core functionality
│   ├── constants/        # App-wide constants
│   ├── di/              # Dependency injection
│   ├── services/        # Core services
│   ├── themes/          # App themes
│   └── utils/           # Utility functions
├── data/                # Data layer
│   ├── datasources/     # API and local data sources
│   ├── models/          # Data models
│   └── repositories/    # Repository implementations
├── domain/              # Business logic layer
│   ├── entities/        # Core business objects
│   ├── repositories/    # Repository interfaces
│   └── usecases/        # Business use cases
└── presentation/        # UI layer
    ├── blocs/           # State management (BLoC)
    ├── screens/         # App screens
    └── widgets/         # Reusable UI components
```

## Technology Stack

- **Framework**: Flutter 3.10+
- **State Management**: BLoC Pattern with flutter_bloc
- **Maps**: Google Maps
- **Real-time Communication**: WebSocket / Firebase
- **Push Notifications**: Firebase Cloud Messaging
- **Authentication**: Firebase Auth / Custom JWT
- **Local Storage**: Hive / SharedPreferences
- **Dependency Injection**: get_it + injectable

## Getting Started

### Prerequisites
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Google Maps API key (for maps functionality)
- Firebase project (for real-time features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/am-muhwezi/Apo_Basi.git
   cd Apo_Basi
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Maps**
   - Get a Google Maps API key from Google Cloud Console
   - Add the API key to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```

4. **Configure Firebase**
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication, Firestore, and Cloud Messaging

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

### Core Components

#### 1. Authentication System
- Secure login for parents and drivers
- Role-based access control
- Password reset functionality

#### 2. Real-time Tracking
- GPS location updates every 30 seconds
- WebSocket connections for live updates
- Efficient battery usage optimization

#### 3. Notification System
- Push notifications for bus events
- Customizable notification preferences
- Emergency alert system

#### 4. Maps Integration
- Interactive map with bus locations
- Route visualization
- Bus stop markers and information

## User Roles

### Parent Dashboard
- Welcome screen with quick overview
- Children management
- Live bus tracking map
- Bus status cards
- Quick action buttons
- Settings and preferences

### Driver Interface
- Simple start/stop tracking
- Route information
- Emergency alerts
- Basic navigation

## State Management

The app uses the **BLoC pattern** for state management:

- `AppBloc`: Global app state and authentication status
- `AuthBloc`: Authentication logic
- `BusTrackingBloc`: Real-time bus tracking data
- Additional BLoCs for specific features

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security Considerations

- All location data is encrypted in transit
- Parent-child relationships are verified
- Driver authorization and verification
- COPPA compliance for children's data
- Secure API endpoints with authentication

## Performance Optimization

- Efficient map rendering
- Location update throttling
- Image caching and optimization
- Network request optimization
- Battery usage minimization

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Run widget tests
flutter test test/widget_test
```

## Deployment

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions, please contact:
- Email: support@apobasi.com
- Issues: [GitHub Issues](https://github.com/am-muhwezi/Apo_Basi/issues)

## Changelog

### Version 1.0.0
- Initial release
- Basic bus tracking functionality
- Parent and driver interfaces
- Real-time location updates
- Push notifications
- Route management