import { AskIfestPanel } from "@/components/ask-ifest-panel";
import { MissionControlShell } from "@/components/mission-control-shell";

const departments = [
  ["Executive Office & Project Management", 72, "On Track"],
  ["Sponsorship & Partnerships", 48, "At Risk"],
  ["Operations, Venues & Logistics", 44, "At Risk"],
  ["Technology & Community OS", 78, "On Track"],
] as const;

export default function Home() {
  return (
    <MissionControlShell active="Executive Overview">
      <section className="hero">
        <span className="eyebrow">AfroFutureTech iFest • Phase 1 foundation</span>
        <h1>Everyone aligned.<br />Every action governed.</h1>
        <p>
          The Mission Control visual language is preserved while shared data, real permissions,
          auditability, approvals, Company Brain, and ASK iFEST are established underneath it.
        </p>
        <div className="heroActions">
          <a className="button primary" href="#brief">View command brief</a>
          <a className="button soft" href="#ask-ifest">Ask iFEST</a>
        </div>
      </section>

      <div className="sectionHeading" id="brief">
        <div><h2>Leadership snapshot</h2><p>Development fixture data — SAMPLE / UNAPPROVED.</p></div>
        <span className="sampleBadge">SAMPLE / UNAPPROVED</span>
      </div>

      <div className="metrics">
        <article className="card metric"><span className="tag green">Provisional</span><strong>62%</strong><p>Readiness methodology requires approval</p></article>
        <article className="card metric"><span className="tag">Across teams</span><strong>7</strong><p>Open sample priority tasks</p></article>
        <article className="card metric"><span className="tag amber">Needs review</span><strong>4</strong><p>Illustrative risk signals</p></article>
        <article className="card metric"><span className="tag green">Level 0</span><strong>Read</strong><p>ASK iFEST authority</p></article>
      </div>

      <div className="twoColumn">
        <article className="card">
          <h3>Department health</h3>
          {departments.map(([name, progress, health]) => (
            <div className="health" key={name}>
              <div><b>{name}</b><span>{health} · {progress}%</span></div>
              <div className="bar"><i style={{ width: `${progress}%` }} /></div>
            </div>
          ))}
        </article>
        <article className="card authorityCard">
          <span className="eyebrow purple">Governance foundation</span>
          <h3>Authority lives in policy, not presentation.</h3>
          <p>Authentication, organization membership, capabilities, Row-Level Security, approval rules, and audit events form the enforcement chain.</p>
          <ol>
            <li>Verify identity and active organization membership</li>
            <li>Evaluate capability and record visibility</li>
            <li>Require configured approval where applicable</li>
            <li>Record human, agent, or system activity</li>
          </ol>
        </article>
      </div>

      <AskIfestPanel />
    </MissionControlShell>
  );
}
