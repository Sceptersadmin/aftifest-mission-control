import {readFileSync} from "node:fs";
import {describe,expect,it} from "vitest";
const migration=readFileSync("supabase/migrations/202608140001_phase_2a_administration_core.sql","utf8");
describe("Phase 2A administration foundation",()=>{
 it("uses explicit administration capabilities and RLS",()=>{for(const key of ["organization.manage","user.provision","membership.manage","role.manage"])expect(migration).toContain(key);expect(migration).toContain("enable row level security");});
 it("fails closed across organizations and protects the last administrator",()=>{expect(migration).toContain("role and membership organization mismatch");expect(migration).toContain("cannot remove or deactivate the last workspace administrator");});
 it("audits administration mutations from a trusted database boundary",()=>{expect(migration).toContain("audit_administration_mutation");expect(migration).toContain("database_trigger");});
 it("distinguishes authenticated human mutations from local system setup",()=>{expect(migration).toContain("when auth.uid() is null then 'system'");});
});
