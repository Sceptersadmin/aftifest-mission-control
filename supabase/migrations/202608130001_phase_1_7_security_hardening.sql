-- Phase 1.7: record sensitivity, department scope, and trusted audit boundaries.

insert into public.permissions(key,description) values
 ('department.read_all','Read records across departments'),
 ('brain.read_department','Read Company Brain items in assigned departments'),
 ('brain.read_restricted','Read explicitly restricted Company Brain items'),
 ('brain.read_confidential','Read confidential Company Brain items'),
 ('governance.read_confidential','Read confidential governance records'),
 ('resource.read_department','Read resources in assigned departments'),
 ('resource.read_restricted','Read restricted resources'),
 ('resource.read_confidential','Read confidential resources'),
 ('content.read_department','Read content in assigned departments'),
 ('content.read_restricted','Read restricted content'),
 ('content.read_confidential','Read confidential content'),
 ('attachment.read_department','Read attachments in assigned departments'),
 ('attachment.read_restricted','Read restricted attachments'),
 ('attachment.read_confidential','Read confidential attachments'),
 ('audit.read_restricted','Read restricted audit events'),
 ('audit.read_confidential','Read confidential audit events')
on conflict (key) do nothing;

alter table public.company_brain_items add column department_id uuid references public.departments(id) on delete set null;
alter table public.resources add column department_id uuid references public.departments(id) on delete set null;
alter table public.content_items add column department_id uuid references public.departments(id) on delete set null;
alter table public.attachments add column department_id uuid references public.departments(id) on delete set null;
alter table public.tasks add column visibility public.visibility_level not null default 'department';
alter table public.reports add column visibility public.visibility_level not null default 'department';
alter table public.audit_events add column visibility public.visibility_level not null default 'restricted';

