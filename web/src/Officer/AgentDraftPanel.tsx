import {
  Accordion,
  AccordionItem,
  Button,
  InlineLoading,
  InlineNotification,
  Tag,
} from "@carbon/react";
import { Renew } from "@carbon/icons-react";
import type { AgentDraftView } from "./agentDraftApi";

interface Props {
  draft: AgentDraftView | null;
  loading: boolean;
  error: string;
  // Citizen's submitted answers, to flag agent-drafted values that differ
  answers: Record<string, string>;
  onRegenerate: () => void;
}

const muted = { fontSize: "0.875rem", color: "#525252" } as const;
const sectionTitle = { fontSize: "0.875rem", fontWeight: 600, margin: "1rem 0 0.5rem" } as const;

function formatMoney(amount: number, currency = "LKR") {
  return `${currency} ${amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function prettyJson(raw: string) {
  try {
    return JSON.stringify(JSON.parse(raw), null, 2);
  } catch {
    return raw;
  }
}

export default function AgentDraftPanel({ draft, loading, error, answers, onRegenerate }: Props) {
  const eligibility = draft?.eligibility;
  const action = draft?.action;
  const fields = action?.draft?.formFields ?? {};

  return (
    <div style={{ backgroundColor: "#fff", padding: "1rem", borderLeft: "4px solid #0f62fe", marginBottom: "2rem" }}>
      <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.5rem" }}>
        <h3 style={{ fontSize: "1rem", fontWeight: 600 }}>Agent Reasoning Trail</h3>
        <Tag type="blue" style={{ marginLeft: "auto" }}>AI Assisted</Tag>
        <Button kind="ghost" size="sm" renderIcon={Renew} hasIconOnly iconDescription="Re-run agents" onClick={onRegenerate} disabled={loading} />
      </div>
      {draft && (
        <p style={{ ...muted, marginBottom: "1rem" }}>Generated {new Date(draft.generatedAt).toLocaleString()}</p>
      )}

      {loading && <InlineLoading description="Running Eligibility and Action/Tool agents…" />}
      {error && !loading && (
        <InlineNotification kind="error" title="Agent draft unavailable" subtitle={error} hideCloseButton lowContrast />
      )}

      {eligibility && action && !loading && (
        <Accordion align="start">
          {/* Agent 2 */}
          <AccordionItem title="Phase 1: Eligibility Check">
            <div style={{ display: "flex", gap: "0.5rem", marginBottom: "0.5rem" }}>
              <Tag type={eligibility.isEligible ? "green" : "red"}>{eligibility.isEligible ? "Eligible" : "Not eligible"}</Tag>
              <Tag type="gray">{eligibility.matchPercentage}% match</Tag>
              {draft?.derivedAgeFromNic != null && <Tag type="cool-gray">Age {draft.derivedAgeFromNic} (from NIC)</Tag>}
            </div>
            {eligibility.missingCriteria.length > 0 && (
              <ul style={{ ...muted, listStyle: "disc", paddingLeft: "1.25rem" }}>
                {eligibility.missingCriteria.map((c) => <li key={c}>⚠ {c}</li>)}
              </ul>
            )}
            <p style={{ ...muted, marginTop: "0.5rem" }}>{eligibility.reasoning}</p>
          </AccordionItem>

          {/* Agent 3 */}
          <AccordionItem title="Phase 2: Draft Application (Action/Tool Agent)" open>
            {!action.draft ? (
              <p style={muted}>No draft was prepared — see Phase 3 for the reasons.</p>
            ) : (
              <>
                <h4 style={sectionTitle}>Calculated Fee</h4>
                {action.fee && action.fee.lineItems.length > 0 ? (
                  <table style={{ width: "100%", fontSize: "0.875rem" }}>
                    <tbody>
                      {action.fee.lineItems.map((i) => (
                        <tr key={i.feeType}>
                          <td style={{ color: "#525252" }}>{i.feeType}</td>
                          <td style={{ textAlign: "right" }}>{formatMoney(i.amount, action.fee!.currency)}</td>
                        </tr>
                      ))}
                      <tr style={{ fontWeight: 600, borderTop: "1px solid #e0e0e0" }}>
                        <td>Total</td>
                        <td style={{ textAlign: "right" }}>{formatMoney(action.fee.totalAmount, action.fee.currency)}</td>
                      </tr>
                    </tbody>
                  </table>
                ) : (
                  <p style={muted}>No fee in force — free of charge.</p>
                )}

                <h4 style={sectionTitle}>Proposed Appointment</h4>
                {action.appointment?.isSlotFound ? (
                  <>
                    <p style={{ fontSize: "0.875rem", fontWeight: 500 }}>{action.appointment.localDisplay}</p>
                    <p style={muted}>{action.appointment.message}</p>
                  </>
                ) : (
                  <p style={muted}>{action.appointment?.message ?? "No slot proposed."}</p>
                )}

                <h4 style={sectionTitle}>Pre-filled Form Fields</h4>
                {Object.keys(fields).length > 0 ? (
                  <dl style={{ display: "grid", gridTemplateColumns: "minmax(8rem, 40%) 1fr", gap: "0.5rem 1rem", fontSize: "0.875rem" }}>
                    {Object.entries(fields).map(([label, value]) => {
                      const submitted = answers[label];
                      const differs = submitted !== undefined && submitted.trim() !== value.trim();
                      return (
                        <div key={label} style={{ display: "contents" }}>
                          <dt style={{ color: "#525252" }}>{label}</dt>
                          <dd style={{ fontWeight: 500, wordBreak: "break-word" }}>
                            {value}
                            {differs && (
                              <Tag type="magenta" size="sm" style={{ marginLeft: "0.5rem" }} title={`Citizen entered: ${submitted}`}>
                                Differs from submission
                              </Tag>
                            )}
                          </dd>
                        </div>
                      );
                    })}
                  </dl>
                ) : (
                  <p style={muted}>No fields could be pre-filled.</p>
                )}
                {action.unfilledRequiredFields.length > 0 && (
                  <div style={{ marginTop: "0.5rem", display: "flex", flexWrap: "wrap", gap: "0.25rem" }}>
                    {action.unfilledRequiredFields.map((f) => <Tag key={f} type="red" size="sm">Missing: {f}</Tag>)}
                  </div>
                )}

                <p style={{ ...muted, marginTop: "1rem" }}>{action.reasoning}</p>
              </>
            )}
          </AccordionItem>

          {/* What the officer needs to act on */}
          <AccordionItem title="Phase 3: Officer Attention" open>
            {action.isReadyForValidation ? (
              <InlineNotification kind="success" title="Draft complete" subtitle="All required fields pre-filled; ready for validation." lowContrast hideCloseButton />
            ) : (
              <InlineNotification
                kind="warning"
                title="Manual Review Recommended"
                subtitle={action.blockers.join(" ") || "The agent could not complete the draft."}
                lowContrast
                hideCloseButton
              />
            )}
            {action.notesForOfficer.length > 0 && (
              <ul style={{ ...muted, listStyle: "disc", paddingLeft: "1.25rem", marginTop: "0.5rem" }}>
                {action.notesForOfficer.map((n) => <li key={n}>{n}</li>)}
              </ul>
            )}
          </AccordionItem>

          <AccordionItem title={`Tool Calls (${action.toolCalls.length})`}>
            {action.toolCalls.length === 0 ? (
              <p style={muted}>No tools were called.</p>
            ) : (
              action.toolCalls.map((t, i) => (
                <details key={i} style={{ marginBottom: "0.5rem", fontSize: "0.8125rem" }}>
                  <summary style={{ cursor: "pointer" }}>
                    <code>{t.toolName}</code> <span style={{ color: "#6f6f6f" }}>· {new Date(t.calledAt).toLocaleTimeString()}</span>
                  </summary>
                  <pre style={{ background: "#f4f4f4", padding: "0.5rem", overflowX: "auto", whiteSpace: "pre-wrap" }}>
                    Input: {prettyJson(t.input)}
                    {"\n"}Output: {prettyJson(t.output)}
                  </pre>
                </details>
              ))
            )}
          </AccordionItem>
        </Accordion>
      )}
    </div>
  );
}
