# DevOps, CI/CD, and Observability Strategy

## 1. Containerization & Local Orchestration
- Each service under `services/*` includes a Dockerfile that installs dependencies, runs tests, and exposes the service on port 8080 (override via `SERVICE_PORT` env).
- `infra/docker/docker-compose.micro.yml` orchestrates the stack locally: gateway, auth, profile, program, reflection, community, reporting, plus infrastructure (Postgres, Firestore emulator, Pub/Sub emulator, Mailhog).
- Developers run `docker compose -f infra/docker/docker-compose.micro.yml up auth-service program-service` to bring up only the services they need.

## 2. Environment Promotion Flow
| Stage | Branch | Infra | Notes |
| --- | --- | --- | --- |
| Local | feature/* | `docker-compose.micro.yml`, emulators | Fast iteration, mocks/external stubs |
| QA | develop | GKE (Autopilot) or Cloud Run + managed Postgres | Uses seeded data sets |
| Prod | main | GKE + managed datastores | Blue/green deployments via GitHub Actions |

## 3. CI/CD Pipelines
- Use GitHub Actions workflows stored in `.github/workflows/`:
  - `flutter.yml`: analyze + test the Flutter app, generate API clients from `shared/contracts`, and upload coverage.
  - `service-{name}.yml`: lint, test, build container, push to Artifact Registry, and run contract tests against `shared/contracts/{service}`.
  - `deploy.yml`: triggered on tags; runs smoke tests, then deploys to Cloud Run/GKE using `gcloud`.
- Shared steps packaged as reusable actions under `tools/ci/`.

## 4. Contract Testing
- Add `make contract-test` (or npm script) per service to validate OpenAPI/Proto compatibility (e.g., using `schemathesis` for REST and `buf` for protobuf).
- Flutter pipeline downloads the same specs and regenerates clients; failing regeneration or mismatched schemas blocks merges.

## 5. Observability
- Introduce `shared/packages/telemetry` containing OpenTelemetry configuration, log formatters, and an HTTP interceptor for request IDs.
- All services export traces/metrics to Google Cloud Trace + Prometheus via OTLP/GRPC.
- Flutter app logs user/session IDs using `lib/core/utils/logging.dart` and attaches `x-trace-id` headers (set by BaseApiClient).

## 6. Messaging Layer
- `infra/messaging/topics.yaml` defines topics (`user.created`, `task.completed`, `reflection.logged`).
- For local development, use the Pub/Sub emulator; in production, use Google Pub/Sub with IAM-based auth.
- Services must publish domain events after transactional commits; a lightweight outbox pattern ensures reliability.

## 7. Secrets & Configuration
- Use Google Secret Manager for API keys (Mailjet, Stripe, etc.); services load secrets at startup.
- Flutter uses `.env` style `--dart-define` flags for service URLs + feature flags (already wired in `ServiceRegistry`).
- Provide `infra/README.md` with onboarding commands for new engineers.

## 8. Testing Strategy
- Unit/integration tests scoped per service with mocks for external dependencies.
- End-to-end smoke tests executed via post-deploy job: orchestrated scenario hitting gateway endpoints to confirm inter-service wiring.
- Flutter golden/widget tests run against stub clients to validate MVC separation.

