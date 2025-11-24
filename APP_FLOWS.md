# Application Flows Documentation

This document outlines the primary user flows within the Reclaim application.

## 1. Authentication Flow
**Entry Point:** `SignInScreen` (`/sign_in`)

*   **Sign In**:
    *   User is presented with sign-in options (Email, Google, Apple).
    *   **Success**:
        *   If user data exists & onboarding is complete -> Navigate to `HomeScreen`.
        *   If user data exists but onboarding incomplete -> Navigate to `OnboardingScreen` (resuming from last step).
        *   If new user -> Navigate to `OnboardingScreen`.
    *   **Failure**: Show error message.

## 2. Onboarding Flow
**Entry Point:** `OnboardingScreen` (`/onboarding`)

A comprehensive 50-step process to personalize the user experience.

*   **Steps**:
    1.  **Welcome**: Introduction to the app.
    2.  **Identity**: Name, Age, Gender, Character Selection (Hero/Villain archetype).
    3.  **Life Context**: Life description, current feelings, motivation ("Journey Drive").
    4.  **Habits Assessment**: Identify "Dark Habits" (bad habits) and current good habits (Wake up, Water, Exercise, Meditation, Reading, etc.).
    5.  **Self-Reflection**: Value assessment (hourly value), distraction hours, current self-rating vs. potential rating.
    6.  **Goal Setting**: Select primary goal, commitment level, "Hard Mode" toggle.
    7.  **Configuration**: Notification settings, Milestone selection (duration).
    8.  **Education**: Science-backed plan explanation, progressive difficulty, core habits introduction.
    9.  **Gamification**: RPG game explanation, penalty system, real stories/testimonials.
    10. **Commitment**: "Mission Awaken", Vow questions, Program Overview & Preview.
    11. **Customization**: Extra tasks selection, Program customization.
    12. **Finalization**: Subscription offer (optional), Referral code, Final Truths, "Lock In" commitment.
    13. **Completion**: Final review -> Navigate to `HomeScreen`.

## 3. Home / Daily Tasks Flow
**Entry Point:** `HomeScreen` (Tab 0: `DailyTasksScreen`)

*   **View Tasks**:
    *   Displays tasks for the selected date.
    *   **Header**: Shows current streak, achievements count, success rate, day counter, and motivational message.
    *   **Filters**: Toggle between "To-dos", "Done", and "Skipped".
*   **Task Interaction**:
    *   **Tap Task**: Opens `TaskDetailScreen` to view details, instructions, and benefits.
    *   **Mark Complete**: Inside `TaskDetailScreen`, user can mark task as done (optionally requiring proof).
*   **Navigation**:
    *   **Date Navigation**: Arrows to change days or tap "Day X" to open date picker.
    *   **Add Task**: "+" button opens `SelectPresetTaskScreen` to add new custom or preset tasks.
    *   **Stats**: Tap streak/achievement icons to navigate to respective screens (`StreaksScreen`, `AchievementsScreen`, `RatingScreen`).
    *   **Settings**: Gear icon opens `SettingsScreen`.

## 4. Progress Tracking Flow
**Entry Point:** `HomeScreen` (Tab 1: `ProgressScreen`)

*   **Overview**:
    *   Displays "Days Active" and "Progress %" with a dynamic status header (e.g., "GOOD", "EXCELLENT").
    *   Shows a timer indicating time since journey start.
*   **Improvements**:
    *   Lists habits/tasks categorized by type (Sleep, Water, Exercise, etc.).
    *   **Category Tabs**: Filter improvements by category.
    *   **Improvement Card**: Shows habit title, attribute (Wisdom, Strength, etc.), and a motivational quote.
*   **Procrastination**:
    *   "I'm procrastinating" button (if tasks are incomplete) -> Likely triggers a motivational intervention or "Hard Mode" prompt.

## 5. Journey / Timeline Flow
**Entry Point:** `HomeScreen` (Tab 2: `JourneyTimelineScreen`)

*   **Timeline View**:
    *   Visualizes the user's journey as a timeline of days/milestones.
    *   Shows past progress and future milestones.

## 6. Community Flow
**Entry Point:** `HomeScreen` (Tab 3: `CommunityScreen`)

*   **Social Feed**:
    *   View updates and progress from friends or the global community.
    *   Interact with posts (like, comment).

## 7. Profile Flow
**Entry Point:** `HomeScreen` (Tab 4: `ProfileScreen`)

*   **User Profile**:
    *   Displays user details (avatar, name, stats).
    *   Access to account settings, subscription management, and personal data.

## 8. Tools & Features Flow
**Entry Point:** `HomeScreen` (Tab 5: `ToolsScreen`)

A hub for additional utility features.

*   **Available Tools**:
    *   **Meditation**: Guided sessions.
    *   **Book Summary**: Key insights.
    *   **Screen Blocker**: App usage control.
    *   **Pomodoro**: Focus timer.
    *   **Workout Counter**: Manual workout tracking.
    *   **Project Planner**: AI-assisted project planning.
    *   **Workout Preferences**: Personalized fitness plan setup.
*   **Tool Actions**:
    *   **Project Planner**: Tapping opens `CreateProjectScreen`.
        *   **Input**: Title, Description, Category, Start Date, End Date/Duration, Hours/Day.
        *   **Action**: "Generate Plan" (currently disabled/manual) -> `ReviewPlanScreen`.
    *   **Workout Preferences**: Tapping opens `AiWorkoutScreen`.
        *   **Input**: Goal, Fitness Level, Equipment, Schedule, Focus Areas, etc.
        *   **Action**: "Save Preferences" -> Saves to Firestore.
    *   **Suggest Tool**: Option to suggest new features via email.

## 9. Project Creation Flow
**Entry Point:** `CreateProjectScreen` (via Tools)

*   **Setup**:
    1.  Enter Project Title & Description.
    2.  Select Category (Learning, Fitness, etc.).
    3.  Set Start Date.
    4.  Set End Date OR Duration (days).
    5.  Set Daily Commitment (Hours per day).
*   **Generation**:
    *   Tap "Generate Plan".
    *   (Note: AI generation is currently disabled; placeholder for manual or future implementation).
    *   On success -> Navigate to `ReviewPlanScreen`.

## 10. Workout Preferences Flow
**Entry Point:** `AiWorkoutScreen` (via Tools)

*   **Preferences Form**:
    1.  **Goals & Fitness**: Goal type, Fitness level, Activity level, Experience.
    2.  **Schedule**: Days/week, Minutes/session, Duration (weeks), Time of day.
    3.  **Equipment & Focus**: Available equipment, Body focus areas, Intensity.
    4.  **Personalization**: Injuries/Constraints, Additional notes.
*   **Save**:
    *   Tap "Save Preferences".
    *   Data is validated and saved to Firestore (`users/{uid}/workout/requirements`).
    *   Show success message.
