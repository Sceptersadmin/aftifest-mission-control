create extension if not exists pgcrypto;

create type public.record_status as enum ('draft','active','archived');
create type public.verification_status as enum ('sample_unapproved','unverified','verified','rejected');
create type public.visibility_level as enum ('public','organization','department','restricted');
create type public.actor_type as enum ('human','agent','system');
create type public.authority_level as enum ('level_0','level_1','level_2','level_3');
create type public.agent_run_mode as enum ('read','suggest','simulate','execute');
create type public.agent_run_status as enum ('requested','denied','simulated','completed','failed','awaiting_approval');
create type public.approval_status as enum ('pending','approved','rejected','expired','cancelled');
create type public.decision_status as enum ('proposed','under_review','awaiting_approval','approved','rejected','deferred','implemented','closed');

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  status public.record_status not null default 'active',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  email text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id,display_name,email)
  values (new.id,coalesce(new.raw_user_meta_data->>'display_name',new.email),new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users for each row execute procedure public.handle_new_auth_user();

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  key text not null,
  name text not null,
  description text,
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  unique nulls not distinct (organization_id, key)
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  description text not null
);

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  status public.record_status not null default 'active',
  joined_at timestamptz not null default now(),
  unique (organization_id, profile_id)
);

create table public.member_roles (
  organization_member_id uuid not null references public.organization_members(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete cascade,
  granted_by uuid references public.profiles(id),
  granted_at timestamptz not null default now(),
  primary key (organization_member_id, role_id)
);

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  description text,
  health text,
  readiness numeric(5,2),
  verification_status public.verification_status not null default 'sample_unapproved',
  status public.record_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, name)
);

