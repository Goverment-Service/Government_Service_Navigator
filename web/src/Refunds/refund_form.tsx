import '@carbon/styles/css/styles.css';
import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { Tile, TextInput, TextArea, Button, InlineNotification, InlineLoading } from "@carbon/react";
import { fetchRefundForm, submitRefundForm, type RefundFormView } from "./refundFormApi";
import { formatCurrency } from "../Finance/format";

export default function RefundFormPage() {
  const { token } = useParams<{ token: string }>();
  const [form, setForm] = useState<RefundFormView | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const [accountHolderName, setAccountHolderName] = useState("");
  const [bankName, setBankName] = useState("");
  const [branchName, setBranchName] = useState("");
  const [accountNumber, setAccountNumber] = useState("");
  const [reason, setReason] = useState("");

  useEffect(() => {
    if (!token) return;
    fetchRefundForm(token)
      .then(setForm)
      .catch((err) => setError(err instanceof Error ? err.message : "This refund link is invalid."))
      .finally(() => setLoading(false));
  }, [token]);

  async function handleSubmit() {
    if (!token) return;
    if (!accountHolderName || !bankName || !branchName || !accountNumber || !reason) {
      setError("Please fill in every field.");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await submitRefundForm(token, { accountHolderName, bankName, branchName, accountNumber, reason });
      setSubmitted(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not submit your refund form.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f4f4f4', display: 'flex', justifyContent: 'center', alignItems: 'flex-start', padding: '3rem 1.25rem' }}>
      <Tile style={{ maxWidth: '520px', width: '100%', padding: '2rem' }}>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 400, marginBottom: '1rem' }}>Refund Request Form</h1>

        {loading && <InlineLoading description="Loading..." />}
        {error && <InlineNotification kind="error" title="Error" subtitle={error} lowContrast style={{ marginBottom: '1rem' }} />}

        {!loading && form && !submitted && (
          <>
            <p style={{ color: '#525252', marginBottom: '1.5rem' }}>
              Refund for payment <strong>{form.transactionReference}</strong> of{" "}
              <strong>{formatCurrency(form.amount, form.currency)}</strong>. Please provide the bank account you'd
              like the refund sent to.
            </p>

            {form.alreadySubmitted ? (
              <InlineNotification kind="info" title="Already submitted" subtitle="You've already submitted this refund form. A Finance Officer is reviewing your request." lowContrast hideCloseButton />
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                <TextInput id="accountHolderName" labelText="Account Holder Name" value={accountHolderName} onChange={(e) => setAccountHolderName(e.target.value)} />
                <TextInput id="bankName" labelText="Bank Name" value={bankName} onChange={(e) => setBankName(e.target.value)} />
                <TextInput id="branchName" labelText="Branch" value={branchName} onChange={(e) => setBranchName(e.target.value)} />
                <TextInput id="accountNumber" labelText="Account Number" value={accountNumber} onChange={(e) => setAccountNumber(e.target.value)} />
                <TextArea id="reason" labelText="Reason for Refund" value={reason} onChange={(e) => setReason(e.target.value)} rows={3} />
                <Button disabled={submitting} onClick={handleSubmit}>
                  {submitting ? "Submitting..." : "Submit Refund Request"}
                </Button>
              </div>
            )}
          </>
        )}

        {submitted && (
          <InlineNotification
            kind="success"
            title="Refund request submitted"
            subtitle="A Finance Officer will review your details and process your refund. You'll receive an email once it's complete."
            lowContrast
            hideCloseButton
          />
        )}
      </Tile>
    </div>
  );
}
