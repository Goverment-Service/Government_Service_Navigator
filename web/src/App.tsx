import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import OfficerLoginPage from "./officer_login"; 
import AdminDashboard from "./Admin/admin_dashboard";
import OfficerDashboard from "./Officer/officer_dashboard";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/officer/login" replace />} />
        <Route path="/officer/login" element={<OfficerLoginPage />} />
        <Route path="/admin/dashboard" element={<AdminDashboard />} />
        <Route path="/officer/dashboard" element={<OfficerDashboard />} />
      </Routes>
    </BrowserRouter>
  );
}