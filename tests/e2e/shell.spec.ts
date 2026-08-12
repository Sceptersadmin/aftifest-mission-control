import { expect,test } from "@playwright/test";

test("unauthenticated users are redirected to the branded login boundary",async({page})=>{
  await page.goto("/");
  await expect(page).toHaveURL(/\/login$/);
  await expect(page.getByText("AFTiFest Mission Control")).toBeVisible();
  await expect(page.getByRole("heading",{name:"Sign in to Mission Control"})).toBeVisible();
  await expect(page.getByText("Self-registration is disabled.")).toBeVisible();
});

test("health endpoint confirms local-only Phase 1 runtime",async({request})=>{
  const response=await request.get("/api/health");
  expect(response.status()).toBe(200);
  await expect(response.json()).resolves.toEqual({status:"ok",phase:1,productionInfrastructure:false});
});

test("ASK iFEST fails closed without authenticated permissions",async({request})=>{
  const response=await request.post("/api/ask-ifest",{data:{question:"What is at risk today?"}});
  expect(response.status()).toBe(503);
  const payload=await response.json();
  expect(payload.authorityLevel).toBe(0);
  expect(payload.policy.allowed).toBe(false);
  expect(payload.citations).toEqual([]);
});
