import { expect,test } from "@playwright/test";

test("unauthenticated users are redirected to the branded login boundary",async({page})=>{
  await page.goto("/");
  await expect(page).toHaveURL(/\/login$/);
  await expect(page.getByText("AFTiFest Mission Control")).toBeVisible();
  await expect(page.getByRole("heading",{name:"Sign in to Mission Control"})).toBeVisible();
  await expect(page.getByText("Self-registration is disabled.")).toBeVisible();
});

test("health endpoint confirms local-only Phase 2C runtime",async({request})=>{
  const response=await request.get("/api/health");
  expect(response.status()).toBe(200);
  await expect(response.json()).resolves.toEqual({status:"ok",phase:"2C",productionInfrastructure:false});
});

test("ASK iFEST fails closed without authenticated permissions",async({request})=>{
  const response=await request.post("/api/ask-ifest",{data:{question:"What is at risk today?"}});
  expect(response.status()).toBe(401);
  const payload=await response.json();
  expect(payload.citations).toEqual([]);
});

test("authenticated TEST member gets role-aware shell and requester-effective ASK results",async({page})=>{
  await page.goto("/login");
  await page.getByLabel("Email").fill("phase17-member@test.invalid");
  await page.getByLabel("Password").fill("TEST-Only-Password-123!");
  await page.getByRole("button",{name:"Sign in"}).click();
  await expect(page).toHaveURL("/");
  await expect(page.getByRole("link",{name:/Company Brain/})).toBeVisible();
  await expect(page.getByRole("link",{name:/Agent Registry/})).toBeVisible();
  await expect(page.getByRole("link",{name:/Decision Center|Governance Room/})).toHaveCount(0);

  const denied=await page.goto("/decision-center");
  expect(denied?.status()).toBe(200);
  await expect(page).toHaveURL("/");

  const ask=await page.request.post("/api/ask-ifest",{data:{question:"What is at risk today?"}});
  expect(ask.status()).toBe(200);
  const payload=await ask.json();
  expect(payload.authorityLevel).toBe(0);
  expect(payload.policy.allowed).toBe(true);
  expect(payload.policy.execute).toBe(true);
  expect(payload.citations.map((citation:{title:string})=>citation.title)).toContain("Authorized TEST source");
  expect(payload.citations.map((citation:{title:string})=>citation.title)).not.toContain("Restricted TEST source");

  await page.getByRole("button",{name:"Sign out"}).click();
  await expect(page).toHaveURL(/\/login$/);
});

test("Phase 2A TEST administrator can use the governed administration workspace",async({page})=>{
  test.setTimeout(90_000);
  await page.goto("/login");
  await page.getByLabel("Email").fill("phase2a-admin@test.invalid");
  await page.getByLabel("Password").fill("TEST-Only-Password-123!");
  await page.getByRole("button",{name:"Sign in"}).click();
  await expect(page.getByRole("link",{name:/Administration/})).toBeVisible();
  await page.getByRole("link",{name:/Administration/}).click();
  await expect(page).toHaveURL(/\/administration$/);
  await expect(page.getByRole("heading",{name:"Governed administration, without inferred authority."})).toBeVisible();
  await page.getByLabel("TEST email").fill("playwright-provisioned@test.invalid");
  await page.getByRole("button",{name:"Create provisioning request"}).click();
  await expect(page.getByText("playwright-provisioned@test.invalid")).toBeVisible();
});

test("Phase 2B TEST administrator can use PostgreSQL-backed operational modules",async({page})=>{
  test.setTimeout(90_000);
  await page.goto("/login");
  await page.getByLabel("Email").fill("phase2a-admin@test.invalid");
  await page.getByLabel("Password").fill("TEST-Only-Password-123!");
  await page.getByRole("button",{name:"Sign in"}).click();
  await expect(page).toHaveURL("/");
  await expect(page.getByText("Operational Readiness — PROVISIONAL")).toBeVisible();
  await page.getByRole("link",{name:/Departments & People/}).click();
  await expect(page.getByRole("heading",{name:"Departments aligned. People scoped."})).toBeVisible();
  await expect(page.getByText("Phase 2B Operations - TEST / SAMPLE")).toBeVisible();
  await page.getByRole("link",{name:/Tasks & Accountability/}).click();
  await expect(page.getByRole("heading",{name:"Accountability in motion."})).toBeVisible();
  await page.getByPlaceholder("Task title").fill("Phase 2B Playwright Task - TEST / SAMPLE");
  await page.locator('select[name="department_id"]').selectOption({label:"Phase 2B Operations - TEST / SAMPLE"});
  await page.getByRole("button",{name:"Create task"}).click();
  await expect(page.getByText("Phase 2B Playwright Task - TEST / SAMPLE").first()).toBeVisible();
  await page.getByRole("link",{name:/Department Reports/}).click();
  await expect(page.getByRole("heading",{name:"Signals leadership can trust."})).toBeVisible();
  await expect(page.getByRole("button",{name:"Submit report"})).toBeVisible();
});

test("Phase 2C TEST administrator can use the governed Decision Center",async({page})=>{
  test.setTimeout(90_000);
  await page.goto("/login");
  await page.getByLabel("Email").fill("phase2a-admin@test.invalid");
  await page.getByLabel("Password").fill("TEST-Only-Password-123!");
  await page.getByRole("button",{name:"Sign in"}).click();
  await page.goto("/decision-center");
  await expect(page.getByRole("heading",{name:"Governance with evidence."})).toBeVisible();
  await page.getByPlaceholder("Decision title").fill("Playwright governance decision - TEST / SAMPLE");
  await page.getByRole("button",{name:"Create draft"}).click();
  await expect(page.getByText("Playwright governance decision - TEST / SAMPLE")).toBeVisible();
});
