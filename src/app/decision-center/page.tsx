import { FoundationPage } from "@/components/foundation-page";

export default function DecisionCenterPage(){return <FoundationPage active="Governance Room" eyebrow="Decision Center" title="Decisions with authority, context, and history." description="Proposals are organization-scoped and move through configurable approval chains. Role names alone never establish authority." columns={[
  {tag:"PROPOSE",title:"Decision record",body:"Owner, requester, due date, impact, supporting context, status, and visibility."},
  {tag:"AUTHORIZE",title:"Approval chain",body:"Ordered configurable steps tied to eligible roles and minimum approvals."},
  {tag:"RECORD",title:"Outcome and audit",body:"Outcome, transitions, approvers, timestamps, and before/after state remain traceable."},
  {tag:"GUARDRAIL",title:"No inferred authority",body:"Approval rules must be explicitly configured from approved organizational governance."},
]}/>}
