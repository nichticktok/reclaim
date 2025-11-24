# Workout AI Assistant

## Overview

The Workout AI Assistant is an AI-powered feature that generates personalized workout plans based on user goals, fitness level, available equipment, and time constraints. Users provide their preferences, and the system generates a structured workout plan using Gemini AI.

## Architecture

### Data Models
- **WorkoutPlanModel**: Main workout plan entity with goal, level, duration, and workout days
- **WorkoutDayModel**: Individual workout sessions with scheduled dates and exercises
- **WorkoutExerciseModel**: Individual exercises with sets, reps, rest, and instructions

### Domain Layer
- **WorkoutPlanningInput**: Input entity for AI planning
- **WorkoutPlan**: AI-generated plan structure (weeks, sessions, exercises)
- **WorkoutRepository**: Abstract interface for workout data operations
- **AIWorkoutPlanningRepository**: Abstract interface for AI planning operations

### Data Layer
- **FirestoreWorkoutRepository**: Firestore implementation for workout CRUD operations
- **AIWorkoutPlanningService**: Gemini API integration for plan generation

### Presentation Layer
- **WorkoutsController**: State management for workouts
- **WorkoutSetupScreen**: Form to input workout preferences
- **ReviewWorkoutPlanScreen**: Review and confirm AI-generated plan
- **TodaysWorkoutScreen**: View and complete today's workout session

## Setup Instructions

### 1. Get Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Copy the API key

### 2. Configure API Key

Update `lib/features/workouts/data/services/ai_workout_planning_service.dart`:

```dart
static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

**For production**, use environment variables or secure storage instead of hardcoding.

## User Flow

1. **Setup Workout**: User fills form with:
   - Goal type (fat loss, strength, stamina, muscle build, general health)
   - Fitness level (beginner, intermediate, advanced)
   - Available equipment (bodyweight, dumbbells, resistance bands, gym)
   - Sessions per week
   - Minutes per session
   - Duration (weeks)
   - Constraints/injuries (optional)

2. **Generate Plan**: 
   - App calls Gemini API with workout preferences
   - AI generates week-by-week workout schedule
   - Plan is validated

3. **Review Plan**:
   - User sees generated weeks and sessions
   - Can review exercises for each session
   - Confirms to activate plan

4. **Today's Workout**:
   - View scheduled workout for today
   - See exercises with sets, reps, rest, and instructions
   - Mark workout as complete
   - Earn Strength + Discipline XP

## Data Structure

### Firestore Collections

```
users/{userId}/workout_plans/{planId}
  - goalType, fitnessLevel, durationWeeks
  - sessionsPerWeek, minutesPerSession
  - startDate, endDate, status
  - equipment, constraints
  
users/{userId}/workout_plans/{planId}/workout_days/{dayId}
  - weekNumber, dayLabel, scheduledDate
  - focus, isCompleted, completedAt
  
users/{userId}/workout_plans/{planId}/workout_days/{dayId}/exercises/{exerciseId}
  - name, sets, reps, restSeconds
  - instructions, equipment, intensityLevel
  - isCompleted
```

## Features

- ✅ AI-powered workout plan generation
- ✅ Personalized based on goal, level, and equipment
- ✅ Week-by-week progression
- ✅ Exercise instructions and form tips
- ✅ Scheduled workout sessions
- ✅ Completion tracking
- ✅ Integration with Strength/Discipline system

## Integration with Task System

Workout sessions can be integrated into the daily tasks system:
- Workout days appear in the task list on scheduled dates
- Completing workouts contributes to Strength and Discipline attributes
- Weekly completion bonuses for consistency

## Future Enhancements

- [ ] Mark individual exercises as complete
- [ ] Track sets/reps completed
- [ ] Progress photos
- [ ] Workout history and analytics
- [ ] Adjust plan based on performance
- [ ] Rest day recommendations
- [ ] Integration with daily tasks
- [ ] XP rewards for workout completion

## API Configuration

### Gemini API Endpoint
- URL: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent`
- Method: POST
- Authentication: API key in query parameter

### Request Format
```json
{
  "contents": [{
    "parts": [{"text": "prompt"}]
  }],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 4096
  }
}
```

### Response Format
The AI returns JSON with weeks, sessions, and exercises structure.

## Error Handling

- Input validation (sessions per week, minutes, duration)
- API error fallback to mock data (development)
- User-friendly error messages
- Graceful handling of missing active plans

## Testing

The service includes a mock plan generator for development/testing when:
- API key is not configured
- API call fails
- Network issues occur

This ensures the feature works even without API access during development.

