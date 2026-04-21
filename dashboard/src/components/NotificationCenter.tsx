import { useState, useRef, useEffect } from 'react';
import { Bell, ShoppingBag, RefreshCw, Check, Trash2, ExternalLink } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useNotifications, type AppNotification } from '../context/NotificationContext';

// ── Helpers ──────────────────────────────────────────────────────────────────

const STATUS_COLORS: Record<string, string> = {
    pending: '#ca8a04',
    confirmed: '#2563eb',
    preparing: '#7c3aed',
    ready: '#16a34a',
    delivered: '#0891b2',
    completed: '#475569',
    cancelled: '#dc2626',
};

function timeAgo(date: Date): string {
    const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
    if (seconds < 60) return 'À l\'instant';
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `Il y a ${minutes} min`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `Il y a ${hours}h`;
    return `Il y a ${Math.floor(hours / 24)}j`;
}

// ── Notification item ────────────────────────────────────────────────────────

function NotifItem({ notif, onClose }: { notif: AppNotification; onClose: () => void }) {
    const { markAsRead } = useNotifications();
    const navigate = useNavigate();
    const isNew = notif.type === 'order_created';
    const statusColor = STATUS_COLORS[notif.orderStatus] ?? '#475569';

    const handleClick = () => {
        markAsRead(notif.id);
        navigate(`/orders?restaurantId=${notif.restaurantId}`);
        onClose();
    };

    return (
        <div
            className="flex items-start gap-3 px-4 py-3 cursor-pointer transition-colors"
            style={{ background: notif.isRead ? 'transparent' : '#fff7ed' }}
            onMouseEnter={e => { (e.currentTarget as HTMLDivElement).style.background = '#f8fafc'; }}
            onMouseLeave={e => { (e.currentTarget as HTMLDivElement).style.background = notif.isRead ? 'transparent' : '#fff7ed'; }}
            onClick={handleClick}
        >
            {/* Icon */}
            <div
                className="shrink-0 w-8 h-8 rounded-xl flex items-center justify-center mt-0.5"
                style={{
                    background: isNew ? '#fff7ed' : '#f8fafc',
                    border: `1px solid ${isNew ? '#fed7aa' : '#f1f5f9'}`,
                }}
            >
                {isNew
                    ? <ShoppingBag className="h-4 w-4" style={{ color: '#f97316' }} />
                    : <RefreshCw className="h-3.5 w-3.5" style={{ color: statusColor }} />
                }
            </div>

            {/* Text */}
            <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-2">
                    <p className="text-sm font-medium leading-snug" style={{ color: '#0f172a' }}>
                        {notif.message}
                    </p>
                    {!notif.isRead && (
                        <span
                            className="shrink-0 w-2 h-2 rounded-full mt-1.5"
                            style={{ background: '#f97316' }}
                        />
                    )}
                </div>
                <p className="text-xs mt-0.5" style={{ color: '#94a3b8' }}>
                    {notif.restaurantName}
                    {notif.amount > 0 && ` · ${notif.amount.toLocaleString()} FCFA`}
                    {' · '}{timeAgo(notif.createdAt)}
                </p>
            </div>
        </div>
    );
}

// ── Main component ───────────────────────────────────────────────────────────

