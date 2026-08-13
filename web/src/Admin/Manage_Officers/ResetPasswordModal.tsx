import React, { useState } from "react";
import {
  Modal,
  PasswordInput,
  Stack,
  InlineNotification
} from "@carbon/react";

interface ResetPasswordModalProps {
  isOpen: boolean;
  onClose: () => void;
  officer: any; 
}

export default function ResetPasswordModal({ isOpen, onClose, officer }: ResetPasswordModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [newPassword, setNewPassword] = useState("");

  const handleSubmit = async () => {
    setFormError(null);
    setSuccessMsg(null);
    setIsSubmitting(true);

    try {
      // NOTE: You will need to create this PATCH/POST endpoint in your backend AdminController
      const response = await fetch(`http://localhost:5119/api/admin/officers/${officer.id}/reset-password`, {
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
        const errorData = await response.json();
        setFormError(errorData.message || "Failed to reset password.");
      }
    } catch (error) {
      setFormError("Network error. Could not connect to the server.");
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