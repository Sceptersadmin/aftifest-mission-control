-- Phase 2C: governance core. Authority configuration remains TEST / SAMPLE / UNAPPROVED.
insert into public.permissions(key,description) values
 ('decision.manage_rules','Administer governance rules'),
 ('decision.transition','Advance authorized decision lifecycles'),
 ('governance.read_confidential','Read confidential governance records')
on conflict(key) do nothing;

alter table public.decisions alter column status drop default;
alter table public.decisions alter column status type text using status::text;
alter table public.decisions alter column status set default 'draft';
alter table public.decisions add constraint decisions_phase2c_status check(status in('draft','proposed','under_review','awaiting_approval','approved','rejected','revision_required','completed','cancelled'));
alter table public.decisions add column department_id uuid references public.departments(id) on delete set null;
alter table public.decisions add column description text;
alter table public.decisions add column decision_type text not null default 'general';
alter table public.decisions add column approval_required boolean not null default false;
alter table public.decisions add column outcome_rationale text;
alter table public.decisions add column authority_grade smallint not null default 1 check(authority_grade between 1 and 4);
alter table public.decisions add column archived_at timestamptz;

alter table public.approval_rules add column department_id uuid references public.departments(id) on delete cascade;
alter table public.approval_rules add column decision_type text;
alter table public.approval_rules add column sensitivity public.visibility_level;
alter table public.approval_rules add column financial_threshold numeric check(financial_threshold is null or financial_threshold>=0);
alter table public.approval_rules add column eligible_permission text not null default 'decision.approve';
alter table public.approval_rules add column prohibit_self_approval boolean not null default true;
alter table public.approval_rules add column classification text not null default 'SAMPLE / UNAPPROVED';

create table public.approval_rule_steps(
 id uuid primary key default gen_random_uuid(), rule_id uuid not null references public.approval_rules(id) on delete cascade,
 organization_id uuid not null references public.organizations(id) on delete cascade, step_order smallint not null check(step_order>0),
 eligible_role_id uuid references public.roles(id) on delete restrict, eligible_permission text not null default 'decision.approve',
 minimum_approvals smallint not null default 1 check(minimum_approvals>0), delegation_allowed boolean not null default false,
 created_at timestamptz not null default now(), unique(rule_id,step_order));
alter table public.approval_rule_steps enable row level security;

alter table public.approvals add column rule_step_id uuid references public.approval_rule_steps(id) on delete restrict;
alter table public.approvals add column eligible_permission text not null default 'decision.approve';
alter table public.approvals add column minimum_approvals smallint not null default 1 check(minimum_approvals>0);

create table public.approval_votes(
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
 approval_id uuid not null references public.approvals(id) on delete restrict, decision_id uuid not null references public.decisions(id) on delete restrict,
 approver_id uuid not null references public.profiles(id) on delete restrict, response text not null check(response in('approved','rejected','revision_required')),
 rationale text not null, delegated_by uuid references public.profiles(id), decided_at timestamptz not null default now(),
 correlation_id uuid not null default gen_random_uuid(), unique(approval_id,approver_id));
alter table public.approval_votes enable row level security;

create or replace function public.assert_governance_scope() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare related uuid;
begin
 if tg_table_name='decisions' then
  if nullif(to_jsonb(new)->>'department_id','') is not null then select organization_id into related from public.departments where id=(to_jsonb(new)->>'department_id')::uuid; if related is distinct from new.organization_id then raise exception 'governance department crosses organization boundary'; end if; end if;
  if nullif(to_jsonb(new)->>'approval_rule_id','') is not null then select organization_id into related from public.approval_rules where id=(to_jsonb(new)->>'approval_rule_id')::uuid; if related is distinct from new.organization_id then raise exception 'governance rule crosses organization boundary'; end if; end if;
  if nullif(to_jsonb(new)->>'requested_by','') is not null and not exists(select 1 from public.organization_members where organization_id=new.organization_id and profile_id=(to_jsonb(new)->>'requested_by')::uuid and status='active') then raise exception 'decision requester is outside active organization membership'; end if;
  if nullif(to_jsonb(new)->>'owner_id','') is not null and not exists(select 1 from public.organization_members where organization_id=new.organization_id and profile_id=(to_jsonb(new)->>'owner_id')::uuid and status='active') then raise exception 'decision owner is outside active organization membership'; end if;
  return new;
 elsif tg_table_name='approval_rules' then
  if nullif(to_jsonb(new)->>'department_id','') is not null then select organization_id into related from public.departments where id=(to_jsonb(new)->>'department_id')::uuid; if related is distinct from new.organization_id then raise exception 'governance rule department crosses organization boundary'; end if; end if;
  if exists(select 1 from public.roles r where r.id in(select jsonb_array_elements_text(to_jsonb(new)->'eligible_role_ids')::uuid) and r.organization_id is distinct from new.organization_id) then raise exception 'governance eligible role crosses organization boundary'; end if;
  return new;
 elsif tg_table_name='approval_rule_steps' then select organization_id into related from public.approval_rules where id=(to_jsonb(new)->>'rule_id')::uuid;
  if related=new.organization_id and nullif(to_jsonb(new)->>'eligible_role_id','') is not null then select organization_id into related from public.roles where id=(to_jsonb(new)->>'eligible_role_id')::uuid; end if;
 elsif tg_table_name='approval_votes' then select organization_id into related from public.approvals where id=(to_jsonb(new)->>'approval_id')::uuid;
 else return new; end if;
 if related is distinct from new.organization_id then raise exception 'governance relationship crosses organization boundary'; end if;
 return new;
