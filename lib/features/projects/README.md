# Personal Project Planner (AI-Assisted)

## Overview

The Personal Project Planner is an AI-powered feature that helps users break down large goals into manageable phases and tasks. Users provide project details, deadline, and available time, and the system generates a structured plan using Gemini AI.

## Architecture

### Data Models
- **ProjectModel**: Main project entity with title, description, category, timeline, and milestones
- **MilestoneModel**: Project phases with start/end dates and tasks
- **ProjectTaskModel**: Individual tasks with estimated hours, due dates, and completion status

### Domain Layer
- **ProjectPlanningInput**: Input entity for AI planning
- **ProjectPlan**: AI-generated plan structure (phases and tasks)
- **ProjectRepository**: Abstract interface for project data operations
- **AIPlanningRepository**: Abstract interface for AI planning operations

### Data Layer
- **FirestoreProjectRepository**: Firestore implementation for project CRUD operations
- **AIPlanningService**: Gemini API integration for plan generation

### Presentation Layer
- **ProjectsController**: State management for projects
- **CreateProjectScreen**: Form to input project details
- **ReviewPlanScreen**: Review and confirm AI-generated plan
- **ProjectRoadmapScreen**: View project progress and milestones

## Setup Instructions

### 1. Get Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Copy the API key

### 2. Configure API Key

Update `lib/features/projects/data/services/ai_planning_service.dart`:

```dart
static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

**For production**, use environment variables or secure storage instead of hardcoding.

### 3. Alternative: Use ChatGPT

To switch to ChatGPT, create a new service class:

```dart
class ChatGPTPlanningService implements AIPlanningRepository {
  // Implement using OpenAI API
  // Same interface, different implementation
}
```

Then update `ProjectsController` to use the new service.

## User Flow

1. **Create Project**: User fills form with:
   - Project title
   - Description (optional)
   - Category
   - Start date
   - End date OR duration
   - Hours per day

2. **Generate Plan**: 
   - App calls Gemini API with project details
   - AI generates phases and tasks
   - Plan is validated against available time

3. **Review Plan**:
   - User sees generated phases and tasks
   - Can review estimated hours
   - Confirms to create project

4. **Project Roadmap**:
   - View project progress
   - See milestones and tasks
   - Mark tasks as complete
   - Track progress percentage

## Data Structure

### Firestore Collections

```
users/{userId}/projects/{projectId}
  - title, description, category
  - startDate, endDate
  - hoursPerDay, status
  
users/{userId}/projects/{projectId}/milestones/{milestoneId}
  - title, description, order
  - startDate, endDate
  
users/{userId}/projects/{projectId}/milestones/{milestoneId}/tasks/{taskId}
  - title, description
  - estimatedHours, dueDate
  - status, completedAt
```

## Features

- ✅ AI-powered plan generation
- ✅ Timeline validation
- ✅ Automatic task scheduling
- ✅ Progress tracking
- ✅ Milestone visualization
- ✅ Task completion tracking
- ✅ Overdue task detection

## Future Enhancements

- [ ] Edit generated plans before confirmation
- [ ] Adjust task estimates
- [ ] Add custom tasks to phases
- [ ] Project templates
- [ ] Integration with daily tasks
- [ ] XP rewards for project completion
- [ ] Project sharing
- [ ] Multiple active projects

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
    "maxOutputTokens": 2048
  }
}
```

### Response Format
The AI returns JSON with phases and tasks structure.

## Error Handling

- Timeline validation (minimum 1 day)
- Hours validation (must be > 0)
- Total hours validation (must fit timeline)
- API error fallback to mock data (development)
- User-friendly error messages

## Testing

The service includes a mock plan generator for development/testing when:
- API key is not configured
- API call fails
- Network issues occur

This ensures the feature works even without API access during development.

