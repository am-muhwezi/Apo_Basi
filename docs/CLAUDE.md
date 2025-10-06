# CLAUDE.md

## Project Overview
AppBasi is a fullstack application with a React Native/Expo frontend and Django backend.

## Project Structure
- `client/` - React Native/Expo mobile application
- `server/` - Django backend API
- `.github/` - GitHub workflows and configuration

## Development Commands

### Client (React Native/Expo)
```bash
cd client
npm start              # Start Expo development server
npm run android        # Run on Android device/emulator
npm run ios           # Run on iOS device/simulator
npm run web           # Run in web browser
npm run lint          # Run ESLint
```

### Server (Django)
```bash
cd server
python manage.py runserver    # Start Django development server
python manage.py migrate      # Run database migrations
python manage.py test         # Run tests
```

## Testing
- Client: Uses Expo's built-in linting with `npm run lint`
- Server: Django's built-in test framework with `python manage.py test`

## Tech Stack
- **Frontend**: React Native, Expo Router, TypeScript
- **Backend**: Django (Python)
- **Mobile**: iOS/Android via Expo

## Key Dependencies
- React Navigation for routing
- React Hook Form for form handling
- Expo modules for device features
- React Native Reanimated for animations