end $$;
create trigger decisions_governance_scope before insert or update on public.decisions for each row execute function public.assert_governance_scope();
create trigger approval_rules_governance_scope before insert or update on public.approval_rules for each row execute function public.assert_governance_scope();
create trigger approval_rule_steps_scope before insert or update on public.approval_rule_steps for each row execute function public.assert_governance_scope();
create trigger approval_votes_scope before insert or update on public.approval_votes for each row execute function public.assert_governance_scope();

drop policy if exists decisions_insert on public.decisions;
drop policy if exists decisions_update on public.decisions;
create policy decisions_insert on public.decisions for insert to authenticated with check(
 proposed_by=auth.uid() and status='draft' and public.has_permission(organization_id,'decision.propose') and
 public.can_access_sensitive_record(organization_id,department_id,visibility,'decision.read',null,'governance.read_restricted','governance.read_confidential'));
create policy decisions_update on public.decisions for update to authenticated using(false) with check(false);
create policy approval_rule_steps_select on public.approval_rule_steps for select to authenticated using(public.has_permission(organization_id,'governance.read_restricted'));
create policy approval_rule_steps_admin on public.approval_rule_steps for all to authenticated using(public.has_permission(organization_id,'decision.manage_rules')) with check(public.has_permission(organization_id,'decision.manage_rules'));
create policy approval_votes_select on public.approval_votes for select to authenticated using(exists(select 1 from public.decisions d where d.id=decision_id));

grant select,insert,update,delete on public.approval_rule_steps to authenticated;
grant select on public.approval_votes to authenticated;

revoke insert,update,delete on public.approvals from authenticated;
revoke insert,update,delete on public.approval_votes from authenticated;
revoke update,delete on public.decisions from authenticated;

create or replace function public.transition_decision(target_decision_id uuid,new_status text,rationale text default null) returns public.decisions
language plpgsql security definer set search_path=public,pg_temp as $$
declare d public.decisions; allowed boolean:=false; result public.decisions;
begin
 select * into d from public.decisions where id=target_decision_id for update;
 if d.id is null or not public.can_access_sensitive_record(d.organization_id,d.department_id,d.visibility,'decision.read',null,'governance.read_restricted','governance.read_confidential') then raise exception 'decision unavailable'; end if;
 if not public.has_permission(d.organization_id,'decision.transition') then raise exception 'decision transition denied'; end if;
 if d.proposed_by=auth.uid() then allowed:=true; elsif public.has_permission(d.organization_id,'workspace.admin') then allowed:=true; end if;
 if not allowed then raise exception 'decision transition denied'; end if;
 if (d.status,new_status) not in (('draft','proposed'),('proposed','under_review'),('under_review','awaiting_approval'),('approved','completed'),('draft','cancelled'),('proposed','cancelled'),('revision_required','proposed')) then raise exception 'invalid decision transition'; end if;
 if new_status='awaiting_approval' and d.approval_required then
  if d.approval_rule_id is null then raise exception 'approval rule required'; end if;
  insert into public.approvals(organization_id,decision_id,target_id,step_order,eligible_role_id,eligible_permission,minimum_approvals,rule_step_id)
   select d.organization_id,d.id,d.id,s.step_order,s.eligible_role_id,s.eligible_permission,s.minimum_approvals,s.id from public.approval_rule_steps s
   where s.rule_id=d.approval_rule_id order by s.step_order on conflict(target_type,target_id,step_order) do nothing;
  if not exists(select 1 from public.approvals where decision_id=d.id) then raise exception 'configured approval steps required'; end if;
 end if;
 update public.decisions set status=new_status,outcome_rationale=coalesce(rationale,outcome_rationale),updated_at=now(),archived_at=case when new_status in('completed','cancelled') then now() else archived_at end where id=d.id returning * into result;
 return result;
end $$;

