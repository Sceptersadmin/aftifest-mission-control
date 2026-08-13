# Security Baseline

- The browser and hidden navigation elements are not security boundaries.
- Supabase Auth establishes identity; active organization membership and capabilities establish scope.
- Row-Level Security is enabled on every application table.
- Ordinary clients use the anonymous browser key. Service-role credentials are server-only and are not committed.
- Sensitive sponsor, governance, Company Brain, agent, attachment, and audit data is internal or restricted by default.
- Private storage paths begin with the organization UUID and are checked by storage RLS.
- Human users may insert only human audit events for themselves. Agent/system audit events require a trusted backend context.
- Agents use the same permissions as humans, plus their own explicit agent policy and authority-level checks.
- ASK iFEST is Level 0, inactive by default, provider-disabled, and has no mutation or external-action tools.
- Phase 1 supports simulation records but not execution of external side effects.
- Development, staging, and production must use separate environment values and databases.

Before any future staging or production connection, perform a dedicated threat model, RLS integration test against a local database, dependency audit, secret scan, and review of database grants and security-definer functions.
