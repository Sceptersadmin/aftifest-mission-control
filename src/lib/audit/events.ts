import { z } from "zod";

export const actorTypeSchema = z.enum(["human", "agent", "system"]);

export const auditEventSchema = z.object({
  organizationId: z.string().uuid(),
  actorType: actorTypeSchema,
  actorId: z.string().uuid().nullable(),
  agentId: z.string().uuid().nullable().default(null),
  action: z.string().min(1).max(160),
  targetType: z.string().min(1).max(80),
  targetId: z.string().uuid().nullable(),
  beforeState: z.record(z.string(), z.unknown()).nullable().default(null),
  afterState: z.record(z.string(), z.unknown()).nullable().default(null),
  approvalId: z.string().uuid().nullable().default(null),
  source: z.string().min(1).max(120),
  context: z.record(z.string(), z.unknown()).default({}),
  occurredAt: z.string().datetime(),
});

export type AuditEventInput = z.infer<typeof auditEventSchema>;

export interface AuditWriter {
  record(event: AuditEventInput): Promise<string>;
}

export function createAuditEvent(input: Omit<AuditEventInput, "occurredAt">): AuditEventInput {
  return auditEventSchema.parse({ ...input, occurredAt: new Date().toISOString() });
}
