import { expect,test } from "@playwright/test";

test("unauthenticated users are redirected to the branded login boundary",async({page})=>{
  await page.goto("/");
  await expect(page).toHaveURL(/\/login$/);
  await expect(page.getByText("AFTiFest Mission Control")).toBeVisible();
  await expect(page.getByRole("heading",{name:"Sign in to Mission Control"})).toBeVisible();
  await expect(page.getByText("Self-registration is disabled.")).toBeVisible();
});

test("health endpoint confirms local-only Phase 2A runtime",async({request})=>{
  const response=await request.get("/api/health");
  expect(response.status()).toBe(200);
  await expect(response.json()).resolves.toEqual({status:"ok",phase:"2A",productionInfrastructure:false});
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
