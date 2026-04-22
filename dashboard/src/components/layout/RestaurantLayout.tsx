import { Outlet, useParams, Navigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import Sidebar from './Sidebar';
import NotificationCenter from '../NotificationCenter';
import NotificationToastContainer from '../NotificationToast';

/**
 * Layout utilisé pour les utilisateurs verrouillés sur un restaurant précis (/r/:restaurantId/*).
 * Vérifie que lockedRestaurantId correspond bien à l'ID dans l'URL.
 */
export default function RestaurantLayout() {
    const { restaurantId } = useParams<{ restaurantId: string }>();
    const { isAuthenticated, isLoading, lockedRestaurantId, user } = useAuth();
    const id = Number(restaurantId);

    if (isLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
            </div>
        );
    }

    if (!isAuthenticated) {
        return <Navigate to={`/r/${id}/login`} replace />;
    }

    // Les admins n'ont pas besoin d'être verrouillés → dashboard normal
    if (user?.is_admin) {
        return <Navigate to="/" replace />;
    }

    // Vérification de sécurité : l'utilisateur est-il verrouillé sur CE restaurant ?
    if (lockedRestaurantId !== id) {
        // Mauvais restaurant → renvoyer vers leur restaurant
        if (lockedRestaurantId) {
            return <Navigate to={`/r/${lockedRestaurantId}/orders`} replace />;
        }
        // Pas de verrou → dashboard normal
        return <Navigate to="/" replace />;
    }

    return (
        <div className="flex min-h-screen" style={{ background: '#f1f5f9' }}>
            <Sidebar restaurantId={id} />
            <main className="flex-1 lg:ml-[260px] min-h-screen flex flex-col">
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
            <NotificationToastContainer />
        </div>
    );
}
