import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import NotificationCenter from '../NotificationCenter';
import NotificationToastContainer from '../NotificationToast';

export default function DashboardLayout() {
  return (
    <div className="flex min-h-screen" style={{ background: '#f1f5f9' }}>
      <Sidebar />
      {/* Main content — offset for fixed sidebar on lg */}
      <main className="flex-1 lg:ml-[260px] min-h-screen flex flex-col">
        {/* Top bar */}
        <div
          className="sticky top-0 z-30 flex items-center justify-end px-5 lg:px-8 h-14 shrink-0"
          style={{ background: '#f1f5f9', borderBottom: '1px solid #e2e8f0' }}
        >
          <NotificationCenter />
        </div>

        <div className="flex-1 p-5 lg:p-8 max-w-screen-2xl animate-fadeIn">
          <Outlet />
        </div>
      </main>

      {/* Toast overlay */}
      <NotificationToastContainer />
    </div>
  );
}
