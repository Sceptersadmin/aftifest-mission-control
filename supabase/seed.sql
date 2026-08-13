-- Development fixture only. Every record is SAMPLE / UNAPPROVED.
insert into public.organizations (id, name, slug, metadata)
values ('00000000-0000-4000-8000-000000000001', 'AFTiFest — SAMPLE / UNAPPROVED', 'aftifest-sample', '{"classification":"SAMPLE / UNAPPROVED"}')
on conflict do nothing;

insert into public.permissions (key, description) values
('workspace.admin','Administer one organization'),('department.read','Read departments'),('department.manage','Manage departments'),
('task.read','Read tasks'),('task.manage_assigned','Manage assigned tasks'),('task.manage_department','Manage department tasks'),
('report.submit','Submit reports'),('report.review','Review reports'),('content.read','Read content'),('content.manage','Manage content'),
('sponsor.read','Read restricted sponsor records'),('sponsor.manage','Manage sponsor records'),('decision.read','Read decisions'),
('decision.propose','Propose decisions'),('decision.approve','Respond to configured approvals'),('governance.read_restricted','Read restricted governance records'),
('resource.read','Read resources'),('resource.manage','Manage resources'),('brain.read','Read authorized Company Brain items'),
('brain.manage','Manage Company Brain items'),('agent.read','Use/read registered agents'),('agent.configure','Configure agents'),('audit.read','Read audit events')
on conflict (key) do nothing;

insert into public.roles (organization_id,key,name,description,is_system) values
('00000000-0000-4000-8000-000000000001','super_admin','Super Admin / Founding Leadership','SAMPLE / UNAPPROVED configurable role',true),
('00000000-0000-4000-8000-000000000001','executive','Executive / EXCO','SAMPLE / UNAPPROVED configurable role',true),
('00000000-0000-4000-8000-000000000001','advisory_board','Advisory Board','SAMPLE / UNAPPROVED configurable role',true),
('00000000-0000-4000-8000-000000000001','patron','Patron','SAMPLE / UNAPPROVED configurable role',true),
('00000000-0000-4000-8000-000000000001','department_lead','Department Lead','SAMPLE / UNAPPROVED configurable role',true),
('00000000-0000-4000-8000-000000000001','team_member','Team Member','SAMPLE / UNAPPROVED configurable role',true)
on conflict do nothing;

insert into public.agents (organization_id,key,name,description,authority_level,provider_key,policy,active)
values ('00000000-0000-4000-8000-000000000001','ask-ifest','ASK iFEST / AI Chief of Staff','Read-only governed retrieval foundation','level_0','disabled','{"allowed_actions":["information.read"],"prohibited_external_actions":true,"classification":"SAMPLE / UNAPPROVED"}',false)
on conflict do nothing;