export default function NotificationCenter() {
    const [isOpen, setIsOpen] = useState(false);
    const { notifications, unreadCount, markAllAsRead, clearAll } = useNotifications();
    const panelRef = useRef<HTMLDivElement>(null);
    const navigate = useNavigate();

    // Close panel on outside click
    useEffect(() => {
        const handleOutsideClick = (e: MouseEvent) => {
            if (panelRef.current && !panelRef.current.contains(e.target as Node)) {
                setIsOpen(false);
            }
        };
        if (isOpen) document.addEventListener('mousedown', handleOutsideClick);
        return () => document.removeEventListener('mousedown', handleOutsideClick);
    }, [isOpen]);

    // Close on Escape
    useEffect(() => {
        const handleEsc = (e: KeyboardEvent) => { if (e.key === 'Escape') setIsOpen(false); };
        if (isOpen) document.addEventListener('keydown', handleEsc);
        return () => document.removeEventListener('keydown', handleEsc);
    }, [isOpen]);

    return (
        <div className="relative" ref={panelRef}>
            {/* Bell button */}
            <button
                onClick={() => setIsOpen(v => !v)}
                className="relative p-2 rounded-xl transition-colors"
                style={{ color: '#64748b' }}
                title="Notifications"
                onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#e2e8f0'; }}
                onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}
            >
                <Bell className="h-5 w-5" />
                {unreadCount > 0 && (
                    <span
                        className="badge-pulse absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] px-1 rounded-full text-[10px] font-bold flex items-center justify-center"
                        style={{ background: '#ef4444', color: 'white' }}
                    >
                        {unreadCount > 99 ? '99+' : unreadCount}
                    </span>
                )}
            </button>

            {/* Dropdown panel */}
            {isOpen && (
                <div
                    className="absolute right-0 top-full mt-2 w-80 rounded-2xl overflow-hidden z-50 animate-fadeIn"
                    style={{
                        background: 'white',
                        boxShadow: '0 16px 48px rgba(0,0,0,0.13)',
                        border: '1px solid #f1f5f9',
                    }}
                >
                    {/* Header */}
                    <div
                        className="flex items-center justify-between px-4 py-3"
                        style={{ borderBottom: '1px solid #f1f5f9' }}
                    >
                        <div className="flex items-center gap-2">
                            <Bell className="h-4 w-4" style={{ color: '#f97316' }} />
                            <span className="font-semibold text-sm" style={{ color: '#0f172a' }}>
                                Notifications
                            </span>
                            {unreadCount > 0 && (
                                <span
                                    className="text-xs px-1.5 py-0.5 rounded-full font-semibold"
                                    style={{ background: '#fff7ed', color: '#f97316', border: '1px solid #fed7aa' }}
                                >
                                    {unreadCount} nouv.
                                </span>
                            )}
                        </div>

                        <div className="flex items-center gap-1">
                            {unreadCount > 0 && (
                                <button
                                    onClick={markAllAsRead}
                                    className="p-1.5 rounded-lg transition-colors"
                                    title="Tout marquer comme lu"
                                    style={{ color: '#94a3b8' }}
                                    onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#f0fdf4'; (e.currentTarget as HTMLButtonElement).style.color = '#16a34a'; }}
                                    onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}
                                >
                                    <Check size={14} />
                                </button>
                            )}
                            {notifications.length > 0 && (
                                <button
                                    onClick={clearAll}
                                    className="p-1.5 rounded-lg transition-colors"
                                    title="Tout effacer"
                                    style={{ color: '#94a3b8' }}
                                    onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fef2f2'; (e.currentTarget as HTMLButtonElement).style.color = '#dc2626'; }}
                                    onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}
                                >
                                    <Trash2 size={14} />
                                </button>
                            )}
                        </div>
                    </div>

                    {/* List */}
                    <div className="max-h-[360px] overflow-y-auto">
                        {notifications.length === 0 ? (
                            <div className="flex flex-col items-center py-10 px-4">
                                <div
                                    className="w-12 h-12 rounded-2xl flex items-center justify-center mb-3"
                                    style={{ background: '#f8fafc' }}
                                >
                                    <Bell className="h-6 w-6" style={{ color: '#cbd5e1' }} />
                                </div>
                                <p className="text-sm font-medium" style={{ color: '#374151' }}>
                                    Aucune notification
                                </p>
                                <p className="text-xs mt-0.5 text-center" style={{ color: '#94a3b8' }}>
                                    Les nouvelles commandes apparaîtront ici en temps réel
                                </p>
                            </div>
                        ) : (
                            <div className="divide-y" style={{ borderColor: '#f8fafc' }}>
                                {notifications.map(n => (
                                    <NotifItem key={n.id} notif={n} onClose={() => setIsOpen(false)} />
                                ))}
                            </div>
                        )}
                    </div>

                    {/* Footer — link to orders */}
                    {notifications.length > 0 && (
                        <div style={{ borderTop: '1px solid #f1f5f9' }}>
                            <button
                                onClick={() => { navigate('/orders'); setIsOpen(false); }}
                                className="w-full flex items-center justify-center gap-1.5 py-3 text-xs font-semibold transition-colors"
                                style={{ color: '#f97316' }}
                                onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fff7ed'; }}
                                onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}
                            >
                                <ExternalLink size={12} />
                                Voir toutes les commandes
                            </button>
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}
