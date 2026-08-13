import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import OfficerLoginPage from "./officer_login"; 
import AdminDashboard from "./Admin/admin_dashboard";
import ManageOfficers from "./Admin/manage_officers";
import OfficerDashboard from "./Officer/officer_dashboard";
import ProtectedRoute from "./components/ProtectedRoute";
import AuditLogs from "./Admin/audit_logs";
import SystemSettings from "./Admin/system_settings";
//import Settings from "./components/settings";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/officer/login" replace />} />
        <Route path="/officer/login" element={<OfficerLoginPage />} />
        
        <Route element={<ProtectedRoute />}>
          <Route path="/admin/dashboard" element={<AdminDashboard />} />
          <Route path="/admin/manage-officers" element={<ManageOfficers />} />
          <Route path="/officer/dashboard" element={<OfficerDashboard />} />
          <Route path="/admin/audit-logs" element={<AuditLogs />} />
          <Route path="/admin/system-settings" element={<SystemSettings />} /> 
          {/* <Route path="/settings" element={<Settings />} /> */}
        </Route>
      </Routes>
    </BrowserRouter>
  );
}