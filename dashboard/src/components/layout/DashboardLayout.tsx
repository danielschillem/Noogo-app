import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';

export default function DashboardLayout() {
  return (
    <div className="flex min-h-screen" style={{ background: '#f1f5f9' }}>
      <Sidebar />
      {/* Main content — offset for fixed sidebar on lg */}
      <main className="flex-1 lg:ml-[260px] min-h-screen flex flex-col">
        <div className="flex-1 p-5 lg:p-8 max-w-screen-2xl animate-fadeIn">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
