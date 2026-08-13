# AFTiFest Mission Control

Phase 1 establishes the governed production foundation for the existing Mission Control prototype. The root `index.html` is preserved as the unchanged visual and functional reference.

## Local development

Requirements: Node.js, pnpm, Supabase CLI, and a Docker-compatible local runtime.

```bash
cp .env.example .env.local
supabase start
pnpm install
pnpm dev
```

Use the local Supabase values printed by `supabase start` in `.env.local`. Do not commit `.env.local` or any service-role credentials.

## Verification

```bash
pnpm verify
pnpm test:e2e
```

No production Supabase project, deployment, GitHub Pages setting, or autonomous agent is configured in Phase 1. All seed data is **SAMPLE / UNAPPROVED**.

See `docs/PHASE_1_IMPLEMENTATION_PLAN.md` and `docs/DATA_RECONCILIATION_REQUIRED.md` before extending the system.
