import { NextResponse } from "next/server";
import { z } from "zod";
import { ASK_IFEST_QUERIES, evaluateAgentRequest } from "@/lib/agents/policy";
import { createClient } from "@/lib/supabase/server";

const requestSchema = z.object({ question: z.enum(ASK_IFEST_QUERIES) });

export async function POST(request: Request) {
  const parsed = requestSchema.safeParse(await request.json());
  if (!parsed.success) return NextResponse.json({ error: "Unsupported Level 0 query." }, { status: 400 });

  const supabase = await createClient();
  const { data: authData } = await supabase.auth.getUser();
  if (!authData.user) return NextResponse.json({ error: "Authentication required.", citations: [] }, { status: 401 });

  const { data: memberships } = await supabase.from("organization_members").select("organization_id").eq("profile_id", authData.user.id).eq("status", "active");
  const organizationId = memberships?.[0]?.organization_id as string | undefined;
  if (!organizationId) return NextResponse.json({ error: "Active organization membership required.", citations: [] }, { status: 403 });
  const { data: hasPermission } = await supabase.rpc("has_permission", { target_organization_id: organizationId, requested_permission: "brain.read" });

  const policy = evaluateAgentRequest({
    agentId: "ask-ifest", authorityLevel: 0, action: "information.read",
    requiredPermission: "brain.read", targetType: "authorized_mission_control_data",
    simulation: false, hasPermission: hasPermission === true, hasApproval: false, policyAllowsAction: true,
  });

  if (!policy.allowed) return NextResponse.json({ authorityLevel: 0, policy, citations: [] }, { status: 403 });

  // Deliberately use the requester's session client. RLS is the retrieval boundary;
  // no service-role client is permitted in the ASK iFEST request path.
  const { data: items, error } = await supabase.from("company_brain_items")
    .select("id,title,summary,source_type,source_reference,visibility,verification_status")
    .eq("organization_id", organizationId).limit(10);
  if (error) return NextResponse.json({ error: "Authorized retrieval failed.", citations: [] }, { status: 500 });

  return NextResponse.json({
    status: "ok",
    question: parsed.data.question,
    authorityLevel: 0,
    policy,
    answer: items?.length ? `Found ${items.length} authorized Mission Control source${items.length === 1 ? "" : "s"}.` : "No authorized sources were found.",
    citations: (items ?? []).map((item) => ({ id: item.id, title: item.title, sourceType: item.source_type, sourceReference: item.source_reference })),
  });
}
