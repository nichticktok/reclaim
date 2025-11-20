# Task System Implementation

## Overview
The task system has been completely refactored to use a database-driven approach with proof tracking and hard mode support.

## Key Features

### 1. **Database-Driven Tasks**
- All tasks are stored in Firestore: `users/{userId}/habits/{habitId}`
- No more hardcoded tasks
- Tasks persist across app sessions

### 2. **Proof Tracking**
- Each task tracks proofs per day (YYYY-MM-DD format)
- Proofs are stored in `proofs` map: `{ "2025-11-20": "proof text" }`
- Daily completion status tracked in `dailyCompletion` map

### 3. **Hard Mode Support**
- If hard mode is enabled: **ALL tasks require proof**
- If hard mode is disabled: Only tasks with `requiresProof: true` need proof
- Hard mode setting is loaded from onboarding data

### 4. **Default Tasks for New Users**
- Automatically creates tasks based on onboarding responses:
  - Wake up time (from `habitsData.wake_up`)
  - Water intake (from `habitsData.water`)
  - Exercise (from `habitsData.exercise`)
  - Meditation (from `habitsData.meditation`)
  - Reading (from `habitsData.reading`)
  - Extra tasks (from `extraTasks` array)

### 5. **Add Custom Tasks**
- Users can add their own tasks via the "+" button
- Tasks respect hard mode setting
- Tasks are saved to Firestore immediately

## Data Structure

### HabitModel (Task Model)
```dart
class HabitModel {
  String id;
  String title;
  String description;
  String scheduledTime;
  bool completed; // Today's completion status
  bool requiresProof; // Base proof requirement
  DateTime createdAt;
  DateTime? lastCompletedAt;
  
  // Proof tracking per day
  Map<String, String> proofs; // { "2025-11-20": "proof text" }
  Map<String, bool> dailyCompletion; // { "2025-11-20": true }
}
```

### Firestore Structure
```
users/{userId}/
  └── habits/ (subcollection)
      └── {habitId} (document)
          ├── id: string
          ├── title: string
          ├── description: string
          ├── scheduledTime: string
          ├── completed: boolean (today's status)
          ├── requiresProof: boolean
          ├── createdAt: timestamp
          ├── lastCompletedAt: timestamp
          ├── proofs: map
          │   └── "2025-11-20": "proof text"
          └── dailyCompletion: map
              └── "2025-11-20": true
```

## How It Works

### 1. Task Initialization
When a user first opens the tasks screen:
1. Controller checks if user has tasks
2. If no tasks exist, loads onboarding data
3. Creates default tasks based on onboarding responses
4. Applies hard mode setting to proof requirements

### 2. Proof Requirements
```dart
// In TasksController
bool isProofRequired(HabitModel habit) {
  return habit.isProofRequired(_hardModeEnabled ?? false);
}

// In HabitModel
bool isProofRequired(bool hardModeEnabled) {
  return hardModeEnabled || requiresProof;
}
```

**Logic:**
- If hard mode enabled → ALL tasks require proof
- If hard mode disabled → Only tasks with `requiresProof: true` need proof

### 3. Task Completion
- When user completes a task:
  1. Check if proof is required
  2. If yes → Show proof dialog
  3. If no → Mark as completed directly
  4. Save completion status for today
  5. Save proof (if provided) for today

### 4. Daily Reset
- Each day, tasks reset (not completed)
- Previous day's completion status is preserved
- Can view history via `dailyCompletion` map

## Usage Examples

### Get Today's Tasks
```dart
final controller = context.read<TasksController>();
await controller.initialize();
final tasks = controller.getFilteredHabits();
```

### Complete a Task
```dart
final habit = tasks[0];
if (controller.isProofRequired(habit)) {
  // Show proof dialog
  controller.submitProof(habit, "Proof text");
} else {
  // Complete directly
  controller.completeHabit(habit);
}
```

### Add a New Task
```dart
final newTask = HabitModel(
  id: '',
  title: 'Morning Run',
  description: '5km run',
  scheduledTime: '6:00 AM',
  requiresProof: false, // Will be overridden by hard mode if enabled
);

await controller.addHabit(newTask);
```

### Check if Task is Completed Today
```dart
final isCompleted = habit.isCompletedToday();
final todayProof = habit.getTodayProof();
```

## Default Tasks Created

Based on onboarding data:

1. **Wake Up** - Uses `habitsData.wake_up` time
   - Proof: Required if hard mode enabled

2. **Water** - Uses `habitsData.water` amount
   - Proof: Never required (hard mode doesn't override)

3. **Exercise** - Based on `habitsData.exercise`
   - Proof: Required if hard mode disabled (hard mode will override to true)

4. **Meditation** - Based on `habitsData.meditation`
   - Proof: Never required

5. **Reading** - Based on `habitsData.reading`
   - Proof: Required if hard mode disabled

6. **Extra Tasks** - From `extraTasks` array
   - Proof: Required if hard mode enabled

## Hard Mode Logic

```dart
// When hard mode is enabled
if (hardModeEnabled) {
  // ALL tasks require proof
  for (var task in allTasks) {
    task.requiresProof = true;
  }
}

// When checking if proof is needed
bool needsProof = hardModeEnabled || task.requiresProof;
```

## Migration Notes

- Old hardcoded tasks are removed
- New users get default tasks automatically
- Existing users keep their current tasks
- Proof tracking starts from implementation date

## Future Enhancements

- Task editing
- Task deletion
- Task reordering
- Task categories
- Recurring tasks
- Task templates
- Proof history viewer

