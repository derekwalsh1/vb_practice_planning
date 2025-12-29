# Ace your Plans

A comprehensive Flutter app for volleyball coaches to create, manage, and execute practice plans with images.

## Features

### Core Functionality
- 📋 **Practice Plans** - Create, edit, and organize complete practice sessions
- 🏐 **Activity Library** - Build a reusable library of drills and activities
- ⏱️ **Practice Execution** - Run plans with built-in timer and activity progression
- 📤 **Import/Export** - Share plans and activities via JSON files
- 🔄 **Plan Management** - Clone, modify, and organize your coaching content

### Advanced Features
- 🎨 **Diagram Editor** - Visual volleyball court diagrams for each activity
  - Full court and half court views with 15% margin for off-court positioning
  - 8 drawing tools: Select, Circle, Square, Triangle, Line, Curve, Text, Label
  - Multiple colors and resizable elements
  - Normalized coordinate system for resolution independence
- ⏰ **Custom Activity Durations** - Override default activity times within plans
- 🏷️ **Tags & Focus** - Organize activities by skills, categories, and coaching focus
- 📊 **Groups** - Categorize plans by team, season, or training phase
- 📱 **iOS/iPad Support** - Native share dialog integration with proper positioning

## Technical Details

### Database
- SQLite with 7 schema versions
- Tables: `practice_plans`, `activities`, `plan_activities`, `groups`
- Support for custom activity durations and embedded JSON diagrams

### Architecture
- **Provider** for state management
- **Models**: Activity, PracticePlan, Diagram, Group
- **Services**: DatabaseService, ActivityService, PracticePlanService, ImportExportService
- **Widgets**: Custom DiagramPainter for volleyball court rendering

### Coordinate System
- Normalized (0-1) coordinates for diagram elements
- Resolution-independent rendering
- Court dimensions: 18m x 9m (1:2 aspect ratio for full court, 1:1 for half)
- 15% margin around courts for off-court element placement

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- iOS/macOS development environment (for iOS builds)

### Installation
```bash
# Clone the repository
git clone https://github.com/derekwalsh1/vb_practice_planning.git
cd vb_practice_planning

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Dependencies
- `provider: ^6.1.1` - State management
- `sqflite: ^2.3.0` - Local database
- `path_provider: ^2.1.1` - File system access
- `intl: ^0.18.1` - Date/time formatting
- `uuid: ^4.2.1` - Unique ID generation
- `share_plus: ^7.2.1` - Native sharing
- `file_picker: ^6.1.1` - File selection

## Project Structure

```
lib/
├── models/           # Data models (Activity, PracticePlan, Diagram, Group)
├── screens/          # UI screens
│   ├── activities_screen.dart        # Activity library
│   ├── activity_form_screen.dart     # Create/edit activities with diagrams
│   ├── diagram_editor_screen.dart    # Visual diagram editor
│   ├── plan_form_screen.dart         # Create/edit plans
│   ├── plan_execution_screen.dart    # Run practice with timer
│   └── settings_screen.dart          # Import/export settings
├── widgets/          # Reusable widgets
│   └── diagram_painter.dart          # Volleyball court renderer
├── services/         # Business logic
│   ├── database_service.dart         # SQLite operations
│   ├── activity_service.dart         # Activity CRUD
│   ├── practice_plan_service.dart    # Plan CRUD
│   └── import_export_service.dart    # JSON import/export
└── main.dart         # App entry point
```

## Database Schema

### Version 7 (Current)
- **practice_plans**: id, name, notes, group_id, created_date, last_modified_date, last_used_date
- **activities**: id, name, duration_minutes, description, coaching_tips, tags, focus, diagram, created_date, last_used_date
- **plan_activities**: plan_id, activity_id, position, custom_duration_minutes
- **groups**: id, name, color, created_date

## Usage

### Creating Activities
1. Navigate to Activities tab
2. Tap "New Activity" button
3. Fill in name, duration, description, tags, and coaching focus
4. Switch to Diagram tab to create visual drill diagram
5. Save activity

### Building Practice Plans
1. Navigate to Plans tab
2. Tap "New Plan" button
3. Add activities from your library
4. Customize activity durations by tapping duration badges
5. Organize with groups and add notes
6. Save plan

### Running Practice
1. Select a plan from Plans tab
2. Tap play button
3. Set start time
4. Navigate through activities with Next/Previous
5. View diagrams during execution with "View Drill Diagram" button
6. Complete practice to update last used dates

### Import/Export
- **Export**: Tap export icon on any screen (Activities, Plans, Settings)
- **Import**: Tap import icon, select JSON file
- **Duplicate Detection**: Importing skips activities/plans with matching IDs

## Known Issues & Future Enhancements
- App Store submission pending
- Consider adding video/image attachments to activities
- Potential for cloud sync across devices
- Print-friendly practice plan formatting

## License
Private project - All rights reserved

## Author
Derek Walsh
- GitHub: [@derekwalsh1](https://github.com/derekwalsh1)
- Repository: [vb_practice_planning](https://github.com/derekwalsh1/vb_practice_planning)
