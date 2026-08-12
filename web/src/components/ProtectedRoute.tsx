import { Navigate, Outlet } from "react-router-dom";

export default function ProtectedRoute() {
  const token = localStorage.getItem("officerToken");
  
  // If there is no token, redirect to the login page
  if (!token) {
    return <Navigate to="/officer/login" replace />;
  }

  // If a token exists, render the child routes
  return <Outlet />;
}
