import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import OfficerLoginPage from "./officer_login";
import AdminDashboard from "./Admin/admin_dashboard";
import ManageOfficers from "./Admin/manage_officers";
import OfficerDashboard from "./Officer/officer_dashboard";
import AuditLogs from "./Admin/audit_logs";
import SystemSettings from "./Admin/system_settings";
import ApplicationCreate from "./Officer/Application_create/application_create";

/*
  Summary: import the necessary components for officer routes
*/
import VerifiedRecords from "./Officer/verified_record";
import PendingReviews from "./Officer/pending_reviews";
import Profile from "./Officer/profile";
import ApplicationsList from "./Officer/applications";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* admin routes */}
        <Route path="/" element={<Navigate to="/officer/login" replace />} />
        <Route path="/admin/dashboard" element={<AdminDashboard />} />
        <Route path="/admin/manage-officers" element={<ManageOfficers />} />
        <Route path="/officer/dashboard" element={<OfficerDashboard />} />
        <Route path="/admin/audit-logs" element={<AuditLogs />} />
        <Route path="/admin/system-settings" element={<SystemSettings />} />

        {/* officer route */}
        <Route path="/officer/login" element={<OfficerLoginPage />} />
        <Route path="/officer/applications" element={<ApplicationsList />} />
        <Route path="/officer/verified-records" element={<VerifiedRecords />} />
        <Route path="/officer/pending-reviews" element={<PendingReviews />} />
        <Route path="/officer/profile" element={<Profile />} />
        <Route path="/officer/Application_create/application_create" element={<ApplicationCreate />} />
      </Routes>
    </BrowserRouter>
  );
}