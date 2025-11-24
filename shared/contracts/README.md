# Shared API Contracts

All client/server integration points are captured as OpenAPI (REST) or Protocol Buffer (event) contracts under `shared/contracts/`. These specs drive:

- Source-of-truth documentation for backend services.
- Generated Flutter MVC models/clients (via `lib/core/network/clients/*`).
- Contract tests in CI to prevent breaking changes.

## Directory Layout

```
shared/contracts/
  {service-name}/
    v1.yaml        # OpenAPI spec for REST/HTTP interface
  events/
    {event}.proto  # Pub/Sub event schemas
```

Version the OpenAPI files using folder names (v1, v2, …) and keep each spec backward compatible until clients migrate.

## Authoring Guidelines

1. Use the `info.version` field to track semantic versions alongside the folder name.
2. Tag operations by bounded context (`identity`, `programs`, `reflections`, etc.) for easier navigation.
3. Define shared schemas for pagination, error envelopes, and metadata; import them into service specs via `$ref`.
4. For events, prefer protobuf `package recalimevents.{domain}` with clearly typed payloads and timestamp metadata.

The following baseline specs are stubs that outline each service boundary and primary resources. Expand them as implementation details solidify.

