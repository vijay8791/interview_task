# Salesforce Analytics — dbt Project

## Design Rationale

This project implements a full dimensional model on top of 14 Salesforce CRM staging
sources using a three-layer dbt architecture on Snowflake.

## Project Structure
```
models/
├── staging/          — Views on raw Salesforce sources. Rename only, no logic.
├── intermediate/     — Business logic, joins and enrichment. Tables.
└── marts/
    ├── dimensions/   — Conformed dimensions with surrogate keys.
    └── facts/        — Fact tables with window metrics and audit columns.

seeds/                — Static lookup data (lead status, opportunity stage maps).
snapshots/            — SCD Type 2 tracking for opportunity and account.
macros/               — Shared Jinja helpers used across models.
docs/                 — Doc blocks referenced in YAML schema files.
```

## Snowflake Schema Layout

| Layer | Database | Schema |
|---|---|---|
| Staging | SALESFORCE | SALESFORCE |
| Intermediate | SALESFORCE | INTERMEDIATE |
| Marts | SALESFORCE | MARTS |
| Seeds | SALESFORCE_RAW | SEEDS |
| Snapshots | SALESFORCE_RAW | SNAPSHOTS |

## Features Demonstrated

| Feature | Detail |
|---|---|
| Surrogate keys | `md5()` on natural keys across all dims and facts |
| Incremental model | `fct_opportunity` — high-water mark on `lastmodifieddate` |
| SCD Type 2 snapshots | `snapshot_opportunity`, `snapshot_account` — check strategy |
| Seeds | `seed_lead_status_map`, `seed_opportunity_stage_map` |
| Custom macros | `safe_divide`, `current_timestamp_utc`, `generate_audit_columns` (Jinja loop) |
| Custom generic test | `unique_combination_of_columns` |
| Window functions | ROW_NUMBER, LAG, running SUM in all three fact tables |
| Tags | staging, intermediate, marts, dimensions, facts, daily, snapshots |
| Doc blocks | `docs/salesforce_docs.md` referenced via `{{ doc('...') }}` |
| `persist_docs` | Enabled — column descriptions written to Snowflake as comments |
| Tests | 149 total — unique, not_null, relationships, accepted_values, composite keys |

## Run Order
```bash
dbt deps
dbt seed
dbt build --select staging intermediate marts.dimensions
dbt build --select marts.facts
dbt snapshot
```

Or simply:
```bash
dbt build
```

## Trade-offs & Design Decisions

**Staging as views** — Pure rename layer. No logic, no joins. If a source column changes,
only the staging model needs updating.

**Intermediate as tables** — Pre-computed enrichment so mart queries join to fast sets
rather than re-executing joins on raw views every run.

**Incremental for fct_opportunity** — Opportunities are the highest-volume object and
change frequently. Incremental processing reduces daily compute cost.

**Snapshots use check strategy** — Salesforce's `systemmodstamp` gets touched by system
events, not just user changes. The check strategy tracks only business-relevant column
changes accurately.

**md5() for surrogate keys** — Native Snowflake function, no package dependency,
compatible with dbt-fusion 2.0.
