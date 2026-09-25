import '@carbon/styles/css/styles.css';
import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Header,
  HeaderContainer,
  HeaderName,
  HeaderGlobalBar,
  Button,
  Grid,
  Column,
  TextArea,
  Select,
  SelectItem,
  InlineNotification,
  Tag,
  Pagination,
  Toggle
} from "@carbon/react";
import { Checkmark, Close, Document, ChevronLeft, ArrowRight, Warning } from "@carbon/icons-react";
import AgentDraftPanel from "./AgentDraftPanel";
import { getAgentDraft, generateAgentDraft, type AgentDraftView } from "./agentDraftApi";
import { ApiError } from "../utils/api";

interface TaskDetail {
  task: {
    id: number;
    applicationId: number;
    status: string;
    referenceNumber: string;
    citizenName?: string | null;
    citizenNic?: string | null;
    serviceName?: string | null;
  };
  submittedAt?: string | null;
  userEmail?: string | null;
  answers: Record<string, string>;
}

export default function VerificationWorkspace() {
  const { taskId } = useParams();
  const navigate = useNavigate();
  const [decision, setDecision] = useState<string>("");
  const [comments, setComments] = useState("");
  const [reasonId, setReasonId] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<"idle" | "success" | "error">("idle");
  const [rejectionReasons, setRejectionReasons] = useState<{id: number, code: string, description: string}[]>([]);
  const [detail, setDetail] = useState<TaskDetail | null>(null);
  const [detailError, setDetailError] = useState("");
  const [agentDraft, setAgentDraft] = useState<AgentDraftView | null>(null);
  const [agentLoading, setAgentLoading] = useState(true);
  const [agentError, setAgentError] = useState("");

  // Document Gallery State: documents the citizen attached, plus those the agents flagged as missing
  const [currentDocIndex, setCurrentDocIndex] = useState(0);
  const [documents, setDocuments] = useState<{ id: number; name: string; isVerified: boolean; aiTag: string }[]>([]);

  const applyAgentDraft = (view: AgentDraftView) => {
    const attached = view.action.draft?.attachedDocumentNames ?? [];
    const missing = view.eligibility.missingDocuments;
    setAgentDraft(view);
    setDocuments([
      ...attached.map((name, i) => ({ id: i + 1, name, isVerified: false, aiTag: "Submitted by citizen" })),
      ...missing.map((name, i) => ({ id: attached.length + i + 1, name, isVerified: false, aiTag: "Missing (flagged by agent)" }))
    ]);
    setCurrentDocIndex(0);
  };

  // Backend returns { message, details } on agent failures; show the details so the officer knows what went wrong
  const describeAgentError = (e: unknown) => {
    const fallback = "The AI agents could not prepare a draft for this application.";
    if (!(e instanceof ApiError)) return fallback;
    try {
      const body = JSON.parse(e.message);
      return body.details ? `${fallback} ${body.details}` : fallback;
    } catch {
      return e.status === 404 ? e.message : fallback;
    }
  };

  // Agent 2 + Agent 3 output: load the stored draft, or run the agents the first time the task is opened
  useEffect(() => {
    if (!taskId) return;
    const loadAgentDraft = async () => {
      try {
        const stored = await getAgentDraft(taskId);
        applyAgentDraft(stored ?? await generateAgentDraft(taskId));
      } catch (e) {
        console.error("Failed to load agent draft", e);
        setAgentError(describeAgentError(e));
      } finally {
        setAgentLoading(false);
      }
    };
    loadAgentDraft();
  }, [taskId]);

  const regenerateAgentDraft = async () => {
    if (!taskId) return;
    setAgentLoading(true);
    setAgentError("");
    try {
      applyAgentDraft(await generateAgentDraft(taskId));
    } catch (e) {
      console.error("Failed to re-run agents", e);
      setAgentError(describeAgentError(e));
    } finally {
      setAgentLoading(false);
    }
  };

  useEffect(() => {
    if (!taskId) return;
    const fetchDetail = async () => {
      try {
        const token = localStorage.getItem("officerToken");
        const response = await fetch(`http://localhost:5119/api/Verification/tasks/${taskId}`, {
          headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}) }
        });
        if (response.ok) {
          setDetail(await response.json());
        } else {
          setDetailError(response.status === 404 ? "Application not found." : "Failed to load application.");
        }
      } catch (e) {
        console.error("Failed to fetch task detail", e);
        setDetailError("Failed to load application.");
      }
    };
    fetchDetail();
  }, [taskId]);

  useEffect(() => {
    const fetchReasons = async () => {
      try {
        const token = localStorage.getItem("officerToken");
        const response = await fetch(`http://localhost:5119/api/Verification/rejection-reasons`, {
          headers: {
            "Content-Type": "application/json",
            ...(token ? { Authorization: `Bearer ${token}` } : {})
          }
        });
        if (response.ok) {
          const data = await response.json();
          setRejectionReasons(data);
        }
      } catch (e) {
        console.error("Failed to fetch rejection reasons", e);
      }
    };
    fetchReasons();
  }, []);


  const currentDoc = documents[currentDocIndex];

  const handleDocumentVerificationToggle = (checked: boolean) => {
    setDocuments(docs => docs.map((d, i) => i === currentDocIndex ? { ...d, isVerified: checked } : d));
  };

  const handleDecision = async (status: string) => {
    setDecision(status);
    if (status === "Approved") {
      await submitDecision(status);
    }
  };

  const submitDecision = async (status: string) => {
    if ((status === "Rejected" || status === "Revision Requested") && (!comments && !reasonId)) {
      alert("Please provide a reason or comments for rejection/revision.");
      return;
    }

    setIsSubmitting(true);
    setSubmitStatus("idle");
    
    const token = localStorage.getItem("officerToken");

    try {
      const response = await fetch(`http://localhost:5119/api/Verification/tasks/${taskId}/decision`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({
          status: status === "Revision Requested" ? "Revised" : status,
          comments: comments,
          rejectionReasonId: reasonId ? parseInt(reasonId) : null
        })
      });

      if (response.ok) {
        setSubmitStatus("success");
        setTimeout(() => navigate('/officer/pending-reviews'), 2000);
      } else {
        setSubmitStatus("error");
      }
    } catch {
      setSubmitStatus("error");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <HeaderContainer
      render={() => (
        <>
          <Header aria-label="Registry Portal System">
            <HeaderName href="#" prefix="GSN">
              Workspace
            </HeaderName>
            <HeaderGlobalBar>
               <Button kind="ghost" size="sm" renderIcon={ChevronLeft} onClick={() => navigate('/officer/pending-reviews')}>
                 Back to Queue
               </Button>
            </HeaderGlobalBar>
          </Header>

          <main className="mt-12 min-h-screen p-4 min-[66rem]:p-8" style={{ backgroundColor: '#f4f4f4' }}>
            <Grid fullWidth>
              {/* Left Column: Document Gallery */}
              <Column sm={4} md={5} lg={9} style={{ backgroundColor: '#fff', border: '1px solid #e0e0e0', padding: '1rem', minHeight: '80vh' }}>
                <div style={{ marginBottom: '1rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Submitted Documents</h2>
                    <p style={{ fontSize: '0.875rem', color: '#525252' }}>Manually review and verify each uploaded proof.</p>
                  </div>
                  {currentDoc && (
                  <div style={{ backgroundColor: currentDoc.isVerified ? '#defbe6' : '#fff', padding: '0.5rem 1rem', border: '1px solid #e0e0e0', borderRadius: '4px' }}>
                     <Toggle
                        id="doc-verify-toggle"
                        size="sm"
                        labelA="Unverified"
                        labelB="Verified"
                        toggled={currentDoc.isVerified}
                        onToggle={handleDocumentVerificationToggle}
                     />
                  </div>
                  )}
                </div>
                
                <div style={{ backgroundColor: '#f4f4f4', minHeight: '550px', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px dashed #c6c6c6' }}>
                  {!currentDoc ? (
                  <div style={{ textAlign: 'center', color: '#525252' }}>
                     <Document size={48} style={{ margin: '0 auto 1rem' }} />
                     <p>{agentLoading ? "Loading documents…" : "No documents were attached or flagged for this application."}</p>
                  </div>
                  ) : (
                  <div style={{ textAlign: 'center', color: '#525252' }}>
                     <Document size={48} style={{ margin: '0 auto 1rem' }} />
                     <p style={{ fontSize: '1.25rem', marginBottom: '0.5rem' }}>{currentDoc.name}</p>
                     <Tag type={currentDoc.aiTag.includes("Missing") ? "red" : "blue"}>
                        {currentDoc.aiTag}
                     </Tag>
                     {currentDoc.isVerified && (
                        <div style={{ marginTop: '1rem', color: '#198038', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                           <Checkmark size={20} />
                           <span style={{ fontWeight: 600 }}>Marked as Verified manually</span>
                        </div>
                     )}
                  </div>
                  )}
                </div>

                <div style={{ marginTop: '1rem' }}>
                   <Pagination
                      backwardText="Previous Document"
                      forwardText="Next Document"
                      itemsPerPageText=""
                      page={currentDocIndex + 1}
                      pageSize={1}
                      pageSizes={[1]}
                      totalItems={Math.max(documents.length, 1)}
                      onChange={({ page }) => setCurrentDocIndex(page - 1)}
                   />
                </div>
              </Column>

              {/* Right Column: Reasoning & Decision Panel */}
              <Column sm={4} md={3} lg={7} style={{ padding: '0 1rem' }}>
                
                <h2 style={{ fontSize: '1.75rem', fontWeight: 300, marginBottom: '0.5rem' }}>Application Review</h2>
                <div style={{ marginBottom: '2rem' }}>
                  <p style={{ fontSize: '0.875rem', color: '#525252' }}>App ID: <strong>{detail?.task.referenceNumber ?? "—"}</strong></p>
                  <p style={{ fontSize: '0.875rem', color: '#525252' }}>Citizen: <strong>{detail?.task.citizenName || "—"}</strong>{detail?.task.citizenNic ? ` (${detail.task.citizenNic})` : ""}</p>
                  <p style={{ fontSize: '0.875rem', color: '#525252' }}>Service: <strong>{detail?.task.serviceName || "—"}</strong></p>
                  {detail?.submittedAt && (
                    <p style={{ fontSize: '0.875rem', color: '#525252' }}>Submitted: <strong>{new Date(detail.submittedAt).toLocaleString()}</strong></p>
                  )}
                </div>

                {detailError && (
                  <InlineNotification kind="error" title="Error" subtitle={detailError} hideCloseButton lowContrast style={{ marginBottom: '1rem' }} />
                )}

                {/* Citizen's submitted form answers */}
                <div style={{ backgroundColor: '#fff', padding: '1rem', border: '1px solid #e0e0e0', marginBottom: '2rem' }}>
                  <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '1rem' }}>Submitted Application</h3>
                  {detail && Object.keys(detail.answers).length > 0 ? (
                    <dl style={{ display: 'grid', gridTemplateColumns: 'minmax(8rem, 40%) 1fr', gap: '0.5rem 1rem', fontSize: '0.875rem' }}>
                      {Object.entries(detail.answers).map(([label, value]) => (
                        <div key={label} style={{ display: 'contents' }}>
                          <dt style={{ color: '#525252' }}>{label}</dt>
                          <dd style={{ fontWeight: 500, wordBreak: 'break-word' }}>{value || "—"}</dd>
                        </div>
                      ))}
                    </dl>
                  ) : (
                    <p style={{ fontSize: '0.875rem', color: '#525252' }}>
                      {detail ? "No form answers were submitted with this application." : "Loading…"}
                    </p>
                  )}
                </div>

                {/* Agent Reasoning Trail: Agent 2 eligibility + Agent 3 draft (fee, appointment, pre-filled fields) */}
                <AgentDraftPanel
                  draft={agentDraft}
                  loading={agentLoading}
                  error={agentError}
                  answers={detail?.answers ?? {}}
                  onRegenerate={regenerateAgentDraft}
                />

                {/* Decision Panel */}
                <div style={{ backgroundColor: '#fff', padding: '1.5rem', border: '1px solid #e0e0e0' }}>
                   <h3 style={{ fontSize: '1.25rem', marginBottom: '1rem' }}>Record Decision</h3>
                   
                   <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem' }}>
                      <Button 
                         kind={decision === "Approved" ? "primary" : "ghost"} 
                         renderIcon={Checkmark} 
                         onClick={() => handleDecision("Approved")}
                         disabled={isSubmitting}
                      >
                         Approve
                      </Button>
                      <Button 
                         kind={decision === "Revision Requested" ? "primary" : "ghost"} 
                         renderIcon={Warning} 
                         onClick={() => handleDecision("Revision Requested")}
                         disabled={isSubmitting}
                      >
                         Request Revision
                      </Button>
                      <Button 
                         kind={decision === "Rejected" ? "danger" : "danger--ghost"} 
                         renderIcon={Close} 
                         onClick={() => handleDecision("Rejected")}
                         disabled={isSubmitting}
                      >
                         Reject
                      </Button>
                   </div>

                   {(decision === "Rejected" || decision === "Revision Requested") && (
                     <div style={{ animation: "fadeIn 0.2s ease-in" }}>
                         <Select 
                            id="reason-code" 
                            labelText="Reason Code" 
                            value={reasonId} 
                            onChange={(e) => setReasonId(e.target.value)}
                            style={{ marginBottom: '1rem' }}
                         >
                            <SelectItem value="" text="Choose an option" />
                            {rejectionReasons.map(r => (
                              <SelectItem key={r.id} value={r.id.toString()} text={`${r.code}: ${r.description}`} />
                            ))}
                         </Select>

                        <TextArea 
                           labelText="Additional Comments (Visible to Citizen)" 
                           placeholder="Explain exactly what needs to be fixed..."
                           value={comments}
                           onChange={(e) => setComments(e.target.value)}
                           rows={4}
                           style={{ marginBottom: '1rem' }}
                        />

                        <Button 
                           renderIcon={ArrowRight} 
                           onClick={() => submitDecision(decision)}
                           disabled={isSubmitting}
                        >
                           Submit {decision}
                        </Button>
                     </div>
                   )}

                   {submitStatus === "success" && (
                     <InlineNotification kind="success" title="Success" subtitle="Decision recorded. Returning to queue..." hideCloseButton style={{ marginTop: '1rem' }} />
                   )}
                   {submitStatus === "error" && (
                     <InlineNotification kind="error" title="Error" subtitle="Failed to save decision. Try again." hideCloseButton style={{ marginTop: '1rem' }} />
                   )}
                </div>
              </Column>
            </Grid>
          </main>
        </>
      )}
    />
  );
}


