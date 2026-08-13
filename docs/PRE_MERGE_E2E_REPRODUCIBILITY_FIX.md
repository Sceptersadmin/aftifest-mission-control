# Pre-Merge E2E Reproducibility Fix

Date: 2026-08-13

Branch: `codex/mission-control-phase-1`

## Root cause

The authenticated Playwright identity was created manually after a database reset. A later clean `supabase db reset` correctly removed it, so the committed suite could not recreate its own prerequisite and the login scenario failed.

## Provisioning design

Playwright now runs `tests/e2e/global-setup.ts`, which executes `scripts/provision-e2e.mjs` before any browser test. The script refuses remote endpoints and targets only the named local Supabase Auth and Postgres containers. It:

1. derives a five-minute service-role JWT in memory from the local Auth container for the local admin API;
2. creates or updates `phase17-member@test.invalid` with the documented deterministic password `TEST-Only-Password-123!`;
3. upserts TEST Organization A, a least-privilege E2E Team Member role, membership, seven minimum capabilities, one organization-visible source, and one restricted source;
4. exits non-zero on any missing container, Auth error, SQL error, missing permission, or timeout.

No token, JWT secret, production credential, or generated environment file is written by the setup. The deterministic password is explicitly local TEST-only and the script cannot target a non-loopback Supabase API.

## Idempotency and isolation

The Auth user is reused by email and its password/metadata are reset deterministically. Organization, role, membership, role assignment, permissions, and source records use stable IDs and conflict-safe upserts. Two consecutive provisioning calls succeeded without duplicates. The role has only `department.read`, `task.read`, `report.submit`, `content.read`, `resource.read`, `brain.read`, and `agent.read`; it is not an administrator and has no restricted, confidential, governance, sponsor, or mutation capability.

## Reproducibility evidence

- Clean run 1: reset applied all migrations and seed; automatic provisioning succeeded; Playwright 4/4 passed.
- Clean run 2: reset applied all migrations and seed; automatic provisioning succeeded; Playwright 4/4 passed.
- Authenticated coverage includes real password login, role-aware shell, direct governance denial, authorized ASK iFEST citation, restricted citation exclusion, and logout.

## Files changed

- `scripts/provision-e2e.mjs`
- `tests/e2e/global-setup.ts`
- `playwright.config.ts`
- `package.json`
- this report

## Security implications

The suite no longer depends on retained state or bypasses browser authentication. Provisioning uses local-only infrastructure and minimum capabilities. Failure is explicit and blocks all Playwright tests. The application authorization boundary remains Supabase Auth plus PostgreSQL RLS.
