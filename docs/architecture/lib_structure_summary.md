# `lib/` Structure Overview

```
lib/
├── app/                         # App root bootstrap + DI
│   ├── app.dart                 # MaterialApp / routing host
│   ├── di.dart                  # Provider graph + client registrations
│   └── env.dart                 # Build-time env toggles
│
├── core/
│   ├── mvc/                     # base_controller, base_view, base_model
│   ├── network/
│   │   ├── service_registry.dart        # Backend endpoint map (gateway-aware)
│   │   └── clients/
│   │       └── base_api_client.dart     # HTTP client, interceptors, auth headers
│   ├── services/                # Cross-feature services (e.g., sync)
│   ├── theme/                   # Colors, typography, theming helpers
│   ├── widgets/                 # Truly shared UI components
│   ├── utils/                   # Helpers, formatters
│   ├── errors/                  # Error definitions / mappers
│   ├── providers/               # Global ChangeNotifiers (language, settings)
│   └── l10n/                    # Generated localization bindings
│
├── features/
│   ├── {feature}/
│   │   ├── presentation/        # Views (screens/widgets) + controllers
│   │   │   ├── screens/
│   │   │   └── controllers/
│   │   ├── application/         # (optional) client-side use-cases/facades
│   │   ├── domain/              # Pure Dart entities + repository contracts
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── infrastructure/      # API/DB implementations of repositories
│   │       └── {feature}_remote_repository.dart
│   └── ... (auth, onboarding, tasks, projects, workouts, subscription, progress,
│             community, profile, etc.) all follow the same pattern
│
└── main.dart                    # Entry point
```

Use this summary as the canonical high-level guide; refer to `docs/architecture/lib_structure.txt` for the exhaustive tree generated from the repo.

