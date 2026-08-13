import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { describe,expect,it } from "vitest";

describe("reference prototype",()=>{
  it("retains the local baseline reference",()=>{
    const content=readFileSync("index.html","utf8");
    expect(content).toContain("AfroFutureTech Mission Control v2.2");
    expect(createHash("sha256").update(content).digest("hex")).toHaveLength(64);
  });
});
