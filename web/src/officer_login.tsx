import '@carbon/styles/css/styles.css';
import React, { useState } from "react";
import type { FormEvent } from "react";
import {
  TextInput,
  PasswordInput,
  Button,
  Checkbox,
  InlineNotification,
  Link,
  Stack
} from "@carbon/react";

export default function OfficerLoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  // showPassword state is removed because Carbon's PasswordInput handles it automatically
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    if (!email.includes("@")) {
      setError("Enter a valid email address.");
      return;
    }
    if (password.length < 6) {
      setError("Password must be at least 6 characters.");
      return;
    }

    setIsLoading(true);
    try {
      let response = await fetch("http://localhost:5119/api/auth/officer-login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      });

      let resData = await response.json();

      if (resData.success && resData.officer) {
        localStorage.setItem("officerToken", resData.token);
        localStorage.setItem("officerUser", JSON.stringify(resData.officer));
        
        window.location.href = "/officer/dashboard"; 
        return; 
      }

      response = await fetch("http://localhost:5119/api/auth/admin-login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      });

      resData = await response.json();

      if (resData.success && resData.admin) {
        localStorage.setItem("officerToken", resData.token);
        localStorage.setItem("officerUser", JSON.stringify(resData.admin));
        
        window.location.href = "/admin/dashboard"; 
        return; 
      }

      setError("Invalid official email or password.");
      
    } catch {
      setError("Could not connect to server. Please check your connection.");
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: '#f4f4f4' }}>
      {/* Left Column: Form */}
      <div style={{ 
        flex: '1 1 50%', 
        display: 'flex', 
        flexDirection: 'column', 
        justifyContent: 'center', 
        alignItems: 'center',
        padding: '2rem'
      }}>
        <div style={{ width: '100%', maxWidth: '400px' }}>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2.5rem' }}>
            <div style={{ 
              display: 'flex', 
              height: '40px', 
              width: '40px', 
              alignItems: 'center', 
              justifyContent: 'center', 
              borderRadius: '50%', 
              border: '2px solid #161616', 
              fontWeight: 'bold',
              fontSize: '13px' 
            }}>
              GSN
            </div>
            <div>
              <p style={{ fontWeight: 600, fontSize: '16px', margin: 0 }}>Government Service Navigator</p>
              <p style={{ fontSize: '12px', textTransform: 'uppercase', color: '#525252', margin: 0 }}>Officer Portal</p>
            </div>
          </div>

          <div style={{ marginBottom: '2rem' }}>
            <p style={{ fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.14em', color: '#525252', marginBottom: '0.5rem' }}>
              Restricted Access
            </p>
            <h1 style={{ fontSize: '2rem', fontWeight: 400, margin: '0 0 0.5rem 0', color: '#161616' }}>
              Sign in to the Registry
            </h1>
            <p style={{ fontSize: '14px', color: '#525252' }}>
              For Verifying Officers, Department Admins, and System Admins only.
            </p>
          </div>

          <form onSubmit={handleSubmit}>
            <Stack gap={6}>
              <TextInput
                id="email"
                type="email"
                labelText="Official Email"
                placeholder="official@gov.lk"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={isLoading}
              />

              <PasswordInput
                id="password"
                labelText="Password"
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={isLoading}
              />

              {error && (
                <InlineNotification
                  kind="error"
                  title="Error:"
                  subtitle={error}
                  lowContrast
                  hideCloseButton
                  style={{ marginBottom: 0 }}
                />
              )}

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '0.5rem' }}>
                <Checkbox 
                  id="keep-signed-in" 
                  labelText="Keep me signed in" 
                />
                <Link href="#" size="sm">
                  Forgot password?
                </Link>
              </div>

              <Button 
                type="submit" 
                disabled={isLoading} 
                style={{ width: '100%', marginTop: '1rem' }}
              >
                {isLoading ? "Verifying…" : "Sign In"}
              </Button>
            </Stack>
          </form>

          <p style={{ fontSize: '12px', lineHeight: 1.5, color: '#525252', marginTop: '3rem' }}>
            Access to this portal is logged and restricted to authorized government personnel. 
            Unauthorized use is a violation of the Computer Crimes Act.
          </p>
        </div>
      </div>

      {/* Right Column: Decorative Banner */}
      <div style={{ 
        flex: '1 1 50%', 
        backgroundColor: '#161616', 
        color: '#f4f4f4', 
        display: 'flex', 
        flexDirection: 'column',
        justifyContent: 'center', 
        alignItems: 'center',
        padding: '3rem',
        position: 'relative',
        overflow: 'hidden'
      }}>
        {/* Subtle grid pattern background */}
        <div style={{
          position: 'absolute',
          inset: 0,
          opacity: 0.05,
          backgroundImage: "repeating-linear-gradient(0deg, transparent, transparent 39px, #ffffff 40px), repeating-linear-gradient(90deg, transparent, transparent 39px, #ffffff 40px)"
        }} />
        
        <div style={{ maxWidth: '400px', textAlign: 'center', zIndex: 1 }}>
          <div style={{ 
            display: 'flex', 
            height: '96px', 
            width: '96px', 
            alignItems: 'center', 
            justifyContent: 'center', 
            borderRadius: '50%', 
            border: '3px solid rgba(244,244,244,0.7)',
            margin: '0 auto 2rem auto'
          }}>
            <div style={{ 
              display: 'flex', 
              height: '64px', 
              width: '64px', 
              alignItems: 'center', 
              justifyContent: 'center', 
              borderRadius: '50%', 
              border: '1px solid rgba(244,244,244,0.4)' 
            }}>
              <span style={{ fontSize: '16px', fontWeight: 600, letterSpacing: '0.05em' }}>GSN</span>
            </div>
          </div>
          
          <h2 style={{ fontSize: '24px', fontWeight: 400, lineHeight: 1.4, marginBottom: '1rem' }}>
            Every application, reviewed with the same care as the citizen who submitted it.
          </h2>
          <p style={{ fontSize: '14px', lineHeight: 1.6, color: '#c6c6c6' }}>
            The Registry gives verifying officers a single, auditable queue — every decision timestamped, every reviewer accountable.
          </p>
        </div>
      </div>
    </div>
  );
}