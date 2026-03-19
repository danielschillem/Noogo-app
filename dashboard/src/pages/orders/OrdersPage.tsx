import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { 
  Clock,
  CheckCircle,
  XCircle,
  ChefHat,
  Package,
  Filter
} from 'lucide-react';
import { ordersApi } from '../../services/api';
import type { Order, OrderStatus } from '../../types';

export default function OrdersPage() {
  const { restaurantId } = useParams();
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('all');

  useEffect(() => {
    if (restaurantId) {
      fetchOrders();
    }
  }, [restaurantId, statusFilter]);

  const fetchOrders = async () => {
    if (!restaurantId) return;
    try {
      const params: Record<string, unknown> = {};
      if (statusFilter !== 'all') {
        params.status = statusFilter;
      }
      const response = await ordersApi.getAll(parseInt(restaurantId), params);
      setOrders(response.data.data.data || response.data.data);
    } catch (error) {
      console.error('Error fetching orders:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpdateStatus = async (orderId: number, newStatus: OrderStatus) => {
    if (!restaurantId) return;
    try {
      await ordersApi.updateStatus(parseInt(restaurantId), orderId, newStatus);
      fetchOrders();
    } catch (error) {
      console.error('Error updating order status:', error);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending': return <Clock className="h-5 w-5 text-yellow-500" />;
      case 'confirmed': return <CheckCircle className="h-5 w-5 text-blue-500" />;
      case 'preparing': return <ChefHat className="h-5 w-5 text-purple-500" />;
      case 'ready': return <Package className="h-5 w-5 text-green-500" />;
      case 'delivered':
      case 'completed': return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'cancelled': return <XCircle className="h-5 w-5 text-red-500" />;
      default: return <Clock className="h-5 w-5 text-gray-500" />;
    }
  };

  const statusColors: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
    confirmed: 'bg-blue-100 text-blue-800 border-blue-200',
    preparing: 'bg-purple-100 text-purple-800 border-purple-200',
    ready: 'bg-green-100 text-green-800 border-green-200',
    delivered: 'bg-green-100 text-green-800 border-green-200',
    completed: 'bg-gray-100 text-gray-800 border-gray-200',
    cancelled: 'bg-red-100 text-red-800 border-red-200',
  };

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
          <h1 className="text-2xl font-bold text-gray-900">Commandes</h1>
          <p className="text-gray-600">Gérez les commandes en cours</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2">
        <Filter className="h-5 w-5 text-gray-400 flex-shrink-0" />
        {['all', 'pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled'].map((status) => (
          <button
            key={status}
            onClick={() => setStatusFilter(status)}
            className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors ${
              statusFilter === status
                ? 'bg-orange-500 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {status === 'all' ? 'Toutes' : 
              status === 'pending' ? 'En attente' :
              status === 'confirmed' ? 'Confirmées' :
              status === 'preparing' ? 'En préparation' :
              status === 'ready' ? 'Prêtes' :
              status === 'completed' ? 'Terminées' : 'Annulées'}
          </button>
        ))}
      </div>

      {/* Orders List */}
      {orders.length > 0 ? (
        <div className="space-y-4">
          {orders.map((order) => (
            <div
              key={order.id}
              className="bg-white rounded-xl border border-gray-200 p-6 hover:shadow-md transition-shadow"
            >
              <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                {/* Order Info */}
                <div className="flex items-start gap-4">
                  <div className={`p-3 rounded-lg ${statusColors[order.status]}`}>
                    {getStatusIcon(order.status)}
                  </div>
                  <div>
                    <div className="flex items-center gap-3">
                      <h3 className="font-semibold text-gray-900">Commande #{order.id}</h3>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${statusColors[order.status]}`}>
                        {order.status_text}
                      </span>
                    </div>
                    <p className="text-sm text-gray-500 mt-1">
                      {order.customer_name || 'Client'} • {order.order_type_text}
                      {order.table_number && ` • Table ${order.table_number}`}
                    </p>
                    <p className="text-sm text-gray-400 mt-1">
                      {new Date(order.order_date).toLocaleString('fr-FR')}
                    </p>
                  </div>
                </div>

                {/* Items Summary */}
                <div className="flex-1 lg:px-6">
                  <div className="flex flex-wrap gap-2">
                    {order.items?.slice(0, 3).map((item, index) => (
                      <span key={index} className="px-2 py-1 bg-gray-100 rounded text-sm text-gray-600">
                        {item.quantity}x {item.dish?.nom || 'Plat'}
                      </span>
                    ))}
                    {order.items?.length > 3 && (
                      <span className="px-2 py-1 bg-gray-100 rounded text-sm text-gray-600">
                        +{order.items.length - 3} autres
                      </span>
                    )}
                  </div>
                </div>

                {/* Total & Actions */}
                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <p className="text-lg font-bold text-gray-900">{order.formatted_total}</p>
                    <p className="text-sm text-gray-500">{order.payment_method}</p>
                  </div>

                  {order.status === 'pending' && (
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleUpdateStatus(order.id, 'confirmed')}
                        className="px-3 py-2 bg-green-500 text-white rounded-lg text-sm hover:bg-green-600"
                      >
                        Confirmer
                      </button>
                      <button
                        onClick={() => handleUpdateStatus(order.id, 'cancelled')}
                        className="px-3 py-2 bg-red-500 text-white rounded-lg text-sm hover:bg-red-600"
                      >
                        Annuler
                      </button>
                    </div>
                  )}

                  {order.status === 'confirmed' && (
                    <button
                      onClick={() => handleUpdateStatus(order.id, 'preparing')}
                      className="px-4 py-2 bg-purple-500 text-white rounded-lg text-sm hover:bg-purple-600"
                    >
                      En préparation
                    </button>
                  )}

                  {order.status === 'preparing' && (
                    <button
                      onClick={() => handleUpdateStatus(order.id, 'ready')}
                      className="px-4 py-2 bg-green-500 text-white rounded-lg text-sm hover:bg-green-600"
                    >
                      Prête
                    </button>
                  )}

                  {order.status === 'ready' && (
                    <button
                      onClick={() => handleUpdateStatus(order.id, 'delivered')}
                      className="px-4 py-2 bg-blue-500 text-white rounded-lg text-sm hover:bg-blue-600"
                    >
                      Livrée
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 rounded-full flex items-center justify-center">
            <Package className="h-8 w-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">Aucune commande</h3>
          <p className="text-gray-500">Les commandes apparaîtront ici</p>
        </div>
      )}
    </div>
  );
}
