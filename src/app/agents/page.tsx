import { FoundationPage } from "@/components/foundation-page";

export default function AgentsPage(){return <FoundationPage active="Executive Overview" eyebrow="Agent Registry" title="Agents operate inside policy, permission, and audit boundaries." description="ASK iFEST is registered at Level 0 with its provider disabled. Future adapters cannot bypass Mission Control authorization." columns={[
  {tag:"LEVEL 0",title:"ASK iFEST",body:"Read-only retrieval and synthesis with citations to authorized Mission Control records."},
  {tag:"SIMULATE",title:"Agent runs",body:"Request, initiator, mode, policy decision, citations, approval, response, and audit linkage."},
  {tag:"NEUTRAL",title:"Provider adapters",body:"Normalized provider interface keeps security and governance outside model-specific code."},
  {tag:"DENY",title:"Prohibited actions",body:"No messaging, payments, contracts, publishing, deletion, permissions, or irreversible actions."},
]}/>}
