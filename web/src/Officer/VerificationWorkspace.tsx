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
  InlineLoading,
  Tag,
  Pagination,
} from "@carbon/react";
import { Checkmark, Close, Document, ChevronLeft, ArrowRight, Warning } from "@carbon/icons-react";

interface ReviewField {
  id: string;
  label: string;
  type: string;
  options?: string;
  isRequired: boolean;
  orderIndex: number;
}

interface ReviewDocument {
  id: number;
  documentName: string;
  fileName: string;
  uploadedAt: string;
}

interface ReviewPayment {
  transactionReference: string;
  method: string;
  amount: number;
  currency: string;
  status: string;
  verifiedAt?: string;
}

interface TaskReview {
  taskId: number;
  status: string;
  createdDate: string;
  applicationId?: number;
  applicationReference?: string;
  serviceName?: string;
  department?: string;
  citizenName?: string;
  citizenEmail?: string;
  submittedAt?: string;
  answers: Record<string, string>;
  formName?: string;
  subTitle?: string;
  fields: ReviewField[];
  documents: ReviewDocument[];
  payment?: ReviewPayment;
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

  const [review, setReview] = useState<TaskReview | null>(null);
  const [reviewLoading, setReviewLoading] = useState(true);
  const [reviewError, setReviewError] = useState<string | null>(null);
  const [currentDocIndex, setCurrentDocIndex] = useState(0);
  const [docObjectUrl, setDocObjectUrl] = useState<string | null>(null);
  const [docLoading, setDocLoading] = useState(false);

  const authHeaders = () => {
    const token = localStorage.getItem("officerToken");
    return { Authorization: `Bearer ${token}` };
  };

  useEffect(() => {
    const fetchReasons = async () => {
      try {
        const response = await fetch(`http://localhost:5119/api/Verification/rejection-reasons`, {
          headers: { "Content-Type": "application/json", ...authHeaders() }
        });
        if (response.ok) setRejectionReasons(await response.json());
      } catch (e) {
        console.error("Failed to fetch rejection reasons", e);
      }
    };
    fetchReasons();
  }, []);

  useEffect(() => {
    const fetchReview = async () => {
      setReviewLoading(true);
      setReviewError(null);
      try {
        const response = await fetch(`http://localhost:5119/api/Verification/tasks/${taskId}/review`, {
          headers: authHeaders(),
        });
        if (response.ok) {
          const data: TaskReview = await response.json();
          setReview(data);
        } else {
          setReviewError("Could not load this application.");
        }
      } catch (e) {
        setReviewError("Could not load this application.");
      } finally {
        setReviewLoading(false);
      }
    };
    if (taskId) fetchReview();
  }, [taskId]);

