-- Phase 2A: governed organization, provisioning, membership, role, and capability administration.
insert into public.permissions(key,description) values
 ('organization.manage','Manage organization settings'),
 ('user.provision','Manage organization-scoped provisioning requests'),
 ('membership.manage','Manage organization memberships'),
 ('role.manage','Manage organization roles and capability assignments')
on conflict (key) do nothing;

create type public.provisioning_status as enum ('pending','accepted','expired','cancelled');
create table public.user_provisioning_requests (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 email text not null check (position('@' in email)>1), display_name text, status public.provisioning_status not null default 'pending',
 requested_role_id uuid references public.roles(id) on delete set null, requested_by uuid not null references public.profiles(id),
 expires_at timestamptz not null default (now()+interval '7 days'), accepted_by uuid references public.profiles(id), accepted_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check ((status='accepted' and accepted_by is not null and accepted_at is not null) or (status<>'accepted' and accepted_by is null and accepted_at is null))
);
create unique index provisioning_one_pending_email_idx on public.user_provisioning_requests(organization_id,lower(email)) where status='pending';
alter table public.user_provisioning_requests enable row level security;

create or replace function public.prevent_administration_scope_violation() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare target_org uuid; member_org uuid;
begin
 if tg_table_name='member_roles' then
  select organization_id into member_org from public.organization_members where id=new.organization_member_id;
  select organization_id into target_org from public.roles where id=new.role_id;
  if member_org is null or target_org is distinct from member_org then raise exception 'role and membership organization mismatch'; end if;
 elsif tg_table_name='role_permissions' then
  select organization_id into target_org from public.roles where id=new.role_id;
  if target_org is null then raise exception 'global system role capabilities are immutable'; end if;
 elsif tg_table_name='department_members' then
  select organization_id into member_org from public.organization_members where id=new.organization_member_id;
  select organization_id into target_org from public.departments where id=new.department_id;
  if member_org is null or target_org is distinct from member_org then raise exception 'department and membership organization mismatch'; end if;
 elsif tg_table_name='user_provisioning_requests' and new.requested_role_id is not null then
  select organization_id into target_org from public.roles where id=new.requested_role_id;
  if target_org is distinct from new.organization_id then raise exception 'requested role belongs to another organization'; end if;
 end if; return new;
end; $$;
create trigger member_roles_scope_guard before insert or update on public.member_roles for each row execute function public.prevent_administration_scope_violation();
create trigger role_permissions_scope_guard before insert or update on public.role_permissions for each row execute function public.prevent_administration_scope_violation();
create trigger department_members_scope_guard before insert or update on public.department_members for each row execute function public.prevent_administration_scope_violation();
create trigger provisioning_scope_guard before insert or update on public.user_provisioning_requests for each row execute function public.prevent_administration_scope_violation();

create or replace function public.prevent_last_workspace_admin_removal() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare affected_member uuid; affected_org uuid; remaining_admins integer;
begin
 if tg_table_name='organization_members' and tg_op='UPDATE' and new.status='active' then return new; end if;
 if tg_table_name='member_roles' then affected_member:=old.organization_member_id; else affected_member:=old.id; end if;
 select organization_id into affected_org from public.organization_members where id=affected_member;
 if tg_table_name='member_roles' and not exists(select 1 from public.role_permissions rp join public.permissions p on p.id=rp.permission_id where rp.role_id=old.role_id and p.key='workspace.admin') then return old; end if;
 select count(distinct om.id) into remaining_admins from public.organization_members om
 join public.member_roles mr on mr.organization_member_id=om.id join public.role_permissions rp on rp.role_id=mr.role_id join public.permissions p on p.id=rp.permission_id
 where om.organization_id=affected_org and om.status='active' and p.key='workspace.admin' and om.id<>affected_member;
 if remaining_admins=0 then raise exception 'cannot remove or deactivate the last workspace administrator'; end if;
 return case when tg_op='DELETE' then old else new end;
end; $$;
create trigger member_roles_last_admin_guard before delete on public.member_roles for each row execute function public.prevent_last_workspace_admin_removal();
create trigger organization_members_last_admin_guard before update of status or delete on public.organization_members for each row execute function public.prevent_last_workspace_admin_removal();

