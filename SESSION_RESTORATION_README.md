# Session Restoration Feature

## Overview

This feature implements comprehensive session restoration using SharedPreferences, ensuring that when the app is closed and reopened, it returns to the user's previous state, including:

- Last visited page/route
- Language preference
- Theme preference
- Page-specific data (text fields, settings, map state, etc.)

## Implementation Details

### 1. Session Provider (`lib/providers/session_provider.dart`)

A new Riverpod provider that manages session state:

- Tracks the last route visited
- Stores language preference
- Manages page-specific data across app restarts
- Automatically loads saved session on app startup

### 2. Main App Updates (`lib/main.dart`)

- Added `RouteObserver` class to track navigation changes
- Automatically saves the current route whenever the user navigates
- Restores locale and theme on app startup
- Routes to the last visited page (except splash/login screens)

### 3. Splash Screen (`lib/screens/splash_screen.dart`)

Enhanced to:

- Load saved language preference and update locale provider
- Load saved theme preference
- Navigate to the last visited route (if available)
- Falls back to login screen for first-time users

### 4. Settings Screen (`lib/screens/settings_screen.dart`)

Now includes:

- Language selection dropdown (Portuguese, English, Spanish, French, Chinese)
- Persists language choice to SharedPreferences
- Updates both locale provider and session provider
- Restores language preference on screen load

### 5. Home Screen (`lib/screens/home_screen.dart`)

Restores vital signs data:

- Heart rate (BPM)
- Blood oxygen level (SpO2)
- Geofence status (inside/outside)
- Last update timestamp
- Automatically saves data on each update

### 6. Profile Screen (`lib/screens/profile_screen.dart`)

Already implemented with SharedPreferences:

- Elder information (name, age, phone, email)
- Caregiver list
- All data persists across app restarts

### 7. Map Screen (`lib/screens/map_screen.dart`)

Enhanced with state persistence:

- Current position on map
- Update interval preference
- Map simulation continues from last known state

## Data Persistence Keys

### Session Management

- `last_route` - Last visited route/page
- `last_language` - Selected language code (pt, en, es, fr, zh)

### Home Screen

- `heart_rate` - Heart rate in BPM (int)
- `spo2` - Blood oxygen level percentage (int)
- `inside_geofence` - Whether inside safe zone (bool)
- `last_update` - ISO 8601 timestamp of last update (string)

### Profile Screen

- `elder_name` - Elder's name (string)
- `elder_age` - Elder's age (string)
- `elder_phone` - Elder's phone number (string)
- `elder_email` - Elder's email (string)
- `caregivers` - JSON encoded array of caregivers (string)

### Settings Screen

- `notifications` - Notifications enabled (bool)
- `darkTheme` - Dark theme enabled (bool)

### Map Screen

- `map_position_x` - X coordinate of position (double)
- `map_position_y` - Y coordinate of position (double)
- `map_interval` - Update interval in seconds (int)

## Usage

### For Users

1. **Language Persistence**: Change language in Settings screen - it will be restored on next app launch
2. **Page Restoration**: The app remembers which page you were on and returns you there
3. **Data Persistence**: All form data, settings, and state are automatically saved

### For Developers

#### To save a new piece of session data:

```dart
// In your screen/widget
import '../providers/session_provider.dart';

// Save data
ref.read(sessionProvider.notifier).savePageData('your_key', yourValue);

// Access saved data
final session = ref.watch(sessionProvider);
final savedValue = session.pageData['your_key'];
```

#### To save route automatically:

Routes are automatically saved by the `RouteObserver` in `main.dart`. Just use named routes:

```dart
Navigator.pushNamed(context, '/your_route');
```

#### To manually save additional data:

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('your_key', 'your_value');
```

## Benefits

1. **Improved User Experience**: Users don't lose their place when the app is closed
2. **Data Persistence**: Form data, settings, and preferences are preserved
3. **Language Continuity**: Language preference is maintained across sessions
4. **State Recovery**: App state (vital signs, map position, etc.) is restored
5. **Seamless Navigation**: Returns to the exact page the user was viewing

## Technical Notes

- Uses `shared_preferences` package for local storage
- Implements Riverpod for state management
- NavigatorObserver pattern for automatic route tracking
- ISO 8601 format for timestamp storage
- JSON encoding for complex data structures (like caregiver lists)

## Future Enhancements

Potential improvements:

1. Add video playback position restoration
2. Implement scroll position restoration for lists
3. Add form field focus restoration
4. Cache network data for offline access
5. Implement session expiration (e.g., 30 days)
6. Add ability to clear session data from settings

## Testing

To test the feature:

1. Open the app and navigate to any screen
2. Change the language in Settings
3. Fill out some data (e.g., in Profile screen)
4. Close the app completely
5. Reopen the app
6. Verify you're on the same screen with the same language and data

## Dependencies

- `flutter_riverpod: ^2.x.x` - State management
- `shared_preferences: ^2.x.x` - Local data persistence
- `google_fonts` - Typography
- `flutter_localizations` - Internationalization support
