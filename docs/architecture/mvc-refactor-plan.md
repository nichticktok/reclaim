# Flutter MVC Refactor Plan

This document maps every major feature to its MVC responsibilities, the backing microservice, and the concrete refactor steps required to remove direct Firestore usage.

## Cross-Cutting Tasks
- Update each controller to extend `BaseController` and rely on dependency-injected service clients.
- Create DTO/model pairs per service inside `lib/features/{feature}/domain/models/`.
- Move Firestore queries into new data sources (`lib/core/data/{service}/`) that wrap generated API clients for offline caching.
- Use `BaseView` in screens that need loading/error scaffolding.

## Feature Breakdown

| Feature | Service | Model Layer Tasks | Controller Tasks | View Tasks |
| --- | --- | --- | --- | --- |
| Auth | `auth-service` | Generate DTOs from `auth-service/v1.yaml` and store under `lib/features/auth/domain/models/otp_models.dart`. | Inject `AuthServiceClient` via DI, expose `requestOtp`/`verifyOtp` using `guardAsync`. Remove direct Cloud Functions calls. | Wrap sign-in UI with `BaseView<AuthController>` to leverage loading states. |
| Profile | `user-profile-service` | Create `UserProfileModel`, `SubscriptionModel`, `AchievementModel`. Add caching in `lib/core/data/profile/profile_cache.dart`. | Controller fetches profile/subscription using service client, updates local cache on success. | Views rely on `context.watch<ProfileController>()` only; remove Firestore streams. |
| Subscription | `user-profile-service` | Share DTOs with profile feature; expose plan metadata provider for pricing table. | Controller orchestrates plan change flows via service client, handles errors centrally. | UI displays `controller.isLoading`. |
| Projects/Community | `community-service` | Introduce `CommunityPostModel`, `ProjectModel`, `ReactionModel`. | Controllers call `CommunityServiceClient` for feed and project publishing. Support pagination by storing cursors. | Views adopt `BaseView` with pull-to-refresh hooking into controller. |
| Program/Tasks/Workouts | `program-service` | Create `ProgramModel`, `TaskModel`, `WorkoutPlanModel` + offline caches. | Controllers schedule/fetch tasks via service client, push completion events. Remove Firestore direct writes. | Views observe controllers; detail pages request data via controller `Future`. |
| Progress/Reporting | `reporting-service` | Add `ProgressPointModel`, `LeaderboardEntryModel`, `RatingSummaryModel`. | Controller fetches analytics from service, merges with local derived metrics. | Charts read from controller state; show skeleton when loading. |
| Reflection/Streaks | `reflection-service` | `ReflectionEntryModel`, `PromptModel`, `StreakModel` generated from contracts. | Controllers maintain entry list + streak status using service client; optimistic updates stored offline. | Use `BaseView` for forms and lists with error fallback. |
| Achievements/Rating | `user-profile-service` / `reporting-service` | DTOs reused from above services; ensure `domain/models` aggregated for achievements. | Controllers subscribe to reporting events via gateway SSE (future). | UI shows aggregated state only via controller. |
| Onboarding | multiple services | Split onboarding data fetch into small models (profile seed, program suggestions). | Controller orchestrates API calls sequentially using `guardAsync`, persisting data to caches. | Views remain mostly unchanged but rely on controller futures for steps. |

## Dependency Injection Plan
1. Add typed clients (e.g., `AuthServiceClient`) under `lib/core/network/clients/` that extend `BaseApiClient`.
2. Register them inside `AppProviders.providers` using `ProxyProvider<ServiceRegistry, AuthServiceClient>`.
3. Update feature controllers to accept required clients in constructors (use `ChangeNotifierProvider(create: (context) => AuthController(context.read<AuthServiceClient>()))`).

## Deliverables
- Controller migration checklist per feature stored in `/docs/architecture/mvc-refactor-plan.md#feature-breakdown`.
- Tracking spreadsheet (optional) referencing GitHub issues for each feature migration.

