\set ON_ERROR_STOP on
begin;

create or replace function pg_temp.assert_true(value boolean, label text) returns void language plpgsql as $$
begin if not value then raise exception 'SECURITY ASSERTION FAILED: %', label; end if; end $$;

-- Deterministic LOCAL TEST identities. The auth trigger must create each profile.
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
select id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', email,
       crypt('TEST-Only-Password-123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}',
       jsonb_build_object('display_name', label), now(), now()
from (values
 ('10000000-0000-4000-8000-000000000001'::uuid,'team-a@test.invalid','TEST Team Member A'),
 ('10000000-0000-4000-8000-000000000002'::uuid,'lead-a@test.invalid','TEST Department Lead A'),
 ('10000000-0000-4000-8000-000000000003'::uuid,'executive-a@test.invalid','TEST Executive A'),
 ('10000000-0000-4000-8000-000000000004'::uuid,'advisory-a@test.invalid','TEST Advisory A'),
 ('10000000-0000-4000-8000-000000000005'::uuid,'patron-a@test.invalid','TEST Patron A'),
 ('10000000-0000-4000-8000-000000000006'::uuid,'admin-a@test.invalid','TEST Super Admin A'),
 ('20000000-0000-4000-8000-000000000001'::uuid,'user-b@test.invalid','TEST User B')) v(id,email,label);

select pg_temp.assert_true((select count(*)=7 from public.profiles where email like '%@test.invalid'), 'profile trigger');

insert into public.organizations(id,name,slug,metadata) values
 ('10000000-0000-4000-8000-000000000000','Organization A - TEST / SAMPLE','org-a-test','{"classification":"TEST / SAMPLE"}'),
 ('20000000-0000-4000-8000-000000000000','Organization B - TEST / SAMPLE','org-b-test','{"classification":"TEST / SAMPLE"}');

insert into public.organization_members(id,organization_id,profile_id) values
 ('11000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000000','10000000-0000-4000-8000-000000000001'),
 ('11000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000000','10000000-0000-4000-8000-000000000002'),
 ('11000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000000','10000000-0000-4000-8000-000000000003'),
 ('11000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000000','10000000-0000-4000-8000-000000000004'),
 ('11000000-0000-4000-8000-000000000005','10000000-0000-4000-8000-000000000000','10000000-0000-4000-8000-000000000005'),
 ('11000000-0000-4000-8000-000000000006','10000000-0000-4000-8000-000000000000','10000000-0000-4000-8000-000000000006'),
 ('22000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000000','20000000-0000-4000-8000-000000000001');

insert into public.roles(id,organization_id,key,name,is_system) values
 ('12000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000000','test_member','TEST Team Member',false),
 ('12000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000000','test_lead','TEST Department Lead',false),
 ('12000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000000','test_executive','TEST Executive',false),
 ('12000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000000','test_advisory','TEST Advisory',false),
 ('12000000-0000-4000-8000-000000000005','10000000-0000-4000-8000-000000000000','test_patron','TEST Patron',false),
 ('12000000-0000-4000-8000-000000000006','10000000-0000-4000-8000-000000000000','test_admin','TEST Super Admin',false),
 ('22000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000000','test_member','TEST User B',false);

insert into public.member_roles select ('11000000-0000-4000-8000-00000000000'||n)::uuid, ('12000000-0000-4000-8000-00000000000'||n)::uuid, null, now() from generate_series(1,6) n;
insert into public.member_roles values ('22000000-0000-4000-8000-000000000001','22000000-0000-4000-8000-000000000001',null,now());

-- Read baselines for all roles; elevated permissions are explicit and test-only.
insert into public.role_permissions
select r.id,p.id from public.roles r cross join public.permissions p
where r.key like 'test_%' and p.key in ('department.read','task.read','report.submit','content.read','resource.read','brain.read','agent.read');
insert into public.role_permissions
select r.id,p.id from public.roles r cross join public.permissions p
where r.key in ('test_lead','test_executive','test_admin') and p.key in ('department.manage','task.manage_department','report.review');
insert into public.role_permissions
select r.id,p.id from public.roles r cross join public.permissions p
where r.key in ('test_executive','test_advisory','test_patron','test_admin') and p.key in ('decision.read','governance.read_restricted');
insert into public.role_permissions
select r.id,p.id from public.roles r cross join public.permissions p
where r.key in ('test_executive','test_admin') and p.key in ('sponsor.read','decision.propose','decision.approve','audit.read');
insert into public.role_permissions
select r.id,p.id from public.roles r cross join public.permissions p
where r.key='test_admin' and p.key in ('workspace.admin','sponsor.manage','content.manage','resource.manage','brain.manage','agent.configure');

insert into public.departments(id,organization_id,name) values
 ('13000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000000','TEST Department A'),
 ('23000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000000','TEST Department B');
insert into public.tasks(id,organization_id,department_id,title) values
 ('14000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000000','13000000-0000-4000-8000-000000000001','TEST Task A'),
 ('24000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000000','23000000-0000-4000-8000-000000000001','TEST Task B');
insert into public.company_brain_items(id,organization_id,title,source_type,source_reference,classification,visibility) values
 ('15000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000000','TEST Brain A','test','TEST / SAMPLE','internal','organization'),
 ('25000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000000','TEST Brain B','test','TEST / SAMPLE','restricted','restricted');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
select pg_temp.assert_true((select count(*)=1 from public.departments), 'Org A sees only Org A departments');
select pg_temp.assert_true((select count(*)=1 from public.tasks), 'Org A sees only Org A tasks');
select pg_temp.assert_true((select count(*)=1 from public.company_brain_items), 'ASK requester RLS hides Org B brain');
select pg_temp.assert_true(not public.has_permission('10000000-0000-4000-8000-000000000000','workspace.admin'), 'team member denied admin');
select pg_temp.assert_true((select count(*)=0 from public.audit_events), 'team member cannot read audit');

-- Human events are attributable; agent/system forgery must be denied by RLS.
insert into public.audit_events(organization_id,actor_type,actor_id,action,target_type,source,before_state,after_state,correlation_id)
values('10000000-0000-4000-8000-000000000000','human','10000000-0000-4000-8000-000000000001','test.read','test','phase-1.6', '{"before":"TEST"}','{"after":"TEST"}','16000000-0000-4000-8000-000000000001');
do $$ begin
  begin
    insert into public.audit_events(organization_id,actor_type,action,target_type,source) values('10000000-0000-4000-8000-000000000000','system','forge','test','client');
    raise exception 'SECURITY ASSERTION FAILED: system event forgery succeeded';
  exception when insufficient_privilege then null; end;
end $$;

select set_config('request.jwt.claims','{"sub":"20000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
select pg_temp.assert_true((select count(*)=1 from public.departments), 'Org B sees only Org B departments');
select pg_temp.assert_true((select count(*)=1 from public.tasks), 'Org B sees only Org B tasks');
select pg_temp.assert_true((select count(*)=1 from public.company_brain_items), 'Org B sees only Org B brain');

reset role;
rollback;
\echo PHASE_1_6_DATABASE_SECURITY_PASS
