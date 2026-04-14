import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { QRCodeCanvas } from 'qrcode.react';
import {
  Plus,
  Search,
  MapPin,
  Phone,
  Clock,
  MoreVertical,
  Eye,
  Pencil,
  Trash2,
  Power,
  QrCode,
} from 'lucide-react';
import { restaurantsApi } from '../../services/api';
import type { Restaurant } from '../../types';

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchRestaurants();
  }, []);

  const fetchRestaurants = async () => {
    try {
      const response = await restaurantsApi.getAll();
      setRestaurants(response.data.data.data || response.data.data);
    } catch (error) {
      console.error('Error fetching restaurants:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleToggleActive = async (id: number) => {
    try {
      await restaurantsApi.toggleActive(id);
      fetchRestaurants();
    } catch (error) {
      console.error('Error toggling restaurant:', error);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer ce restaurant ?')) return;
    try {
      await restaurantsApi.delete(id);
      fetchRestaurants();
    } catch (error) {
      console.error('Error deleting restaurant:', error);
    }
  };

  const filteredRestaurants = restaurants.filter(r =>
    r.nom.toLowerCase().includes(search.toLowerCase()) ||
    r.adresse.toLowerCase().includes(search.toLowerCase())
  );

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Restaurants</h1>
          <p className="text-gray-600">Gérez vos restaurants</p>
        </div>
        <Link
          to="/restaurants/new"
          className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-colors"
        >
          <Plus className="h-5 w-5" />
          Nouveau Restaurant
        </Link>
      </div>

      {/* Search */}
      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Rechercher un restaurant..."
          className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
        />
      </div>

      {/* Grid */}
      {filteredRestaurants.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredRestaurants.map((restaurant) => (
            <RestaurantCard
              key={restaurant.id}
              restaurant={restaurant}
              onToggleActive={handleToggleActive}
              onDelete={handleDelete}
            />
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 rounded-full flex items-center justify-center">
            <MapPin className="h-8 w-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">Aucun restaurant</h3>
          <p className="text-gray-500 mb-4">Commencez par ajouter votre premier restaurant</p>
          <Link
            to="/restaurants/new"
            className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600"
          >
            <Plus className="h-5 w-5" />
            Ajouter un restaurant
          </Link>
        </div>
      )}
    </div>
  );
}

interface RestaurantCardProps {
  restaurant: Restaurant;
  onToggleActive: (id: number) => void;
  onDelete: (id: number) => void;
}

function RestaurantCard({ restaurant, onToggleActive, onDelete }: RestaurantCardProps) {
  const [showMenu, setShowMenu] = useState(false);
  const [showQrModal, setShowQrModal] = useState(false);
  const qrCanvasRef = useRef<HTMLCanvasElement>(null);

  const qrValue = `${import.meta.env.VITE_APP_URL || window.location.origin}/restaurant/${restaurant.id}`;

  const handleShowQr = () => {
    setShowQrModal(true);
    setShowMenu(false);
  };

  const handleDownloadQr = () => {
    const canvas = qrCanvasRef.current;
    if (!canvas) return;
    const link = document.createElement('a');
    link.download = `qr-${restaurant.nom.replace(/[^a-z0-9]/gi, '-')}.png`;
    link.href = canvas.toDataURL('image/png');
    link.click();
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden hover:shadow-lg transition-shadow">
      {/* Image */}
      <div className="relative h-40 bg-gray-100">
        {restaurant.logo_url ? (
          <img
            src={restaurant.logo_url}
            alt={restaurant.nom}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <span className="text-4xl font-bold text-gray-300">
              {restaurant.nom.charAt(0)}
            </span>
          </div>
        )}
        <div className={`absolute top-3 right-3 px-2 py-1 rounded-full text-xs font-medium ${restaurant.is_active
          ? 'bg-green-100 text-green-700'
          : 'bg-gray-100 text-gray-700'
          }`}>
          {restaurant.is_active ? 'Actif' : 'Inactif'}
        </div>
      </div>

      {/* Content */}
      <div className="p-4">
        <div className="flex items-start justify-between mb-3">
          <div>
            <h3 className="font-semibold text-gray-900">{restaurant.nom}</h3>
            <div className="flex items-center gap-1 text-sm text-gray-500 mt-1">
              <MapPin className="h-4 w-4" />
              <span className="truncate">{restaurant.adresse}</span>
            </div>
          </div>

          {/* Menu */}
          <div className="relative">
            <button
              onClick={() => setShowMenu(!showMenu)}
              className="p-1 hover:bg-gray-100 rounded"
            >
              <MoreVertical className="h-5 w-5 text-gray-400" />
            </button>
            {showMenu && (
              <>
                <div
                  className="fixed inset-0 z-10"
                  onClick={() => setShowMenu(false)}
                />
                <div className="absolute right-0 mt-1 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-1 z-20">
                  <Link
                    to={`/restaurants/${restaurant.id}`}
                    className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  >
                    <Eye className="h-4 w-4" />
                    Voir détails
                  </Link>
                  <Link
                    to={`/restaurants/${restaurant.id}/edit`}
                    className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  >
                    <Pencil className="h-4 w-4" />
                    Modifier
                  </Link>
                  <button
                    onClick={() => { onToggleActive(restaurant.id); setShowMenu(false); }}
                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  >
                    <Power className="h-4 w-4" />
                    {restaurant.is_active ? 'Désactiver' : 'Activer'}
                  </button>
                  <button
                    onClick={handleShowQr}
                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  >
                    <QrCode className="h-4 w-4" />
                    Voir QR Code
                  </button>
                  <button
                    onClick={() => { onDelete(restaurant.id); setShowMenu(false); }}
                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                  >
                    <Trash2 className="h-4 w-4" />
                    Supprimer
                  </button>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Info */}
        <div className="flex items-center gap-4 text-sm text-gray-500">
          <div className="flex items-center gap-1">
            <Phone className="h-4 w-4" />
            <span>{restaurant.telephone}</span>
          </div>
          {restaurant.heures_ouverture && (
            <div className="flex items-center gap-1">
              <Clock className="h-4 w-4" />
              <span>{restaurant.is_open ? 'Ouvert' : 'Fermé'}</span>
            </div>
          )}
        </div>

        {/* Stats */}
        <div className="flex items-center gap-4 mt-4 pt-4 border-t border-gray-100 text-sm">
          <div className="text-center">
            <p className="font-semibold text-gray-900">{restaurant.categories_count || 0}</p>
            <p className="text-gray-500">Catégories</p>
          </div>
          <div className="text-center">
            <p className="font-semibold text-gray-900">{restaurant.dishes_count || 0}</p>
            <p className="text-gray-500">Plats</p>
          </div>
          <div className="text-center">
            <p className="font-semibold text-gray-900">{restaurant.orders_count || 0}</p>
            <p className="text-gray-500">Commandes</p>
          </div>
          <div className="ml-auto">
            <button
              onClick={handleShowQr}
              title="Voir QR Code"
              className="inline-flex items-center gap-1 px-3 py-1.5 bg-gray-100 text-gray-600 rounded-lg text-xs hover:bg-orange-50 hover:text-orange-600"
            >
              <QrCode className="h-4 w-4" />
              QR Code
            </button>
          </div>
        </div>
      </div>

      {/* QR Code Modal */}
      {showQrModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setShowQrModal(false)}>
          <div className="bg-white rounded-xl p-6 text-center shadow-xl max-w-sm w-full" onClick={e => e.stopPropagation()}>
            <h3 className="text-lg font-semibold mb-2">QR Code — {restaurant.nom}</h3>
            <p className="text-sm text-gray-500 mb-4">Affichez ce QR code sur les tables pour permettre aux clients de commander</p>
            <div className="flex justify-center mb-4">
              <div className="border-2 border-gray-200 rounded-lg p-3 bg-white">
                <QRCodeCanvas
                  ref={qrCanvasRef}
                  value={qrValue}
                  size={192}
                  level="H"
                  includeMargin={false}
                />
              </div>
            </div>
            <div className="flex flex-col gap-2">
              <button
                onClick={handleDownloadQr}
                className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 text-sm"
              >
                Télécharger PNG
              </button>
            </div>
            <button onClick={() => setShowQrModal(false)} className="mt-2 block w-full px-4 py-2 text-gray-500 text-sm">Fermer</button>
          </div>
        </div>
      )}
    </div>
  );
}
