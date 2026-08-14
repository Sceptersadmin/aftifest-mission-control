import {describe,expect,it} from "vitest";
import {readFileSync} from "node:fs";
const sql=readFileSync("supabase/migrations/202608140003_phase_2c_governance_core.sql","utf8");
describe("Phase 2C governance core",()=>{
 it("uses capability-driven ordered approval evidence",()=>{expect(sql).toContain("eligible_permission");expect(sql).toContain("approval_rule_steps");expect(sql).toContain("approval_votes")});
 it("fails closed on historical evidence",()=>{expect(sql).toContain("revoke insert,update,delete on public.approval_votes");expect(sql).toContain("prior approval step incomplete")});
 it("keeps AI authority descriptive",()=>expect(sql).toContain("authority_grade"));
});
