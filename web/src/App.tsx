import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import OfficerLoginPage from "./officer_login"; 
import AdminDashboard from "./Admin/admin_dashboard";
import ManageOfficers from "./Admin/manage_officers";
import OfficerDashboard from "./Officer/officer_dashboard";
import ProtectedRoute from "./components/ProtectedRoute";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/officer/login" replace />} />
        <Route path="/officer/login" element={<OfficerLoginPage />} />
        
        {/* Protected Routes - require login */}
        <Route element={<ProtectedRoute />}>
          <Route path="/admin/dashboard" element={<AdminDashboard />} />
          <Route path="/admin/manage-officers" element={<ManageOfficers />} />
          <Route path="/officer/dashboard" element={<OfficerDashboard />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}