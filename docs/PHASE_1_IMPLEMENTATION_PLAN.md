# AFTiFest Mission Control — Phase 1 Implementation Plan

Status: approved for `codex/mission-control-phase-1` only. This phase creates a production-ready foundation without deploying or changing GitHub Pages. The root `index.html` remains the unchanged reference implementation and UI specification.

## Phase 1 outcome

Phase 1 establishes an authenticated, organization-scoped application; PostgreSQL schema and Row-Level Security; configurable roles and approvals; auditability; a governed Company Brain; a Level 0 ASK iFEST entry point; an Agent Registry; and a validated migration path from the browser-local prototype.

It does not implement ticketing, payments, accreditation, logistics, autonomous agents, outbound messaging, publishing, contract changes, or production infrastructure.

## Prototype-to-architecture map

| Current capability | Classification | Phase 1 treatment |
|---|---|---|
| Brand palette, executive visual language | KEEP | Preserve CSS tokens, gradients, cards, readiness language, and governance orientation. |
| Sidebar and ten operational modules | KEEP / MIGRATE | Rebuild as an authenticated application shell without removing any module. |
| Executive Overview | EXTEND / CONNECT | Connect authorized summaries to shared data; label readiness as provisional. |
| Departments & People | MIGRATE / CONNECT | Persist departments and memberships with organization and department scope. |
| Tasks & Accountability | MIGRATE / EXTEND | Add assignees, dependencies, comments, attachments, and auditable state. |
| Department Reports | MIGRATE / EXTEND | Add report periods, ownership, blockers, leadership requests, and access rules. |
| Social Content Calendar | MIGRATE / CONNECT | Persist content workflow records; no publishing automation. |
| Sponsor CRM | MIGRATE / EXTEND | Add contacts and restricted commercial visibility; sample values remain unapproved. |
| Road to iFest | MIGRATE / CONNECT | Persist milestones; do not approve disputed dates. |
| Governance Room | EXTEND / CONNECT | Connect to Decision Center, approvals, restricted context, and audit history. |
| Resources & Links | MIGRATE / EXTEND | Persist governed resources; placeholder links stay flagged. |
| Workspace Settings | EXTEND / CONNECT | Backend-protected organization settings and environment-aware configuration. |
| localStorage persistence | DEPRECATE | Retain only as an explicit, validated import source. |
| JSON export/import | EXTEND | Convert into a preview-first, transactional, audited admin migration workflow. |
| Cosmetic role switcher | DEPRECATE | Replace with authenticated roles and database-enforced permissions. |
| Company Brain | CREATE | Governed knowledge records with scope, source, owner, classification, visibility, verification, and provenance. |
| ASK iFEST | CREATE | Level 0 read-only retrieval/synthesis entry point with source citations. |
| Agent Registry and runs | CREATE | Provider-neutral registry, authority levels, simulation, and traceability. |
| Decision Center | CREATE | Configurable decisions, approval steps, outcome, and history. |

## Delivery sequence

1. Preserve and verify the reference prototype.
2. Add architecture, authorization, agent, migration, and reconciliation documentation.
3. Scaffold the branded application shell and Phase 1 foundation screens.
4. Add local Supabase configuration, schema migrations, RLS, and sample seed fixtures.
5. Implement server authorization, audit, approvals, agent policy, and migration validation modules.
6. Add tests for security boundaries, agent authority, migration validation, and schema invariants.
7. Run lint, type checks, tests, build, and secret checks locally.
8. Commit to the development branch only. Do not merge or deploy.

## Acceptance gates

- `main` and root `index.html` remain unchanged.
- Every operational table is organization-scoped and protected by RLS.
- Administrative operations are checked server-side.
- Human, agent, and system actors are distinguishable in audit records.
- ASK iFEST is Level 0 and cannot execute mutations or external side effects.
- All seeded facts are visibly `SAMPLE / UNAPPROVED`.
- No secret or production credential is committed.
