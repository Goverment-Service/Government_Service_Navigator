import { Navigate, Outlet } from "react-router-dom";

export default function ProtectedRoute() {
  const token = localStorage.getItem("officerToken");
  
  if (!token) {
    return <Navigate to="/officer/login" replace />;
  }

  return <Outlet />;
}
