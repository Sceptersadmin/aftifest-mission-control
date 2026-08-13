import { FoundationPage } from "@/components/foundation-page";

export default function CompanyBrainPage(){return <FoundationPage active="Resources & Links" eyebrow="Company Brain" title="Governed knowledge, not an unbounded document dump." description="Knowledge items carry scope and provenance so authorized people—and Level 0 ASK iFEST—can understand where information came from." columns={[
  {tag:"SOURCE",title:"Provenance",body:"Source type, reference, owner, timestamps, and structured provenance metadata."},
  {tag:"CONTROL",title:"Classification",body:"Organization, department, restricted, or public visibility with verification status."},
  {tag:"VERIFY",title:"Knowledge lifecycle",body:"Unverified, verified, rejected, or sample/unapproved status with effective and expiry dates."},
  {tag:"PHASE 1",title:"No broad ingestion",body:"External document ingestion and automatic indexing are intentionally outside this phase."},
]}/>}
