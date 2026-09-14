import { useState } from "react";
import {
  Modal,
  TextInput,
  Select,
  SelectItem,
  Stack,
  InlineNotification
} from "@carbon/react";

interface Officer {
  id: string;
  name?: string;
  email?: string;
  department?: string;
  role?: string;
  status?: string;
}

interface EditOfficerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  officer: Officer | null; // Pass the selected officer row data here
}

export default function EditOfficerModal({ isOpen, onClose, onSuccess, officer }: EditOfficerModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    fullName: "",
    department: "",
    role: ""
  });

  // Populate form when the modal opens with a specific officer
  const [prevOfficer, setPrevOfficer] = useState(officer);
  if (officer !== prevOfficer) {
    setPrevOfficer(officer);
    if (officer) {
      setFormData({
        fullName: officer.name || "",
        department: officer.department || "",
        role: officer.role || "Verifying Officer"
      });
    }
  }

  const handleSubmit = async () => {
    if (!officer) return;
    setFormError(null);
    setIsSubmitting(true);

    try {
      // NOTE: You will need to create this PUT endpoint in your backend AdminController
      const response = await fetch(`http://localhost:5119/api/admin/officers/${officer.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      if (response.ok) {
        onSuccess(); // Refresh table
        onClose(); // Close modal
      } else {
        const errorData = await response.json();
        setFormError(errorData.message || "Failed to update officer profile.");
      }
    } catch {
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
      modalHeading="Edit Officer Profile"
      primaryButtonText={isSubmitting ? "Saving..." : "Save Changes"}
      secondaryButtonText="Cancel"
      primaryButtonDisabled={isSubmitting || !formData.fullName || !formData.department}
    >
      <p style={{ marginBottom: '1.5rem', color: '#525252' }}>
        Update the details for <strong>{officer?.email}</strong>.
      </p>

      {formError && (
        <InlineNotification kind="error" title="Error" subtitle={formError} lowContrast style={{ marginBottom: '1rem' }} />
      )}

      <Stack gap={5}>
        <TextInput
          id="edit-fullName"
          labelText="Full Name"
          value={formData.fullName}
          onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
          disabled={isSubmitting}
        />
        <TextInput
          id="edit-department"
          labelText="Department"
          value={formData.department}
          onChange={(e) => setFormData({ ...formData, department: e.target.value })}
          disabled={isSubmitting}
        />
        <Select
          id="edit-role"
          labelText="Role Designation"
          value={formData.role}
          onChange={(e) => setFormData({ ...formData, role: e.target.value })}
          disabled={isSubmitting}
        >
          <SelectItem value="Verifying Officer" text="Verifying Officer" />
          <SelectItem value="Department Admin" text="Department Admin" />
          <SelectItem value="Auditor" text="Auditor" />
        </Select>
      </Stack>
    </Modal>
  );
}