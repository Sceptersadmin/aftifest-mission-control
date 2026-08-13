import { describe,expect,it } from "vitest";
import { evaluateApproval } from "./policy";

describe("approval policy",()=>{
  it("does not invent approval requirements",()=>expect(evaluateApproval(null,new Set())).toBe("not_required"));
  it("requires configured minimum unique eligible roles",()=>{
    const rule={id:"r",organizationId:"o",action:"decision.approve",targetType:"decision",requiredPermission:"decision.approve" as const,eligibleRoleIds:["a","b"],minimumApprovals:2,active:true};
    expect(evaluateApproval(rule,new Set(["a"]))).toBe("pending");
    expect(evaluateApproval(rule,new Set(["a","b"]))).toBe("approved");
  });
});
