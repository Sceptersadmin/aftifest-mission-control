# Data Model Summary

## Identity and organization

`organizations` owns internal records. `profiles` extends `auth.users`. `organization_members` joins profiles to organizations. `roles` and `permissions` are joined by `role_permissions`; membership-role assignments determine capabilities. `departments` belong to organizations and `department_members` joins memberships to departments.

## Work and reporting

`tasks` belong to an organization and optionally a department. `task_assignees` and `task_dependencies` provide many-to-many relationships. Polymorphic `comments` and `attachments` reference authorized targets. `report_periods` define expected windows and `reports` belong to a period, department, and reporter.

## Commercial, content, and delivery

`content_items`, `sponsors`, `sponsor_contacts`, `milestones`, and `resources` are organization-scoped. Sensitive commercial values and internal resources can be restricted by visibility.

## Decisions and approvals

`decisions` capture requester, owner, department, type, due date, impact, context, sensitivity, human-authority grade, lifecycle, and outcome. `approval_rules` define configurable organization/department/type/sensitivity criteria without granting authority by title. `approval_rule_steps` provide ordered capability/role eligibility and minimum counts; `approvals` materialize those steps; immutable `approval_votes` preserve attributable responses and rationale. No seeded individual is treated as an approved authority.

## Audit, agents, and knowledge

`audit_events` records actor type and identity, action, target, before/after state, approval, and source context. `agents` stores authority level and policy; `agent_runs` stores initiator, mode, request, response, citations, policy result, and audit linkage. `company_brain_items` stores governed knowledge metadata and provenance. `notifications` is an in-app foundation only.

## Controlled data transition

`import_batches` protects source filename, canonical SHA-256 digest, schema version, preview, warnings, lifecycle, counts, uploader, confirmation, completion, and rollback evidence. `import_items` stores deterministic source keys, original payloads, target types, mappings, exclusions, deferrals, and imported target IDs. `import_person_mappings` can link a prototype name only to an explicitly selected active organization member; it never creates Auth identities or leadership authority. Imported target rows retain batch, source key, digest-backed provenance, original payload, importer, timestamp, and `SAMPLE / UNAPPROVED` verification state.
