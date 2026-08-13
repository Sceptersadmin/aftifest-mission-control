import { requireSessionUser } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import { signOut } from "@/app/login/actions";

const navigation = [
  ["◫", "Executive Overview"], ["◉", "Departments & People"],
  ["✓", "Tasks & Accountability"], ["▤", "Department Reports"],
  ["▦", "Social Content Calendar"], ["◆", "Sponsor CRM"],
  ["↗", "Road to iFest"], ["♛", "Governance Room"],
  ["⬡", "Resources & Links"], ["⚙", "Workspace Settings"],
] as const;

export async function MissionControlShell({ active, children }: { active: string; children: React.ReactNode }) {
  const user = await requireSessionUser();
  const supabase = await createClient();
  const { data: memberships } = await supabase.from("organization_members").select("organization_id").eq("profile_id", user.id).eq("status", "active");
  const organizationId = memberships?.[0]?.organization_id as string | undefined;
  const can = async (permission: string) => organizationId
    ? (await supabase.rpc("has_permission", { target_organization_id: organizationId, requested_permission: permission })).data === true
    : false;
  const [canDecide, canUseBrain, canUseAgents] = await Promise.all([can("decision.read"), can("brain.read"), can("agent.read")]);
  const initials = (user.email ?? "MC").slice(0, 2).toUpperCase();
  return (
    <div className="appShell">
      <aside className="sidebar">
        <div className="brand"><span className="mark">iF</span><div><b>AFTiFest Mission Control</b><small>Alignment • Accountability • Action</small></div></div>
        <nav aria-label="Mission Control modules">
          {navigation.filter(([, label]) => label !== "Governance Room" || canDecide).map(([icon, label]) => (
            <a className={label === active ? "active" : ""} href={label === "Governance Room" ? "/decision-center" : label === active ? "#" : `#${label.toLowerCase().replaceAll(/[^a-z0-9]+/g, "-")}`} key={label}>
              <span>{icon}</span>{label}
            </a>
          ))}
          <a className="agentLink" href="#ask-ifest"><span>✦</span>ASK iFEST</a>
          {canDecide && <a href="/decision-center"><span>◇</span>Decision Center</a>}
          {canUseBrain && <a href="/company-brain"><span>⌁</span>Company Brain</a>}
          {canUseAgents && <a href="/agents"><span>◎</span>Agent Registry</a>}
        </nav>
        <div className="sideCard"><b>Phase 1 security posture</b><p>Local foundation. No production infrastructure or autonomous actions.</p><div className="bar"><i style={{ width: "72%" }} /></div></div>
      </aside>
      <main className="main">
        <header className="topbar"><div><b>{active}</b><small>One governed source of truth for leadership and delivery teams.</small></div><div className="identity"><span className="level">ASK iFEST · LEVEL 0</span><span className="avatar" title={user.email}>{initials}</span><form action={signOut}><button type="submit">Sign out</button></form></div></header>
        <div className="content">{children}</div>
      </main>
    </div>
  );
}
