import { ASK_IFEST_QUERIES } from "@/lib/agents/policy";

export function AskIfestPanel() {
  return (
    <section className="askPanel" id="ask-ifest">
      <div>
        <span className="eyebrow">ASK iFEST / AI Chief of Staff</span>
        <h2>Read. Synthesize. Cite.</h2>
        <p>Level 0 can retrieve only information the signed-in user is authorized to read. It cannot change records or take external action.</p>
        <div className="queryGrid">
          {ASK_IFEST_QUERIES.map((query) => <button disabled key={query}>{query}</button>)}
        </div>
      </div>
      <aside className="guardrail">
        <b>Simulation-first guardrails</b>
        <ul>
          <li>No messages, payments, contracts, publishing, deletion, or permission changes</li>
          <li>Same authorization boundary as human requests</li>
          <li>Every run records requester, sources, policy decision, and result</li>
          <li>Provider-neutral adapter; no provider is enabled in Phase 1</li>
        </ul>
        <span className="statusPill">Provider disabled · foundation ready</span>
      </aside>
    </section>
  );
}