create or replace function public.is_department_member(target_organization_id uuid, target_department_id uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp
as $$
  select target_department_id is not null and exists (
    select 1 from public.department_members dm
    join public.departments d on d.id=dm.department_id
    join public.organization_members om on om.id=dm.organization_member_id
    where d.id=target_department_id and d.organization_id=target_organization_id
      and om.organization_id=target_organization_id and om.profile_id=auth.uid() and om.status='active'
  );
$$;

create or replace function public.can_access_sensitive_record(
  target_organization_id uuid,
  target_department_id uuid,
  target_visibility public.visibility_level,
  base_capability text,
  department_capability text,
  restricted_capability text,
  confidential_capability text
) returns boolean language sql stable security definer set search_path = public, pg_temp
as $$
  select target_organization_id is not null
    and target_visibility is not null
    and public.is_org_member(target_organization_id)
    and public.has_permission(target_organization_id,base_capability)
    and case target_visibility
      when 'public' then true
      when 'organization' then true
      when 'department' then target_department_id is not null and (
        (public.is_department_member(target_organization_id,target_department_id)
          and (department_capability is null or public.has_permission(target_organization_id,department_capability)
            or public.has_permission(target_organization_id,base_capability)))
        or public.has_permission(target_organization_id,'department.read_all')
      )
      when 'restricted' then restricted_capability is not null and public.has_permission(target_organization_id,restricted_capability)
      when 'confidential' then confidential_capability is not null and public.has_permission(target_organization_id,confidential_capability)
      else false
    end;
$$;

create or replace function public.can_access_attachment(target_attachment_id uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.attachments a where a.id=target_attachment_id
      and public.can_access_sensitive_record(a.organization_id,a.department_id,a.visibility,
        'resource.read','attachment.read_department','attachment.read_restricted','attachment.read_confidential')
  );
$$;

revoke all on function public.is_department_member(uuid,uuid) from public;
revoke all on function public.can_access_sensitive_record(uuid,uuid,public.visibility_level,text,text,text,text) from public;
revoke all on function public.can_access_attachment(uuid) from public;
grant execute on function public.is_department_member(uuid,uuid) to authenticated;
grant execute on function public.can_access_sensitive_record(uuid,uuid,public.visibility_level,text,text,text,text) to authenticated;
grant execute on function public.can_access_attachment(uuid) to authenticated;

drop policy if exists department_members_select on public.department_members;
create policy department_members_select on public.department_members for select to authenticated using (
  exists (select 1 from public.departments d where d.id=department_id and public.has_permission(d.organization_id,'department.read')
    and (public.is_department_member(d.organization_id,d.id) or public.has_permission(d.organization_id,'department.read_all')))
);

drop policy if exists tasks_select on public.tasks;
drop policy if exists tasks_write on public.tasks;
create policy tasks_select on public.tasks for select to authenticated using (
 public.can_access_sensitive_record(organization_id,department_id,visibility,'task.read',null,'task.manage_department','workspace.admin'));
create policy tasks_write on public.tasks for all to authenticated using (
 public.has_permission(organization_id,'task.manage_department') and department_id is not null
 and (public.is_department_member(organization_id,department_id) or public.has_permission(organization_id,'department.read_all')))
with check (public.has_permission(organization_id,'task.manage_department') and department_id is not null
 and (public.is_department_member(organization_id,department_id) or public.has_permission(organization_id,'department.read_all')));

drop policy if exists reports_select on public.reports;
drop policy if exists reports_insert on public.reports;
drop policy if exists reports_review on public.reports;
create policy reports_select on public.reports for select to authenticated using (
 public.can_access_sensitive_record(organization_id,department_id,visibility,'report.submit',null,'report.review','workspace.admin'));
create policy reports_insert on public.reports for insert to authenticated with check (
 reporter_id=auth.uid() and public.has_permission(organization_id,'report.submit') and public.is_department_member(organization_id,department_id));
create policy reports_review on public.reports for update to authenticated using (
 public.has_permission(organization_id,'report.review') and (public.is_department_member(organization_id,department_id) or public.has_permission(organization_id,'department.read_all')))
with check (public.has_permission(organization_id,'report.review') and (public.is_department_member(organization_id,department_id) or public.has_permission(organization_id,'department.read_all')));

drop policy if exists content_select on public.content_items;
drop policy if exists content_write on public.content_items;
create policy content_select on public.content_items for select to authenticated using (
 public.can_access_sensitive_record(organization_id,department_id,visibility,'content.read','content.read_department','content.read_restricted','content.read_confidential'));
create policy content_write on public.content_items for all to authenticated using (public.has_permission(organization_id,'content.manage'))
with check (public.has_permission(organization_id,'content.manage') and (visibility<>'department' or department_id is not null));

drop policy if exists resources_select on public.resources;
drop policy if exists resources_write on public.resources;
create policy resources_select on public.resources for select to authenticated using (
 public.can_access_sensitive_record(organization_id,department_id,visibility,'resource.read','resource.read_department','resource.read_restricted','resource.read_confidential'));
create policy resources_write on public.resources for all to authenticated using (public.has_permission(organization_id,'resource.manage'))
with check (public.has_permission(organization_id,'resource.manage') and (visibility<>'department' or department_id is not null));

drop policy if exists attachments_select on public.attachments;
drop policy if exists attachments_insert on public.attachments;
create policy attachments_select on public.attachments for select to authenticated using (
 public.can_access_sensitive_record(organization_id,department_id,visibility,'resource.read','attachment.read_department','attachment.read_restricted','attachment.read_confidential'));
create policy attachments_insert on public.attachments for insert to authenticated with check (
 uploaded_by=auth.uid() and public.is_org_member(organization_id) and storage_bucket='mission-control-private'
 and (visibility<>'department' or (department_id is not null and public.is_department_member(organization_id,department_id))));

drop policy if exists brain_select on public.company_brain_items;
drop policy if exists brain_write on public.company_brain_items;
create policy brain_select on public.company_brain_items for select to authenticated using (
 verification_status<>'rejected' and nullif(btrim(classification),'') is not null
 and public.can_access_sensitive_record(organization_id,department_id,visibility,'brain.read','brain.read_department','brain.read_restricted','brain.read_confidential'));
create policy brain_write on public.company_brain_items for all to authenticated using (public.has_permission(organization_id,'brain.manage'))
with check (public.has_permission(organization_id,'brain.manage') and nullif(btrim(classification),'') is not null
 and (visibility<>'department' or department_id is not null));

drop policy if exists decisions_select on public.decisions;
drop policy if exists decisions_insert on public.decisions;
drop policy if exists decisions_update on public.decisions;
drop policy if exists approvals_select on public.approvals;
drop policy if exists approvals_decide on public.approvals;
drop policy if exists approval_rules_select on public.approval_rules;
create policy decisions_select on public.decisions for select to authenticated using (
 public.can_access_sensitive_record(organization_id,null,visibility,'decision.read',null,'governance.read_restricted','governance.read_confidential'));
create policy decisions_insert on public.decisions for insert to authenticated with check (
 proposed_by=auth.uid() and public.has_permission(organization_id,'decision.propose')
 and public.can_access_sensitive_record(organization_id,null,visibility,'decision.read',null,'governance.read_restricted','governance.read_confidential'));
create policy decisions_update on public.decisions for update to authenticated using (
 (proposed_by=auth.uid() or public.has_permission(organization_id,'workspace.admin'))
 and public.has_permission(organization_id,'decision.propose')
 and public.can_access_sensitive_record(organization_id,null,visibility,'decision.read',null,'governance.read_restricted','governance.read_confidential'))
with check ((proposed_by=auth.uid() or public.has_permission(organization_id,'workspace.admin'))
 and public.has_permission(organization_id,'decision.propose')
 and public.can_access_sensitive_record(organization_id,null,visibility,'decision.read',null,'governance.read_restricted','governance.read_confidential'));
create policy approvals_select on public.approvals for select to authenticated using (
 public.has_permission(organization_id,'decision.read') and exists (
  select 1 from public.decisions d where d.id=decision_id and public.can_access_sensitive_record(d.organization_id,null,d.visibility,
   'decision.read',null,'governance.read_restricted','governance.read_confidential')));
create policy approvals_decide on public.approvals for update to authenticated using (
 public.has_permission(organization_id,'decision.approve') and (
  public.has_permission(organization_id,'workspace.admin') or exists (
   select 1 from public.organization_members om join public.member_roles mr on mr.organization_member_id=om.id
   where om.organization_id=approvals.organization_id and om.profile_id=auth.uid() and om.status='active' and mr.role_id=approvals.eligible_role_id)))
with check (public.has_permission(organization_id,'decision.approve') and approver_id=auth.uid());
create policy approval_rules_select on public.approval_rules for select to authenticated using (
 public.has_permission(organization_id,'governance.read_restricted'));

drop policy if exists audit_select on public.audit_events;
create policy audit_select on public.audit_events for select to authenticated using (
 public.can_access_sensitive_record(organization_id,null,visibility,'audit.read',null,'audit.read_restricted','audit.read_confidential'));
revoke update, delete on public.audit_events from authenticated;

drop policy if exists storage_org_read on storage.objects;
drop policy if exists storage_org_upload on storage.objects;
create policy storage_attachment_read on storage.objects for select to authenticated using (
 bucket_id='mission-control-private' and public.can_access_attachment(((storage.foldername(name))[4])::uuid));
create policy storage_attachment_upload on storage.objects for insert to authenticated with check (
 bucket_id='mission-control-private' and owner_id=auth.uid()::text
 and public.can_access_attachment(((storage.foldername(name))[4])::uuid)
 and exists (select 1 from public.attachments a where a.id=((storage.foldername(name))[4])::uuid and a.uploaded_by=auth.uid() and a.storage_path=name));
