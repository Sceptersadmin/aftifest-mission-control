import { execFileSync } from "node:child_process";
import { createHmac } from "node:crypto";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { createClient } from "@supabase/supabase-js";

export const E2E_EMAIL = "phase17-member@test.invalid";
export const E2E_PASSWORD = "TEST-Only-Password-123!";
export const E2E_ADMIN_EMAIL = "phase2a-admin@test.invalid";

const organizationId = "81000000-0000-4000-8000-000000000001";
const roleId = "81000000-0000-4000-8000-000000000002";
const authorizedSourceId = "81000000-0000-4000-8000-000000000003";
const restrictedSourceId = "81000000-0000-4000-8000-000000000004";
const adminRoleId = "81000000-0000-4000-8000-000000000005";
const departmentId = "81000000-0000-4000-8000-000000000006";
const reportPeriodId = "81000000-0000-4000-8000-000000000007";

function dockerCommand() {
  if (process.platform !== "win32") return "docker";
  const candidates = [
    join(process.env.LOCALAPPDATA ?? "", "Programs", "DockerDesktop", "resources", "bin", "docker.exe"),
    join(process.env.LOCALAPPDATA ?? "", "Programs", "DockerDesktop", "resources", "bin", "docker.exe"),
    "C:\\Program Files\\Docker\\Docker\\resources\\bin\\docker.exe",
  ];
  return candidates.find(existsSync) ?? "docker.exe";
}

