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

        // Vérifier que l'utilisateur est lié à un livreur actif
        $hasDriverRecord = DeliveryDriver::where('user_id', $user->id)
            ->whereIn('status', ['available', 'busy'])
            ->exists();

        if (!$hasDriverRecord) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé : vous n\'êtes pas enregistré comme livreur.',
            ], 403);
        }

        return $next($request);
    }
}