create or replace function public.audit_administration_mutation() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare org_id uuid; target uuid;
begin
 if tg_table_name='organizations' then org_id:=coalesce(new.id,old.id); target:=org_id;
 elsif tg_table_name='member_roles' then select organization_id into org_id from public.organization_members where id=coalesce(new.organization_member_id,old.organization_member_id);
 elsif tg_table_name='role_permissions' then select organization_id into org_id from public.roles where id=coalesce(new.role_id,old.role_id);
 else org_id:=coalesce(new.organization_id,old.organization_id); target:=coalesce(new.id,old.id); end if;
 insert into public.audit_events(organization_id,actor_type,actor_id,action,target_type,target_id,before_state,after_state,source,visibility,context)
 values(org_id,case when auth.uid() is null then 'system'::public.actor_type else 'human'::public.actor_type end,auth.uid(),'administration.'||tg_table_name||'.'||lower(tg_op),tg_table_name,target,
  case when tg_op='INSERT' then null else to_jsonb(old) end,case when tg_op='DELETE' then null else to_jsonb(new) end,
  'database_trigger','restricted',jsonb_build_object('phase','2A'));
 return case when tg_op='DELETE' then old else new end;
end; $$;
create trigger organizations_admin_audit after update on public.organizations for each row execute function public.audit_administration_mutation();
create trigger provisioning_admin_audit after insert or update or delete on public.user_provisioning_requests for each row execute function public.audit_administration_mutation();
create trigger memberships_admin_audit after insert or update or delete on public.organization_members for each row execute function public.audit_administration_mutation();
create trigger roles_admin_audit after insert or update or delete on public.roles for each row execute function public.audit_administration_mutation();
create trigger member_roles_admin_audit after insert or delete on public.member_roles for each row execute function public.audit_administration_mutation();
create trigger role_permissions_admin_audit after insert or delete on public.role_permissions for each row execute function public.audit_administration_mutation();

create policy organizations_update on public.organizations for update to authenticated using (public.has_permission(id,'organization.manage')) with check (public.has_permission(id,'organization.manage'));
drop policy if exists profiles_self_select on public.profiles;
create policy profiles_member_select on public.profiles for select to authenticated using (id=auth.uid() or exists(
 select 1 from public.organization_members viewer join public.organization_members subject on subject.profile_id=profiles.id
 where viewer.profile_id=auth.uid() and viewer.status='active' and subject.status<>'archived' and viewer.organization_id=subject.organization_id
 and public.has_permission(viewer.organization_id,'membership.manage')));
create policy provisioning_select on public.user_provisioning_requests for select to authenticated using (public.has_permission(organization_id,'user.provision'));
create policy provisioning_insert on public.user_provisioning_requests for insert to authenticated with check (public.has_permission(organization_id,'user.provision') and requested_by=auth.uid());
create policy provisioning_update on public.user_provisioning_requests for update to authenticated using (public.has_permission(organization_id,'user.provision')) with check (public.has_permission(organization_id,'user.provision'));
create policy organization_members_admin_insert on public.organization_members for insert to authenticated with check (public.has_permission(organization_id,'membership.manage'));
create policy organization_members_admin_update on public.organization_members for update to authenticated using (public.has_permission(organization_id,'membership.manage')) with check (public.has_permission(organization_id,'membership.manage'));
create policy organization_members_admin_delete on public.organization_members for delete to authenticated using (public.has_permission(organization_id,'membership.manage'));
create policy roles_admin_insert on public.roles for insert to authenticated with check (organization_id is not null and public.has_permission(organization_id,'role.manage') and not is_system);
create policy roles_admin_update on public.roles for update to authenticated using (organization_id is not null and public.has_permission(organization_id,'role.manage') and not is_system) with check (organization_id is not null and public.has_permission(organization_id,'role.manage') and not is_system);
create policy roles_admin_delete on public.roles for delete to authenticated using (organization_id is not null and public.has_permission(organization_id,'role.manage') and not is_system);
create policy member_roles_admin_insert on public.member_roles for insert to authenticated with check (exists(select 1 from public.organization_members om where om.id=organization_member_id and public.has_permission(om.organization_id,'role.manage')));
create policy member_roles_admin_delete on public.member_roles for delete to authenticated using (exists(select 1 from public.organization_members om where om.id=organization_member_id and public.has_permission(om.organization_id,'role.manage')));
create policy role_permissions_admin_insert on public.role_permissions for insert to authenticated with check (exists(select 1 from public.roles r where r.id=role_id and r.organization_id is not null and public.has_permission(r.organization_id,'role.manage')));
create policy role_permissions_admin_delete on public.role_permissions for delete to authenticated using (exists(select 1 from public.roles r where r.id=role_id and r.organization_id is not null and public.has_permission(r.organization_id,'role.manage')));
grant select,insert,update,delete on public.user_provisioning_requests to authenticated;
