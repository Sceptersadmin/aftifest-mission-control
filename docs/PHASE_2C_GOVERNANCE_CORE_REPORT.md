# Phase 2C — Governance Core Report

Status: Implemented for local review; no merge or deployment.

## Scope delivered

The Decision Center is PostgreSQL-backed and retains the AFTiFest Mission Control hierarchy, cards, attention states, and audit history. It supports governed decision context, department, impact, deadline, sensitivity, descriptive human-authority grade, approval requirement, lifecycle, outcomes, and archived/cancelled states. All fixtures and configuration remain `TEST / SAMPLE / UNAPPROVED`.

## Schema and lifecycle

`decisions` now supports `draft → proposed → under_review → awaiting_approval → approved/rejected/revision_required → completed/cancelled`. The guarded transition function permits only enumerated edges; the lifecycle is a configurable technical foundation, not adopted organizational policy.

Approval rules can scope future configuration by organization, department, decision type, sensitivity, structural financial threshold, minimum approvals, eligible roles/capabilities, and self-approval policy. `approval_rule_steps` defines ordered requirements. `approvals` materializes each step. Immutable `approval_votes` records one attributable response per person and step with rationale, timestamp, and correlation identifier.

The four authority grades are stored and displayed as descriptive human-governance context. They do not enable AI or agent execution, and no agent may approve.

## Authorization and visibility

Role names grant no authority. Server actions perform capability checks, and guarded database functions re-evaluate organization membership, requester-effective sensitivity access, eligible capability/role, step order, duplicate responses, self-approval policy, and terminal state. Direct decision, approval, vote, audit-history mutation is revoked from ordinary authenticated clients. Restricted and confidential visibility remain separate explicit privileges.

## Trusted audit coverage

Trusted triggers capture decision, approval-rule, rule-step, approval, and immutable-vote mutations with actor type/identity, organization, target, before/after state, source, approval reference, time, and correlation data. The Phase 2C review also confirmed existing triggers cover administration, memberships, role assignments, departments, department memberships, tasks, assignments, dependencies, comments, report periods, and reports.

## Verification evidence

Two final clean-from-zero certification runs passed after all fixes. On each, migrations and seed completed, Phase 1.6, Phase 1.7, Phase 2A, Phase 2B, and Phase 2C SQL suites passed, deterministic TEST identity provisioning completed, and Playwright passed 7/7. The final `pnpm verify` passed lint, type checking, 30/30 unit tests, foundation validation, the 94-file secret scan, and the production build.

## Vulnerabilities addressed

- Directly mutable approval rows could rewrite historical governance evidence: ordinary mutations are revoked and responses now append immutable votes.
- A single broad approval capability could skip ordered requirements: step ordering and eligible role/capability checks now execute in the guarded response function.
- Self and duplicate approvals lacked durable enforcement: configured self-approval denial and unique approver/step evidence now fail closed.
- Broad decision reads could expose sensitive records: restricted and confidential privileges remain independently required.
- Cross-organization references could corrupt governance scope: relationship triggers reject organization mismatches.
- A shared trigger initially referenced a table-specific field before safe dispatch: identifiers now use generic row JSON extraction and the cross-organization test passes.
- The approval RPC parameter initially collided with a vote column: the parameter was renamed and ordered approval tests pass.
- New vote reads initially lacked an explicit table grant despite correct RLS: explicit SELECT permission was added while every vote mutation remains revoked.

## Unresolved decisions and limitations

- No real AFTiFest authority, financial threshold, final approver, or role mandate is configured.
- Delegation is structurally represented but fails closed until an approved delegation policy exists.
- Reopening after rejection/cancellation is not enabled.
- Supporting references remain governed JSON context; dedicated resource-link administration is future work.
- Authority grades are descriptive only. No autonomous execution, notification, importer, staging, or outbound integration was added.
