import { describe, expect, it } from "vitest";
import { canAccessDepartment, hasPermission, requirePermission, type AuthorizationContext } from "./permissions";

const context:AuthorizationContext={actorId:"u",organizationId:"o",membershipId:"m",permissions:new Set(["task.read"]),departmentIds:new Set(["d1"])};
describe("authorization",()=>{
  it("grants only assigned capabilities",()=>{expect(hasPermission(context,"task.read")).toBe(true);expect(hasPermission(context,"workspace.admin")).toBe(false)});
  it("enforces department scope",()=>{expect(canAccessDepartment(context,"d1")).toBe(true);expect(canAccessDepartment(context,"d2")).toBe(false)});
  it("fails closed",()=>expect(()=>requirePermission(context,"sponsor.read")).toThrow("FORBIDDEN:sponsor.read"));
});
