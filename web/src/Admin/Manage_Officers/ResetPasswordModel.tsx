import { useState } from "react";
import { API_BASE } from "../../lib/apiBase";
import {
  Modal,
  PasswordInput,
  Stack,
  InlineNotification
} from "@carbon/react";

interface ResetPasswordModalProps {
  isOpen: boolean;
  onClose: () => void;
  officer: { id: string; name?: string } | null;
}

export default function ResetPasswordModal({ isOpen, onClose, officer }: ResetPasswordModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [newPassword, setNewPassword] = useState("");

  const handleSubmit = async () => {
    if (!officer) return;
    setFormError(null);
    setSuccessMsg(null);
    setIsSubmitting(true);

    try {
      const response = await fetch(`${API_BASE}/admin/officers/${officer.id}/reset-password`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ newPassword }),
      });

      if (response.ok) {
        setSuccessMsg("Password successfully reset.");
        setTimeout(() => {
          onClose();
          setNewPassword("");
          setSuccessMsg(null);
        }, 1500);
      } else {
        let errorMessage = "Failed to reset password.";
        try {
          const errorData = await response.json();
          errorMessage = errorData.message || (errorData.errors && JSON.stringify(errorData.errors)) || errorMessage;
        } catch {
          errorMessage = `Server Error: ${response.status} ${response.statusText}. Check backend console.`;
        }
        setFormError(errorMessage);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      if (message === "Failed to fetch") {
         setFormError("Backend is offline. Please ensure the server is running on port 5119.");
      } else {
         setFormError(`Request failed: ${message}`);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      open={isOpen}
      onRequestClose={onClose}
      onRequestSubmit={handleSubmit}
      modalHeading="Reset Officer Password"
      primaryButtonText={isSubmitting ? "Resetting..." : "Reset Password"}
      secondaryButtonText="Cancel"
      primaryButtonDisabled={isSubmitting || newPassword.length < 6 || !!successMsg}
    >
      <p style={{ marginBottom: '1.5rem', color: '#525252' }}>
        You are overriding the password for <strong>{officer?.name}</strong>. They will be logged out of all active sessions.
      </p>

      {formError && (
        <InlineNotification kind="error" title="Error" subtitle={formError} lowContrast style={{ marginBottom: '1rem' }} />
      )}
      {successMsg && (
        <InlineNotification kind="success" title="Success" subtitle={successMsg} lowContrast style={{ marginBottom: '1rem' }} />
      )}

      <Stack gap={5}>
        <PasswordInput
          id="new-password"
          labelText="New Temporary Password"
          placeholder="Enter at least 6 characters"
          value={newPassword}
          onChange={(e) => setNewPassword(e.target.value)}
          disabled={isSubmitting || !!successMsg}
        />
      </Stack>
    </Modal>
  );
}