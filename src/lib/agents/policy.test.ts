import { describe, expect, it } from "vitest";
import { evaluateAgentRequest } from "./policy";

const base = { agentId:"ask-ifest", authorityLevel:0 as const, requiredPermission:"brain.read" as const, targetType:"knowledge", simulation:false, hasPermission:true, hasApproval:false, policyAllowsAction:true };

describe("agent authority",()=>{
  it("allows an authorized Level 0 read",()=>expect(evaluateAgentRequest({...base,action:"information.read"}).execute).toBe(true));
  it("denies mutation by Level 0",()=>expect(evaluateAgentRequest({...base,action:"action.suggest"}).allowed).toBe(false));
  it("denies prohibited actions at every level",()=>expect(evaluateAgentRequest({...base,authorityLevel:2,action:"payment.approve",hasApproval:true}).allowed).toBe(false));
  it("never executes simulation",()=>expect(evaluateAgentRequest({...base,authorityLevel:2,action:"task.update",hasApproval:true,simulation:true}).execute).toBe(false));
});
