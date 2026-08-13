import React, { useState } from "react";
import { Modal, InlineNotification } from "@carbon/react";

interface SuspendAccountModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  officer: any;
}

export default function SuspendAccountModal({ isOpen, onClose, onSuccess, officer }: SuspendAccountModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const isCurrentlySuspended = officer?.status === "Suspended";

  const handleSubmit = async () => {
    setFormError(null);
    setIsSubmitting(true);

    try {
      // NOTE: You will need to create this PATCH endpoint in your backend AdminController
      const endpoint = isCurrentlySuspended 
        ? `http://localhost:5119/api/admin/officers/${officer.id}/activate`
        : `http://localhost:5119/api/admin/officers/${officer.id}/suspend`;

      const response = await fetch(endpoint, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" }
      });

      if (response.ok) {
        onSuccess();
        onClose();
      } else {
        const errorData = await response.json();
        setFormError(errorData.message || "Failed to change account status.");
      }
    } catch (error) {
      setFormError("Network error. Could not connect to the server.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      danger={!isCurrentlySuspended}
      open={isOpen}
      onRequestClose={onClose}
      onRequestSubmit={handleSubmit}
      modalHeading={isCurrentlySuspended ? "Reactivate Account" : "Suspend Account"}
      primaryButtonText={isSubmitting ? "Processing..." : (isCurrentlySuspended ? "Reactivate Officer" : "Suspend Officer")}
      secondaryButtonText="Cancel"
      primaryButtonDisabled={isSubmitting}
    >
      <p style={{ marginBottom: '1.5rem', color: '#525252' }}>
        {isCurrentlySuspended 
          ? `Are you sure you want to restore access for ${officer?.name}? They will be able to log in and verify documents immediately.`
          : `Are you sure you want to suspend ${officer?.name}? They will immediately lose access to the Registry Portal.`
        }
      </p>

      {formError && (
        <InlineNotification kind="error" title="Error" subtitle={formError} lowContrast style={{ marginBottom: '1rem' }} />
      )}
    </Modal>
  );
}