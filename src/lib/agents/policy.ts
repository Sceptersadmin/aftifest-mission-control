import type { Permission } from "@/lib/auth/permissions";

export const AUTHORITY_LEVELS = [0, 1, 2, 3] as const;
export type AuthorityLevel = (typeof AUTHORITY_LEVELS)[number];

export const ASK_IFEST_QUERIES = [
  "What is at risk today?",
  "Which departments are behind?",
  "What decisions await approval?",
  "Which sponsor opportunities are stalled?",
  "Which high-priority tasks are overdue?",
  "What content is due today?",
  "Which leadership requests remain unresolved?",
] as const;

export const PROHIBITED_AGENT_ACTIONS = new Set([
  "external_message.send", "decision.approve", "payment.approve", "contract.modify",
  "content.publish", "record.delete", "permission.change", "external.irreversible",
]);

export type AgentRequest = {
  agentId: string;
  authorityLevel: AuthorityLevel;
  action: string;
  requiredPermission: Permission;
  targetType: string;
  targetId?: string;
  simulation: boolean;
  hasPermission: boolean;
  hasApproval: boolean;
  policyAllowsAction: boolean;
};

export type AgentPolicyDecision = {
  allowed: boolean;
  execute: boolean;
  requiresApproval: boolean;
  reason: string;
};

export function evaluateAgentRequest(request: AgentRequest): AgentPolicyDecision {
  if (PROHIBITED_AGENT_ACTIONS.has(request.action)) {
    return { allowed: false, execute: false, requiresApproval: false, reason: "Action is prohibited for Phase 1 agents." };
  }
  if (!request.hasPermission || !request.policyAllowsAction) {
    return { allowed: false, execute: false, requiresApproval: false, reason: "Permission or explicit agent policy denied the request." };
  }
  if (request.authorityLevel === 0 && request.action !== "information.read") {
    return { allowed: false, execute: false, requiresApproval: false, reason: "Level 0 agents are read only." };
  }
  if (request.authorityLevel === 1 && request.action !== "information.read" && request.action !== "action.suggest") {
    return { allowed: false, execute: false, requiresApproval: false, reason: "Level 1 agents may read or suggest only." };
  }
  const requiresApproval = request.authorityLevel === 2;
  if (requiresApproval && !request.hasApproval) {
    return { allowed: true, execute: false, requiresApproval: true, reason: "A valid approval is required before execution." };
  }
  if (request.simulation) {
    return { allowed: true, execute: false, requiresApproval, reason: "Simulation mode never executes the requested action." };
  }
  if (request.authorityLevel === 3) {
    return { allowed: false, execute: false, requiresApproval: false, reason: "Level 3 execution is disabled in Phase 1." };
  }
  return { allowed: true, execute: request.action === "information.read", requiresApproval, reason: "Authorized read-only request." };
}
