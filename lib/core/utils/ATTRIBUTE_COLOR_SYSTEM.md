# Attribute Color System - Centralized Implementation

## Overview

The attribute color system provides consistent color coding for tasks throughout the app based on which attribute they contribute to (Wisdom, Confidence, Strength, Discipline, Focus).

## Architecture

### Central Utility: `AttributeUtils`
**Location:** `lib/core/utils/attribute_utils.dart`

Provides centralized methods for:
- `getAttributeColor(String attribute)` - Returns color for an attribute
- `getAttributeIcon(String attribute)` - Returns icon for an attribute
- `getAttributeGradient(String attribute)` - Returns gradient colors
- `determineAttribute(...)` - Fallback method to determine attribute from task properties

### Color Scheme

| Attribute | Color | Hex Code |
|-----------|-------|----------|
| Wisdom | Purple | `#9C27B0` |
| Confidence | Green | `#4CAF50` |
| Strength | Orange | `#FF9800` |
| Discipline | Blue | `#2196F3` |
| Focus | Teal | `#00BCD4` |

## Database Schema

### PresetTaskModel
- **Field:** `attribute` (String, optional)
- **Default:** "Focus" if not specified
- **Values:** "Wisdom", "Confidence", "Strength", "Discipline", "Focus"
- **Storage:** Stored in Firestore `preset_tasks` collection

### HabitModel
- **Field:** `attribute` (String?, nullable)
- **Default:** `null` (falls back to `AttributeUtils.determineAttribute()`)
- **Storage:** Stored in Firestore `users/{userId}/habits` collection

## Usage

### In UI Components

```dart
import '../../../../core/utils/attribute_utils.dart';

// Get attribute from model (database) or determine it
final attribute = habit.attribute ?? AttributeUtils.determineAttribute(
  title: habit.title,
  description: habit.description,
  category: '',
);

// Get color
final color = AttributeUtils.getAttributeColor(attribute);

// Get gradient
final gradient = AttributeUtils.getAttributeGradient(attribute);
```

### Where It's Applied

1. **Select Preset Task Screen** (`select_preset_task_screen.dart`)
   - Task cards use attribute-based gradient colors
   - Colored vertical bar indicator on each card

2. **Daily Tasks Screen** (`daily_tasks_screen.dart`)
   - Task cards use attribute-based gradient colors
   - Colored vertical bar indicator on each card

3. **Task Detail Screen** (`task_detail_screen.dart`)
   - Task detail card uses attribute-based gradient background
   - Attribute name displayed with color indicator

4. **Rating Screen** (`rating_screen.dart`)
   - Attribute items use their respective colors
   - Attribute detail dialogs use attribute colors

## Data Flow

1. **Preset Tasks:**
   - Attributes are defined in `PresetTasksRepository._getDefaultPresetTasks()`
   - Stored in Firestore when tasks are seeded
   - Retrieved when loading preset tasks

2. **User Habits:**
   - When adding a preset task, attribute is copied from `PresetTaskModel` to `HabitModel`
   - Stored in Firestore with the habit
   - Retrieved when loading user habits

3. **Fallback:**
   - If attribute is missing, `AttributeUtils.determineAttribute()` is called
   - Uses title, description, and category to determine attribute
   - Ensures all tasks have colors even if database doesn't have attribute

## Benefits

1. **Consistency:** Same color scheme everywhere
2. **Maintainability:** Single source of truth for colors
3. **Flexibility:** Easy to change colors globally
4. **Backward Compatibility:** Fallback ensures old tasks still work
5. **Database-Driven:** Attributes stored in database for persistence

## Migration

For existing tasks without attributes:
- They will automatically use `AttributeUtils.determineAttribute()` as fallback
- Colors will still be applied correctly
- No data migration required

To add attributes to existing tasks:
- Update tasks in Firestore with `attribute` field
- Or rely on fallback determination (automatic)

