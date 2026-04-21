import { useEffect, useRef, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { QRCodeCanvas } from 'qrcode.react';
import {
    ArrowLeft,
    MapPin,
    Phone,
    Mail,
    Pencil,
    ShoppingBag,
    UtensilsCrossed,
    TrendingUp,
    Clock,
    Tag,
    Power,
    Download,
    Printer,
    Image,
    Users,
    ChefHat,
} from 'lucide-react';
import { restaurantsApi } from '../../services/api';
import type { Restaurant } from '../../types';

interface RestaurantStats {
    total_orders: number;
    orders_today: number;
    pending_orders: number;
    total_revenue: number;
    revenue_today: number;
    total_dishes: number;
    available_dishes: number;
    total_categories: number;
    active_promotions: number;
}

function buildImageUrl(path?: string | null): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = (import.meta.env.VITE_IMAGE_BASE_URL || '').replace(/\/$/, '');
    const clean = path.replace(/^\//, '');
    return `${base}/storage/${clean}`;
}

function StatCard({ icon, label, value }: { icon: React.ReactNode; label: string; value: string | number }) {
    return (
        <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-2 mb-2">
                {icon}
                <span className="text-xs text-gray-500 font-medium">{label}</span>
            </div>
            <p className="text-2xl font-bold text-gray-900">{value}</p>
        </div>
    );
}

export default function RestaurantDetailPage() {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const [restaurant, setRestaurant] = useState<Restaurant | null>(null);
    const [stats, setStats] = useState<RestaurantStats | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const qrCanvasRef = useRef<HTMLCanvasElement>(null);

    useEffect(() => {
        if (!id) return;
        const numId = Number(id);
        setIsLoading(true);
        Promise.all([
            restaurantsApi.getById(numId),
            restaurantsApi.getStatistics(numId),
        ])
            .then(([restaurantRes, statsRes]) => {
                const r: Restaurant = restaurantRes.data.data;
                setRestaurant(r);
                setStats(statsRes.data.data);
            })
            .catch(() => navigate('/restaurants'))
            .finally(() => setIsLoading(false));
    }, [id, navigate]);

    if (isLoading) {
        return (
            <div className="flex items-center justify-center min-h-96">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
            </div>
        );
    }

    if (!restaurant) return null;

    const qrValue = `${import.meta.env.VITE_APP_URL || window.location.origin}/restaurant/${restaurant.id}`;

    const handleDownloadQr = () => {
        const canvas = qrCanvasRef.current;
        if (!canvas) return;
        const link = document.createElement('a');
        link.download = `qrcode-${restaurant.nom.replace(/[^a-z0-9]/gi, '-')}.png`;
        link.href = canvas.toDataURL('image/png');
        link.click();
    };

    const handlePrintQr = () => {
        const canvas = qrCanvasRef.current;
        if (!canvas) return;
        const dataUrl = canvas.toDataURL('image/png');
        const win = window.open('', '_blank');
        if (!win) return;
        win.document.write(`
            <!DOCTYPE html><html><head><title>QR Code - ${restaurant.nom}</title>
            <style>body{display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;font-family:sans-serif;}
            img{width:300px;height:300px;} h2{margin-bottom:16px;} p{color:#666;margin-top:8px;font-size:14px;}
            @media print{button{display:none;}}</style></head>
            <body><h2>${restaurant.nom}</h2>
            <img src="${dataUrl}" alt="QR Code" />
            <p>Scannez pour voir le menu</p>
            <button onclick="window.print()" style="margin-top:24px;padding:8px 20px;cursor:pointer;">Imprimer</button>
            </body></html>`);
        win.document.close();
        win.focus();
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center gap-4">
                <button
                    onClick={() => navigate('/restaurants')}
                    className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                >
                    <ArrowLeft className="h-5 w-5 text-gray-600" />
                </button>
                <div className="flex-1 min-w-0">
                    <h1 className="text-2xl font-bold text-gray-900 truncate">{restaurant.nom}</h1>
                    <div className="flex items-center gap-2 mt-1">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${restaurant.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                            {restaurant.is_active ? 'Actif' : 'Inactif'}
                        </span>
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${restaurant.is_open ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-500'}`}>
                            {restaurant.is_open ? 'Ouvert' : 'Fermé'}
                        </span>
                    </div>
                </div>
                <Link
                    to={`/restaurants/${restaurant.id}/edit`}
                    className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-colors text-sm flex-shrink-0"
                >
                    <Pencil className="h-4 w-4" />
                    Modifier
                </Link>
            </div>

            {/* Stats grid */}
            {stats && (
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <StatCard
                        icon={<ShoppingBag className="h-4 w-4 text-blue-500" />}
                        label="Commandes totales"
                        value={stats.total_orders}
                    />
                    <StatCard
                        icon={<ShoppingBag className="h-4 w-4 text-orange-500" />}
                        label="Aujourd'hui"
                        value={stats.orders_today}
                    />
                    <StatCard
                        icon={<TrendingUp className="h-4 w-4 text-green-500" />}
                        label="Revenu total"
                        value={`${stats.total_revenue.toLocaleString()} F`}
                    />
                    <StatCard
                        icon={<TrendingUp className="h-4 w-4 text-emerald-500" />}
                        label="Revenu aujourd'hui"
                        value={`${stats.revenue_today.toLocaleString()} F`}
                    />
                    <StatCard
                        icon={<UtensilsCrossed className="h-4 w-4 text-purple-500" />}
                        label="Plats disponibles"
                        value={`${stats.available_dishes} / ${stats.total_dishes}`}
                    />
                    <StatCard
                        icon={<Tag className="h-4 w-4 text-pink-500" />}
                        label="Catégories"
                        value={stats.total_categories}
                    />
                    <StatCard
                        icon={<Power className="h-4 w-4 text-yellow-500" />}
                        label="En attente"
                        value={stats.pending_orders}
                    />
                    <StatCard
                        icon={<Tag className="h-4 w-4 text-red-500" />}
                        label="Promotions actives"
                        value={stats.active_promotions}
                    />
                </div>
            )}

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Info */}
                <div className="bg-white rounded-xl border border-gray-200 p-6 space-y-4">
                    <h2 className="text-base font-semibold text-gray-900">Informations</h2>

                    {restaurant.logo_url && (
                        <img
                            src={buildImageUrl(restaurant.logo_url)}
                            alt={restaurant.nom}
                            className="h-24 w-24 rounded-xl object-cover border border-gray-100"
                        />
                    )}

                    {restaurant.description && (
                        <p className="text-sm text-gray-600">{restaurant.description}</p>
                    )}

                    <dl className="space-y-3 text-sm">
                        <div className="flex items-start gap-3">
                            <MapPin className="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0" />
                            <span className="text-gray-700">{restaurant.adresse}</span>
                        </div>
                        <div className="flex items-center gap-3">
                            <Phone className="h-4 w-4 text-gray-400 flex-shrink-0" />
                            <span className="text-gray-700">{restaurant.telephone}</span>
                        </div>
                        {restaurant.email && (
                            <div className="flex items-center gap-3">
                                <Mail className="h-4 w-4 text-gray-400 flex-shrink-0" />
                                <span className="text-gray-700">{restaurant.email}</span>
                            </div>
                        )}
                        {restaurant.heures_ouverture && (
                            <div className="flex items-start gap-3">
                                <Clock className="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0" />
                                <span className="text-gray-700 whitespace-pre-line">{restaurant.heures_ouverture}</span>
                            </div>
                        )}
                    </dl>
                </div>

                {/* Quick actions */}
                <div className="bg-white rounded-xl border border-gray-200 p-6 space-y-3">
                    <h2 className="text-base font-semibold text-gray-900">Accès rapide</h2>

                    <Link
                        to={`/restaurants/${restaurant.id}/orders`}
                        className="flex items-center gap-3 p-3 rounded-lg hover:bg-orange-50 transition-colors group"
                    >
                        <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center group-hover:bg-orange-200 transition-colors">
                            <ShoppingBag className="h-5 w-5 text-orange-600" />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-gray-900">Commandes</p>
                            <p className="text-xs text-gray-500">{stats?.pending_orders ?? 0} en attente</p>
                        </div>
                    </Link>

                    <Link
                        to="/menu"
                        className="flex items-center gap-3 p-3 rounded-lg hover:bg-purple-50 transition-colors group"
                    >
                        <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center group-hover:bg-purple-200 transition-colors">
                            <UtensilsCrossed className="h-5 w-5 text-purple-600" />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-gray-900">Gérer le menu</p>
                            <p className="text-xs text-gray-500">{stats?.total_dishes ?? 0} plats</p>
                        </div>
                    </Link>

                    <Link
                        to={`/restaurants/${restaurant.id}/staff`}
                        className="flex items-center gap-3 p-3 rounded-lg hover:bg-indigo-50 transition-colors group"
                    >
                        <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center group-hover:bg-indigo-200 transition-colors">
                            <Users className="h-5 w-5 text-indigo-600" />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-gray-900">Personnel</p>
                            <p className="text-xs text-gray-500">Gérants, caissiers, serveurs</p>
                        </div>
                    </Link>

                    <Link
                        to={`/restaurants/${restaurant.id}/kitchen`}
                        className="flex items-center gap-3 p-3 rounded-lg hover:bg-amber-50 transition-colors group"
                    >
                        <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center group-hover:bg-amber-200 transition-colors">
                            <ChefHat className="h-5 w-5 text-amber-600" />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-gray-900">KDS Cuisine</p>
                            <p className="text-xs text-gray-500">Vue temps réel — écran cuisine</p>
                        </div>
                    </Link>

                    <Link
                        to={`/restaurants/${restaurant.id}/edit`}
                        className="flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors group"
                    >
                        <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center group-hover:bg-gray-200 transition-colors">
                            <Pencil className="h-5 w-5 text-gray-600" />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-gray-900">Modifier le restaurant</p>
                            <p className="text-xs text-gray-500">Infos, logo, horaires</p>
                        </div>
                    </Link>
                </div>
            </div>

            {/* Galerie photos */}
            {restaurant.images && restaurant.images.length > 0 && (
                <div className="bg-white rounded-xl border border-gray-200 p-6">
                    <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">
                        <Image className="h-4 w-4 text-orange-500" />
                        Galerie photos
                        <span className="ml-2 text-xs font-normal text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">
                            {restaurant.images.length} photo{restaurant.images.length > 1 ? 's' : ''}
                        </span>
                    </h2>
                    <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                        {restaurant.images.map((path, i) => (
                            <div key={i} className="aspect-square rounded-xl overflow-hidden border border-gray-100">
                                <img
                                    src={buildImageUrl(path)}
                                    alt={`Photo ${i + 1}`}
                                    className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                                />
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* QR Code */}
            <div className="bg-white rounded-xl border border-gray-200 p-6">
                <div className="flex items-center justify-between mb-4">
                    <div>
                        <h2 className="text-base font-semibold text-gray-900">QR Code</h2>
                        <p className="text-xs text-gray-500 mt-0.5">Affichez ce QR code dans votre restaurant pour que les clients accèdent au menu</p>
                    </div>
                </div>

                <div className="flex flex-col sm:flex-row items-center gap-6">
                    <div className="flex-shrink-0 border border-gray-200 rounded-xl p-4 bg-white shadow-sm">
                        <QRCodeCanvas
                            ref={qrCanvasRef}
                            value={qrValue}
                            size={192}
                            level="H"
                            includeMargin={false}
                        />
                    </div>
                    <div className="flex flex-col items-start gap-3">
                        <p className="text-sm text-gray-600">
                            Scannez ce QR code pour accéder directement au menu du restaurant depuis un smartphone.
                        </p>
                        <div className="flex flex-wrap gap-2">
                            <button
                                onClick={handleDownloadQr}
                                className="inline-flex items-center gap-2 px-3 py-1.5 border border-gray-200 rounded-lg text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                            >
                                <Download className="h-4 w-4" />
                                Télécharger PNG
                            </button>
                            <button
                                onClick={handlePrintQr}
                                className="inline-flex items-center gap-2 px-3 py-1.5 border border-gray-200 rounded-lg text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                            >
                                <Printer className="h-4 w-4" />
                                Imprimer
                            </button>
                        </div>
                        <p className="text-xs text-gray-400">
                            Format PNG — compatible tous navigateurs et imprimantes
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
}