create or replace function public.respond_to_approval(target_approval_id uuid,requested_response text,rationale text,delegate_to uuid default null) returns public.approvals
language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.approvals; d public.decisions; rule public.approval_rules; votes int; result public.approvals;
begin
 if requested_response not in('approved','rejected','revision_required') or nullif(btrim(rationale),'') is null then raise exception 'response and rationale required'; end if;
 select * into a from public.approvals where id=target_approval_id for update; select * into d from public.decisions where id=a.decision_id for update;
 if a.id is null or d.status<>'awaiting_approval' or a.status<>'pending' then raise exception 'approval is not actionable'; end if;
 select * into rule from public.approval_rules where id=d.approval_rule_id;
 if not public.can_access_sensitive_record(d.organization_id,d.department_id,d.visibility,'decision.read',null,'governance.read_restricted','governance.read_confidential') then raise exception 'approval unavailable'; end if;
 if not public.has_permission(d.organization_id,a.eligible_permission) then raise exception 'approval authority denied'; end if;
 if a.eligible_role_id is not null and not exists(select 1 from public.organization_members om join public.member_roles mr on mr.organization_member_id=om.id where om.organization_id=d.organization_id and om.profile_id=auth.uid() and om.status='active' and mr.role_id=a.eligible_role_id) then raise exception 'eligible role required'; end if;
 if rule.prohibit_self_approval and auth.uid() in(d.proposed_by,d.requested_by) then raise exception 'self approval prohibited'; end if;
 if exists(select 1 from public.approvals prior where prior.decision_id=d.id and prior.step_order<a.step_order and prior.status<>'approved') then raise exception 'prior approval step incomplete'; end if;
 if delegate_to is not null then raise exception 'delegation requires a future approved policy'; end if;
 insert into public.approval_votes(organization_id,approval_id,decision_id,approver_id,response,rationale) values(d.organization_id,a.id,d.id,auth.uid(),requested_response,rationale);
 if requested_response='rejected' then update public.approvals set status='rejected',approver_id=auth.uid(),note=rationale,decided_at=now() where id=a.id returning * into result; update public.decisions set status='rejected',outcome='rejected',outcome_rationale=rationale,updated_at=now() where id=d.id;
 elsif requested_response='revision_required' then update public.approvals set status='rejected',approver_id=auth.uid(),note=rationale,decided_at=now() where id=a.id returning * into result; update public.decisions set status='revision_required',outcome_rationale=rationale,updated_at=now() where id=d.id;
 else
  select count(*) into votes from public.approval_votes where approval_id=a.id and response='approved';
  if votes>=a.minimum_approvals then update public.approvals set status='approved',approver_id=auth.uid(),note=rationale,decided_at=now() where id=a.id returning * into result;
   if not exists(select 1 from public.approvals x where x.decision_id=d.id and x.id<>a.id and x.status<>'approved') then update public.decisions set status='approved',outcome='approved',outcome_rationale=rationale,updated_at=now() where id=d.id; end if;
  else select * into result from public.approvals where id=a.id; end if;
 end if;
 return result;
end $$;

revoke all on function public.transition_decision(uuid,text,text) from public;
revoke all on function public.respond_to_approval(uuid,text,text,uuid) from public;
grant execute on function public.transition_decision(uuid,text,text) to authenticated;
grant execute on function public.respond_to_approval(uuid,text,text,uuid) to authenticated;

create or replace function public.audit_governance_mutation() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare org uuid:=coalesce(new.organization_id,old.organization_id); target uuid:=coalesce(new.id,old.id); approval_ref uuid;
begin
 if tg_table_name='approval_votes' then approval_ref:=coalesce(new.approval_id,old.approval_id); end if;
 insert into public.audit_events(organization_id,actor_type,actor_id,action,target_type,target_id,before_state,after_state,approval_id,source,visibility,context)
 values(org,case when auth.uid() is null then 'system'::public.actor_type else 'human'::public.actor_type end,auth.uid(),'governance.'||tg_table_name||'.'||lower(tg_op),tg_table_name,target,case when tg_op='INSERT' then null else to_jsonb(old) end,case when tg_op='DELETE' then null else to_jsonb(new) end,approval_ref,'database_trigger','restricted',jsonb_build_object('phase','2C'));
 return case when tg_op='DELETE' then old else new end;
end $$;
create trigger decisions_governance_audit after insert or update or delete on public.decisions for each row execute function public.audit_governance_mutation();
create trigger approval_rules_governance_audit after insert or update or delete on public.approval_rules for each row execute function public.audit_governance_mutation();
create trigger approval_rule_steps_governance_audit after insert or update or delete on public.approval_rule_steps for each row execute function public.audit_governance_mutation();
create trigger approvals_governance_audit after insert or update or delete on public.approvals for each row execute function public.audit_governance_mutation();
create trigger approval_votes_governance_audit after insert on public.approval_votes for each row execute function public.audit_governance_mutation();
