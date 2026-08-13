import { describe, expect, it } from "vitest";
import { simulateAgentAction } from "./simulation";

describe("agent simulation", () => {
  it("never executes an otherwise approved action", () => {
    const result = simulateAgentAction({
      agentId: "test-agent",
      authorityLevel: 2,
      action: "task.update",
      requiredPermission: "task.manage_department",
      targetType: "task",
      hasPermission: true,
      hasApproval: true,
      policyAllowsAction: true,
      simulation: false,
    }, 1);
    expect(result.decision.allowed).toBe(true);
    expect(result.decision.execute).toBe(false);
    expect(result.estimatedAffectedRecords).toBe(1);
  });

  it("marks prohibited actions as prohibited risk", () => {
    const result = simulateAgentAction({
      agentId: "test-agent",
      authorityLevel: 0,
      action: "permission.change",
      requiredPermission: "agent.configure",
      targetType: "role",
      hasPermission: true,
      hasApproval: false,
      policyAllowsAction: true,
      simulation: false,
    });
    expect(result.risk).toBe("prohibited");
  });
});
