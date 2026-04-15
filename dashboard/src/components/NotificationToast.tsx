import { X, ShoppingBag, RefreshCw } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useNotifications, type AppNotification } from '../context/NotificationContext';

const STATUS_COLORS: Record<string, string> = {
    pending: '#ca8a04',
    confirmed: '#2563eb',
    preparing: '#7c3aed',
    ready: '#16a34a',
    delivered: '#0891b2',
    completed: '#475569',
    cancelled: '#dc2626',
};

function Toast({ notif }: { notif: AppNotification }) {
    const { dismissToast } = useNotifications();
    const navigate = useNavigate();
    const isNew = notif.type === 'order_created';
    const statusColor = STATUS_COLORS[notif.orderStatus] ?? '#475569';

    const handleClick = () => {
        navigate(`/orders?restaurantId=${notif.restaurantId}`);
        dismissToast(notif.id);
    };

    return (
        <div
            className="flex items-start gap-3 w-80 rounded-xl p-4 cursor-pointer animate-slideUp"
            style={{
                background: 'white',
                boxShadow: '0 8px 32px rgba(0,0,0,0.14)',
                border: `1px solid ${isNew ? '#fed7aa' : '#e2e8f0'}`,
            }}
            onClick={handleClick}
        >
            <div
                className="shrink-0 w-9 h-9 rounded-xl flex items-center justify-center"
                style={{ background: isNew ? '#fff7ed' : '#f8fafc' }}
            >
                {isNew
                    ? <ShoppingBag className="h-5 w-5" style={{ color: '#f97316' }} />
                    : <RefreshCw className="h-4 w-4" style={{ color: statusColor }} />
                }
            </div>

            <div className="flex-1 min-w-0">
                <p className="font-semibold text-sm leading-snug" style={{ color: '#0f172a' }}>
                    {notif.message}
                </p>
                <p className="text-xs mt-0.5" style={{ color: '#64748b' }}>
                    {notif.restaurantName}
                    {notif.amount > 0 && ` · ${notif.amount.toLocaleString()} FCFA`}
                </p>
            </div>

            <button
                onClick={e => { e.stopPropagation(); dismissToast(notif.id); }}
                className="shrink-0 p-0.5 rounded-lg transition-colors"
                style={{ color: '#94a3b8' }}
                onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.color = '#374151'; }}
                onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}
            >
                <X size={14} />
            </button>
        </div>
    );
}

export default function NotificationToastContainer() {
    const { toasts } = useNotifications();

    if (toasts.length === 0) return null;

    return (
        <div className="fixed bottom-5 right-5 z-[9999] flex flex-col gap-2 items-end pointer-events-none">
            {toasts.map(n => (
                <div key={n.id} className="pointer-events-auto">
                    <Toast notif={n} />
                </div>
            ))}
        </div>
    );
}
