import { describe,expect,it } from "vitest";
import { previewPrototypeMigration } from "./prototype";

const fixture=JSON.stringify({settings:{workspaceName:"SAMPLE / UNAPPROVED",eventStart:"2026-12-04",eventEnd:"2026-12-06"},departments:[],tasks:[],reports:[],content:[],milestones:[],resources:[],sponsors:[],decisions:[]});
describe("prototype migration",()=>{
  it("produces a stable preview with explicit reconciliation warnings",()=>{const result=previewPrototypeMigration(fixture);expect(result.classification).toBe("SAMPLE / UNAPPROVED");expect(result.digest).toHaveLength(64);expect(result.warnings).toContain("Event dates require reconciliation.");expect(result.warnings.join(" ")).toContain("approval authorities")});
  it("rejects unexpected top-level keys",()=>expect(()=>previewPrototypeMigration(fixture.replace(/}$/,',"secret":"x"}'))).toThrow());
});
