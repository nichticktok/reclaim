# Datastore Decisions

| Service | Primary Store | Reasoning | Notes |
| --- | --- | --- | --- |
| Auth | Postgres (Cloud SQL) | Strong consistency for OTP + session data, relational schema for audit logs | Replicate read-only to analytics warehouse |
| User Profile | Postgres | Relational joins between profile, subscription, achievements | Uses Stripe webhooks via outbox pattern |
| Program | Firestore / Document DB | Highly nested program + schedule docs; offline sync friendly | Long term migrate to Spanner if complex queries required |
| Reflection | Firestore | Append-only journal entries and streak counters, natural fit for document model | TTL policies to purge stale drafts |
| Community | Postgres + ElasticSearch (future) | Need transactional writes for posts/reactions, search for discovery | Search cluster optional until volume grows |
| Reporting | BigQuery | Aggregations over events/tasks/progress | Materialized views exported to Postgres for low-latency leaderboard reads |

Support services:
- Pub/Sub topics mirror events defined in `shared/contracts/events/*`.
- Redis (future) for caching leaderboard snapshots (`reporting-service`).

