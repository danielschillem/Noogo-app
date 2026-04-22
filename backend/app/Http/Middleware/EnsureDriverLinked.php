<?php

namespace App\Http\Middleware;

use App\Models\DeliveryDriver;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Vérifie que l'utilisateur authentifié est bien lié à un compte livreur (DeliveryDriver).
 *
 * Appliqué sur les endpoints exclusivement réservés aux livreurs :
 *   - PATCH /deliveries/{delivery}/status
 *   - POST  /deliveries/{delivery}/driver-location
 *
 * Les admins contournent cette vérification (via is_admin).
 */
class EnsureDriverLinked
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Non authentifié.',
            ], 401);
        }

        // Les admins ont accès sans restriction
        if ($user->is_admin) {
            return $next($request);
        }

        // Récupérer le profil livreur lié à cet utilisateur
        $driver = DeliveryDriver::where('user_id', $user->id)->first();

        if (!$driver) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé : vous n\'êtes pas enregistré comme livreur.',
            ], 403);
        }

        // Autoriser si le livreur est en ligne (available/busy) OU s'il a une livraison
        // en cours (assigned/picked_up/on_way) — permet de terminer une livraison même
        // après une perte de connexion qui aurait basculé le statut en offline.
        $isOnline = in_array($driver->status, ['available', 'busy']);
        $hasActiveDelivery = $driver->activeDelivery()->exists();

        if (!$isOnline && !$hasActiveDelivery) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé : vous êtes hors ligne et n\'avez aucune livraison en cours.',
            ], 403);
        }

        return $next($request);
    }
}
