# Recalim Service & Feature Inventory

## Overview

This document inventories the current Flutter MVC modules under `lib/` and the backend capabilities (Firebase Functions + planned services) so that each bounded context has a clear owner before extraction into microservices.

## Flutter Feature Inventory (MVC Perspective)

| Feature Module (`lib/features/*`) | Views (UI) | Controllers | Domain Models | Notes |
| --- | --- | --- | --- | --- |
| `auth` | `presentation/screens/sign_in_screen.dart` | `presentation/controllers/auth_controller.dart` | Uses shared user models | Handles OTP login flow that currently calls Firebase Functions directly |
| `profile` | `presentation/screens/profile_screen.dart` | `presentation/controllers/profile_controller.dart` | Relies on `core/models/user_model.dart` | Displays subscription, stats, social profile |
| `subscription` | `presentation/screens/subscription_screen.dart` | `controllers/subscription_controller.dart` | `domain/entities/subscription.dart` | Manages billing state, currently tied to Firestore |
| `projects` | `presentation/screens/*` (3) | `controllers/projects_controller.dart` | `domain/entities/project.dart` | Coordinates project creation/sync |
| `program` | Controllers + data under `features/program/*` | Same | DTOs under `data/repositories` | Drives onboarding programs and plan templates |
| `tasks` | `presentation/screens/*` (daily tasks, detail) | `controllers/tasks_controller.dart` | Entities in `domain/entities` | Creates/updates tasks & streak data |
| `workouts` | Similar structure | controllers/models under feature | Entities for workouts/plans | Generates AI-assisted workout plan |
| `progress` | `screens/progress_*` | `progress_controller.dart` | Entities in `domain/entities` | Aggregates stats for charts |
| `journey`, `mastery`, `milestone` | Each has controllers/screens | Entities + Firestore repos | Represent long-term gamification |
| `reflection` | `screens/reflection_screen.dart` | `reflection_controller.dart` | `domain/repositories/reflection_repository.dart` | Journal entries + prompts |
| `community` | `community_screen.dart` | `community_controller.dart` | Entities + repos | Social feed, announcements |
| `achievements`, `rating`, `streaks`, `ai_workout`, `onboarding`, `home`, `penalty`, `tools`, `web` | Follow same pattern | Controllers under `presentation/controllers` | Entities either in feature or shared core | Smaller supporting experiences (badges, rating slider, utility tools, landing page) |

Supporting shared layers:
- `lib/core/models/*` — reusable domain models (`user_model`, `project_model`, etc.).
- `lib/core/network/*` — placeholder for future clients (currently minimal).
- `lib/app/di.dart` — dependency graph feeding controllers.

## Backend Capability Inventory

| Current Location | Responsibility | Notes / Dependencies |
| --- | --- | --- |
| `functions/index.js` | OTP email login (request & verify code), Mailjet SMTP integration, Firestore `authMagicCodes` collection | Only production-grade backend code today; everything else happens client-side (Firestore direct access). |
| `server/gemini_proxy/` | Placeholder for Gemini proxy (no implementation yet) | Future AI service hook. |
| Firestore (rules/indexes) | Primary datastore for tasks, programs, reflections, community, etc. | Accessed directly from Flutter controllers/repositories. |

## Proposed Microservices Alignment

| Service | Flutter MVC Features Served | Core Data / External Systems | Initial Scope |
| --- | --- | --- | --- |
| `auth-service` | `auth`, onboarding identity steps | Firebase Auth (users), Mailjet | Issue OTP, manage sessions, provide JWTs to gateway |
| `user-profile-service` | `profile`, `subscription`, `achievements`, `rating` | Users collection, billing provider, achievements tables | CRUD profile, manage subscription state, badges/ratings |
| `program-service` | `program`, `tasks`, `workouts`, `journey`, `mastery`, `milestone`, `penalty` | Program/task Firestore collections, workout generators, AI proxy | Schedule programs, generate tasks, evaluate mastery |
| `reflection-service` | `reflection`, `streaks` | Reflection entries, streak counters | Journal CRUD, streak tracking, prompt catalog |
| `community-service` | `community`, `projects`, `tools`, `web` content feed | Community posts, messaging, landing content | Publish/share projects, handle social interactions |
| `reporting-service` | `progress`, `rating`, dashboards in `home` | Aggregated stats warehouse | Provide analytics APIs powering charts & leaderboards |
| `api-gateway` | Consumable by all Flutter controllers | Auth service, downstream microservices | Single entry point, JWT validation, routing, rate limiting |

Each service exposes REST/GraphQL contracts stored in `shared/contracts/{service}/v1.yaml` and emits domain events (`task.completed`, `reflection.logged`, etc.) defined under `shared/contracts/events/`.

## Next Steps

1. Use this inventory to prioritize extraction (starting with Auth & Profile).
2. Generate OpenAPI specs for prioritized services in `shared/contracts`.
3. Scaffold service repos under `services/` and wire Flutter MVC models to generated clients.