create table public.department_members (
  department_id uuid not null references public.departments(id) on delete cascade,
  organization_member_id uuid not null references public.organization_members(id) on delete cascade,
  title text,
  is_lead boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (department_id, organization_member_id)
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  department_id uuid references public.departments(id) on delete set null,
  title text not null,
  description text,
  status text not null default 'backlog',
  priority text not null default 'medium',
  progress smallint not null default 0 check (progress between 0 and 100),
  due_at timestamptz,
  created_by uuid references public.profiles(id),
  verification_status public.verification_status not null default 'sample_unapproved',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.task_assignees (
  task_id uuid not null references public.tasks(id) on delete cascade,
  organization_member_id uuid not null references public.organization_members(id) on delete cascade,
  assigned_by uuid references public.profiles(id),
  assigned_at timestamptz not null default now(),
  primary key (task_id, organization_member_id)
);

create table public.task_dependencies (
  task_id uuid not null references public.tasks(id) on delete cascade,
  depends_on_task_id uuid not null references public.tasks(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (task_id, depends_on_task_id),
  check (task_id <> depends_on_task_id)
);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  target_type text not null,
  target_id uuid not null,
  body text not null,
  author_id uuid not null references public.profiles(id),
  visibility public.visibility_level not null default 'organization',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  target_type text not null,
  target_id uuid not null,
  storage_bucket text not null default 'mission-control-private',
  storage_path text not null,
  filename text not null,
  content_type text,
  size_bytes bigint check (size_bytes >= 0),
  uploaded_by uuid not null references public.profiles(id),
  visibility public.visibility_level not null default 'organization',
  created_at timestamptz not null default now(),
  unique (storage_bucket, storage_path)
);

create table public.report_periods (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  label text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  due_at timestamptz not null,
  status public.record_status not null default 'active',
  created_at timestamptz not null default now(),
  check (starts_at < ends_at and ends_at <= due_at)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  report_period_id uuid not null references public.report_periods(id) on delete restrict,
  department_id uuid not null references public.departments(id) on delete restrict,
  reporter_id uuid not null references public.profiles(id),
  health text not null,
  summary text not null,
  blockers text,
  leadership_request text,
  status text not null default 'submitted',
  verification_status public.verification_status not null default 'sample_unapproved',
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (report_period_id, department_id)
);

create table public.content_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  title text not null,
  platform text not null,
  status text not null default 'idea',
  owner_id uuid references public.profiles(id),
  scheduled_at timestamptz,
  asset_url text,
  visibility public.visibility_level not null default 'organization',
  verification_status public.verification_status not null default 'sample_unapproved',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.sponsors (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  category text,
  stage text not null default 'prospecting',
  owner_id uuid references public.profiles(id),
  currency text,
  estimated_value numeric(18,2),
  next_action text,
  next_action_at timestamptz,
  visibility public.visibility_level not null default 'restricted',
  verification_status public.verification_status not null default 'sample_unapproved',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.sponsor_contacts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  sponsor_id uuid not null references public.sponsors(id) on delete cascade,
  name text not null,
  title text,
  email text,
  phone text,
  verification_status public.verification_status not null default 'sample_unapproved',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.milestones (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  title text not null,
  description text,
  workstream text,
  status text not null default 'active',
  due_at timestamptz,
  verification_status public.verification_status not null default 'sample_unapproved',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.approval_rules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  action text not null,
  target_type text not null,
  eligible_role_ids uuid[] not null default '{}',
  minimum_approvals smallint not null check (minimum_approvals > 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.decisions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  title text not null,
  proposed_by uuid not null references public.profiles(id),
  requested_by uuid references public.profiles(id),
  owner_id uuid references public.profiles(id),
  due_at timestamptz,
  impact text,
  supporting_context jsonb not null default '{}'::jsonb,
  status public.decision_status not null default 'proposed',
  outcome text,
  approval_rule_id uuid references public.approval_rules(id) on delete set null,
  visibility public.visibility_level not null default 'restricted',
  verification_status public.verification_status not null default 'sample_unapproved',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.approvals (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  decision_id uuid references public.decisions(id) on delete cascade,
  target_type text not null default 'decision',
  target_id uuid not null,
  step_order smallint not null check (step_order > 0),
  eligible_role_id uuid references public.roles(id) on delete restrict,
  approver_id uuid references public.profiles(id),
  status public.approval_status not null default 'pending',
  note text,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  unique (target_type, target_id, step_order)
);

create table public.resources (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  title text not null,
  resource_type text,
  url text,
  description text,
  owner_id uuid references public.profiles(id),
  visibility public.visibility_level not null default 'organization',
  verification_status public.verification_status not null default 'sample_unapproved',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_type public.actor_type not null,
  actor_id uuid references public.profiles(id),
  agent_id uuid,
  action text not null,
  target_type text not null,
  target_id uuid,
  occurred_at timestamptz not null default now(),
  before_state jsonb,
  after_state jsonb,
  approval_id uuid references public.approvals(id) on delete set null,
  source text not null,
  context jsonb not null default '{}'::jsonb,
  correlation_id uuid not null default gen_random_uuid()
);

create table public.agents (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  key text not null,
  name text not null,
  description text,
  authority_level public.authority_level not null default 'level_0',
  provider_key text not null default 'disabled',
  policy jsonb not null default '{}'::jsonb,
  active boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, key)
);

alter table public.audit_events add constraint audit_events_agent_fk foreign key (agent_id) references public.agents(id) on delete set null;

create table public.agent_runs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  agent_id uuid not null references public.agents(id) on delete restrict,
  initiated_by uuid references public.profiles(id),
  mode public.agent_run_mode not null default 'read',
  status public.agent_run_status not null default 'requested',
  requested_action text not null,
  required_permission text not null,
  request_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb,
  citations jsonb not null default '[]'::jsonb,
  policy_decision jsonb not null default '{}'::jsonb,
  approval_id uuid references public.approvals(id) on delete set null,
  audit_event_id uuid references public.audit_events(id) on delete set null,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.company_brain_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  title text not null,
  summary text,
  content text,
  source_type text not null,
  source_reference text not null,
  owner_id uuid references public.profiles(id),
  classification text not null,
  visibility public.visibility_level not null default 'restricted',
  verification_status public.verification_status not null default 'unverified',
  provenance jsonb not null default '{}'::jsonb,
  effective_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text,
  target_type text,
  target_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index tasks_org_due_idx on public.tasks (organization_id, due_at);
create index decisions_org_status_idx on public.decisions (organization_id, status, due_at);
create index audit_events_org_time_idx on public.audit_events (organization_id, occurred_at desc);
create index brain_org_visibility_idx on public.company_brain_items (organization_id, visibility, verification_status);
create index agent_runs_org_time_idx on public.agent_runs (organization_id, started_at desc);

create or replace function public.is_org_member(target_organization_id uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.organization_members om
    where om.organization_id = target_organization_id
      and om.profile_id = auth.uid()
      and om.status = 'active'
  );
$$;

create or replace function public.has_permission(target_organization_id uuid, requested_permission text)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1
    from public.organization_members om
    join public.member_roles mr on mr.organization_member_id = om.id
    join public.role_permissions rp on rp.role_id = mr.role_id
    join public.permissions p on p.id = rp.permission_id
    where om.organization_id = target_organization_id
      and om.profile_id = auth.uid()
      and om.status = 'active'
      and p.key in (requested_permission, 'workspace.admin')
  );
$$;

revoke all on function public.is_org_member(uuid) from public;
revoke all on function public.has_permission(uuid,text) from public;
grant execute on function public.is_org_member(uuid) to authenticated;
grant execute on function public.has_permission(uuid,text) to authenticated;

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.organization_members enable row level security;
alter table public.member_roles enable row level security;
alter table public.departments enable row level security;
alter table public.department_members enable row level security;
alter table public.tasks enable row level security;
alter table public.task_assignees enable row level security;
alter table public.task_dependencies enable row level security;
alter table public.comments enable row level security;
alter table public.attachments enable row level security;
alter table public.report_periods enable row level security;
alter table public.reports enable row level security;
alter table public.content_items enable row level security;
alter table public.sponsors enable row level security;
alter table public.sponsor_contacts enable row level security;
alter table public.milestones enable row level security;
alter table public.approval_rules enable row level security;
alter table public.decisions enable row level security;
alter table public.approvals enable row level security;
alter table public.resources enable row level security;
alter table public.audit_events enable row level security;
alter table public.agents enable row level security;
alter table public.agent_runs enable row level security;
alter table public.company_brain_items enable row level security;
alter table public.notifications enable row level security;

create policy organizations_select on public.organizations for select to authenticated using (public.is_org_member(id));
create policy profiles_self_select on public.profiles for select to authenticated using (id = auth.uid());
create policy profiles_self_update on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy permissions_member_select on public.permissions for select to authenticated using (exists (select 1 from public.organization_members om where om.profile_id = auth.uid() and om.status = 'active'));
create policy roles_member_select on public.roles for select to authenticated using (organization_id is null or public.is_org_member(organization_id));
create policy role_permissions_member_select on public.role_permissions for select to authenticated using (exists (select 1 from public.roles r where r.id = role_id and (r.organization_id is null or public.is_org_member(r.organization_id))));
create policy organization_members_select on public.organization_members for select to authenticated using (profile_id = auth.uid() or public.has_permission(organization_id,'workspace.admin'));
create policy member_roles_select on public.member_roles for select to authenticated using (exists (select 1 from public.organization_members om where om.id = organization_member_id and (om.profile_id = auth.uid() or public.has_permission(om.organization_id,'workspace.admin'))));

create policy departments_select on public.departments for select to authenticated using (public.has_permission(organization_id,'department.read'));
create policy departments_write on public.departments for all to authenticated using (public.has_permission(organization_id,'department.manage')) with check (public.has_permission(organization_id,'department.manage'));
create policy department_members_select on public.department_members for select to authenticated using (exists (select 1 from public.departments d where d.id=department_id and public.has_permission(d.organization_id,'department.read')));
create policy department_members_write on public.department_members for all to authenticated using (exists (select 1 from public.departments d where d.id=department_id and public.has_permission(d.organization_id,'department.manage'))) with check (exists (select 1 from public.departments d where d.id=department_id and public.has_permission(d.organization_id,'department.manage')));

create policy tasks_select on public.tasks for select to authenticated using (public.has_permission(organization_id,'task.read'));
create policy tasks_write on public.tasks for all to authenticated using (public.has_permission(organization_id,'task.manage_department')) with check (public.has_permission(organization_id,'task.manage_department'));
create policy task_assignees_select on public.task_assignees for select to authenticated using (exists (select 1 from public.tasks t where t.id=task_id and public.has_permission(t.organization_id,'task.read')));
create policy task_assignees_write on public.task_assignees for all to authenticated using (exists (select 1 from public.tasks t where t.id=task_id and public.has_permission(t.organization_id,'task.manage_department'))) with check (exists (select 1 from public.tasks t where t.id=task_id and public.has_permission(t.organization_id,'task.manage_department')));
create policy task_dependencies_select on public.task_dependencies for select to authenticated using (exists (select 1 from public.tasks t where t.id=task_id and public.has_permission(t.organization_id,'task.read')));
create policy task_dependencies_write on public.task_dependencies for all to authenticated using (exists (select 1 from public.tasks t where t.id=task_id and public.has_permission(t.organization_id,'task.manage_department'))) with check (exists (select 1 from public.tasks t where t.id=task_id and public.has_permission(t.organization_id,'task.manage_department')));

create policy comments_select on public.comments for select to authenticated using (public.is_org_member(organization_id));
create policy comments_insert on public.comments for insert to authenticated with check (public.is_org_member(organization_id) and author_id=auth.uid());
create policy attachments_select on public.attachments for select to authenticated using (public.is_org_member(organization_id));
create policy attachments_insert on public.attachments for insert to authenticated with check (public.is_org_member(organization_id) and uploaded_by=auth.uid());

create policy report_periods_select on public.report_periods for select to authenticated using (public.is_org_member(organization_id));
create policy report_periods_write on public.report_periods for all to authenticated using (public.has_permission(organization_id,'report.review')) with check (public.has_permission(organization_id,'report.review'));
create policy reports_select on public.reports for select to authenticated using (public.is_org_member(organization_id));
create policy reports_insert on public.reports for insert to authenticated with check (public.has_permission(organization_id,'report.submit') and reporter_id=auth.uid());
create policy reports_review on public.reports for update to authenticated using (public.has_permission(organization_id,'report.review')) with check (public.has_permission(organization_id,'report.review'));

create policy content_select on public.content_items for select to authenticated using (public.has_permission(organization_id,'content.read'));
create policy content_write on public.content_items for all to authenticated using (public.has_permission(organization_id,'content.manage')) with check (public.has_permission(organization_id,'content.manage'));
create policy sponsors_select on public.sponsors for select to authenticated using (public.has_permission(organization_id,'sponsor.read'));
create policy sponsors_write on public.sponsors for all to authenticated using (public.has_permission(organization_id,'sponsor.manage')) with check (public.has_permission(organization_id,'sponsor.manage'));
create policy sponsor_contacts_select on public.sponsor_contacts for select to authenticated using (public.has_permission(organization_id,'sponsor.read'));
create policy sponsor_contacts_write on public.sponsor_contacts for all to authenticated using (public.has_permission(organization_id,'sponsor.manage')) with check (public.has_permission(organization_id,'sponsor.manage'));
create policy milestones_select on public.milestones for select to authenticated using (public.is_org_member(organization_id));
create policy milestones_admin on public.milestones for all to authenticated using (public.has_permission(organization_id,'department.manage')) with check (public.has_permission(organization_id,'department.manage'));

create policy decisions_select on public.decisions for select to authenticated using (public.has_permission(organization_id,'decision.read'));
create policy decisions_insert on public.decisions for insert to authenticated with check (public.has_permission(organization_id,'decision.propose') and proposed_by=auth.uid());
create policy decisions_update on public.decisions for update to authenticated using (public.has_permission(organization_id,'decision.propose')) with check (public.has_permission(organization_id,'decision.propose'));
create policy approval_rules_select on public.approval_rules for select to authenticated using (public.has_permission(organization_id,'decision.read'));
create policy approval_rules_admin on public.approval_rules for all to authenticated using (public.has_permission(organization_id,'workspace.admin')) with check (public.has_permission(organization_id,'workspace.admin'));
create policy approvals_select on public.approvals for select to authenticated using (public.has_permission(organization_id,'decision.read'));
create policy approvals_decide on public.approvals for update to authenticated using (public.has_permission(organization_id,'decision.approve')) with check (public.has_permission(organization_id,'decision.approve'));

create policy resources_select on public.resources for select to authenticated using (public.has_permission(organization_id,'resource.read'));
create policy resources_write on public.resources for all to authenticated using (public.has_permission(organization_id,'resource.manage')) with check (public.has_permission(organization_id,'resource.manage'));
create policy audit_select on public.audit_events for select to authenticated using (public.has_permission(organization_id,'audit.read'));
create policy audit_insert on public.audit_events for insert to authenticated with check (public.is_org_member(organization_id) and actor_type='human' and actor_id=auth.uid() and agent_id is null);
create policy agents_select on public.agents for select to authenticated using (public.has_permission(organization_id,'agent.read'));
create policy agents_admin on public.agents for all to authenticated using (public.has_permission(organization_id,'agent.configure')) with check (public.has_permission(organization_id,'agent.configure'));
create policy agent_runs_select on public.agent_runs for select to authenticated using (public.has_permission(organization_id,'agent.read'));
create policy agent_runs_insert on public.agent_runs for insert to authenticated with check (public.has_permission(organization_id,'agent.read') and initiated_by=auth.uid());
create policy brain_select on public.company_brain_items for select to authenticated using (public.has_permission(organization_id,'brain.read'));
create policy brain_write on public.company_brain_items for all to authenticated using (public.has_permission(organization_id,'brain.manage')) with check (public.has_permission(organization_id,'brain.manage'));
create policy notifications_self_select on public.notifications for select to authenticated using (recipient_id=auth.uid() and public.is_org_member(organization_id));
create policy notifications_self_update on public.notifications for update to authenticated using (recipient_id=auth.uid()) with check (recipient_id=auth.uid());

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;

insert into storage.buckets (id,name,public,file_size_limit)
values ('mission-control-private','mission-control-private',false,26214400)
on conflict (id) do nothing;

create policy storage_org_read on storage.objects for select to authenticated
using (bucket_id='mission-control-private' and public.is_org_member((storage.foldername(name))[1]::uuid));

create policy storage_org_upload on storage.objects for insert to authenticated
with check (bucket_id='mission-control-private' and public.is_org_member((storage.foldername(name))[1]::uuid) and owner_id=auth.uid()::text);
