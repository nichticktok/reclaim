# Attribute Calculator Contract

## Goals

Convert raw user metrics (tasks completed, streaks, exercise time, etc.) into normalized attribute scores (Wisdom, Confidence, Strength, Discipline, Focus) ranging from 0-100.

## Inputs

**Type:** `Map<String, double>`

**Required Metrics:**
- `tasksCompleted` - Total tasks completed (count)
- `currentStreak` - Current consecutive day streak (days)
- `longestStreak` - Longest streak achieved (days)
- `workoutMinutes` - Total workout/exercise minutes (minutes)
- `meditationMinutes` - Total meditation minutes (minutes)
- `readingMinutes` - Total reading/learning minutes (minutes)
- `sleepQuality` - Average sleep quality score (0-100)
- `taskCompletionRate` - Daily task completion rate (0-1)
- `consistencyScore` - Consistency metric (0-1)
- `proofSubmitted` - Number of tasks with proof submitted (count)

**Optional Metrics:**
- `socialInteractions` - Social/community engagement (count)
- `reflectionCount` - Number of reflections completed (count)
- `achievementsUnlocked` - Number of achievements unlocked (count)

## Outputs

**Type:** `Map<String, double>`

**Attributes (all normalized to 0-100):**
- `wisdom` - Knowledge, learning, reflection (0-100)
- `confidence` - Self-assurance, social engagement (0-100)
- `strength` - Physical fitness, endurance (0-100)
- `discipline` - Consistency, commitment, follow-through (0-100)
- `focus` - Concentration, task completion, attention (0-100)

## Ranges

- **Input metrics:** Can be any non-negative double value
- **Output attributes:** Always clamped to [0, 100]
- **Missing metrics:** Default to 0.0 (no contribution to attributes)

## Success Criteria

1. **Correctness:** All outputs are in [0, 100] range
2. **Consistency:** Same inputs always produce same outputs
3. **Sensitivity:** Small changes in metrics produce proportional changes in attributes
4. **Performance:** Calculation completes in < 10ms for typical inputs
5. **Robustness:** Handles missing, NaN, negative, and extreme values gracefully

## Error Modes & Invalid Data Behavior

### Missing Metrics
- **Behavior:** Default to 0.0
- **Impact:** Attribute receives no contribution from missing metric

### NaN Values
- **Behavior:** Treated as 0.0
- **Impact:** No contribution to attributes

### Negative Values
- **Behavior:** Clamped to 0.0
- **Impact:** No negative contribution

### Extreme Values (Outliers)
- **Behavior:** Clamped to metric cap (max expected value)
- **Impact:** Prevents single metric from dominating attribute

### Empty Input Map
- **Behavior:** All attributes return default baseline (e.g., 40)
- **Impact:** New users start with baseline scores

## Thread Safety

- **Read-only operations:** Thread-safe (immutable config)
- **Configuration changes:** Not thread-safe (should be set during initialization)
- **Calculation:** Thread-safe (stateless, pure function)

## Extensibility

- **New metrics:** Add to input map, update formulas
- **New attributes:** Add to output map, define formula
- **Weight tuning:** Change via configuration without code changes
- **Normalization changes:** Update caps and formulas independently

