<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Gestion du token FCM des appareils.
 *
 * POST /api/auth/device-token  — enregistre ou met à jour le token FCM
 * DELETE /api/auth/device-token — efface le token (déconnexion)
 */
class DeviceTokenController extends Controller
{
    /**
     * Enregistre ou met à jour le FCM token de l'utilisateur connecté.
     * Pour les clients non-connectés (guest), on ne stocke pas de token.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'fcm_token' => 'required|string|max:500',
        ]);

        $request->user()->update([
            'fcm_token' => $request->fcm_token,
        ]);

        return response()->json(['success' => true, 'message' => 'Token enregistré']);
    }

    /**
     * Efface le FCM token lors de la déconnexion.
     */
    public function destroy(Request $request): JsonResponse
    {
        $request->user()->update(['fcm_token' => null]);

        return response()->json(['success' => true, 'message' => 'Token supprimé']);
    }
}
