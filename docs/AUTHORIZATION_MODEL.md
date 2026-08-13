# Authorization Model

## Phase 1.7 record sensitivity

Authorization is the intersection of active organization membership, an explicit capability, and record scope. `public` means intentionally broad inside the authenticated Mission Control boundary; `organization` means active same-organization members with the base capability; `department` additionally requires membership in the assigned department (or explicit `department.read_all`); `restricted` requires a dedicated restricted capability; and `confidential` requires a separate confidential capability. Missing organization, visibility, department assignment, classification, membership, or capability fails closed.

Reusable `SECURITY DEFINER` helpers centralize these rules: `is_org_member`, `has_permission`, `is_department_member`, `can_access_sensitive_record`, and `can_access_attachment`. They use fixed `public, pg_temp` search paths, expose execution only to `authenticated`, accept no caller-supplied SQL, and return booleans rather than data. Their purpose is consistent RLS evaluation, not bypassing RLS.

## Principle

Authentication identifies a user. Organization membership establishes scope. Roles grant capabilities. Row-Level Security enforces data access at the database layer. Server-side capability checks protect workflows and administrative operations.

## Initial configurable roles

- Super Admin / Founding Leadership
- Executive / EXCO
- Advisory Board
- Patron
- Department Lead
- Team Member

Future roles such as Volunteer, Sponsor, Vendor, Speaker, and External Collaborator can be added as data without schema changes.

## Permission examples

`workspace.admin`, `department.read`, `department.manage`, `task.read`, `task.manage_assigned`, `task.manage_department`, `report.submit`, `report.review`, `content.read`, `content.manage`, `sponsor.read`, `sponsor.manage`, `decision.read`, `decision.propose`, `decision.approve`, `governance.read_restricted`, `brain.read`, `brain.manage`, `agent.read`, and `agent.configure`.

No role name automatically confers approval authority. Approval requirements and eligible roles are configured in approval rules and steps.

## Enforcement

Every internal table includes `organization_id`. Policies require active organization membership and, where relevant, department membership or explicit capability. Sensitive governance, sponsor, Company Brain, agent, and audit records carry visibility/classification fields and receive stricter policies.

Agents do not receive a bypass. Their initiating user, registered agent, authority level, requested capability, policy decision, simulation result, and approval reference are recorded.
