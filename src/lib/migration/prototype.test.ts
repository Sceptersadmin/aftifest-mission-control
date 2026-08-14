import { describe,expect,it } from "vitest";
import { previewPrototypeMigration } from "./prototype";

const fixture=JSON.stringify({settings:{workspaceName:"SAMPLE / UNAPPROVED",eventStart:"2026-12-04",eventEnd:"2026-12-06"},departments:[],tasks:[],reports:[],content:[],milestones:[],resources:[],sponsors:[],decisions:[]});
describe("prototype migration",()=>{
  it("produces a stable preview with explicit reconciliation warnings",()=>{const result=previewPrototypeMigration(fixture);expect(result.classification).toBe("SAMPLE / UNAPPROVED");expect(result.digest).toHaveLength(64);expect(result.warnings).toContain("Event dates require reconciliation.");expect(result.warnings.join(" ")).toContain("approval authorities")});
  it("rejects unexpected top-level keys",()=>expect(()=>previewPrototypeMigration(fixture.replace(/}$/,',"secret":"x"}'))).toThrow());
  it("rejects invalid JSON",()=>expect(()=>previewPrototypeMigration("{" )).toThrow("INVALID_PROTOTYPE_JSON"));
  it("accepts an explicit aftifestCommandData wrapper",()=>expect(previewPrototypeMigration(JSON.stringify({aftifestCommandData:JSON.parse(fixture)})).detectedSchema).toContain("wrapped"));
  it("defers unsafe people and report relationships",()=>{const value=JSON.parse(fixture);value.departments=[{id:1,name:"TEST Department",lead:"Unmapped Lead"}];value.tasks=[{id:1,title:"Mapped task",dept:"TEST Department",owner:"Unmapped Owner"},{id:2,title:"Unsafe task",dept:"Missing"}];value.reports=[{dept:"TEST Department",reporter:"Unknown"}];const preview=previewPrototypeMigration(JSON.stringify(value));expect(preview.peopleMappings.every(x=>x.state==="UNMAPPED PERSON")).toBe(true);expect(preview.items.find(x=>x.sourceKey==="tasks:2")?.status).toBe("deferred");expect(preview.items.find(x=>x.sourceType==="reports")?.status).toBe("deferred")});
  it("flags duplicate deterministic source keys",()=>{const value=JSON.parse(fixture);value.decisions=[{title:"Same"},{title:"Same"}];expect(previewPrototypeMigration(JSON.stringify(value)).duplicateCandidates).toContain("decisions:Same")});
});
