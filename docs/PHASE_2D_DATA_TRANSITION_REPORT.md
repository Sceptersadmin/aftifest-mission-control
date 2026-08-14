# Phase 2D — Data Transition and Controlled Importer Report

Status: Implemented for local review. No merge, deployment, production connection, ASK iFEST expansion, or notification work.

## Architecture and lifecycle

An administrator explicitly selects a JSON file. The server validates the strict `aftifestCommandData` export shape (root export or explicit wrapper), applies a 2 MB limit, computes SHA-256, creates a preview, and persists reconciliation records. The flow is upload → validate → preview → reconcile → administrator confirmation → transactional import. No localStorage ingestion occurs.

Batch states are `uploaded`, `validated`, `ready`, `importing`, `completed`, `failed`, and `rolled_back`. The current preview RPC creates a validated `ready` batch after the complete application validation succeeds. Execution runs inside a guarded PostgreSQL function and an exception subtransaction: any record failure rolls back target inserts and item changes, then records `rolled_back` with the reason.

## Mapping and reconciliation

Supported targets are departments, tasks, content items, sponsors, milestones, decisions, and resources. Reports remain deferred until an approved reporting period, department, and authenticated reporter mapping exist. Department memberships and task assignments are created only from an administrator-approved active-member mapping. Such mappings never grant department-lead status. Unsupported or invalid relationships are deferred rather than coerced.

Warnings cover date conflicts, pillar counts, unapproved departments/leads, illustrative sponsor organizations and values, placeholder URLs, outdated deadlines, provisional readiness, sample governance, unsupported owners, and missing people mappings. Administrators can mark records ready, deferred, or excluded and names unmapped, deferred, or mapped to an existing active member.

## Provenance and idempotency

Every imported target stores batch ID, source record key, source digest context, source type, importer, import time, original identifier, safe original payload, and `SAMPLE / UNAPPROVED`. A unique organization-plus-digest batch key prevents repeat-file duplication; per-batch source keys and target-table unique indexes provide a second layer. Re-executing a completed batch returns without inserting again.

## Data safeguards

- People names never create Auth identities.
- Prototype decisions import as restricted drafts with no approval requirement or active chain.
- Sponsor values, currencies, confirmed stages, contracts, payments, and commitments are not imported.
- Placeholder resource URLs are not imported.
- Prototype readiness is provenance metadata only; governed Operational Readiness remains PROVISIONAL.
- Dates are retained in original provenance when not independently approved.

## Security, audit, and history

`import.manage` controls preview, history, item reconciliation, and member mapping. `import.execute` controls confirmation. All trusted functions re-evaluate active organization permission; PostgreSQL recomputes the submitted digest. Direct table mutation is unavailable to authenticated clients. Batch, item, and person-mapping changes create trusted audit events with organization, actor, action, batch, before/after state, source, and correlation data. Completed and rolled-back history is read-only to ordinary clients.

## Verification and discovered failures

The importer unit suite covers invalid JSON, unexpected fields, wrappers, missing mappings, duplicate source keys, reconciliation warnings, inactive governance, and prohibited Auth creation. The pgTAP/RLS suite covers unauthorized and inactive users, cross-organization targets, forged digests, preview, duplicate files, atomic execution, idempotency, sponsor/governance safeguards, forced rollback, protected history, and audit evidence.

During implementation, an ambiguous digest parameter was detected by pgTAP and replaced with an unambiguous positional argument. The initial reconciliation design lacked explicit member mapping; a protected mapping table and RPC were added.

Two final clean-from-zero certification runs passed. Each applied all migrations through Phase 2D, seeded local data, passed Phase 1.6, Phase 1.7, Phase 2A, Phase 2B, Phase 2C, and Phase 2D database security suites, deterministically provisioned TEST identities, and passed Playwright 8/8. Final `pnpm verify` passed lint, type checking, 12 test files and 38/38 unit tests, foundation validation, the 100-file secret scan, and the production build including `/administration/import`.

## Deferred and unresolved

Reporting-period creation, reporter approval, real people, leadership, festival dates, pillars, sponsor facts/values, resource URLs, deadlines, readiness methodology, ownership, and governance authority all require approved reconciliation. The importer does not support attachments, comments, dependencies, contracts, payments, logistics, accreditation, ticketing, or downstream systems.
