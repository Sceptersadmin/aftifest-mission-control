# Phase 1.6 — Local Supabase Security Validation

Date: 2026-08-13

Branch: `codex/mission-control-phase-1`

Result: **FAIL — NOT MERGE READY**

## 1. Tool versions and setup

- Docker Desktop 4.86.0; Docker Engine/CLI 29.7.2.
- WSL 2.7.11.0; Linux kernel 6.18.33.2-2.
- Supabase CLI 2.113.0, pinned as a project dev dependency.
- PostgreSQL 17.6.
- Local API: `http://127.0.0.1:54321`.
- Local Studio: `http://127.0.0.1:54323`.
- Supabase Analytics was disabled locally after its optional Logflare container failed health checks. Database, Auth, REST, Realtime, Storage, Studio and Mailpit remained local and enabled.

## 2. Migration and reset reproducibility

PASS. Migration `202608120001` applied from zero. `pnpm supabase db reset --local` completed successfully three times after initial startup. Only the existing `SAMPLE / UNAPPROVED` seed was loaded.

Catalog verification after reset:

- 29 public application tables.
- RLS enabled on all 29.
- 56 public/storage policies.
- 63 foreign keys.
- 43 public indexes.
- Auth profile trigger was exercised by both SQL fixtures and the GoTrue admin API.

## 3. Adversarial RLS and cross-organization tests

The repeatable harness is `supabase/tests/phase_1_6_security.sql`. It uses deterministic LOCAL TEST identities and transaction rollback. It proved:

- anonymous/default access receives no application policies;
- Organization A and Organization B cannot read each other's departments, tasks or Company Brain rows;
- a Team Member lacks `workspace.admin` and cannot read audit events;
- human audit inserts must match `auth.uid()`;
- ordinary authenticated clients cannot forge `system` audit events;
- actor before/after state and correlation ID can be preserved.

Cross-organization baseline: **PASS** for exercised departments, tasks and Company Brain tables.

Full requested table/action/role matrix: **NOT COMPLETE / FAIL**, because a prohibited operation succeeded and the phase stop rule was triggered.

## 4. Security failure discovered

**FAIL: restricted Company Brain disclosure.** A real local Team Member with only baseline `brain.read` successfully retrieved an organization-scoped row whose `visibility` was `restricted`. Actual result: `TEAM_MEMBER_RESTRICTED_BRAIN_VISIBLE=1`.

Cause: `brain_select` checks only `has_permission(organization_id,'brain.read')`; it does not enforce `visibility`, `classification`, ownership or department scope.

Related unproven/unsafe policy shapes:

- Storage read/upload policies check only bucket and organization folder membership; they cannot enforce restricted attachment visibility.
- Department Lead task writes are permission-wide and do not prove department membership scope.
- Reports, comments and attachments have broad organization-member read policies.
- Restricted decision/governance visibility is not independently enforced by the row policy.

These must be resolved in backend/RLS design before a complete adversarial matrix can pass. No policy was weakened and no security bypass was added.

## 5. Authentication

- Valid local TEST login: PASS.
- Invalid password rejected (HTTP 400): PASS.
- Self-registration disabled (HTTP 422): PASS.
- Authenticated REST request resolved requester permissions and returned one authorized department: PASS.
- Logout invalidated the access token (HTTP 403): PASS.
- Profile creation trigger through real local GoTrue user creation: PASS.
- Protected application route already rejects unauthenticated users from Phase 1.5.

## 6. ASK iFEST, audit, storage and UI

- ASK iFEST remains Level 0 and non-mutating, but authorized retrieval cannot be certified because restricted Company Brain filtering failed at the shared RLS boundary.
- Human/system audit forgery baseline: PASS for the exercised cases; trusted agent-event backend context remains unimplemented/unverified.
- Storage security: FAIL / not certifiable because policy metadata cannot distinguish restricted objects.
- Authenticated role-aware Playwright suite: NOT RUN after the mandatory security failure stop condition. The existing application also lacks complete role-aware navigation and an authorized ASK retrieval implementation.

## 7. Commands executed

```text
docker version
docker run --rm hello-world
pnpm add -D supabase@latest
pnpm supabase --version
pnpm supabase start
pnpm supabase status -o env
pnpm supabase migration list --local
pnpm supabase db reset --local   (three successful runs)
docker exec ... psql ... show server_version
docker exec -i ... psql < supabase/tests/phase_1_6_security.sql
Supabase Auth REST: admin user creation, password login, invalid login, signup denial, logout
PostgREST authenticated reads for departments and restricted Company Brain items
```

Local keys emitted by `supabase status` were used only for local testing and were not written to tracked files.

## 8. Fixes made and remaining blockers

Fixes made:

- pinned the project-scoped Supabase CLI;
- disabled only the failing optional local Analytics service;
- added a deterministic transaction-rolled-back database security harness.

Remaining blockers:

1. Define and implement restricted/department visibility rules for Company Brain and attachments.
2. Enforce Department Lead scope in RLS, not only permission names.
3. Harden governance/report/comment/attachment visibility.
4. Implement trusted backend-only agent/system audit creation.
5. Re-run the complete role/table/action/storage matrix.
6. Implement and run authenticated role-aware Playwright and ASK permission-inheritance tests.

**MERGE READY: NO.**
