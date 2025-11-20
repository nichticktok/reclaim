# Firestore Structure Recommendation

## Current Structure (Single Document)

**Current:**
```
users/{userId}
  ├── All user data in one document
  ├── onboardingData (nested map)
  ├── onboardingStep, onboardingCompleted
  ├── isGuest, createdAt, updatedAt, etc.
```

### Issues with Current Structure:
1. **Document Size Limit**: Firestore documents have a 1MB limit
2. **Query Limitations**: Can't efficiently query nested data
3. **Performance**: Loading entire document when you only need part
4. **Scalability**: As user data grows, document becomes unwieldy
5. **Atomic Updates**: All data must be updated together

## Recommended Structure (Separated Collections)

### Structure Overview:
```
users/{userId}
  ├── Basic profile data (lightweight)
  │
  ├── onboarding/ (subcollection)
  │   └── data (document)
  │       └── All onboarding responses
  │
  ├── programs/ (subcollection)
  │   └── current (document)
  │       └── Program data
  │
  ├── habits/ (subcollection)
  │   └── {habitId} (documents)
  │       └── Habit data
  │
  ├── mastery/ (subcollection)
  │   └── data (document)
  │       └── XP, rank, achievements
  │
  └── settings/ (subcollection)
      └── preferences (document)
          └── App settings
```

### Detailed Structure:

#### 1. User Profile (Main Document)
```javascript
users/{userId}
{
  // Basic Info (frequently accessed)
  uid: string
  email: string
  displayName: string
  photoURL: string
  
  // Status
  isGuest: boolean
  isPremium: boolean
  
  // Metadata
  createdAt: timestamp
  lastSeen: timestamp
  updatedAt: timestamp
  
  // Quick flags (for queries)
  onboardingCompleted: boolean
  hasActiveProgram: boolean
}
```

#### 2. Onboarding Data (Subcollection)
```javascript
users/{userId}/onboarding/data
{
  // Basic Info
  name: string
  ageGroup: string
  gender: string
  confirmedAge: number
  
  // Character & Identity
  character: string
  selectedCharacter: string
  lifeDescription: string
  mainCharacterFeeling: string
  
  // Motivation & Goals
  motivation: string
  selectedGoal: string
  commitmentLevel: string
  
  // Habits & Lifestyle
  darkHabits: array
  habitsData: map
  distractionHours: number
  
  // Values & Assessment
  hourlyValue: number
  currentRating: number
  potentialRating: number
  
  // Program Settings
  hardModeEnabled: boolean
  notificationSettings: map
  extraTasks: array
  
  // Additional
  referCode: string?
  vowAnswers: map
  
  // Metadata
  onboardingStep: number
  completedAt: timestamp
  createdAt: timestamp
  updatedAt: timestamp
}
```

#### 3. Programs (Subcollection)
```javascript
users/{userId}/programs/current
{
  startDate: timestamp
  currentDay: number
  totalDays: number
  hardMode: boolean
  // ... program data
}
```

#### 4. Habits (Subcollection)
```javascript
users/{userId}/habits/{habitId}
{
  name: string
  description: string
  // ... habit data
}
```

## Benefits of This Structure

### 1. **Scalability**
- No document size limits per collection
- Can grow independently
- Better for large datasets

### 2. **Query Performance**
- Query only what you need
- Can index specific fields
- Faster reads for partial data

### 3. **Data Organization**
- Logical separation of concerns
- Easier to maintain
- Clear data boundaries

### 4. **Flexibility**
- Update sections independently
- Add new data types easily
- Better for team collaboration

### 5. **Cost Optimization**
- Read only necessary data
- Smaller document reads = lower costs
- Better for Firestore billing

## Migration Strategy

### Step 1: Update Repository Methods
Move onboarding data to subcollection while maintaining backward compatibility.

### Step 2: Gradual Migration
- New users: Use new structure
- Existing users: Migrate on next access
- Keep old structure for compatibility

### Step 3: Cleanup
After all users migrated, remove old structure.

## Implementation Example

```dart
// Save onboarding data to subcollection
Future<void> saveOnboardingData(String userId, Map<String, dynamic> data) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('onboarding')
      .doc('data')
      .set({
    ...data,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  
  // Update main user document flag
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({
    'onboardingCompleted': true,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

// Read onboarding data
Future<Map<String, dynamic>?> getOnboardingData(String userId) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('onboarding')
      .doc('data')
      .get();
  
  return doc.data();
}
```

## Query Examples

### Get User Profile Only
```dart
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
// Only loads profile data, not onboarding
```

### Get Onboarding Data Only
```dart
final onboardingDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('onboarding')
    .doc('data')
    .get();
// Only loads onboarding data
```

### Get Both (if needed)
```dart
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
    
final onboardingDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('onboarding')
    .doc('data')
    .get();
// Two separate reads, but more efficient
```

## Best Practices

1. **Keep main user document lightweight** - Only frequently accessed data
2. **Use subcollections for large/complex data** - Onboarding, programs, habits
3. **Use flags in main document** - For quick queries (onboardingCompleted, hasActiveProgram)
4. **Index appropriately** - Create indexes for fields you query
5. **Batch writes when possible** - Update multiple documents atomically

## Recommendation

**Yes, you should separate the data!** The current single-document approach works for now but will cause issues as:
- User data grows
- You add more features
- You need to query specific data
- Document approaches 1MB limit

The recommended structure provides better scalability, performance, and maintainability.

