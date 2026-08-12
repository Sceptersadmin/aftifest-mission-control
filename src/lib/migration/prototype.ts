import { createHash } from "node:crypto";
import { z } from "zod";

const prototypeSchema = z.object({
  settings: z.object({ workspaceName: z.string(), eventStart: z.string(), eventEnd: z.string() }),
  departments: z.array(z.record(z.string(), z.unknown())).default([]),
  tasks: z.array(z.record(z.string(), z.unknown())).default([]),
  reports: z.array(z.record(z.string(), z.unknown())).default([]),
  content: z.array(z.record(z.string(), z.unknown())).default([]),
  milestones: z.array(z.record(z.string(), z.unknown())).default([]),
  resources: z.array(z.record(z.string(), z.unknown())).default([]),
  sponsors: z.array(z.record(z.string(), z.unknown())).default([]),
  decisions: z.array(z.record(z.string(), z.unknown())).default([]),
}).strict();

export type PrototypeData = z.infer<typeof prototypeSchema>;

export type MigrationPreview = {
  digest: string;
  classification: "SAMPLE / UNAPPROVED";
  counts: Record<string, number>;
  warnings: string[];
  data: PrototypeData;
};

export function previewPrototypeMigration(raw: string): MigrationPreview {
  if (Buffer.byteLength(raw, "utf8") > 2_000_000) throw new Error("MIGRATION_FILE_TOO_LARGE");
  const data = prototypeSchema.parse(JSON.parse(raw));
  const warnings = [
    "Event dates require reconciliation.", "Festival pillar count requires reconciliation.",
    "Departments, leads, sponsor relationships, values, resource URLs, deadlines, approval authorities, and readiness methodology are unapproved.",
  ];
  return {
    digest: createHash("sha256").update(raw).digest("hex"),
    classification: "SAMPLE / UNAPPROVED",
    counts: Object.fromEntries(Object.entries(data).filter(([, value]) => Array.isArray(value)).map(([key, value]) => [key, value.length])),
    warnings,
    data,
  };
}
