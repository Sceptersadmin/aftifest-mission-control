begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(14);
select has_table('public','user_provisioning_requests','provisioning requests exist');
select has_column('public','user_provisioning_requests','organization_id','requests are organization scoped');
select is((select relrowsecurity from pg_class where oid='public.user_provisioning_requests'::regclass),true,'provisioning RLS is active');
select has_function('public','prevent_administration_scope_violation',array[]::text[],'scope guard exists');
select has_function('public','prevent_last_workspace_admin_removal',array[]::text[],'last admin guard exists');
select has_function('public','audit_administration_mutation',array[]::text[],'administration audit trigger exists');
select policies_are('public','user_provisioning_requests',array['provisioning_insert','provisioning_select','provisioning_update'],'provisioning policies are explicit');
select ok(not has_table_privilege('anon','public.user_provisioning_requests','select'),'anonymous role cannot read provisioning requests');

insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at) values
 ('82000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','phase2a-low@test.invalid',crypt('TEST-ONLY',gen_salt('bf')),now(),'{}','{}',now(),now()),
 ('82000000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','phase2a-sql-admin@test.invalid',crypt('TEST-ONLY',gen_salt('bf')),now(),'{}','{}',now(),now());
insert into public.organizations(id,name,slug) values
 ('82000000-0000-4000-8000-000000000010','Phase 2A Organization A TEST / SAMPLE','phase2a-org-a-test'),
 ('82000000-0000-4000-8000-000000000020','Phase 2A Organization B TEST / SAMPLE','phase2a-org-b-test');
insert into public.roles(id,organization_id,key,name) values
 ('82000000-0000-4000-8000-000000000011','82000000-0000-4000-8000-000000000010','low','Phase 2A Low TEST'),
 ('82000000-0000-4000-8000-000000000012','82000000-0000-4000-8000-000000000010','admin','Phase 2A Admin TEST'),
 ('82000000-0000-4000-8000-000000000021','82000000-0000-4000-8000-000000000020','foreign','Phase 2A Foreign TEST');
insert into public.organization_members(id,organization_id,profile_id) values
 ('82000000-0000-4000-8000-000000000013','82000000-0000-4000-8000-000000000010','82000000-0000-4000-8000-000000000001'),
 ('82000000-0000-4000-8000-000000000014','82000000-0000-4000-8000-000000000010','82000000-0000-4000-8000-000000000002');
insert into public.member_roles(organization_member_id,role_id) values
 ('82000000-0000-4000-8000-000000000013','82000000-0000-4000-8000-000000000011'),
 ('82000000-0000-4000-8000-000000000014','82000000-0000-4000-8000-000000000012');
insert into public.role_permissions(role_id,permission_id)
 select '82000000-0000-4000-8000-000000000012',id from public.permissions where key in ('workspace.admin','organization.manage','user.provision','membership.manage','role.manage','audit.read','audit.read_restricted');
create or replace function pg_temp.denied(statement text) returns boolean language plpgsql as $$begin execute statement; return false; exception when others then return true; end$$;

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"82000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
select is((select count(*) from public.user_provisioning_requests),0::bigint,'low member cannot read provisioning requests');
update public.organizations set name='FORBIDDEN' where id='82000000-0000-4000-8000-000000000010';
reset role;
select is((select name from public.organizations where id='82000000-0000-4000-8000-000000000010'),'Phase 2A Organization A TEST / SAMPLE','low member cannot update organization');
set local role authenticated;

select set_config('request.jwt.claims','{"sub":"82000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
insert into public.user_provisioning_requests(organization_id,email,requested_by) values
 ('82000000-0000-4000-8000-000000000010','phase2a-request@test.invalid','82000000-0000-4000-8000-000000000002');
select is((select count(*) from public.user_provisioning_requests),1::bigint,'authorized admin can create and read provisioning request');
select ok(exists(select 1 from public.audit_events where organization_id='82000000-0000-4000-8000-000000000010' and action='administration.user_provisioning_requests.insert' and actor_type='human' and actor_id='82000000-0000-4000-8000-000000000002'),'admin mutation produces attributable audit event');
select ok(pg_temp.denied($$insert into public.member_roles(organization_member_id,role_id) values('82000000-0000-4000-8000-000000000013','82000000-0000-4000-8000-000000000021')$$),'cross-organization role assignment is denied');
select ok(pg_temp.denied($$update public.organization_members set status='archived' where id='82000000-0000-4000-8000-000000000014'$$),'last active workspace administrator cannot be deactivated');
reset role;
select * from finish();
rollback;
