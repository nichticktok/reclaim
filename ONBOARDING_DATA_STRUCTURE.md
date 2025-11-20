# Onboarding Data Structure

## Overview
All onboarding responses are now saved to Firebase in the `users/{userId}/onboardingData` field. This data is used to personalize the user experience throughout the app.

## Data Structure

The onboarding data is stored in Firestore under:
```
users/{userId}
  ├── onboardingData: {
  │     // Basic Info
  │     name: String
  │     ageGroup: String
  │     gender: String
  │     confirmedAge: int
  │     
  │     // Character & Identity
  │     character: String
  │     selectedCharacter: String
  │     lifeDescription: String
  │     mainCharacterFeeling: String
  │     
  │     // Motivation & Goals
  │     motivation: String
  │     selectedGoal: String
  │     commitmentLevel: String (days as string)
  │     
  │     // Habits & Lifestyle
  │     darkHabits: List<String>
  │     habitsData: {
  │       wake_up: String
  │       water: String
  │       exercise: String
  │       meditation: String
  │       reading: String
  │       social_media: String
  │       cold_shower: String
  │     }
  │     distractionHours: int
  │     
  │     // Values & Assessment
  │     hourlyValue: double
  │     currentRating: int
  │     potentialRating: int
  │     
  │     // Program Settings
  │     hardModeEnabled: bool
  │     notificationSettings: {
  │       "Stay on track": bool
  │       "Daily ritual": bool
  │       "Weekly Recap": bool
  │     }
  │     extraTasks: List<String>
  │     
  │     // Additional
  │     referCode: String?
  │     vowAnswers: {
  │       reflection_vow: bool
  │     }
  │     
  │     // Metadata
  │     onboardingStep: int
  │     lastUpdated: Timestamp
  │     completedAt: Timestamp
  │   }
  ├── onboardingStep: int
  ├── onboardingCompleted: bool
  └── updatedAt: Timestamp
```

## How to Use This Data

### 1. Accessing Onboarding Data

```dart
// Get user's onboarding data
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

final onboardingData = userDoc.data()?['onboardingData'] as Map<String, dynamic>?;

// Access specific fields
final userName = onboardingData?['name'] as String?;
final selectedGoal = onboardingData?['selectedGoal'] as String?;
final hardMode = onboardingData?['hardModeEnabled'] as bool?;
```

### 2. Personalizing User Experience

#### Example: Customize Program Based on Goals
```dart
final goal = onboardingData?['selectedGoal'] as String?;
if (goal == 'Financial Freedom') {
  // Show financial-focused habits
} else if (goal == 'Physical Health') {
  // Show fitness-focused habits
}
```

#### Example: Adjust Difficulty Based on Commitment
```dart
final commitmentDays = int.tryParse(onboardingData?['commitmentLevel'] ?? '7');
if (commitmentDays != null && commitmentDays >= 30) {
  // Show advanced program options
}
```

#### Example: Use Habit Baseline Data
```dart
final habitsData = onboardingData?['habitsData'] as Map<String, dynamic>?;
final currentWakeTime = habitsData?['wake_up'] as String?;
// Use this to set initial wake-up goal
```

#### Example: Apply Hard Mode Settings
```dart
final hardMode = onboardingData?['hardModeEnabled'] as bool?;
if (hardMode == true) {
  // Enable strict rules: no editing, reset on miss, etc.
}
```

#### Example: Configure Notifications
```dart
final notifications = onboardingData?['notificationSettings'] as Map<String, bool>?;
if (notifications?['Stay on track'] == true) {
  // Schedule daily reminder notifications
}
```

## Data Collection Points

### Screen-by-Screen Data Collection

1. **Name Screen** → `name`
2. **Age Selection** → `ageGroup`
3. **Gender Selection** → `gender`
4. **Character Selection** → `selectedCharacter`
5. **Character Confirmation** → `character`
6. **Life Description** → `lifeDescription`
7. **Confirm Age** → `confirmedAge`
8. **Main Character Feeling** → `mainCharacterFeeling`
9. **Journey Drive** → `motivation`
10. **Dark Habits** → `darkHabits` (List)
11. **Value Assessment** → `hourlyValue`
12. **Distraction Hours** → `distractionHours`
13. **Habits Questions** (7 screens) → `habitsData` (Map)
14. **Current Rating** → `currentRating`
15. **Potential Rating** → `potentialRating`
16. **Goal Setting** → `selectedGoal`
17. **Commitment** → `commitmentLevel`
18. **Hard Mode** → `hardModeEnabled`
19. **Notifications** → `notificationSettings`
20. **Extra Tasks** → `extraTasks`
21. **Refer Code** → `referCode`
22. **Vow Questions** → `vowAnswers`

## Implementation Details

### Saving Data
Data is automatically saved to Firebase:
- **During progress**: Every time user moves to next step (`_saveProgress()`)
- **On completion**: When onboarding is finished (`_markCompleted()`)

### Data Persistence
- All data is saved incrementally as user progresses
- If user exits and returns, data is preserved
- Final data is saved when onboarding completes

## Usage Examples

### Example 1: Create Personalized Program
```dart
Future<void> createPersonalizedProgram(String userId) async {
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
  
  final onboardingData = userDoc.data()?['onboardingData'] as Map<String, dynamic>?;
  
  final goal = onboardingData?['selectedGoal'] as String?;
  final habitsData = onboardingData?['habitsData'] as Map<String, dynamic>?;
  final hardMode = onboardingData?['hardModeEnabled'] as bool?;
  
  // Create program based on user's choices
  final program = {
    'goal': goal,
    'hardMode': hardMode ?? false,
    'baselineHabits': habitsData,
    'createdAt': FieldValue.serverTimestamp(),
  };
  
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('programs')
      .doc('current')
      .set(program);
}
```

### Example 2: Get User Preferences
```dart
class UserPreferences {
  final String? name;
  final String? goal;
  final bool hardMode;
  final Map<String, bool> notifications;
  
  static Future<UserPreferences> fromFirebase(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    final data = userDoc.data()?['onboardingData'] as Map<String, dynamic>?;
    
    return UserPreferences(
      name: data?['name'] as String?,
      goal: data?['selectedGoal'] as String?,
      hardMode: data?['hardModeEnabled'] as bool? ?? false,
      notifications: (data?['notificationSettings'] as Map?)?.cast<String, bool>() ?? {},
    );
  }
}
```

## Notes

- All data is saved incrementally, so partial progress is preserved
- Data structure is flexible - missing fields are handled gracefully
- Timestamps track when data was last updated and when onboarding completed
- This data can be used throughout the app for personalization

