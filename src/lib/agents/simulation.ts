import { evaluateAgentRequest, type AgentRequest } from "./policy";

export type SimulationResult = {
  action: string;
  targetType: string;
  targetId?: string;
  estimatedAffectedRecords: number;
  risk: "low" | "medium" | "high" | "prohibited";
  decision: ReturnType<typeof evaluateAgentRequest>;
  simulatedAt: string;
};

export function simulateAgentAction(request: AgentRequest, estimatedAffectedRecords = 0): SimulationResult {
  const decision = evaluateAgentRequest({ ...request, simulation: true });
  return {
    action: request.action,
    targetType: request.targetType,
    targetId: request.targetId,
    estimatedAffectedRecords,
    risk: decision.allowed ? (request.authorityLevel >= 2 ? "high" : "low") : "prohibited",
    decision,
    simulatedAt: new Date().toISOString(),
  };
}
