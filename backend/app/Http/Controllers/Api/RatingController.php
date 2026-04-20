<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Rating;
use App\Models\Restaurant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RatingController extends Controller
{
    /**
     * Soumettre un avis pour une commande.
     * POST /restaurants/{restaurant}/orders/{order}/rate
     */
    public function store(Request $request, Restaurant $restaurant, Order $order): JsonResponse
    {
        // Vérifier que la commande appartient au restaurant
        if ($order->restaurant_id !== $restaurant->id) {
            return response()->json(['success' => false, 'message' => 'Commande introuvable'], 404);
        }

        // Vérifier que la commande est terminée
        if (!in_array($order->status, ['delivered', 'completed'])) {
            return response()->json([
                'success' => false,
                'message' => 'Seule une commande livrée ou terminée peut être notée',
            ], 422);
        }

        // Vérifier qu'il n'y a pas déjà un avis
        if (Rating::where('order_id', $order->id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande a déjà été notée',
            ], 409);
        }

        $validator = Validator::make($request->all(), [
            'stars' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Données invalides',
                'errors' => $validator->errors(),
            ], 422);
        }

        $rating = Rating::create([
            'order_id' => $order->id,
            'restaurant_id' => $restaurant->id,
            'user_id' => $request->user()?->id,
            'stars' => $request->stars,
            'comment' => $request->comment,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Merci pour votre avis !',
            'data' => $rating,
        ], 201);
    }

    /**
     * Lister les avis d'un restaurant.
     * GET /restaurants/{restaurant}/ratings
     */
    public function index(Request $request, Restaurant $restaurant): JsonResponse
    {
        $ratings = $restaurant->ratings()
            ->with('user:id,name')
            ->latest()
            ->paginate($request->get('per_page', 20));

        $avg = $restaurant->ratings()->avg('stars');

        return response()->json([
            'success' => true,
            'data' => $ratings,
            'meta' => [
                'average' => round($avg ?? 0, 1),
                'total' => $restaurant->ratings()->count(),
            ],
        ]);
    }
}
