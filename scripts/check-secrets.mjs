import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

const files = execFileSync("git", ["ls-files", "--cached", "--others", "--exclude-standard"], { encoding: "utf8" }).trim().split(/\r?\n/).filter(Boolean);
const forbidden = [
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,
  /^(?:SUPABASE_SERVICE_ROLE_KEY|ASK_IFEST_API_KEY)[ \t]*=[ \t]*(?!replace-|$)[^\r\n]+/m,
  /\b(?:sk|sb_secret)_[A-Za-z0-9_-]{20,}\b/,
];
const findings = [];
for (const file of files) {
  if (file === "index.html") continue;
  let text;
  try { text = readFileSync(file, "utf8"); } catch { continue; }
  forbidden.forEach((pattern) => { if (pattern.test(text)) findings.push(`${file}: ${pattern}`); });
}
if (findings.length) { console.error(findings.join("\n")); process.exit(1); }
console.log(`Secret scan passed across ${files.length} tracked files.`);
