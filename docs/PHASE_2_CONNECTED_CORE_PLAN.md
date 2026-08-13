# Phase 2 — Connected Core Plan

Status: Planning only — implementation requires approval

Branch: `codex/mission-control-phase-2-connected-core`

## Objective

Connect the core operational modules to the governed PostgreSQL, Supabase Auth, RLS, audit, and approval foundation delivered in Phase 1. Phase 2 will replace presentation-only sample states with authorized application workflows while preserving organization isolation, department scope, record sensitivity, provenance, and the AFTiFest visual identity.

## Delivery principles

- PostgreSQL and backend authorization remain the source of truth; frontend visibility is never the security boundary.
- Every mutation validates identity, active membership, capability, record scope, and sensitivity through the Phase 1 authorization model.
- Meaningful mutations emit attributable audit events with before/after state and correlation identifiers.
- Test and imported data remain clearly labelled; unresolved organizational facts are not silently invented.
- Schema and workflow changes are delivered as reproducible migrations with local reset, adversarial RLS, and authenticated E2E coverage.
- ASK iFEST remains Level 0 and uses requester-effective authorization without service-role leakage.

## Workstreams

### 1. Organization administration

Build authorized organization settings for name, status, metadata, and operational configuration. Define capability-gated create/update paths, validation, audit events, and safe handling of immutable identifiers. No production organization is created during local development.

### 2. User provisioning

Implement administrator-controlled invitations and account provisioning through a backend-only Auth boundary. Keep self-registration disabled. Specify invitation lifecycle, expiry, retry, deactivation, and audit behavior without adding outbound messaging in this phase.

### 3. Membership administration

Connect organization membership creation, activation, suspension, and removal to PostgreSQL. Prevent self-escalation, last-administrator lockout, cross-organization assignment, and orphaned department membership. Record all state changes.

### 4. Approved role and capability assignments

Provide auditable role assignment using the configurable Phase 1 capability model. Validate organization ownership of roles, prohibit unauthorized grant chains, display effective permissions, and add adversarial tests for escalation and scope leakage.

### 5. PostgreSQL-backed Executive Overview

Replace hard-coded dashboard metrics with authorized queries over tasks, reports, decisions, departments, and notifications. Define each metric and readiness calculation explicitly; unresolved methodology remains marked for reconciliation rather than inferred.

### 6. Departments & People

Connect department lists, department health, membership, leadership flags, and scoped people views. Enforce department and organization isolation for reads and writes. Do not assign real department leadership without approved data.

### 7. Tasks & Accountability

Implement task creation, assignment, dependencies, priority, status, progress, due dates, and comments. Enforce assigned-user, department-lead, cross-department, and elevated capabilities through backend policies. Audit task and assignment changes.

### 8. Department Reports

Implement report periods, submissions, review states, blockers, leadership requests, and department-scoped visibility. Add deadline validation, one-report-per-period constraints, reviewer capability checks, and auditable transitions.

### 9. Decision Center workflows

Connect proposals, configurable approval rules, approval steps, outcomes, and lifecycle transitions. Validate eligible roles, approver identity, minimum approvals, visibility, and transition invariants in backend logic. No authority is inferred from display labels alone.

### 10. Mutation audit coverage

Create a shared trusted backend audit service for organization, membership, role, department, task, report, decision, importer, and notification mutations. Preserve actor type, actor identity, source, before/after state, approval linkage, and correlation identifiers. Ordinary clients remain unable to forge agent or system events.

### 11. Transactional prototype importer

Implement preview, validation, reconciliation, and transactional import for the preserved prototype's local data. Imports must be idempotent, organization-scoped, labelled with provenance, and fully rolled back on validation failure. Dates, pillars, leadership, sponsors, finances, approvals, URLs, and readiness methodology remain unresolved until explicitly approved.

### 12. ASK iFEST authorized live retrieval

Extend Level 0 retrieval from authorized live tasks, reports, decisions, departments, resources, and Company Brain records. Apply requester-effective RLS to every source, return source-level citations, exclude unauthorized information from synthesis, and log the request and policy decision. No mutations or external actions are introduced.

### 13. Notification foundation

Connect in-application notifications for assigned work, report deadlines, approval requests, and decision outcomes. Implement recipient-scoped read/unread state and audit meaningful notification generation. Delivery remains inside Mission Control; email and WhatsApp are excluded.

### 14. Controlled staging-environment design

Document a future staging topology, environment separation, migration promotion, secret management, backups, observability, access control, and rollback strategy. Produce design and readiness criteria only; creating or deploying staging infrastructure requires separate approval.

## Proposed delivery sequence

1. Administration core: organization, provisioning, membership, roles, and capabilities.
2. Operational core: departments, tasks, reports, and Executive Overview queries.
3. Governance core: Decision Center transitions and comprehensive mutation auditing.
4. Data transition: transactional prototype importer with reconciliation gates.
5. Intelligence and attention: ASK iFEST live retrieval and in-app notifications.
6. Staging design and final security re-certification.

Each increment must include migration/reset reproducibility, unit tests, RLS adversarial tests, authenticated Playwright coverage, secret scanning, and an updated security/data reconciliation record.

## Acceptance criteria

- Core screens read authorized PostgreSQL data rather than hard-coded operational fixtures.
- Authorized users can complete scoped workflows; prohibited direct API/database actions fail.
- Organization, department, restricted, and confidential boundaries remain intact.
- Role assignment cannot create unauthorized privilege escalation.
- Decision transitions follow configured approval rules.
- Every meaningful mutation produces a correct, immutable audit event.
- Prototype import is previewable, transactional, provenance-preserving, and repeatable.
- ASK iFEST citations contain only requester-authorized live records and Level 0 remains read-only.
- Local resets, tests, builds, and security matrices pass from zero.
- Staging architecture is documented but no production or staging deployment occurs.

## Explicit exclusions

Phase 2 does not include autonomous agents, outbound email or WhatsApp, payments, contract execution, social publishing, full ticketing, logistics, accreditation, or production deployment.

## Approval boundary

This document is the only Phase 2 change currently authorized. Implementation must not begin until the plan is reviewed and explicitly approved.