function localCredentials() {
  const output = execFileSync(dockerCommand(), ["inspect", "supabase_auth_aftifest-mission-control-local", "--format", "{{range .Config.Env}}{{println .}}{{end}}"], {
    encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], timeout: 30_000,
  });
  const secretLine = output.split(/\r?\n/).find((line) => line.startsWith("GOTRUE_JWT_SECRET="));
  if (!secretLine) throw new Error("Local Supabase Auth container did not expose its local JWT secret.");
  const secret = secretLine.slice("GOTRUE_JWT_SECRET=".length);
  const encode = (value) => Buffer.from(JSON.stringify(value)).toString("base64url");
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${encode({ alg: "HS256", typ: "JWT" })}.${encode({ iss: "supabase-demo", role: "service_role", iat: now, exp: now + 300 })}`;
  const token = `${unsigned}.${createHmac("sha256", secret).update(unsigned).digest("base64url")}`;
  return { apiUrl: "http://127.0.0.1:54321", serviceRoleKey: token };
}

async function must(result, operation) {
  result = await result;
  if (result.error) throw new Error(`${operation}: ${result.error.message}`);
  return result.data;
}

export async function provisionE2E() {
  const { apiUrl, serviceRoleKey } = localCredentials();
  const admin = createClient(apiUrl, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });

  const users = await must(admin.auth.admin.listUsers({ page: 1, perPage: 1000 }), "list TEST users");
  let user = users.users.find((candidate) => candidate.email === E2E_EMAIL);
  if (user) {
    user = await must(admin.auth.admin.updateUserById(user.id, { password: E2E_PASSWORD, email_confirm: true, user_metadata: { display_name: "Phase 1 E2E TEST Member" } }), "update TEST user").then((data) => data.user);
  } else {
    user = await must(admin.auth.admin.createUser({ email: E2E_EMAIL, password: E2E_PASSWORD, email_confirm: true, user_metadata: { display_name: "Phase 1 E2E TEST Member" } }), "create TEST user").then((data) => data.user);
  }
  if (!user) throw new Error("E2E TEST user provisioning returned no user.");

  let adminUser = users.users.find((candidate) => candidate.email === E2E_ADMIN_EMAIL);
  if (adminUser) {
    adminUser = await must(admin.auth.admin.updateUserById(adminUser.id, { password: E2E_PASSWORD, email_confirm: true, user_metadata: { display_name: "Phase 2A E2E TEST Administrator" } }), "update TEST administrator").then((data) => data.user);
  } else {
    adminUser = await must(admin.auth.admin.createUser({ email: E2E_ADMIN_EMAIL, password: E2E_PASSWORD, email_confirm: true, user_metadata: { display_name: "Phase 2A E2E TEST Administrator" } }), "create TEST administrator").then((data) => data.user);
  }
  if (!adminUser) throw new Error("E2E TEST administrator provisioning returned no user.");

  const sql = `
    insert into public.organizations(id,name,slug,metadata) values('${organizationId}','Organization A - E2E TEST / SAMPLE','organization-a-e2e-test','{"classification":"TEST / SAMPLE"}')
      on conflict(id) do update set name=excluded.name,metadata=excluded.metadata;
    insert into public.roles(id,organization_id,key,name,description,is_system) values('${roleId}','${organizationId}','e2e_team_member','E2E TEST Team Member','Minimum Playwright capabilities',false)
      on conflict(id) do update set name=excluded.name,description=excluded.description;
    insert into public.roles(id,organization_id,key,name,description,is_system) values('${adminRoleId}','${organizationId}','e2e_phase2a_admin','E2E TEST Phase 2A Administrator','TEST-only administration capabilities',false)
      on conflict(id) do update set name=excluded.name,description=excluded.description;
    delete from public.user_provisioning_requests where organization_id='${organizationId}' and email='playwright-provisioned@test.invalid';
    insert into public.organization_members(organization_id,profile_id,status) values('${organizationId}','${user.id}','active')
      on conflict(organization_id,profile_id) do update set status='active';
    insert into public.member_roles(organization_member_id,role_id)
      select id,'${roleId}' from public.organization_members where organization_id='${organizationId}' and profile_id='${user.id}'
      on conflict do nothing;
    insert into public.organization_members(organization_id,profile_id,status) values('${organizationId}','${adminUser.id}','active')
      on conflict(organization_id,profile_id) do update set status='active';
    insert into public.member_roles(organization_member_id,role_id)
      select id,'${adminRoleId}' from public.organization_members where organization_id='${organizationId}' and profile_id='${adminUser.id}'
      on conflict do nothing;
    insert into public.role_permissions(role_id,permission_id)
      select '${roleId}',id from public.permissions where key in ('department.read','task.read','report.submit','content.read','resource.read','brain.read','agent.read')
      on conflict do nothing;
    insert into public.role_permissions(role_id,permission_id)
      select '${adminRoleId}',id from public.permissions where key in ('workspace.admin','organization.manage','user.provision','membership.manage','role.manage','audit.read','audit.read_restricted','department.read','department.read_all','department.manage','department.people_read','task.read','task.manage_department','task.manage_assigned','task.assign','task.comment','report.submit','report.review','decision.read','decision.propose','decision.transition','decision.approve','decision.manage_rules','governance.read_restricted','governance.read_confidential','import.manage','import.execute')
      on conflict do nothing;
    insert into public.departments(id,organization_id,name,description,health,readiness,verification_status,metadata) values
      ('${departmentId}','${organizationId}','Phase 2B Operations - TEST / SAMPLE','TEST / SAMPLE / UNAPPROVED','Unassessed',0,'sample_unapproved','{"classification":"TEST / SAMPLE / UNAPPROVED"}')
      on conflict(id) do update set name=excluded.name,description=excluded.description;
    insert into public.department_members(department_id,organization_member_id,title,is_lead)
      select '${departmentId}',id,'TEST Member',false from public.organization_members where organization_id='${organizationId}' and profile_id in ('${user.id}','${adminUser.id}') on conflict do nothing;
    insert into public.report_periods(id,organization_id,label,starts_at,ends_at,due_at,status) values
      ('${reportPeriodId}','${organizationId}','Phase 2B TEST Reporting Period',now()-interval '1 day',now()+interval '1 day',now()+interval '2 days','active')
      on conflict(id) do update set label=excluded.label;
    insert into public.company_brain_items(id,organization_id,title,summary,source_type,source_reference,classification,visibility,verification_status) values
      ('${authorizedSourceId}','${organizationId}','Authorized TEST source','TEST / SAMPLE organization source','test','TEST / SAMPLE','internal','organization','verified'),
      ('${restrictedSourceId}','${organizationId}','Restricted TEST source','MUST NOT LEAK','test','TEST / SAMPLE','restricted','restricted','verified')
      on conflict(id) do update set title=excluded.title,summary=excluded.summary,classification=excluded.classification,visibility=excluded.visibility,verification_status=excluded.verification_status;
  `;
  execFileSync(dockerCommand(), ["exec", "-i", "supabase_db_aftifest-mission-control-local", "psql", "-v", "ON_ERROR_STOP=1", "-U", "postgres", "-d", "postgres"], {
    input: sql, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"], timeout: 30_000,
  });

  process.stdout.write(`Provisioned local E2E TEST identity ${E2E_EMAIL}.\n`);
}

provisionE2E().catch((error) => { console.error(error); process.exitCode = 1; });
