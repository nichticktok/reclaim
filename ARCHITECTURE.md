# Reclaim App Architecture

## Overview

This project follows **Clean Architecture** principles with a **feature-first** structure. Each feature is self-contained with clear separation of concerns across three main layers.

## Directory Structure

```
lib/
├── app/                    # App-level configuration
│   ├── app.dart           # Root widget, MaterialApp
│   ├── env.dart           # Environment config (dev/qa/prod)
│   └── di.dart            # Dependency injection / providers
│
├── core/                   # Truly shared, generic utilities
│   ├── config/            # App configuration
│   ├── network/           # Network utilities
│   ├── theme/             # App theme, colors, text styles
│   ├── utils/             # Utility functions
│   └── widgets/           # Shared UI components (buttons, inputs, loaders)
│
├── routes/                 # Centralized routing
│   └── app_router.dart    # Route definitions (go_router / named routes)
│
├── providers/              # Global app-wide providers
│   └── app_providers.dart # Session, theme, etc.
│
├── models/                 # Only if *truly* shared across many features
│
├── widgets/                # (Optional) Additional shared widgets
│
└── features/               # Feature-based modules
    └── {feature}/
        ├── presentation/   # UI Layer
        │   ├── screens/    # UI screens
        │   ├── controllers/ # State management (blocs/notifiers/providers)
        │   └── widgets/    # Feature-specific widgets
        │
        ├── domain/         # Business Logic Layer
        │   ├── entities/  # Business models (pure Dart classes)
        │   └── repositories/ # Abstract repository interfaces
        │
        └── data/           # Data Layer
            ├── models/     # DTOs (Data Transfer Objects)
            ├── datasources/ # API/DB data sources
            └── repositories/ # Concrete repository implementations
```

## Architecture Principles

### 1. Feature-First Structure

- All app logic belongs in `features/<feature_name>` except truly shared stuff
- Each feature is self-contained and can be developed independently
- Features should not directly import from other features' presentation layer

### 2. Three-Layer Architecture

Each feature follows Clean Architecture with three layers:

#### **Presentation Layer** (`presentation/`)
- **Screens**: UI components (StatelessWidget/StatefulWidget)
- **Controllers**: State management (ChangeNotifier, Bloc, etc.)
- **Widgets**: Feature-specific reusable UI components

#### **Domain Layer** (`domain/`)
- **Entities**: Pure business models (no dependencies on Flutter/Firebase)
- **Repositories**: Abstract interfaces defining data operations
- **Business Rules**: Core logic that doesn't depend on external frameworks

#### **Data Layer** (`data/`)
- **Models/DTOs**: Data Transfer Objects for API/DB
- **Datasources**: Direct interactions with APIs, Firestore, etc.
- **Repositories**: Concrete implementations of domain repository interfaces

### 3. Dependency Direction

```
presentation → domain
     ↓
    data → domain
```

**Rules:**
- ✅ `presentation` can depend on `domain`
- ✅ `data` can depend on `domain` (to implement abstractions)
- ✅ `domain` depends on **nothing** app-specific
- ❌ `data` should **NOT** import `presentation`
- ❌ `domain` should **NOT** import `data` or `presentation`

### 4. Feature Boundaries

**Cross-Feature Communication:**
- Feature A should **NOT** import Feature B's `presentation` layer
- If Feature A needs data from Feature B:
  - Use Feature B's `domain` repository interface
  - Or use an app-wide provider/service
  - Or create a shared domain model

**Example:**
```dart
// ❌ BAD - Direct import of another feature's presentation
import '../../tasks/presentation/controllers/tasks_controller.dart';

// ✅ GOOD - Use domain repository
import '../../tasks/domain/repositories/tasks_repository.dart';
```

### 5. Global vs Feature-Local Providers

**Global Providers** (`lib/providers/` or `app/di.dart`):
- App-wide state (auth session, theme, language)
- Used across multiple features
- Examples: `LanguageProvider`, `AuthProvider`

**Feature-Specific Providers** (`features/<feature>/presentation/controllers/`):
- State specific to one feature
- Examples: `TasksController`, `ProfileController`

