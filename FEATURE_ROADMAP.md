# Reclaim App - Feature Roadmap

This document outlines the new features to be implemented based on the Life Reset app structure, adapted for Reclaim.

## ✅ Completed Features
- Basic onboarding flow (name, age, gender, etc.)
- Home screen with navigation
- Tasks/Daily habits screen
- Progress tracking (basic)
- Community feed
- Profile management
- Subscription controller structure

## 🚧 New Features to Implement

### 1. Enhanced Onboarding Flow
- [ ] **Welcome Intro Screen** (`onboarding_welcome_intro.dart`)
  - "Understanding more about your situation" message
  - "Let's start" button
  
- [ ] **Character Selection** (`onboarding_character_selection.dart`)
  - Male/Female anime-style character selection
  - Visual character preview
  
- [ ] **Goal Setting** (`onboarding_goal_setting.dart`)
  - Long-term goal selection
  - Hour value assessment ("If you're selling 1 hour of your life...")
  - Distraction hours tracking
  
- [ ] **Commitment Selection** (`onboarding_commitment.dart`)
  - Streak options: 7-day, 14-day, 30-day, 50-day
  - Show percentage of users choosing each option
  - Success rate information
  
- [ ] **Hard Mode Selection** (`onboarding_hard_mode.dart`)
  - Rules explanation:
    - Missed a day = Back to Day 1
    - Program can't be edited
    - Future days are hidden
    - Skip a task = Penalty
    - One day skip allowed
  
- [ ] **Notification Settings** (`onboarding_notifications.dart`)
  - Stay on track toggle
  - Daily ritual toggle
  - Weekly Recap toggle
  
- [ ] **Science-Backed Plan** (`onboarding_science_backed.dart`)
  - Research citations (Harvard, UCL, Atomic Habits)
  - 66-day habit formation explanation
  
- [ ] **Analysis Screen** (`onboarding_analysis.dart`)
  - "Analysing your current habits..." with progress bar
  - Show installs and program generated stats

### 2. Program Management
- [ ] **Program Overview** (`program_overview_screen.dart`)
  - 66-day calendar view
  - Week-based organization
  - Task list per week
  - Edit/Delete task functionality
  - "Plan preview" expandable section
  
- [ ] **Program Preview** (`program_preview_screen.dart`)
  - Full program schedule display
  - Grid view of habits across days
  - Customization options
  
- [ ] **Program Customization** (`program_customization_screen.dart`)
  - Edit task frequency
  - Adjust intensity
  - Modify schedule
  - Add custom tasks (max 2)

### 3. Progress & Rating System
- [ ] **Weekly Progress** (`weekly_progress_screen.dart`)
  - Week number and date range
  - Radar chart showing:
    - Overall
    - Focus
    - Wisdom
    - Strength
    - Discipline
    - Confidence
  - Motivational messages based on progress
  
- [ ] **Rating Screen** (`rating_screen.dart`)
  - Current Life Reset Rating
  - Category ratings with progress bars
  - Potential rating display
  - Improvement indicators (+X ▲)

### 4. Habits System
- [ ] **Core Habits Showcase** (`core_habits_screen.dart`)
  - Carousel of 8 core habits:
    1. Wake up early
    2. Drink water
    3. Run
    4. Gym (Resistance Training)
    5. Meditate
    6. Read
    7. Reduce screentime
    8. Cold shower
  - Benefits for each habit
  - Impact metrics (10-week projections)
  
- [ ] **Habit Detail Screen** (`habit_detail_screen.dart`)
  - Individual habit information
  - 3 benefit bullet points
  - Impact metrics with percentages
  - Scientific backing

### 5. Daily Journey
- [ ] **Daily Journey Screen** (`daily_journey_screen.dart`)
  - Day number (Day X/66)
  - Mood selection (happy, neutral, sad, etc.)
  - Today's tasks list
  - Journal entry
  - Achievement unlocks
  - Progress tracking

### 6. Mastery & Achievements
- [ ] **Mastery Screen** (`mastery_screen.dart`)
  - Rank system: Bronze V → Bronze I → Silver V → ... → Legend I
  - XP tracking
  - Level progression
  - Achievement badges
  - Top percentage display

### 7. Penalty System
- [ ] **Penalty System Screen** (`penalty_system_screen.dart`)
  - Rules explanation
  - Penalty quest generation
  - Quest completion interface
  - Reset warning

### 8. Subscription & Offers
- [ ] **Subscription Offer Screen** (`subscription_offer_screen.dart`)
  - Monthly/Yearly pricing
  - Feature showcase (4 overlapping phone screens)
  - Special offer countdown timer
  - Money-back guarantee
  - "Kickstart My Journey" button

### 9. Additional Screens
- [ ] **Potential Return Screen**
  - ROI calculation
  - Time saved calculation
  - Value proposition
  
- [ ] **Real Stories Screen**
  - User testimonials
  - Before/After comparisons
  - User progress stories
  
- [ ] **Lock In Screen**
  - "Are you ready to lock in?" prompt
  - Tap and hold interaction
  - Character illustration

## Technical Implementation Notes

### File Structure
All new features follow the Clean Architecture pattern:
```
features/
  ├── program/
  │   ├── presentation/
  │   │   ├── screens/
  │   │   └── controllers/
  │   ├── domain/
  │   │   ├── entities/
  │   │   └── repositories/
  │   └── data/
  │       ├── models/
  │       ├── datasources/
  │       └── repositories/
  ├── journey/
  ├── mastery/
  └── penalty/
```

### Controllers Created
- `ProgramController` - Program management
- `JourneyController` - Daily journey/reflection
- `MasteryController` - Rank and achievement system
- `PenaltyController` - Penalty quest system

### Next Steps
1. Implement domain entities for each feature
2. Create repository interfaces
3. Implement Firestore data sources
4. Build UI screens matching the design
5. Integrate with existing onboarding flow
6. Add routing for new screens

## Design Guidelines
- Dark theme (Color(0xFF0D0D0F) or similar)
- Orange accents for primary actions
- White text for readability
- Progress bars without "Step X of Y" text
- Consistent spacing and padding
- Rounded corners on cards and buttons

