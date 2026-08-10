import { useState } from "react";
import type { FormEvent } from "react";

export default function OfficerLoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
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
    <div className="flex min-h-screen bg-[#F1EFE8] font-[Inter,sans-serif] text-[#13233D]">
      <div className="flex w-full flex-col justify-center px-8 sm:px-16 lg:w-[440px] lg:flex-none xl:w-[480px]">
        <div className="mb-10 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-full border-2 border-[#13233D] text-[13px] font-bold">
            GSN
          </div>
          <div>
            <p className="font-['Source_Serif_4',serif] text-[15px] font-semibold leading-tight">
              Government Service Navigator
            </p>
            <p className="text-[11px] uppercase tracking-wide text-[#13233D]/50">
              Officer Portal
            </p>
          </div>
        </div>

        <p className="text-[11px] uppercase tracking-[0.14em] text-[#13233D]/45">
          Restricted Access
        </p>
        <h1 className="mt-1 font-['Source_Serif_4',serif] text-[30px] font-semibold leading-tight">
          Sign in to the Registry
        </h1>
        <p className="mt-2 text-[13px] text-[#13233D]/55">
          For Verifying Officers, Department Admins, and System Admins only.
        </p>

        <form onSubmit={handleSubmit} className="mt-8 space-y-5">
          <div>
            <label className="mb-1.5 block text-[12px] font-semibold text-[#13233D]/70">
              Official Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="official@gov.lk"
              className="w-full rounded-md border border-[#13233D]/15 bg-white px-4 py-2.5 text-[13px] placeholder:text-[#13233D]/35 focus:border-[#13233D]/40 focus:outline-none focus:ring-2 focus:ring-[#13233D]/10"
            />
          </div>

          <div>
            <label className="mb-1.5 block text-[12px] font-semibold text-[#13233D]/70">
              Password
            </label>
            <div className="relative">
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                className="w-full rounded-md border border-[#13233D]/15 bg-white px-4 py-2.5 pr-16 text-[13px] placeholder:text-[#13233D]/35 focus:border-[#13233D]/40 focus:outline-none focus:ring-2 focus:ring-[#13233D]/10"
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-[11px] font-semibold text-[#13233D]/50 hover:text-[#13233D]"
              >
                {showPassword ? "Hide" : "Show"}
              </button>
            </div>
          </div>

          {error && (
            <div className="flex items-start gap-2 rounded-md border border-[#A8352A]/25 bg-[#A8352A]/[0.06] px-3.5 py-2.5">
              <span className="mt-0.5 h-1.5 w-1.5 flex-none rounded-full bg-[#A8352A]" />
              <p className="text-[12.5px] text-[#832A21]">{error}</p>
            </div>
          )}

          <div className="flex items-center justify-between text-[12px]">
            <label className="flex items-center gap-2 text-[#13233D]/60">
              <input
                type="checkbox"
                className="h-3.5 w-3.5 rounded border-[#13233D]/30 accent-[#13233D]"
              />
              Keep me signed in
            </label>
            <button
              type="button"
              className="font-medium text-[#13233D]/70 underline decoration-[#13233D]/25 underline-offset-2 hover:text-[#13233D]"
            >
              Forgot password?
            </button>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full rounded-md bg-[#13233D] py-3 text-[13px] font-semibold text-[#F1EFE8] transition-opacity hover:opacity-90 disabled:opacity-50"
          >
            {isLoading ? "Verifying…" : "Sign In"}
          </button>
        </form>

        <p className="mt-8 text-[11.5px] leading-relaxed text-[#13233D]/40">
          Access to this portal is logged and restricted to authorized
          government personnel. Unauthorized use is a violation of the
          Computer Crimes Act.
        </p>
      </div>

      <div className="relative hidden flex-1 items-center justify-center overflow-hidden bg-[#13233D] lg:flex">
        <div
          className="absolute inset-0 opacity-[0.06]"
          style={{
            backgroundImage:
              "repeating-linear-gradient(0deg, transparent, transparent 39px, #F1EFE8 40px), repeating-linear-gradient(90deg, transparent, transparent 39px, #F1EFE8 40px)",
          }}
        />
        <div className="relative flex max-w-md flex-col items-center px-10 text-center">
          <div className="flex h-24 w-24 items-center justify-center rounded-full border-[3px] border-[#F1EFE8]/70">
            <div className="flex h-16 w-16 items-center justify-center rounded-full border border-[#F1EFE8]/40">
              <span className="font-['Source_Serif_4',serif] text-[13px] font-semibold tracking-wide text-[#F1EFE8]/90">
                GSN
              </span>
            </div>
          </div>
          <p className="mt-8 font-['Source_Serif_4',serif] text-[22px] font-semibold leading-snug text-[#F1EFE8]">
            Every application, reviewed with the same care as the citizen
            who submitted it.
          </p>
          <p className="mt-4 text-[13px] leading-relaxed text-[#F1EFE8]/55">
            The Registry gives verifying officers a single, auditable
            queue — every decision timestamped, every reviewer accountable.
          </p>
        </div>
      </div>
    </div>
  );
}