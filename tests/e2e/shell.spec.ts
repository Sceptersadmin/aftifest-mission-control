import { expect,test } from "@playwright/test";

test("preserves Mission Control identity and Level 0 guardrail",async({page})=>{await page.goto("/");await expect(page.getByText("AFTiFest Mission Control").first()).toBeVisible();await expect(page.getByText("ASK iFEST · LEVEL 0")).toBeVisible();await expect(page.getByText("Everyone aligned.")).toBeVisible()});
