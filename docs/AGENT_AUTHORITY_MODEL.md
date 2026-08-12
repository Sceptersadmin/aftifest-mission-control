# Agent Authority and ASK iFEST

## Authority levels

- **Level 0 — Read Only:** retrieve and synthesize authorized information.
- **Level 1 — Suggest:** propose a change without executing it.
- **Level 2 — Act With Approval:** execution is possible only after a valid approval.
- **Level 3 — Autonomous Within Explicit Policy:** bounded execution under an explicit policy; not enabled in Phase 1.

All Phase 1 agents default to Level 0. ASK iFEST is fixed at Level 0 in its initial implementation.

## Prohibited actions

ASK iFEST and Phase 1 agents cannot send external messages, approve decisions or payments, alter contracts, publish content, delete records, change permissions, or perform irreversible external actions.

## ASK iFEST contract

The entry point accepts one approved query category, retrieves only records the requester can read, synthesizes a response, and cites internal record identifiers and update timestamps. The initial query categories cover risks today, departments behind, pending decisions, stalled sponsor opportunities, overdue high-priority tasks, content due today, and unresolved leadership requests.

## Simulation

All proposed agent actions produce a non-executing simulation containing the requested action, capability, target, affected-record estimate, risk, approval requirement, policy result, and explanation. Simulation and future approved runs are auditable.
