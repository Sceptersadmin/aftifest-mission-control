export type KnowledgeCitation = { recordType: string; recordId: string; updatedAt: string; label: string };

export type AgentPrompt = {
  organizationId: string;
  requesterId: string;
  question: string;
  authorizedContext: readonly { content: string; citation: KnowledgeCitation }[];
};

export type AgentAnswer = {
  text: string;
  citations: readonly KnowledgeCitation[];
  providerMetadata: Record<string, unknown>;
};

export interface AgentProvider {
  readonly name: string;
  answer(prompt: AgentPrompt): Promise<AgentAnswer>;
}

export class DisabledAgentProvider implements AgentProvider {
  readonly name = "disabled";
  async answer(): Promise<AgentAnswer> {
    throw new Error("ASK_IFEST_PROVIDER_DISABLED");
  }
}
