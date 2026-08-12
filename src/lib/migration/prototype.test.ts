import { describe,expect,it } from "vitest";
import { previewPrototypeMigration } from "./prototype";

const fixture=JSON.stringify({settings:{workspaceName:"SAMPLE / UNAPPROVED",eventStart:"2026-12-04",eventEnd:"2026-12-06"},departments:[],tasks:[],reports:[],content:[],milestones:[],resources:[],sponsors:[],decisions:[]});
describe("prototype migration",()=>{
  it("produces a stable preview without approving data",()=>{const result=previewPrototypeMigration(fixture);expect(result.classification).toBe("SAMPLE / UNAPPROVED");expect(result.digest).toHaveLength(64);expect(result.warnings.length).toBeGreaterThan(0)});
  it("rejects unexpected top-level keys",()=>expect(()=>previewPrototypeMigration(fixture.replace(/}$/,',"secret":"x"}'))).toThrow());
});
