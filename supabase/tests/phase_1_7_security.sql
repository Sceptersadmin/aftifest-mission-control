\set ON_ERROR_STOP on
begin;
create or replace function pg_temp.ok(v boolean,n text) returns void language plpgsql as $$begin if not v then raise exception 'FAIL: %',n; end if; end$$;

-- LOCAL TEST identities only. IDs: member, lead A, lead B, executive, advisory,
-- patron, admin, restricted reader, and cross-organization user.
insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
select id,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',email,crypt('TEST-ONLY',gen_salt('bf')),now(),'{}','{}',now(),now()
from (values
 ('71000000-0000-4000-8000-000000000001'::uuid,'member@test.invalid'),('71000000-0000-4000-8000-000000000002','lead-a@test.invalid'),
 ('71000000-0000-4000-8000-000000000003','lead-b@test.invalid'),('71000000-0000-4000-8000-000000000004','executive@test.invalid'),
 ('71000000-0000-4000-8000-000000000005','advisory@test.invalid'),('71000000-0000-4000-8000-000000000006','patron@test.invalid'),
 ('71000000-0000-4000-8000-000000000007','admin@test.invalid'),('71000000-0000-4000-8000-000000000008','restricted@test.invalid'),
 ('72000000-0000-4000-8000-000000000001','cross-org@test.invalid'))v(id,email);
select pg_temp.ok((select count(*)=9 from public.profiles where id::text like '71000000-%' or id::text like '72000000-%'),'auth profile trigger');

insert into public.organizations(id,name,slug) values
 ('71000000-0000-4000-8000-000000000000','Organization A TEST / SAMPLE','org-a-security-test'),
 ('72000000-0000-4000-8000-000000000000','Organization B TEST / SAMPLE','org-b-security-test');
insert into public.organization_members(id,organization_id,profile_id)
select ('71100000-0000-4000-8000-00000000000'||n)::uuid,'71000000-0000-4000-8000-000000000000',('71000000-0000-4000-8000-00000000000'||n)::uuid from generate_series(1,8)n;
insert into public.organization_members values('72200000-0000-4000-8000-000000000001','72000000-0000-4000-8000-000000000000','72000000-0000-4000-8000-000000000001','active',now());

insert into public.roles(id,organization_id,key,name) values
 ('71200000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000000','member','TEST Member'),
 ('71200000-0000-4000-8000-000000000002','71000000-0000-4000-8000-000000000000','lead_a','TEST Lead A'),
 ('71200000-0000-4000-8000-000000000003','71000000-0000-4000-8000-000000000000','lead_b','TEST Lead B'),
 ('71200000-0000-4000-8000-000000000004','71000000-0000-4000-8000-000000000000','executive','TEST Executive'),
 ('71200000-0000-4000-8000-000000000005','71000000-0000-4000-8000-000000000000','advisory','TEST Advisory'),
 ('71200000-0000-4000-8000-000000000006','71000000-0000-4000-8000-000000000000','patron','TEST Patron'),
 ('71200000-0000-4000-8000-000000000007','71000000-0000-4000-8000-000000000000','admin','TEST Admin'),
 ('71200000-0000-4000-8000-000000000008','71000000-0000-4000-8000-000000000000','restricted','TEST Restricted Reader'),
 ('72200000-0000-4000-8000-000000000001','72000000-0000-4000-8000-000000000000','member','TEST Cross Org');
insert into public.member_roles select ('71100000-0000-4000-8000-00000000000'||n)::uuid,('71200000-0000-4000-8000-00000000000'||n)::uuid,null,now() from generate_series(1,8)n;
insert into public.member_roles values('72200000-0000-4000-8000-000000000001','72200000-0000-4000-8000-000000000001',null,now());

