import { NextResponse } from "next/server";
import { z } from "zod";
import { ASK_IFEST_QUERIES, evaluateAgentRequest } from "@/lib/agents/policy";

const requestSchema = z.object({ question: z.enum(ASK_IFEST_QUERIES) });

export async function POST(request: Request) {
  const parsed = requestSchema.safeParse(await request.json());
  if (!parsed.success) return NextResponse.json({ error: "Unsupported Level 0 query." }, { status: 400 });

  const policy = evaluateAgentRequest({
    agentId: "ask-ifest", authorityLevel: 0, action: "information.read",
    requiredPermission: "brain.read", targetType: "authorized_mission_control_data",
    simulation: false, hasPermission: false, hasApproval: false, policyAllowsAction: true,
  });

  return NextResponse.json({
    status: "not_configured",
    question: parsed.data.question,
    authorityLevel: 0,
    policy,
    message: "Authentication and authorized retrieval must be configured before ASK iFEST can answer.",
    citations: [],
  }, { status: 503 });
}
