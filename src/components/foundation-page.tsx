import { MissionControlShell } from "./mission-control-shell";

export function FoundationPage({ active, eyebrow, title, description, columns }: { active: string; eyebrow: string; title: string; description: string; columns: readonly { title: string; body: string; tag: string }[] }) {
  return <MissionControlShell active={active}><section className="hero"><span className="eyebrow">{eyebrow}</span><h1>{title}</h1><p>{description}</p></section><div className="sectionHeading"><div><h2>Phase 1 foundation</h2><p>Structure and guardrails are implemented; production workflows remain intentionally disabled.</p></div><span className="sampleBadge">NO PRODUCTION DATA</span></div><div className="metrics">{columns.map((column)=><article className="card" key={column.title}><span className="tag">{column.tag}</span><h3>{column.title}</h3><p>{column.body}</p></article>)}</div></MissionControlShell>;
}
