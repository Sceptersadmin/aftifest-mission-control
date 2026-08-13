import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

const sql = readFileSync("supabase/migrations/202608120001_phase_1_foundation.sql", "utf8");
const agentPolicy = readFileSync("src/lib/agents/policy.ts", "utf8");
const migration = readFileSync("src/lib/migration/prototype.ts", "utf8");
const reconciliation = readFileSync("docs/DATA_RECONCILIATION_REQUIRED.md", "utf8");
const tables = [...sql.matchAll(/create table public\.([a-z_]+)/g)].map((match) => match[1]);
const required = ["profiles","roles","permissions","departments","department_members","tasks","task_assignees","task_dependencies","comments","attachments","reports","report_periods","content_items","sponsors","sponsor_contacts","milestones","decisions","approvals","resources","audit_events","agents","agent_runs","company_brain_items","notifications"];

required.forEach((table) => {
  assert(tables.includes(table), `missing table ${table}`);
  assert(sql.includes(`alter table public.${table} enable row level security`), `missing RLS ${table}`);
});
assert(sql.includes("actor_type='human' and actor_id=auth.uid() and agent_id is null"), "human audit policy must fail closed");
assert(sql.includes("authority_level public.authority_level not null default 'level_0'"), "agents must default to Level 0");
assert(agentPolicy.includes('"external_message.send"') && agentPolicy.includes('"payment.approve"'), "prohibited actions incomplete");
assert(migration.includes('classification: "SAMPLE / UNAPPROVED"'), "migration classification missing");
["Festival dates","Festival pillars","Sponsor relationships","Approval authorities","Readiness"].forEach((item) => assert(reconciliation.includes(item), `reconciliation missing ${item}`));
execFileSync("git", ["diff", "--quiet", "--", "index.html"]);
console.log(`Foundation validation passed: ${tables.length} tables, required RLS, Level 0 agent default, audit guardrail, reconciliation, and unchanged index.html.`);
