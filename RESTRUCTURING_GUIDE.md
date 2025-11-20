# Project Restructuring Guide

## Overview
This project has been restructured to follow a **feature-first architecture** with clear separation of concerns:
- **Controllers**: Business logic and state management
- **Services**: Data operations and API calls
- **Models**: Data structures
- **Screens**: UI components
- **Widgets**: Reusable UI components

## New Structure

```
lib/
├── main.dart
├── core/                          # Shared utilities, constants, theme
│   ├── constants/
│   ├── errors/
│   ├── firebase/
│   ├── theme/
│   └── utils/
├── features/                      # Feature-based modules
│   ├── auth/
│   │   ├── controllers/
│   │   │   └── auth_controller.dart
│   │   ├── services/
│   │   ├── screens/
│   │   │   └── sign_in_screen.dart
│   │   └── widgets/
│   ├── home/
│   │   ├── controllers/
│   │   │   └── home_controller.dart
│   │   ├── services/
│   │   │   └── home_service.dart
│   │   └── screens/
│   │       └── home_screen.dart
│   ├── onboarding/
│   │   ├── controllers/
│   │   │   └── onboarding_controller.dart
│   │   ├── services/
│   │   │   └── onboarding_service.dart
│   │   └── screens/
│   │       └── (all onboarding screens)
│   ├── tasks/
│   │   ├── controllers/
│   │   │   └── tasks_controller.dart
│   │   └── services/
│   │       └── tasks_service.dart
│   ├── progress/
│   │   ├── controllers/
│   │   │   └── progress_controller.dart
│   │   └── services/
│   │       └── progress_service.dart
│   ├── profile/
│   │   ├── controllers/
│   │   │   └── profile_controller.dart
│   │   └── services/
│   │       └── profile_service.dart
│   ├── community/
│   │   ├── controllers/
│   │   │   └── community_controller.dart
│   │   └── services/
│   │       └── community_service.dart
│   └── reflection/
│       ├── controllers/
│       │   └── reflection_controller.dart
│       └── services/
│           └── reflection_service.dart
├── models/                        # Shared models
│   ├── habit_model.dart
│   ├── progress_model.dart
│   └── user_model.dart
├── providers/                     # Global providers
│   └── language_provider.dart
└── widgets/                       # Shared widgets
    ├── custom_button.dart
    ├── habit_card.dart
    └── ...
```

## Migration Steps

### 1. Update main.dart
Update imports to use the new feature structure:

```dart
// Old
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';

// New
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/screens/sign_in_screen.dart';
```

### 2. Move Onboarding Screens
Move all files from `lib/screens/onboarding/` to `lib/features/onboarding/screens/`:
- onboarding_age.dart
- onboarding_awakening.dart
- onboarding_character.dart
- ... (all other onboarding screens)

### 3. Update Onboarding Screen
Update `features/onboarding/screens/onboarding_screen.dart` to use the controller:

```dart
import 'package:provider/provider.dart';
import '../controllers/onboarding_controller.dart';

// Use Provider.of<OnboardingController>(context) or Consumer<OnboardingController>
```

### 4. Update Screen Imports
Update all screen files to use the new import paths:
- Update relative imports for widgets
- Update imports for models
- Update imports for other features

### 5. Update main.dart Provider Setup
Add providers for all controllers:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ChangeNotifierProvider(create: (_) => HomeController()),
    ChangeNotifierProvider(create: (_) => OnboardingController()),
    // ... other controllers
  ],
  child: const ReclaimApp(),
)
```

## Usage Examples

### Using a Controller in a Screen

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TasksController>(
      builder: (context, controller, child) {
        if (controller.loading) {
          return CircularProgressIndicator();
        }
        
        return ListView(
          children: controller.habits.map((habit) => 
            HabitCard(habit: habit)
          ).toList(),
        );
      },
    );
  }
}
```

### Using a Service Directly

```dart
final service = TasksService();
final habits = await service.loadHabits();
```

## Benefits

1. **Separation of Concerns**: UI, business logic, and data operations are clearly separated
2. **Testability**: Controllers and services can be easily unit tested
3. **Maintainability**: Related code is grouped together by feature
4. **Scalability**: Easy to add new features following the same pattern
5. **Reusability**: Services can be reused across different screens

## Next Steps

1. ✅ Controllers and services created
2. ⏳ Move onboarding screens to features/onboarding/screens
3. ⏳ Update all import paths
4. ⏳ Update main.dart to use new structure
5. ⏳ Test all features to ensure they work correctly
6. ⏳ Update any remaining screens to use controllers

