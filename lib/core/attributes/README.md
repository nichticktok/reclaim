# Attribute Calculator System

## Overview

The Attribute Calculator converts raw user metrics (tasks completed, streaks, exercise time, etc.) into normalized attribute scores (Wisdom, Confidence, Strength, Discipline, Focus) ranging from 0-100.

## Architecture

```
lib/core/attributes/
├── attribute_calculator.dart    # Core calculation engine
├── attribute_config.dart        # Configuration (caps, weights)
├── attribute_service.dart       # Service layer (data integration)
└── README.md                    # This file
```

## Usage

### Basic Usage

```dart
import 'package:recalim/core/attributes/attribute_calculator.dart';

// Create calculator with default config
final calculator = AttributeCalculator();

// Calculate attributes from metrics
final metrics = {
  'tasksCompleted': 100.0,
  'currentStreak': 10.0,
  'workoutMinutes': 500.0,
  'meditationMinutes': 200.0,
  'readingMinutes': 300.0,
  'taskCompletionRate': 0.8,
  'consistencyScore': 0.7,
};

final attributes = calculator.calculate(metrics);
// Returns: {'wisdom': 65.2, 'confidence': 58.3, ...}
```

### Using AttributeService (Recommended)

```dart
import 'package:recalim/core/attributes/attribute_service.dart';

final service = AttributeService();

// Calculate from current user data
final attributes = await service.calculateUserAttributes();

// Update Firestore with calculated ratings
await service.updateUserRatings();
```

### Custom Configuration

```dart
import 'package:recalim/core/attributes/attribute_config.dart';
import 'package:recalim/core/attributes/attribute_calculator.dart';

// Create custom config
final config = AttributeConfig(
  metricCaps: {
    'tasksCompleted': 500.0,  // Lower cap for testing
  },
  attributeWeights: {
    'wisdom': {
      'readingMinutes': 0.5,
      'meditationMinutes': 0.5,
    },
  },
);

final calculator = AttributeCalculator(config: config);
```

## Input Metrics

### Required Metrics

| Metric | Type | Description | Default Cap |
|--------|------|-------------|-------------|
| `tasksCompleted` | double | Total tasks completed | 1000 |
| `currentStreak` | double | Current consecutive day streak | 365 |
| `longestStreak` | double | Longest streak achieved | 365 |
| `workoutMinutes` | double | Total workout/exercise minutes | 10000 |
| `meditationMinutes` | double | Total meditation minutes | 5000 |
| `readingMinutes` | double | Total reading/learning minutes | 5000 |
| `sleepQuality` | double | Average sleep quality (0-100) | 100 |
| `taskCompletionRate` | double | Daily task completion rate (0-1) | 1.0 |
| `consistencyScore` | double | Consistency metric (0-1) | 1.0 |
| `proofSubmitted` | double | Number of tasks with proof | 500 |

### Optional Metrics

| Metric | Type | Description | Default Cap |
|--------|------|-------------|-------------|
| `socialInteractions` | double | Social/community engagement | 1000 |
| `reflectionCount` | double | Number of reflections completed | 500 |
| `achievementsUnlocked` | double | Number of achievements unlocked | 100 |

## Output Attributes

All attributes are normalized to 0-100 range:

- **Wisdom** - Knowledge, learning, reflection
- **Confidence** - Self-assurance, social engagement
- **Strength** - Physical fitness, endurance
- **Discipline** - Consistency, commitment, follow-through
- **Focus** - Concentration, task completion, attention

## Attribute Formulas

Each attribute is calculated using a weighted average of normalized metrics:

```
attribute = Σ(metric_value * weight) / Σ(weights) * 100
```

### Default Weights

**Wisdom:**
- readingMinutes: 30%
- meditationMinutes: 25%
- reflectionCount: 20%
- tasksCompleted: 15%
- achievementsUnlocked: 10%

**Confidence:**
- socialInteractions: 30%
- achievementsUnlocked: 25%
- currentStreak: 20%
- taskCompletionRate: 15%
- reflectionCount: 10%

**Strength:**
- workoutMinutes: 40%
- currentStreak: 25%
- proofSubmitted: 20%
- consistencyScore: 15%

**Discipline:**
- currentStreak: 30%
- longestStreak: 25%
- consistencyScore: 25%
- taskCompletionRate: 20%

**Focus:**
- taskCompletionRate: 30%
- meditationMinutes: 25%
- consistencyScore: 25%
- tasksCompleted: 20%

## Normalization

All metrics are normalized to 0-1 range using caps:

```dart
normalized = min(value / cap, 1.0)
```

Values exceeding caps are clamped to 1.0.

## Error Handling

- **Missing metrics:** Default to 0.0 (no contribution)
- **NaN values:** Treated as 0.0
- **Negative values:** Clamped to 0.0
- **Extreme values:** Clamped to metric cap
- **Empty input:** Returns baseline scores (40.0)

## Performance

- **Calculation time:** < 10ms for typical inputs
- **Thread-safe:** Yes (stateless, immutable config)
- **Memory:** Minimal (no caching required)

## Testing

Run tests with:

```bash
flutter test test/core/attributes/
```

Tests cover:
- Empty/missing inputs
- Invalid values (NaN, negative, infinite)
- Clamping behavior
- Consistency
- Custom configurations

## Tuning & Configuration

### Local Tuning

Modify `AttributeConfig.defaultConfig()` to adjust:
- Metric caps
- Attribute weights
- Baseline scores

### Remote Configuration (Future)

For A/B testing, load config from remote:

```dart
final remoteConfig = await fetchRemoteConfig();
final config = AttributeConfig.fromRemote(remoteConfig);
final calculator = AttributeCalculator(config: config);
```

## Integration Points

1. **Rating Screen** - Displays calculated attributes
2. **User Stats** - Updates ratings in Firestore
3. **Progress Tracking** - Triggers recalculation on metric changes

## Update Triggers

Attributes are recalculated:
- On-demand (when rating screen opens)
- After task completion
- After streak updates
- Daily (via background job, if implemented)

## Migration Notes

If metrics or caps change:
1. Update `AttributeConfig.defaultConfig()`
2. Update `AttributeService._collectMetrics()`
3. Update documentation
4. Consider migration script for existing users

## Future Enhancements

- [ ] Remote config support (Firebase Remote Config)
- [ ] A/B testing framework
- [ ] Historical attribute tracking
- [ ] Attribute trends and predictions
- [ ] Batch processing for analytics
- [ ] Caching for performance optimization

