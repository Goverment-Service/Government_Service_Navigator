import { useState, useEffect } from "react";
import { 
  LayoutDashboard, 
  Users, 
  FileText, 
  Settings, 
  LogOut, 
  Bell, 
  Search, 
  ShieldCheck,
  TrendingUp,
  Activity 
} from "lucide-react";

export default function AdminDashboard() {
  const [adminName, setAdminName] = useState("System Admin");

  useEffect(() => {
    const storedUser = localStorage.getItem("officerUser");
    if (storedUser) {
      try {
        const parsedUser = JSON.parse(storedUser);
        // eslint-disable-next-line react-hooks/set-state-in-effect
        if (parsedUser.fullName) setAdminName(parsedUser.fullName);
      } catch {
        // ignore parse error
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
              Registry Admin
            </h2>
            <p className="text-[10px] uppercase tracking-wider text-white/50">
              System Control
            </p>
          </div>
        </div>

        <nav className="flex-1 space-y-1.5 px-4 py-6">
          <NavItem icon={<LayoutDashboard size={18} />} label="Overview" active />
          <NavItem icon={<Users size={18} />} label="Manage Officers" />
          <NavItem icon={<ShieldCheck size={18} />} label="Audit Logs" />
          <NavItem icon={<Settings size={18} />} label="System Settings" /> 
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
              Welcome back, {adminName}
            </h1>
            <p className="mt-1 text-[13.5px] text-[#13233D]/60">
              Monitor system activity and manage registry officers across the platform.
            </p>
          </div>

          <div className="flex items-center gap-4">
            <div className="relative flex items-center">
              <Search className="absolute left-3 text-[#13233D]/40" size={16} />
              <input 
                type="text" 
                placeholder="Search records..." 
                className="h-10 w-64 rounded-full border border-[#13233D]/10 bg-white/60 pl-10 pr-4 text-[13px] backdrop-blur-md focus:border-[#13233D]/30 focus:outline-none focus:ring-2 focus:ring-[#13233D]/10"
              />
            </div>
            <button className="relative flex h-10 w-10 items-center justify-center rounded-full border border-[#13233D]/10 bg-white/60 text-[#13233D]/70 shadow-sm backdrop-blur-md transition-all hover:bg-white">
              <Bell size={18} />
              <span className="absolute right-2.5 top-2.5 h-2 w-2 rounded-full bg-[#A8352A]"></span>
            </button>
          </div>
        </header>

        <div className="mb-10 grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-4">
          <StatCard 
            title="Total Applications" 
            value="12,845" 
            trend="+14%" 
            icon={<FileText size={20} />} 
          />
          <StatCard 
            title="Active Officers" 
            value="342" 
            trend="+2%" 
            icon={<Users size={20} />} 
          />
          <StatCard 
            title="Pending Reviews" 
            value="1,204" 
            trend="-5%" 
            icon={<Activity size={20} />} 
            alert
          />
          <StatCard 
            title="System Health" 
            value="99.9%" 
            trend="Stable" 
            icon={<ShieldCheck size={20} />} 
          />
        </div>

        <section className="overflow-hidden rounded-2xl border border-[#13233D]/10 bg-white/60 shadow-sm backdrop-blur-xl">
          <div className="border-b border-[#13233D]/10 px-6 py-5">
            <h3 className="font-['Source_Serif_4',serif] text-[18px] font-semibold text-[#13233D]">
              Recent Officer Activity
            </h3>
            <p className="text-[12.5px] text-[#13233D]/50">
              Live audit trail of registry modifications and approvals.
            </p>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-left text-[13px]">
              <thead className="bg-[#13233D]/[0.02] text-[11px] uppercase tracking-wider text-[#13233D]/50">
                <tr>
                  <th className="px-6 py-4 font-medium">Officer</th>
                  <th className="px-6 py-4 font-medium">Action</th>
                  <th className="px-6 py-4 font-medium">Target ID</th>
                  <th className="px-6 py-4 font-medium">Timestamp</th>
                  <th className="px-6 py-4 font-medium">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#13233D]/5">
                <TableRow 
                  officer="Sarah Fernando" 
                  action="Approved Application" 
                  target="APP-8992" 
                  time="2 mins ago" 
                  status="Success" 
                />
                <TableRow 
                  officer="Nuwan Perera" 
                  action="Rejected Document" 
                  target="DOC-1029" 
                  time="15 mins ago" 
                  status="Flagged" 
                />
                <TableRow 
                  officer="System Auto-Sync" 
                  action="Database Backup" 
                  target="SYS-DB-01" 
                  time="1 hour ago" 
                  status="Success" 
                />
              </tbody>
            </table>
          </div>
        </section>

      </main>
    </div>
  );
}


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

function StatCard({ title, value, trend, icon, alert = false }: { title: string, value: string, trend: string, icon: React.ReactNode, alert?: boolean }) {
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
      <div className="mt-4 flex items-center gap-1.5 text-[12px] font-medium">
        <TrendingUp size={14} className={alert ? 'text-[#A8352A]' : 'text-green-600'} />
        <span className={alert ? 'text-[#A8352A]' : 'text-green-600'}>{trend}</span>
        <span className="text-[#13233D]/40">vs last week</span>
      </div>
    </div>
  );
}

function TableRow({ officer, action, target, time, status }: { officer: string, action: string, target: string, time: string, status: string }) {
  const isFlagged = status === "Flagged";
  return (
    <tr className="transition-colors hover:bg-white/40">
      <td className="px-6 py-4 font-medium text-[#13233D]">{officer}</td>
      <td className="px-6 py-4 text-[#13233D]/70">{action}</td>
      <td className="px-6 py-4 font-mono text-[11.5px] text-[#13233D]/60">{target}</td>
      <td className="px-6 py-4 text-[#13233D]/60">{time}</td>
      <td className="px-6 py-4">
        <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide ${
          isFlagged 
            ? "bg-[#A8352A]/10 text-[#A8352A]" 
            : "bg-green-500/10 text-green-700"
        }`}>
          {status}
        </span>
      </td>
    </tr>
  );
}