import { execFileSync } from "node:child_process";

export default async function globalSetup() {
  execFileSync(process.execPath, ["scripts/provision-e2e.mjs"], { cwd: process.cwd(), stdio: "inherit", timeout: 90_000 });
}
