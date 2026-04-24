import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import NotificationCenter from '../NotificationCenter';
import NotificationToastContainer from '../NotificationToast';

export default function DashboardLayout() {
  return (
    <div className="flex min-h-screen dashboard-surface">
      <Sidebar />
      {/* Main content */}
      <main className="flex-1 lg:ml-[260px] min-h-screen flex flex-col">
        <div className="sticky top-0 z-30 h-16 shrink-0 topbar-glass">
          <div className="h-full px-5 lg:px-8 flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em]" style={{ color: '#94a3b8' }}>
                Noogo Control Center
              </p>
              <p className="text-sm font-semibold" style={{ color: '#0f172a' }}>
                Dashboard
              </p>
            </div>
            <NotificationCenter />
          </div>
        </div>

        <div className="flex-1 p-4 lg:p-8 max-w-screen-2xl animate-fadeIn">
          <Outlet />
        </div>
      </main>

      {/* Toast overlay */}
      <NotificationToastContainer />
    </div>
  );
}
