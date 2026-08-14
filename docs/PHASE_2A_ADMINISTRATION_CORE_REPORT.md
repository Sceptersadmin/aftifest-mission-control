# Phase 2A — Administration Core Review

Status: Implemented and locally certified on `codex/mission-control-phase-2-connected-core`.

## Scope

Phase 2A connects organization settings, local provisioning requests, memberships, roles, capabilities, and administration audit events to the Phase 1 PostgreSQL/RLS foundation. It does not begin Phase 2B.

## Security design

- Separate capabilities govern organization, provisioning, membership, and role administration.
- Server actions authenticate and authorize from the cookie-backed session; PostgreSQL RLS is the final boundary.
- Cross-organization role, department, and provisioning relationships fail closed in database triggers.
- The final active workspace administrator cannot be removed or deactivated.
- Administration mutations generate human-attributed, restricted audit events from trusted database triggers.
- Provisioning creates internal lifecycle records only. No outbound message, production identity, or production connection is created.
- Playwright uses deterministic `@test.invalid` identities and local-only credentials.

## Phase boundary

No Phase 2B operational module, autonomous agent, outbound email/WhatsApp, deployment, GitHub Pages change, production user, or production Supabase connection is included.

## Implemented components

- Organization name/status administration with an immutable slug.
- Internal provisioning-request lifecycle foundation; no email delivery or direct production identity creation.
- Membership status and role assignment administration.
- Custom role creation and explicit capability assignment.
- New capabilities: `organization.manage`, `user.provision`, `membership.manage`, and `role.manage`.
- RLS policies plus cross-organization, global-role, and last-administrator database guards.
- Restricted audit events for organization, provisioning, membership, role, member-role, and capability mutations.
- Branded, capability-gated `/administration` UI and local TEST administrator provisioning.

## Verification evidence

- Clean reset #1: migrations and seed completed successfully.
- Clean reset #2: migrations and seed completed; the CLI initially timed out waiting for Storage, which subsequently reached `healthy`. Migration `202608140001` was confirmed and all post-reset checks passed.
- Phase 1.6 database security: PASS.
- Phase 1.7 security matrix: PASS.
- Phase 2A pgTAP: 14/14, including low-privilege denial, authorized audited mutation, cross-organization denial, and last-administrator protection.
- Unit tests: 23/23.
- Authenticated Playwright: 5/5.
- Foundation and prototype integrity: PASS; preserved `index.html` unchanged.
- Secret scan and production build: PASS.

## Known limitations

- Provisioning requests do not send invitations or create Auth users; real invitation delivery remains excluded.
- Role capability removal, membership creation from accepted requests, and invitation expiry processing need future approved workflow work.
- The second reset exposed slow local Docker/Storage health reporting, but the service recovered to healthy and functional gates passed.
