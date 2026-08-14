-- Phase 2B: operational core. All methodology and fixtures remain SAMPLE / UNAPPROVED.
insert into public.permissions(key,description) values
 ('department.people_read','Read authorized department people'),
 ('task.comment','Comment on authorized tasks'),
 ('task.assign','Assign authorized organization members to tasks')
on conflict(key) do nothing;

alter table public.departments add column metadata jsonb not null default '{}'::jsonb;
alter table public.departments add constraint departments_readiness_range check(readiness is null or readiness between 0 and 100);
alter table public.tasks add column updated_by uuid references public.profiles(id);
alter table public.tasks add column archived_at timestamptz;
alter table public.tasks add column ai_owner_agent_id uuid references public.agents(id) on delete set null;
alter table public.reports add column progress_wins text;
alter table public.reports add column reviewer_id uuid references public.profiles(id);
alter table public.reports add column review_state text not null default 'pending' check(review_state in('pending','in_review','changes_requested','accepted'));
alter table public.reports add column review_comments text;
alter table public.reports add column reviewed_at timestamptz;

create or replace function public.prevent_operational_scope_violation() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare target_org uuid; related_org uuid;
begin
 if tg_table_name='task_assignees' then
  select organization_id into target_org from public.tasks where id=new.task_id;
  select organization_id into related_org from public.organization_members where id=new.organization_member_id;
 elsif tg_table_name='task_dependencies' then
  select organization_id into target_org from public.tasks where id=new.task_id;
  select organization_id into related_org from public.tasks where id=new.depends_on_task_id;
 elsif tg_table_name='reports' then
  target_org:=new.organization_id; select organization_id into related_org from public.departments where id=new.department_id;
 elsif tg_table_name='department_members' then
  select organization_id into target_org from public.departments where id=new.department_id;
  select organization_id into related_org from public.organization_members where id=new.organization_member_id;
 end if;
 if target_org is null or related_org is distinct from target_org then raise exception 'operational relationship crosses organization boundary'; end if;
 return new;
end; $$;
create trigger task_assignees_operational_scope before insert or update on public.task_assignees for each row execute function public.prevent_operational_scope_violation();
create trigger task_dependencies_operational_scope before insert or update on public.task_dependencies for each row execute function public.prevent_operational_scope_violation();
create trigger reports_operational_scope before insert or update on public.reports for each row execute function public.prevent_operational_scope_violation();

create or replace function public.can_manage_task(target_task_id uuid,target_organization_id uuid,target_department_id uuid) returns boolean
language sql stable security definer set search_path=public,pg_temp as $$
 select public.is_org_member(target_organization_id) and (
  (public.has_permission(target_organization_id,'task.manage_department') and target_department_id is not null and
   (public.is_department_member(target_organization_id,target_department_id) or public.has_permission(target_organization_id,'department.read_all')))
  or (public.has_permission(target_organization_id,'task.manage_assigned') and exists(
   select 1 from public.task_assignees ta join public.organization_members om on om.id=ta.organization_member_id
   where ta.task_id=target_task_id and om.profile_id=auth.uid() and om.status='active')));
$$;
revoke all on function public.can_manage_task(uuid,uuid,uuid) from public;
grant execute on function public.can_manage_task(uuid,uuid,uuid) to authenticated;

drop policy if exists tasks_write on public.tasks;
create policy tasks_insert on public.tasks for insert to authenticated with check(
 created_by=auth.uid() and public.has_permission(organization_id,'task.manage_department') and department_id is not null and
 (public.is_department_member(organization_id,department_id) or public.has_permission(organization_id,'department.read_all')));
create policy tasks_update on public.tasks for update to authenticated using(public.can_manage_task(id,organization_id,department_id))
 with check(public.can_manage_task(id,organization_id,department_id) and (updated_by is null or updated_by=auth.uid()));
create policy tasks_delete on public.tasks for delete to authenticated using(public.has_permission(organization_id,'workspace.admin'));
drop policy if exists task_assignees_write on public.task_assignees;
create policy task_assignees_insert on public.task_assignees for insert to authenticated with check(exists(
 select 1 from public.tasks t where t.id=task_id and public.has_permission(t.organization_id,'task.assign') and public.can_manage_task(t.id,t.organization_id,t.department_id) and assigned_by=auth.uid()));
create policy task_assignees_delete on public.task_assignees for delete to authenticated using(exists(
 select 1 from public.tasks t where t.id=task_id and public.has_permission(t.organization_id,'task.assign') and public.can_manage_task(t.id,t.organization_id,t.department_id)));
