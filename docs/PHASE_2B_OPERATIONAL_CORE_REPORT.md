# Phase 2B — Operational Core Review

Status: Implemented and locally certified on `codex/mission-control-phase-2-connected-core`.

## Schema changes

Migration `202608140002_phase_2b_operational_core.sql` extends departments with governed metadata, tasks with update/archive and structural AI-owner provenance, and reports with progress, reviewer, review state, comments, and timestamps. It adds organization-consistency triggers, assigned-user/department task authorization, trusted operational audit triggers, and the requester-authorized `operational_overview` function.

## Departments & People

The branded department-card experience reads PostgreSQL departments, readiness, health, lifecycle, and scoped membership. Lead flags are explicit database values. All new UI-created records are `SAMPLE / UNAPPROVED`; no AFTiFest leadership is inferred.

## Tasks & Accountability

The Kanban experience reads and mutates authorized PostgreSQL tasks. It supports lifecycle, status, priority, progress, due dates, department, comments, assignees/dependencies at the schema and policy layers, archive timestamps, and a structural AI-owner reference without autonomous execution. Cross-organization assignments and dependencies fail closed.

## Department Reports

Reports use configured periods, one-report-per-department/period uniqueness, author identity, department scope, health, summary, wins, blockers, leadership request, review state, reviewer, review comments, and reviewed/submitted timestamps. Deadlines remain TEST configuration until approved.

## Executive Overview and readiness

The overview queries authorized PostgreSQL records for provisional readiness, open/overdue/high-risk tasks, reports due/submitted, leadership requests, and pending decisions. Empty authorized datasets display zero.

`Operational Readiness — PROVISIONAL` is the arithmetic mean of non-null readiness values for authorized active departments. Missing values are excluded and an empty set returns zero. It is not an approved KPI; evidence, weights, thresholds, owners, and cadence require governance approval.

## Security and auditing

RLS preserves organization, department, visibility, assigned-user, reviewer, and active-membership scope. Department leads do not gain unrelated-department access. Trusted database triggers audit department, membership, task, assignment, dependency, comment, reporting-period, and report mutations with actor, organization, target, before/after state, source, timestamp, and correlation ID.

## Phase boundary

No Decision Center expansion, prototype importer, ASK iFEST live retrieval, notifications, staging infrastructure, autonomous agent, outbound message, payment, contract, ticketing, logistics, accreditation, merge, or deployment is included.

## Verification evidence

- Three clean resets completed; the additional third reset certified the final `task.assign` policy exactly as committed.
- Phase 1.6 database security: PASS.
- Phase 1.7 security matrix: PASS.
- Phase 2A pgTAP: 14/14 PASS.
- Phase 2B pgTAP/RLS: 14/14 PASS.
- Unit tests: 27/27 PASS.
- Authenticated Playwright: 6/6 PASS.
- `pnpm verify`: PASS.
- Production build: PASS.
- Secret scan, foundation validation, and preserved `index.html` integrity: PASS.

## Bugs discovered and fixed

- The first local reset completed migrations but Supabase timed out while Storage was becoming healthy. Storage recovered and subsequent full resets completed normally.
- The initial Kanban projection attempted to infer a foreign-key relationship from polymorphic comments. The task mutation succeeded but the invalid projection hid all tasks; comments remain separately governed and the unsupported nested projection was removed.
- Stale local preview processes served earlier builds during verification. Repository-owned preview processes were restarted and final Playwright evidence was captured against the fresh Phase 2B production build.
- Task assignment was initially schema-only. An explicit `task.assign` server action, UI control, and RLS capability check were added before final certification.

## Unresolved decisions

Department taxonomy/leads, reporting calendar/review authority, real task assignments/deadlines, and readiness methodology remain unresolved in `DATA_RECONCILIATION_REQUIRED.md`.

## Known limitations

- Task dependencies and governed attachments retain their Phase 1 schema/storage enforcement but do not yet have dedicated Phase 2B editing/upload controls.
- Report versioning is not enabled; uniqueness remains one report per department and period.
- Readiness is deliberately provisional and unweighted.
- No real AFTiFest departments, people, leads, tasks, periods, deadlines, or reports were introduced.
