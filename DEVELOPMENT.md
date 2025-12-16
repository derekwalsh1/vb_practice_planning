# VB Practice Plan - Development Guide

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- iOS: Xcode 14+ and iOS 12+
- Android: Android Studio and API level 21+

### Installation

1. **Clone/Navigate to the project**
```bash
cd /Users/derek/Workspace/VBPracticePlan
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# iOS Simulator
flutter run

# Android Emulator
flutter run

# Specific device
flutter devices
flutter run -d <device-id>
```

## 📱 Platform Setup

### iOS Setup

1. **Open iOS project**
```bash
open ios/Runner.xcworkspace
```

2. **Set deployment target** (iOS 12.0+)
   - In Xcode, select Runner target
   - Set iOS Deployment Target to 12.0 or higher

3. **Update Info.plist** for file access
Already configured with necessary permissions.

### Android Setup

1. **Minimum SDK Version**: API 21 (Android 5.0)
2. **Target SDK Version**: API 34 (Android 14)

Permissions are automatically handled by the plugins.

## 🏗️ Project Architecture

### Directory Structure
```
lib/
├── models/              # Data models
│   ├── activity.dart           # Activity model with categories
│   ├── practice_plan.dart      # Practice plan model
│   └── scheduled_plan.dart     # Scheduled practice model
│
├── services/            # Business logic & data
│   ├── database_service.dart   # SQLite database operations
│   ├── activity_service.dart   # Activity CRUD with Provider
│   ├── practice_plan_service.dart  # Plan CRUD with Provider
│   ├── schedule_service.dart   # Schedule CRUD with Provider
│   └── import_export_service.dart  # JSON import/export
│
├── screens/             # UI screens
│   ├── home_screen.dart           # Main dashboard
│   ├── activities_screen.dart     # Activity library
│   ├── activity_form_screen.dart  # Add/edit activity
│   ├── plans_screen.dart          # Practice plans list
│   ├── plan_form_screen.dart      # Plan builder
│   ├── calendar_screen.dart       # Calendar view
│   ├── schedule_form_screen.dart  # Schedule picker
│   └── settings_screen.dart       # Settings & import/export
│
└── main.dart            # App entry point
```

### State Management
- **Provider**: Reactive state management
- **ChangeNotifier**: Services notify UI of data changes
- **Consumer/Provider.of**: Access services in widgets

### Database
- **SQLite** (sqflite): Local persistent storage
- **Tables**:
  - `activities`: Activity library
  - `practice_plans`: Practice plans
  - `plan_activities`: Junction table (many-to-many)
  - `scheduled_plans`: Scheduled practices

### Data Flow
1. User interacts with UI
2. UI calls service methods
3. Service updates database
4. Service calls `notifyListeners()`
5. UI automatically rebuilds with new data

## 🔑 Key Features Implementation

### Clone Functionality
```dart
// In PracticePlan model
PracticePlan clone({String? newName}) {
  return PracticePlan(
    id: const Uuid().v4(),  // New ID
    name: newName ?? '$name (Copy)',
    activities: activities.map((a) => a.copyWith()).toList(),
    // ... other fields
  );
}
```

### Import/Export
- JSON serialization with `toJson()` and `fromJson()`
- File picker for importing
- Share functionality for exporting
- Maintains data structure integrity

### Reorderable Activities
- `ReorderableListView` for drag-and-drop
- Maintains activity order in database via `position` field
- Real-time UI updates

## 📦 Dependencies

### Core
- **provider**: State management
- **sqflite**: Local database
- **path_provider**: File system access
- **uuid**: Generate unique IDs
- **intl**: Date/time formatting

### UI
- **table_calendar**: Calendar widget
- **flutter_slidable**: Swipe actions

### Import/Export
- **file_picker**: Select files
- **share_plus**: Share functionality

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Build Release
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🎨 Customization

### Theme
Edit `main.dart`:
```dart
theme: ThemeData(
  primarySwatch: Colors.orange,  // Change primary color
  // ... other theme properties
)
```

### Activity Categories
Edit `lib/models/activity.dart`:
```dart
class ActivityCategory {
  static const String newCategory = 'New Category';
  // Add to 'all' list
}
```

## 📊 Database Schema

### Activities Table
```sql
CREATE TABLE activities (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL,
  description TEXT NOT NULL,
  coaching_tips TEXT NOT NULL,
  category TEXT NOT NULL,
  created_date TEXT NOT NULL
)
```

### Practice Plans Table
```sql
CREATE TABLE practice_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  notes TEXT,
  created_date TEXT NOT NULL,
  last_modified_date TEXT
)
```

### Plan Activities Junction
```sql
CREATE TABLE plan_activities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id TEXT NOT NULL,
  activity_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  FOREIGN KEY (plan_id) REFERENCES practice_plans (id),
  FOREIGN KEY (activity_id) REFERENCES activities (id)
)
```

### Scheduled Plans Table
```sql
CREATE TABLE scheduled_plans (
  id TEXT PRIMARY KEY,
  practice_plan_id TEXT NOT NULL,
  scheduled_date TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  completed_date TEXT,
  notes TEXT,
  FOREIGN KEY (practice_plan_id) REFERENCES practice_plans (id)
)
```

## 🔄 Adding New Features

### Add a New Screen
1. Create file in `lib/screens/`
2. Add navigation in relevant screen
3. Update `MaterialApp` routes if needed

### Add a New Service
1. Create file in `lib/services/`
2. Extend `ChangeNotifier`
3. Add to providers in `main.dart`

### Add a New Model
1. Create file in `lib/models/`
2. Add `toJson()` and `fromJson()` methods
3. Add `toMap()` and `fromMap()` for database
4. Update `database_service.dart` if persistence needed

## 🐛 Common Issues

### Database Errors
- Delete app and reinstall for fresh database
- Check SQL syntax in `database_service.dart`

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### iOS Pod Issues
```bash
cd ios
pod deinstall
pod install
cd ..
flutter run
```

## 📱 App Screenshots & Testing

### Test Scenarios
1. Create 5-10 activities in different categories
2. Create 2-3 practice plans with multiple activities
3. Schedule plans on calendar
4. Export and import plans
5. Clone and modify a plan

## 🚢 Production Deployment

### Android
1. Generate keystore
2. Update `android/app/build.gradle`
3. `flutter build appbundle --release`
4. Upload to Google Play Console

### iOS
1. Set up provisioning profiles in Xcode
2. `flutter build ios --release`
3. Archive in Xcode
4. Upload to App Store Connect

## 📈 Future Enhancements

Potential features to add:
- [ ] Execution mode with timer
- [ ] Statistics and analytics
- [ ] Cloud sync (Firebase)
- [ ] Team/player management
- [ ] Video integration
- [ ] Print practice plans
- [ ] Share via QR code
- [ ] Template library
- [ ] Season planning

## 📄 License

This project is created for personal/educational use.

---

**Built with Flutter 💙 for Volleyball Coaches 🏐**