-- Baseline capability plus explicit, independently configurable elevation.
insert into public.role_permissions select r.id,p.id from public.roles r cross join public.permissions p
where p.key in ('department.read','task.read','report.submit','content.read','resource.read','brain.read','agent.read') on conflict do nothing;
insert into public.role_permissions select r.id,p.id from public.roles r cross join public.permissions p where r.key in ('lead_a','lead_b') and p.key in ('department.manage','task.manage_department','brain.read_department','resource.read_department','content.read_department','attachment.read_department') on conflict do nothing;
insert into public.role_permissions select r.id,p.id from public.roles r cross join public.permissions p where r.key in ('executive','advisory') and r.organization_id='71000000-0000-4000-8000-000000000000' and p.key in ('decision.read','governance.read_restricted') on conflict do nothing;
insert into public.role_permissions select r.id,p.id from public.roles r cross join public.permissions p where r.key='patron' and p.key='decision.read' on conflict do nothing;
insert into public.role_permissions select r.id,p.id from public.roles r cross join public.permissions p where r.key='restricted' and p.key in ('brain.read_restricted','resource.read_restricted','attachment.read_restricted') on conflict do nothing;
insert into public.role_permissions select r.id,p.id from public.roles r cross join public.permissions p where r.key='admin' and p.key in ('workspace.admin','department.read_all','brain.read_restricted','brain.read_confidential','governance.read_restricted','governance.read_confidential','sponsor.read','sponsor.manage','resource.read_restricted','resource.read_confidential','attachment.read_restricted','attachment.read_confidential','audit.read','audit.read_restricted','audit.read_confidential') on conflict do nothing;

insert into public.departments(id,organization_id,name) values
 ('71300000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000000','Department A TEST'),
 ('71300000-0000-4000-8000-000000000002','71000000-0000-4000-8000-000000000000','Department B TEST'),
 ('72300000-0000-4000-8000-000000000001','72000000-0000-4000-8000-000000000000','Cross Org Department TEST');
insert into public.department_members(department_id,organization_member_id,is_lead) values
 ('71300000-0000-4000-8000-000000000001','71100000-0000-4000-8000-000000000001',false),
 ('71300000-0000-4000-8000-000000000001','71100000-0000-4000-8000-000000000002',true),
 ('71300000-0000-4000-8000-000000000002','71100000-0000-4000-8000-000000000003',true),
 ('72300000-0000-4000-8000-000000000001','72200000-0000-4000-8000-000000000001',false);

insert into public.company_brain_items(id,organization_id,department_id,title,source_type,source_reference,classification,visibility,verification_status) values
 ('71400000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000000',null,'Organization item TEST','test','TEST / SAMPLE','internal','organization','verified'),
 ('71400000-0000-4000-8000-000000000002','71000000-0000-4000-8000-000000000000','71300000-0000-4000-8000-000000000001','Department A item TEST','test','TEST / SAMPLE','departmental','department','verified'),
 ('71400000-0000-4000-8000-000000000003','71000000-0000-4000-8000-000000000000','71300000-0000-4000-8000-000000000002','Department B item TEST','test','TEST / SAMPLE','departmental','department','verified'),
 ('71400000-0000-4000-8000-000000000004','71000000-0000-4000-8000-000000000000',null,'Restricted item TEST','test','TEST / SAMPLE','restricted','restricted','verified'),
 ('71400000-0000-4000-8000-000000000005','71000000-0000-4000-8000-000000000000',null,'Confidential item TEST','test','TEST / SAMPLE','confidential','confidential','verified'),
 ('72400000-0000-4000-8000-000000000001','72000000-0000-4000-8000-000000000000',null,'Cross org item TEST','test','TEST / SAMPLE','internal','organization','verified');
insert into public.sponsors(id,organization_id,name) values('71500000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000000','Sponsor TEST / SAMPLE');
insert into public.decisions(id,organization_id,title,proposed_by,visibility) values
 ('71600000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000000','Restricted governance TEST','71000000-0000-4000-8000-000000000004','restricted'),
 ('71600000-0000-4000-8000-000000000002','71000000-0000-4000-8000-000000000000','Confidential governance TEST','71000000-0000-4000-8000-000000000004','confidential');
