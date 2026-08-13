# Phase 1.7 Security Hardening Report

Date: 2026-08-13

Branch: `codex/mission-control-phase-1`

## Result

The confirmed Company Brain disclosure and a newly discovered cross-department helper flaw were fixed. Local migration, RLS, Auth, Storage, ASK iFEST, audit, and authenticated Playwright validation pass. No production system was connected.

## Root cause and authorization changes

Phase 1.6 policies combined organization membership with broad capabilities but ignored record sensitivity and department assignment. Phase 1.7 introduces `confidential`, explicit restricted/confidential capabilities, department foreign keys, sensitivity columns, and centralized helpers. Department capability never substitutes for department membership; only `department.read_all` grants explicit cross-department access.

The model is: `public` (intentional authenticated exposure), `organization` (same organization plus base capability), `department` (base capability plus assigned department), `restricted` (base plus restricted capability), and `confidential` (base plus confidential capability). Ambiguous values fail closed.

## RLS changes

Company Brain, tasks, reports, content, resources, attachments, decisions, approvals, approval rules, and audit events now apply sensitivity/scope checks. Sponsor tables retain explicit commercial capabilities and organization scoping. Audit update/delete grants were revoked. Ordinary clients can create only correctly attributed human events; agent/system events remain backend-only.

## Storage

Storage policies resolve the attachment UUID from a structured object path and authorize against the attachment row. The path itself is not trusted. Live local results: authorized department upload 200, authorized download 200, anonymous denied 400, cross-department denied 400, restricted-without-capability denied 400.

## ASK iFEST and UI

ASK iFEST authenticates the requester, verifies active membership and `brain.read`, queries through the requester session, and cites only RLS-returned rows. Level 0 remains read-only. Navigation and the Decision Center route enforce server-side capabilities; hidden links are not used as the security proof.

## Test results

- Clean migrations and reset: PASS.
- `phase_1_7_security.sql`: PASS after detecting and fixing a cross-department helper flaw.
- Organization, department, restricted/confidential isolation: PASS.
- Governance and sponsor/commercial denial: PASS.
- Audit attribution/forgery/immutability: PASS for exercised cases.
- Local Auth valid login, invalid login, disabled signup, logout: PASS.
- Live Storage matrix: PASS for exercised anonymous, department, cross-department and restricted cases.
- Authenticated Playwright: 4/4 PASS, including authorized ASK citation and excluded restricted citation.
- Full application verification: PASS (lint, typecheck, 19 unit tests, foundation validation, secret scan, production build).

## Remaining risks

- `public` remains inside the authenticated Mission Control boundary; external publication is out of scope.
- Trusted agent/system audit insertion still requires a future backend worker; ordinary clients remain denied.
- Broader domain-specific classifications require approved governance definitions before production use.
- Phase 1 UI is a foundation, not full operational CRUD for all 29 tables.