drop policy if exists task_dependencies_write on public.task_dependencies;
create policy task_dependencies_write on public.task_dependencies for all to authenticated using(exists(
 select 1 from public.tasks t where t.id=task_id and public.can_manage_task(t.id,t.organization_id,t.department_id))) with check(exists(
 select 1 from public.tasks t where t.id=task_id and public.can_manage_task(t.id,t.organization_id,t.department_id)));

drop policy if exists comments_insert on public.comments;
create policy comments_insert on public.comments for insert to authenticated with check(author_id=auth.uid() and public.is_org_member(organization_id) and
 (target_type<>'task' or exists(select 1 from public.tasks t where t.id=target_id and public.can_access_sensitive_record(t.organization_id,t.department_id,t.visibility,'task.read',null,'task.manage_department','workspace.admin'))));
create policy comments_update on public.comments for update to authenticated using(author_id=auth.uid()) with check(author_id=auth.uid());

create or replace function public.audit_operational_mutation() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare org_id uuid; target uuid;
begin
 if tg_table_name='task_assignees' then select organization_id into org_id from public.tasks where id=coalesce(new.task_id,old.task_id); target:=coalesce(new.task_id,old.task_id);
 elsif tg_table_name='task_dependencies' then select organization_id into org_id from public.tasks where id=coalesce(new.task_id,old.task_id); target:=coalesce(new.task_id,old.task_id);
 elsif tg_table_name='department_members' then select organization_id into org_id from public.departments where id=coalesce(new.department_id,old.department_id); target:=coalesce(new.department_id,old.department_id);
 else org_id:=coalesce(new.organization_id,old.organization_id); target:=coalesce(new.id,old.id); end if;
 insert into public.audit_events(organization_id,actor_type,actor_id,action,target_type,target_id,before_state,after_state,source,visibility,context)
 values(org_id,case when auth.uid() is null then 'system'::public.actor_type else 'human'::public.actor_type end,auth.uid(),
  'operational.'||tg_table_name||'.'||lower(tg_op),tg_table_name,target,case when tg_op='INSERT' then null else to_jsonb(old) end,
  case when tg_op='DELETE' then null else to_jsonb(new) end,'database_trigger','restricted',jsonb_build_object('phase','2B'));
 return case when tg_op='DELETE' then old else new end;
end; $$;
create trigger departments_operational_audit after insert or update or delete on public.departments for each row execute function public.audit_operational_mutation();
create trigger department_members_operational_audit after insert or update or delete on public.department_members for each row execute function public.audit_operational_mutation();
create trigger tasks_operational_audit after insert or update or delete on public.tasks for each row execute function public.audit_operational_mutation();
create trigger task_assignees_operational_audit after insert or delete on public.task_assignees for each row execute function public.audit_operational_mutation();
create trigger task_dependencies_operational_audit after insert or delete on public.task_dependencies for each row execute function public.audit_operational_mutation();
create trigger comments_operational_audit after insert or update or delete on public.comments for each row execute function public.audit_operational_mutation();
create trigger report_periods_operational_audit after insert or update or delete on public.report_periods for each row execute function public.audit_operational_mutation();
create trigger reports_operational_audit after insert or update or delete on public.reports for each row execute function public.audit_operational_mutation();

create or replace function public.operational_overview(target_organization_id uuid) returns jsonb
language sql stable set search_path=public,pg_temp as $$
 select jsonb_build_object(
  'operational_readiness_provisional',coalesce((select round(avg(readiness),1) from public.departments where organization_id=target_organization_id and status='active' and readiness is not null),0),
  'open_tasks',(select count(*) from public.tasks where organization_id=target_organization_id and status not in('completed','archived')),
  'overdue_tasks',(select count(*) from public.tasks where organization_id=target_organization_id and status not in('completed','archived') and due_at<now()),
  'high_risk_tasks',(select count(*) from public.tasks where organization_id=target_organization_id and status not in('completed','archived') and (priority='critical' or status='blocked')),
  'reports_due',(select count(*) from public.report_periods where organization_id=target_organization_id and status='active' and due_at>=now()),
  'reports_submitted',(select count(*) from public.reports where organization_id=target_organization_id and status in('submitted','reviewed','accepted')),
  'leadership_requests',(select count(*) from public.reports where organization_id=target_organization_id and nullif(btrim(leadership_request),'') is not null),
  'pending_decisions',(select count(*) from public.decisions where organization_id=target_organization_id and status in('proposed','under_review','awaiting_approval')));
$$;
grant execute on function public.operational_overview(uuid) to authenticated;