  useEffect(() => {
    if (docObjectUrl) URL.revokeObjectURL(docObjectUrl);
    setDocObjectUrl(null);
    const doc = review?.documents[currentDocIndex];
    if (!doc || !taskId) return;

    setDocLoading(true);
    fetch(`http://localhost:5119/api/Verification/tasks/${taskId}/documents/${doc.id}/file`, { headers: authHeaders() })
      .then((res) => (res.ok ? res.blob() : null))
      .then((blob) => {
        if (blob) setDocObjectUrl(URL.createObjectURL(blob));
      })
      .finally(() => setDocLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [review, currentDocIndex, taskId]);

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

    try {
      const response = await fetch(`http://localhost:5119/api/Verification/tasks/${taskId || 1}/decision`, {
        method: "PUT",
        headers: { "Content-Type": "application/json", ...authHeaders() },
        body: JSON.stringify({
          status: status,
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
    } catch (e) {
      setSubmitStatus("error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const documents = review?.documents ?? [];
  const currentDoc = documents[currentDocIndex];
  const isPdf = currentDoc?.fileName.toLowerCase().endsWith(".pdf");

  const fieldLabelById = new Map((review?.fields ?? []).map((f) => [f.id, f]));
  const answerEntries = review
    ? [...(review.fields.length > 0
        ? review.fields
            .filter((f) => !["heading", "paragraph"].includes(f.type))
            .map((f) => ({ label: f.label, value: review.answers[f.id] || "-" }))
        : Object.entries(review.answers).map(([key, value]) => ({ label: fieldLabelById.get(key)?.label || key, value })))]
    : [];

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
            {reviewLoading ? (
              <InlineLoading description="Loading application..." />
            ) : reviewError ? (
              <InlineNotification kind="error" title="Error" subtitle={reviewError} hideCloseButton />
            ) : (
            <Grid fullWidth>
              {/* Left Column: Document Gallery */}
              <Column sm={4} md={5} lg={9} style={{ backgroundColor: '#fff', border: '1px solid #e0e0e0', padding: '1rem', minHeight: '80vh' }}>
                <div style={{ marginBottom: '1rem' }}>
                  <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Submitted Documents</h2>
                  <p style={{ fontSize: '0.875rem', color: '#525252' }}>Documents the citizen uploaded with this application.</p>
                </div>

                <div style={{ backgroundColor: '#f4f4f4', minHeight: '550px', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px dashed #c6c6c6' }}>
                  {documents.length === 0 ? (
                    <div style={{ textAlign: 'center', color: '#525252' }}>
                      <Document size={48} style={{ margin: '0 auto 1rem' }} />
                      <p>No documents were submitted with this application.</p>
                    </div>
                  ) : docLoading ? (
                    <InlineLoading description="Loading document..." />
                  ) : isPdf && docObjectUrl ? (
                    <div style={{ textAlign: 'center' }}>
                      <Document size={48} style={{ margin: '0 auto 1rem' }} />
                      <p style={{ marginBottom: '0.5rem' }}>{currentDoc?.documentName}</p>
                      <a href={docObjectUrl} target="_blank" rel="noreferrer">Open PDF in new tab</a>
                    </div>
                  ) : docObjectUrl ? (
                    <img src={docObjectUrl} alt={currentDoc?.documentName} style={{ maxWidth: '100%', maxHeight: '540px' }} />
                  ) : (
                    <div style={{ textAlign: 'center', color: '#525252' }}>
                      <Document size={48} style={{ margin: '0 auto 1rem' }} />
                      <p>Could not load this document.</p>
                    </div>
                  )}
                </div>

                {currentDoc && (
                  <p style={{ marginTop: '0.5rem', fontSize: '0.75rem', color: '#525252' }}>
                    {currentDoc.documentName} &middot; {currentDoc.fileName} &middot; uploaded {new Date(currentDoc.uploadedAt).toLocaleString()}
                  </p>
                )}

                {documents.length > 1 && (
                  <div style={{ marginTop: '1rem' }}>
                     <Pagination
                        backwardText="Previous Document"
                        forwardText="Next Document"
                        itemsPerPageText=""
                        page={currentDocIndex + 1}
                        pageSize={1}
                        pageSizes={[1]}
                        totalItems={documents.length}
                        onChange={({ page }) => setCurrentDocIndex(page - 1)}
                     />
                  </div>
                )}
              </Column>

              {/* Right Column: Application data & Decision Panel */}
              <Column sm={4} md={3} lg={7} style={{ padding: '0 1rem' }}>

                <h2 style={{ fontSize: '1.75rem', fontWeight: 300, marginBottom: '0.5rem' }}>Application Review</h2>
                <div style={{ marginBottom: '1.5rem' }}>
                  <p style={{ fontSize: '0.875rem', color: '#525252' }}>App ID: <strong>{review?.applicationReference || `APP-${review?.applicationId ?? review?.taskId}`}</strong></p>
                  <p style={{ fontSize: '0.875rem', color: '#525252' }}>Citizen: <strong>{review?.citizenName || 'Unknown'}</strong> ({review?.citizenEmail || '-'})</p>
                  <p style={{ fontSize: '0.875rem', color: '#525252' }}>Service: <strong>{review?.serviceName || '-'}</strong> &middot; {review?.department || '-'}</p>
                </div>

                {/* Submitted Answers */}
                <div style={{ backgroundColor: '#fff', padding: '1rem', borderLeft: '4px solid #0f62fe', marginBottom: '1.5rem' }}>
                   <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '0.75rem' }}>
                     {review?.formName || 'Submitted Answers'}
                   </h3>
                   {answerEntries.length === 0 ? (
                     <p style={{ fontSize: '0.875rem', color: '#8d8d8d', fontStyle: 'italic' }}>No form fields were submitted with this application.</p>
                   ) : (
                     answerEntries.map((entry, i) => (
                       <div key={i} style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', padding: '0.4rem 0', borderBottom: '1px solid #f4f4f4' }}>
                         <span style={{ fontSize: '0.875rem', color: '#525252' }}>{entry.label}</span>
                         <span style={{ fontSize: '0.875rem', fontWeight: 600, textAlign: 'right' }}>{entry.value}</span>
                       </div>
                     ))
                   )}
                </div>

                {/* Payment */}
                {review?.payment && (
                  <div style={{ backgroundColor: '#fff', padding: '1rem', borderLeft: '4px solid #24a148', marginBottom: '1.5rem' }}>
                    <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '0.75rem' }}>Payment</h3>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', padding: '0.25rem 0' }}>
                      <span style={{ color: '#525252' }}>Reference</span><strong>{review.payment.transactionReference}</strong>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', padding: '0.25rem 0' }}>
                      <span style={{ color: '#525252' }}>Method</span><strong>{review.payment.method}</strong>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', padding: '0.25rem 0' }}>
                      <span style={{ color: '#525252' }}>Amount</span><strong>{review.payment.currency} {review.payment.amount.toFixed(2)}</strong>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', padding: '0.25rem 0' }}>
                      <span style={{ color: '#525252' }}>Status</span>
                      <Tag type={review.payment.status === 'Verified' || review.payment.status === 'Paid' ? 'green' : review.payment.status === 'Rejected' || review.payment.status === 'Failed' ? 'red' : 'blue'}>
                        {review.payment.status}
                      </Tag>
                    </div>
                  </div>
                )}

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
            )}
          </main>
        </>
      )}
    />
  );
}
