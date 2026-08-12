import { describe, expect, it } from "vitest";
import { createAuditEvent } from "./events";

const uuid = "00000000-0000-4000-8000-000000000001";

describe("audit event contract", () => {
  it("distinguishes human actors and preserves before/after state", () => {
    const event = createAuditEvent({
      organizationId: uuid,
      actorType: "human",
      actorId: uuid,
      agentId: null,
      action: "task.update",
      targetType: "task",
      targetId: uuid,
      beforeState: { status: "doing" },
      afterState: { status: "review" },
      approvalId: null,
      source: "unit_test",
      context: { correlationId: uuid },
    });
    expect(event.actorType).toBe("human");
    expect(event.beforeState).toEqual({ status: "doing" });
    expect(event.afterState).toEqual({ status: "review" });
    expect(event.context.correlationId).toBe(uuid);
  });

  it("rejects an unsupported actor type", () => {
    expect(() => createAuditEvent({
      organizationId: uuid,
      actorType: "robot" as "human",
      actorId: uuid,
      agentId: null,
      action: "test",
      targetType: "test",
      targetId: null,
      beforeState: null,
      afterState: null,
      approvalId: null,
      source: "unit_test",
      context: {},
    })).toThrow();
  });
});
