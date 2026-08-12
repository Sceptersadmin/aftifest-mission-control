import { readFileSync } from "node:fs";
import { describe,expect,it } from "vitest";

const sql=readFileSync("supabase/migrations/202608120001_phase_1_foundation.sql","utf8");
const required=["users","profiles","roles","permissions","departments","department_members","tasks","task_assignees","task_dependencies","comments","attachments","reports","report_periods","content_items","sponsors","sponsor_contacts","milestones","decisions","approvals","resources","audit_events","agents","agent_runs","company_brain_items","notifications"];
describe("database foundation",()=>{
  it("defines every requested domain",()=>required.filter((name)=>name!=="users").forEach((name)=>expect(sql).toContain(`create table public.${name}`)));
  it("enables RLS on every application table",()=>required.filter((name)=>!['users'].includes(name)).forEach((name)=>expect(sql).toContain(`alter table public.${name} enable row level security`)));
  it("keeps agents permission-bound",()=>expect(sql).toContain("public.has_permission(organization_id,'agent.read')"));
});