insert into public.resources(id,organization_id,department_id,title,visibility) values
 ('71700000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000000','71300000-0000-4000-8000-000000000001','Department resource TEST','department'),
 ('71700000-0000-4000-8000-000000000002','71000000-0000-4000-8000-000000000000',null,'Restricted resource TEST','restricted');

set local role authenticated;
-- Ordinary member: organization + own department only; no sensitive/commercial/governance.
select set_config('request.jwt.claims','{"sub":"71000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
select pg_temp.ok((select count(*)=2 from public.company_brain_items),'member brain organization and department A only');
select pg_temp.ok((select count(*)=0 from public.company_brain_items where visibility in ('restricted','confidential')),'member denied sensitive brain');
select pg_temp.ok((select count(*)=0 from public.sponsors),'member denied sponsor');
select pg_temp.ok((select count(*)=0 from public.decisions),'member denied governance');
select pg_temp.ok((select count(*)=1 from public.resources),'member department resource only');

-- Lead A cannot cross into Department B and cannot read restricted by broad brain.read.
select set_config('request.jwt.claims','{"sub":"71000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
select pg_temp.ok((select count(*)=2 from public.company_brain_items),'lead A scope');
select pg_temp.ok((select count(*)=0 from public.company_brain_items where department_id='71300000-0000-4000-8000-000000000002'),'lead A denied department B');
select pg_temp.ok((select count(*)=0 from public.company_brain_items where visibility='restricted'),'lead A denied restricted');

-- Explicit restricted capability does not imply confidential.
select set_config('request.jwt.claims','{"sub":"71000000-0000-4000-8000-000000000008","role":"authenticated"}',true);
select pg_temp.ok((select count(*)=2 from public.company_brain_items),'restricted reader sees organization and restricted');
select pg_temp.ok((select count(*)=0 from public.company_brain_items where visibility='confidential'),'restricted reader denied confidential');

-- Governance capability split and sponsor capability.
select set_config('request.jwt.claims','{"sub":"71000000-0000-4000-8000-000000000004","role":"authenticated"}',true);
select pg_temp.ok((select count(*)=1 from public.decisions),'executive restricted but not confidential');
select pg_temp.ok((select count(*)=0 from public.sponsors),'executive lacks commercial capability');

-- Admin sees all same-org records, never Organization B.
select set_config('request.jwt.claims','{"sub":"71000000-0000-4000-8000-000000000007","role":"authenticated"}',true);
select pg_temp.ok((select count(*)=5 from public.company_brain_items),'admin sensitive brain');
select pg_temp.ok((select count(*)=2 from public.decisions),'admin governance');
select pg_temp.ok((select count(*)=1 from public.sponsors),'admin sponsor');
select pg_temp.ok((select count(*)=0 from public.company_brain_items where organization_id='72000000-0000-4000-8000-000000000000'),'admin cross-org denied');

-- Cross-org identity sees only its organization.
select set_config('request.jwt.claims','{"sub":"72000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
select pg_temp.ok((select count(*)=1 from public.company_brain_items),'cross org isolation');
select pg_temp.ok((select count(*)=0 from public.company_brain_items where organization_id='71000000-0000-4000-8000-000000000000'),'cross org A denied');

-- Audit identity and immutability.
select set_config('request.jwt.claims','{"sub":"71000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
insert into public.audit_events(organization_id,actor_type,actor_id,action,target_type,source,before_state,after_state,correlation_id)
values('71000000-0000-4000-8000-000000000000','human','71000000-0000-4000-8000-000000000001','TEST','test','phase-1.7','{"v":1}','{"v":2}','71900000-0000-4000-8000-000000000001');
do $$begin begin insert into public.audit_events(organization_id,actor_type,action,target_type,source) values('71000000-0000-4000-8000-000000000000','agent','FORGE','test','client'); raise exception 'FAIL agent forgery'; exception when insufficient_privilege then null; end; end$$;
do $$begin begin update public.audit_events set action='FORGE'; raise exception 'FAIL audit update'; exception when insufficient_privilege then null; end; end$$;
reset role;
rollback;
\echo PHASE_1_7_SECURITY_MATRIX_PASS
