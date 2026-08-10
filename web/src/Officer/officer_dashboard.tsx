import { useState, useEffect } from "react";
import { 
  LayoutDashboard, 
  FileText, 
  CheckCircle2, 
  Clock, 
  LogOut, 
  Bell, 
  Search, 
  UserCheck,
  AlertCircle
} from "lucide-react";

export default function OfficerDashboard() {
  const [officerName, setOfficerName] = useState("Verifying Officer");

  useEffect(() => {
    // Retrieve the officer details stored during login
    const storedUser = localStorage.getItem("officerUser");
    if (storedUser) {
      try {
        const parsedUser = JSON.parse(storedUser);
        // eslint-disable-next-line react-hooks/set-state-in-effect
        if (parsedUser.fullName) setOfficerName(parsedUser.fullName);
        else if (parsedUser.email) setOfficerName(parsedUser.email.split("@")[0]);
      } catch {
        // Handle parse error silently
      }
    }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("officerToken");
    localStorage.removeItem("officerUser");
    window.location.href = "/officer/login";
  };

  return (
    <div className="flex min-h-screen bg-[#F1EFE8] font-[Inter,sans-serif] text-[#13233D] selection:bg-[#13233D] selection:text-[#F1EFE8]">
      
      {/* Sidebar - Dark Glassmorphism */}
      <aside className="fixed bottom-0 left-0 top-0 z-40 flex w-64 flex-col bg-[#13233D] shadow-2xl transition-transform sm:translate-x-0">
        <div className="flex h-20 items-center justify-center gap-3 border-b border-white/10 px-6">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-[13px] font-bold text-white shadow-inner backdrop-blur-md">
            GSN
          </div>
          <div>
            <h2 className="font-['Source_Serif_4',serif] text-[15px] font-semibold leading-tight text-white">
              Registry Portal
            </h2>
            <p className="text-[10px] uppercase tracking-wider text-white/50">
              Verifying Officer
            </p>
          </div>
        </div>

        <nav className="flex-1 space-y-1.5 px-4 py-6">
          <NavItem icon={<LayoutDashboard size={18} />} label="Application Queue" active />
          <NavItem icon={<FileText size={18} />} label="Verified Records" />
          <NavItem icon={<Clock size={18} />} label="Pending Reviews" />
          <NavItem icon={<UserCheck size={18} />} label="My Profile" />
        </nav>

        <div className="border-t border-white/10 p-4">
          <button 
            onClick={handleLogout}
            className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-[13px] font-medium text-white/70 transition-colors hover:bg-white/5 hover:text-white"
          >
            <LogOut size={18} />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 p-8 sm:ml-64">
        
        {/* Top Header */}
        <header className="mb-10 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="font-['Source_Serif_4',serif] text-[28px] font-bold tracking-tight text-[#13233D]">
              Welcome back, {officerName}
            </h1>
            <p className="mt-1 text-[13.5px] text-[#13233D]/60">
              Review assigned citizen submissions and maintain accountable registry records.
            </p>
          </div>

          <div className="flex items-center gap-4">
            <div className="relative flex items-center">
              <Search className="absolute left-3 text-[#13233D]/40" size={16} />
              <input 
                type="text" 
                placeholder="Search NIC or Application ID..." 
                className="h-10 w-64 rounded-full border border-[#13233D]/10 bg-white/60 pl-10 pr-4 text-[13px] backdrop-blur-md focus:border-[#13233D]/30 focus:outline-none focus:ring-2 focus:ring-[#13233D]/10"
              />
            </div>
            <button className="relative flex h-10 w-10 items-center justify-center rounded-full border border-[#13233D]/10 bg-white/60 text-[#13233D]/70 shadow-sm backdrop-blur-md transition-all hover:bg-white">
              <Bell size={18} />
              <span className="absolute right-2.5 top-2.5 h-2 w-2 rounded-full bg-[#A8352A]"></span>
            </button>
          </div>
        </header>

        {/* Stats Grid - Soft UI / Glass Cards */}
        <div className="mb-10 grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-4">
          <StatCard 
            title="Queue Pending" 
            value="24" 
            subtitle="Requires your review" 
            icon={<Clock size={20} />} 
            alert
          />
          <StatCard 
            title="Reviewed Today" 
            value="18" 
            subtitle="+4 from yesterday" 
            icon={<CheckCircle2 size={20} />} 
          />
          <StatCard 
            title="Approved Total" 
            value="482" 
            subtitle="This month" 
            icon={<FileText size={20} />} 
          />
          <StatCard 
            title="Accuracy Rating" 
            value="99.4%" 
            subtitle="Audit compliant" 
            icon={<UserCheck size={20} />} 
          />
        </div>

        {/* Application Verification Queue Section */}
        <section className="overflow-hidden rounded-2xl border border-[#13233D]/10 bg-white/60 shadow-sm backdrop-blur-xl">
          <div className="border-b border-[#13233D]/10 px-6 py-5 flex items-center justify-between">
            <div>
              <h3 className="font-['Source_Serif_4',serif] text-[18px] font-semibold text-[#13233D]">
                Active Verification Queue
              </h3>
              <p className="text-[12.5px] text-[#13233D]/50">
                Citizen submissions waiting for departmental review and timestamping.
              </p>
            </div>
            <span className="rounded-full bg-[#13233D]/10 px-3 py-1 text-[11px] font-semibold text-[#13233D]">
              24 Pending
            </span>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-left text-[13px]">
              <thead className="bg-[#13233D]/[0.02] text-[11px] uppercase tracking-wider text-[#13233D]/50">
                <tr>
                  <th className="px-6 py-4 font-medium">App ID</th>
                  <th className="px-6 py-4 font-medium">Citizen Name</th>
                  <th className="px-6 py-4 font-medium">Service Type</th>
                  <th className="px-6 py-4 font-medium">Submitted</th>
                  <th className="px-6 py-4 font-medium">Priority</th>
                  <th className="px-6 py-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#13233D]/5">
                <QueueRow 
                  appId="GSN-2026-9012" 
                  citizen="Kasun Bandara" 
                  service="Business Registration" 
                  time="15 mins ago" 
                  priority="High" 
                />
                <QueueRow 
                  appId="GSN-2026-9015" 
                  citizen="Chamari Silva" 
                  service="Residence Certificate" 
                  time="42 mins ago" 
                  priority="Normal" 
                />
                <QueueRow 
                  appId="GSN-2026-9021" 
                  citizen="Amesh Perera" 
                  service="Character Verification" 
                  time="1 hour ago" 
                  priority="Normal" 
                />
              </tbody>
            </table>
          </div>
        </section>

      </main>
    </div>
  );
}

// --- Subcomponents for clean code structure ---

function NavItem({ icon, label, active = false }: { icon: React.ReactNode, label: string, active?: boolean }) {
  return (
    <button 
      className={`flex w-full items-center gap-3 rounded-xl px-4 py-3 text-[13px] font-medium transition-all ${
        active 
          ? "bg-white/10 text-white shadow-inner backdrop-blur-md" 
          : "text-white/50 hover:bg-white/5 hover:text-white"
      }`}
    >
      {icon}
      {label}
    </button>
  );
}

function StatCard({ title, value, subtitle, icon, alert = false }: { title: string, value: string, subtitle: string, icon: React.ReactNode, alert?: boolean }) {
  return (
    <div className="relative overflow-hidden rounded-2xl border border-white bg-white/40 p-6 shadow-[0_8px_30px_rgb(0,0,0,0.04)] backdrop-blur-xl transition-all hover:-translate-y-1 hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)]">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-[12px] font-semibold uppercase tracking-wider text-[#13233D]/50">
            {title}
          </p>
          <h4 className="mt-2 text-3xl font-bold tracking-tight text-[#13233D]">
            {value}
          </h4>
        </div>
        <div className={`flex h-12 w-12 items-center justify-center rounded-full bg-white shadow-sm ${alert ? 'text-[#A8352A]' : 'text-[#13233D]'}`}>
          {icon}
        </div>
      </div>
      <div className="mt-4 flex items-center gap-1.5 text-[12px] font-medium text-[#13233D]/60">
        {alert && <AlertCircle size={14} className="text-[#A8352A]" />}
        <span>{subtitle}</span>
      </div>
    </div>
  );
}

function QueueRow({ appId, citizen, service, time, priority }: { appId: string, citizen: string, service: string, time: string, priority: string }) {
  const isHigh = priority === "High";
  return (
    <tr className="transition-colors hover:bg-white/40">
      <td className="px-6 py-4 font-mono text-[12px] font-semibold text-[#13233D]">{appId}</td>
      <td className="px-6 py-4 font-medium text-[#13233D]">{citizen}</td>
      <td className="px-6 py-4 text-[#13233D]/70">{service}</td>
      <td className="px-6 py-4 text-[#13233D]/60">{time}</td>
      <td className="px-6 py-4">
        <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide ${
          isHigh 
            ? "bg-[#A8352A]/10 text-[#A8352A]" 
            : "bg-blue-500/10 text-blue-700"
        }`}>
          {priority}
        </span>
      </td>
      <td className="px-6 py-4 text-right space-x-2">
        <button 
          onClick={() => alert(`Reviewing application ${appId}`)}
          className="rounded-lg bg-[#13233D] px-3 py-1.5 text-[11.5px] font-semibold text-[#F1EFE8] transition-opacity hover:opacity-90"
        >
          Review
        </button>
      </td>
    </tr>
  );
}