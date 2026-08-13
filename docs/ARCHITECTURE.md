# Phase 1 Architecture

## Sensitivity enforcement

Phase 1.7 adds record-level visibility and department scope beneath capability checks. The browser and server UI are convenience layers only; PostgreSQL RLS remains authoritative. Private Storage resolves each object to governed attachment metadata and applies the same sensitivity helper. ASK iFEST uses the requester's cookie-backed Supabase client and never a service-role client, so its sources and citations are filtered by the same RLS policies.

## Components

- **Next.js application:** authenticated shell, server-rendered views, route handlers, and server actions.
- **Supabase Auth:** identity and session provider. Application profiles and memberships reference `auth.users`.
- **PostgreSQL:** shared source of truth with organization scoping and Row-Level Security.
- **Supabase Storage:** future private attachment storage; access is governed by database policies.
- **Authorization service:** capability checks complement RLS. UI visibility is never the security boundary.
- **Audit service:** append-only event contract for human, agent, and system activity.
- **Approval service:** configurable rules and steps; no organizational authority is inferred.
- **Agent gateway:** provider-neutral interface, capability evaluation, and simulation-first execution.
- **Company Brain:** governed knowledge metadata; no broad external ingestion in Phase 1.

## Trust boundaries

The browser is untrusted. Client requests are authenticated server-side, authorized against organization membership and permissions, then constrained again by PostgreSQL RLS. Agent requests carry an agent identity and human initiator where applicable and pass through the same capability checks.

Service-role credentials are server-only and are not required for ordinary user flows. Phase 1 does not connect to a remote or production Supabase project.

## Environments

- **Development:** local Supabase and local Next.js server using sample fixtures.
- **Staging:** separate future Supabase project and environment values; not created in Phase 1.
- **Production:** separate future Supabase project and protected credentials; not created or connected in Phase 1.

Database migrations are the portable source of truth. Environment-specific data and credentials are never stored in migrations.

## Provider-neutral AI boundary

Core records contain no provider-specific model identifiers. `AgentProvider` accepts a normalized request and returns a normalized response containing answer text, citations, usage metadata, and provider metadata. Providers are adapters selected by server configuration. Authorization and audit behavior live outside adapters.