## File Organization Rules

### Where to Put Things

#### **Shared Models**
- If used by **2+ features** → `lib/models/`
- If used by **1 feature** → `features/<feature>/domain/entities/`

#### **Widgets**
- Generic, reusable → `core/widgets/` or `lib/widgets/`
- Feature-specific → `features/<feature>/presentation/widgets/`

#### **Services**
- App-wide services → `core/` or `app/`
- Feature-specific → `features/<feature>/data/datasources/`

#### **Repositories**
- Abstract interfaces → `features/<feature>/domain/repositories/`
- Concrete implementations → `features/<feature>/data/repositories/`

## State Management

We use **Provider** pattern with `ChangeNotifier`:

- **Controllers** extend `ChangeNotifier`
- **Screens** use `Consumer<Controller>` or `Provider.of<Controller>`
- **Global providers** registered in `app/di.dart`
- **Feature controllers** registered in `app/di.dart` or feature-specific providers

## Routing

- Centralized routing in `routes/app_router.dart`
- Route definitions reference feature screens
- Import only `presentation/screens` from features

## Naming Conventions

- **Entities**: `user.dart`, `habit.dart`, `subscription.dart`
- **DTOs**: `user_dto.dart`, `habit_dto.dart`, `subscription_dto.dart`
- **Repositories**: `user_repository.dart` (abstract), `firestore_user_repository.dart` (concrete)
- **Controllers**: `tasks_controller.dart`, `profile_controller.dart`
- **Screens**: `sign_in_screen.dart`, `home_screen.dart`
- **Widgets**: `custom_button.dart`, `habit_card.dart`

## Migration Strategy

When restructuring:

1. **Don't delete anything** - Move files to new locations
2. **Update imports** - Fix all import paths
3. **Test incrementally** - Test each feature after migration
4. **Update documentation** - Keep ARCHITECTURE.md updated

## Best Practices

1. **Keep Domain Pure**
   - Domain entities should be pure Dart classes
   - No Flutter, Firebase, or external dependencies
   - Easy to test and reason about

2. **Use DTOs for Data Layer**
   - Convert between domain entities and data models
   - Handle serialization/deserialization in DTOs
   - Keep domain entities clean

3. **Repository Pattern**
   - Abstract interfaces in `domain/repositories/`
   - Concrete implementations in `data/repositories/`
   - Easy to swap data sources (Firestore → API → Local)

4. **Dependency Injection**
   - Register all providers in `app/di.dart`
   - Use interfaces, not concrete classes
   - Makes testing easier

5. **Feature Independence**
   - Features should work in isolation
   - Use domain interfaces for cross-feature communication
   - Avoid circular dependencies

## Example: Subscription Feature

```
features/subscription/
├── presentation/
│   ├── screens/
│   │   └── subscription_screen.dart
│   ├── controllers/
│   │   └── subscription_controller.dart
│   └── widgets/
│       └── subscription_plan_card.dart
│
├── domain/
│   ├── entities/
│   │   └── subscription.dart          # Business model
│   └── repositories/
│       └── subscription_repository.dart # Abstract interface
│
└── data/
    ├── models/
    │   └── subscription_dto.dart       # Firestore DTO
    ├── datasources/
    │   └── firestore_subscription_datasource.dart
    └── repositories/
        └── firestore_subscription_repository.dart # Implements domain repo
```

**Flow:**
1. `SubscriptionController` (presentation) uses `SubscriptionRepository` (domain)
2. `FirestoreSubscriptionRepository` (data) implements `SubscriptionRepository`
3. `FirestoreSubscriptionRepository` uses `FirestoreSubscriptionDatasource` (data)
4. `SubscriptionDto` (data) converts to/from `Subscription` (domain)

## Testing Strategy

- **Unit Tests**: Test domain entities and business logic
- **Repository Tests**: Mock datasources, test repository implementations
- **Controller Tests**: Mock repositories, test state management
- **Widget Tests**: Test UI components in isolation

## Resources

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture Guide](https://resocoder.com/flutter-clean-architecture-tdd/)

