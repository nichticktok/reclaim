# New Features Structure - Summary

## Overview
Created placeholder files and structure for new features based on the Life Reset app design, adapted for Reclaim. All existing functionality remains intact.

## New Features Created

### 1. Program Management (`features/program/`)
**Screens:**
- `program_overview_screen.dart` - 66-day calendar with week-based tasks
- `program_preview_screen.dart` - Full program schedule preview
- `program_customization_screen.dart` - Task editing and customization

**Controllers:**
- `program_controller.dart` - Program management logic

**Repositories:**
- `program_repository.dart` (domain) - Abstract interface
- `firestore_program_repository.dart` (data) - Firestore implementation

### 2. Daily Journey (`features/journey/`)
**Screens:**
- `daily_journey_screen.dart` - Day X/66 with mood tracking and journal

**Controllers:**
- `journey_controller.dart` - Journey/reflection logic

**Repositories:**
- `journey_repository.dart` (domain) - Abstract interface
- `firestore_journey_repository.dart` (data) - Firestore implementation

### 3. Mastery System (`features/mastery/`)
**Screens:**
- `mastery_screen.dart` - Rank system (Bronze V to Legend I)

**Controllers:**
- `mastery_controller.dart` - Mastery/achievement logic

**Repositories:**
- `mastery_repository.dart` (domain) - Abstract interface
- `firestore_mastery_repository.dart` (data) - Firestore implementation

### 4. Penalty System (`features/penalty/`)
**Screens:**
- `penalty_system_screen.dart` - Penalty rules and quest interface

**Controllers:**
- `penalty_controller.dart` - Penalty quest logic

**Repositories:**
- `penalty_repository.dart` (domain) - Abstract interface
- `firestore_penalty_repository.dart` (data) - Firestore implementation

### 5. Enhanced Onboarding (`features/onboarding/presentation/screens/`)
**New Screens:**
- `onboarding_welcome_intro.dart` - Welcome message before onboarding
- `onboarding_character_selection.dart` - Character selection
- `onboarding_goal_setting.dart` - Goal and value assessment
- `onboarding_commitment.dart` - Streak commitment selection
- `onboarding_hard_mode.dart` - Hard mode selection
- `onboarding_notifications.dart` - Notification preferences
- `onboarding_science_backed.dart` - Science-backed plan explanation
- `onboarding_analysis.dart` - Analysis/loading screen

### 6. Habits System (`features/habits/`)
**Screens:**
- `core_habits_screen.dart` - 8 core habits showcase
- `habit_detail_screen.dart` - Individual habit details

### 7. Progress & Rating (`features/progress/presentation/screens/`)
**New Screens:**
- `weekly_progress_screen.dart` - Weekly progress with radar chart
- `rating_screen.dart` - Current and potential ratings

### 8. Subscription (`features/subscription/presentation/screens/`)
**New Screens:**
- `subscription_offer_screen.dart` - Enhanced subscription offer

## Controllers Added to DI
All new controllers have been added to `lib/app/di.dart`:
- `ProgramController`
- `JourneyController`
- `MasteryController`
- `PenaltyController`

## File Count
- Total Dart files in features: 83 files
- New placeholder files created: ~25 files

## Next Steps
1. Implement UI designs matching the reference images
2. Connect controllers to repositories
3. Implement Firestore data operations
4. Add routing for new screens
5. Integrate with existing onboarding flow
6. Add domain entities for each feature

## Design Guidelines
- Dark theme: `Color(0xFF0D0D0F)` or similar
- Orange accents for primary actions
- White text for readability
- Progress bars without "Step X of Y" text
- Consistent spacing and padding
- Rounded corners on cards and buttons

## Documentation
- `FEATURE_ROADMAP.md` - Detailed feature breakdown
- `NEW_FEATURES_SUMMARY.md` - This file

