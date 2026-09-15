import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import OfficerLoginPage from "./officer_login";
import AdminDashboard from "./Admin/admin_dashboard";
import DepartmentAdminDashboard from "./Admin/department_admin_dashboard";
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
import ApplicationPreview from "./Officer/application_preview";
import ServiceCatalogManager from "./Admin/Service_Catalog/service_catalog_manager";
import EligibilityRuleBuilder from "./Admin/Service_Catalog/eligibility_rule_builder";
import ServiceConfigurationTabs from "./Admin/Service_Catalog/service_configuration_tabs";
import EligibilitySimulator from "./Admin/Service_Catalog/eligibility_simulator";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* admin routes */}
        <Route path="/" element={<Navigate to="/officer/login" replace />} />
        <Route path="/admin/dashboard" element={<AdminDashboard />} />
        <Route
          path="/admin/:deptSlug/dashboard"
          element={<DepartmentAdminDashboard />}
        />
        <Route path="/admin/manage-officers" element={<ManageOfficers />} />
        <Route path="/officer/dashboard" element={<OfficerDashboard />} />
        <Route path="/admin/audit-logs" element={<AuditLogs />} />
        <Route path="/admin/system-settings" element={<SystemSettings />} />
        <Route path="/admin/services" element={<ServiceCatalogManager />} />
        <Route
          path="/admin/services/rules"
          element={<EligibilityRuleBuilder />}
        />
        <Route
          path="/admin/services/config"
          element={<ServiceConfigurationTabs />}
        />

        <Route
          path="/admin/services/simulator"
          element={<EligibilitySimulator />}
        />

        {/* officer route */}
        <Route path="/officer/login" element={<OfficerLoginPage />} />
        <Route path="/officer/applications" element={<ApplicationsList />} />
        <Route path="/officer/verified-records" element={<VerifiedRecords />} />
        <Route path="/officer/pending-reviews" element={<PendingReviews />} />
        <Route path="/officer/profile" element={<Profile />} />
        <Route
          path="/officer/Application_create/application_create"
          element={<ApplicationCreate />}
        />
        <Route
          path="/officer/application-preview"
          element={<ApplicationPreview />}
        />
      </Routes>
    </BrowserRouter>
  );
}
