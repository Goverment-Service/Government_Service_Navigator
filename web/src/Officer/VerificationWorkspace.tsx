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
  Accordion,
  AccordionItem,
  Tag,
  Pagination,
  Toggle
} from "@carbon/react";
import { Checkmark, Close, Document, ChevronLeft, ArrowRight, Warning } from "@carbon/icons-react";

export default function VerificationWorkspace() {
  const { taskId } = useParams();
  const navigate = useNavigate();
  const [decision, setDecision] = useState<string>("");
  const [comments, setComments] = useState("");
  const [reasonId, setReasonId] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<"idle" | "success" | "error">("idle");
  const [rejectionReasons, setRejectionReasons] = useState<{id: number, code: string, description: string}[]>([]);

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

  // Document Gallery State
  const [currentDocIndex, setCurrentDocIndex] = useState(0);
  const [documents, setDocuments] = useState([
    { id: 1, name: "National Identity Card", type: "nic", isVerified: true, aiTag: "Verified by AI" },
    { id: 2, name: "Proof of Address", type: "address", isVerified: false, aiTag: "Expired (Over 6 Months)" },
    { id: 3, name: "Birth Certificate", type: "birth_cert", isVerified: false, aiTag: "Not Processed by AI" },
    { id: 4, name: "Vehicle Registration", type: "vehicle_reg", isVerified: false, aiTag: "Verified by AI" },
    { id: 5, name: "Medical Certificate", type: "medical", isVerified: false, aiTag: "Not Processed by AI" }
  ]);

  const handleDocumentVerificationToggle = (checked: boolean) => {
    const updatedDocs = [...documents];
    updatedDocs[currentDocIndex].isVerified = checked;
    setDocuments(updatedDocs);
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
      const response = await fetch(`http://localhost:5119/api/Verification/tasks/${taskId || 1}/decision`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
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
                  <div style={{ backgroundColor: documents[currentDocIndex].isVerified ? '#defbe6' : '#fff', padding: '0.5rem 1rem', border: '1px solid #e0e0e0', borderRadius: '4px' }}>
                     <Toggle 
                        id="doc-verify-toggle"
                        size="sm"
                        labelA="Unverified"
                        labelB="Verified"
                        toggled={documents[currentDocIndex].isVerified}
                        onToggle={handleDocumentVerificationToggle}
                     />
                  </div>
                </div>
                
                <div style={{ backgroundColor: '#f4f4f4', minHeight: '550px', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px dashed #c6c6c6' }}>
                  <div style={{ textAlign: 'center', color: '#525252' }}>
                     <Document size={48} style={{ margin: '0 auto 1rem' }} />
                     <p style={{ fontSize: '1.25rem', marginBottom: '0.5rem' }}>{documents[currentDocIndex].name}</p>
                     <Tag type={
                        documents[currentDocIndex].aiTag.includes("Verified") ? "blue" : 
                        documents[currentDocIndex].aiTag.includes("Expired") ? "red" : "gray"
                     }>
                        {documents[currentDocIndex].aiTag}
                     </Tag>
                     {documents[currentDocIndex].isVerified && (
                        <div style={{ marginTop: '1rem', color: '#198038', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                           <Checkmark size={20} />
                           <span style={{ fontWeight: 600 }}>Marked as Verified manually</span>
                        </div>
                     )}
                  </div>
                </div>

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
              </Column>

              {/* Right Column: Reasoning & Decision Panel */}
              <Column sm={4} md={3} lg={7} style={{ padding: '0 1rem' }}>
                
                <h2 style={{ fontSize: '1.75rem', fontWeight: 300, marginBottom: '0.5rem' }}>Application Review</h2>
                <div style={{ marginBottom: '2rem' }}>
                  <p style={{ fontSize: '0.875rem', color: '#525252' }}>App ID: <strong>GSN-2026-9102</strong></p>
                  <p style={{ fontSize: '0.875rem', color: '#525252' }}>Citizen: <strong>Amila Kumara</strong></p>
                </div>

                {/* Agent Reasoning Trail Viewer */}
                <div style={{ backgroundColor: '#fff', padding: '1rem', borderLeft: '4px solid #0f62fe', marginBottom: '2rem' }}>
                   <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1rem' }}>
                      <h3 style={{ fontSize: '1rem', fontWeight: 600 }}>Agent Reasoning Trail</h3>
                      <Tag type="blue" style={{ marginLeft: 'auto' }}>AI Assisted</Tag>
                   </div>
                   
                   <Accordion align="start">
                      <AccordionItem title="Phase 1: Eligibility Check">
                         <p style={{ fontSize: '0.875rem', color: '#525252' }}>
                           ✓ Citizen meets age requirement (Age &gt; 18).<br />
                           ✓ Citizen resides in specified district.
                         </p>
                      </AccordionItem>
                      <AccordionItem title="Phase 2: Document Extraction">
                         <p style={{ fontSize: '0.875rem', color: '#525252' }}>
                           ✓ <strong>NIC:</strong> Validated format (991234567V). Extracted Name: "Amila Kumara".<br />
                           ⚠ <strong>Proof of Address:</strong> Name matches, but date of issue is over 6 months old.
                         </p>
                      </AccordionItem>
                      <AccordionItem title="Phase 3: Final Validation" open>
                         <InlineNotification 
                           kind="warning" 
                           title="Manual Review Recommended"
                           subtitle="The Proof of Address document is older than the standard 6-month threshold. Please verify manually."
                           lowContrast
                           hideCloseButton
                         />
                      </AccordionItem>
                   </Accordion>
                </div>

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

