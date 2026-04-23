<?php

namespace App\Http\Controllers\Api;

use App\Events\OrderStatusChanged;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Restaurant;
use App\Models\Dish;
use App\Services\FcmNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    /**
     * Display orders for a restaurant
     */
    public function index(Request $request, Restaurant $restaurant): JsonResponse
    {
        $query = $restaurant->orders()->with(['items.dish:id,nom,prix', 'user:id,name,phone']);

        // Filter by status
        if ($request->has('status')) {
            $query->status($request->status);
        }

        // Filter by date
        if ($request->has('date')) {
            $query->whereDate('order_date', $request->date);
        }

        // Filter by today
        if ($request->boolean('today')) {
            $query->today();
        }

        // Filter by order type
        if ($request->has('order_type')) {
            $query->where('order_type', $request->order_type);
        }

        $orders = $query->latest('order_date')->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $orders
        ]);
    }

    /**
     * Historique des commandes du client connecté
     */
    public function myOrders(Request $request): JsonResponse
    {
        $orders = Order::where('user_id', $request->user()->id)
            ->with(['items.dish:id,nom,prix,image', 'restaurant:id,nom,logo'])
            ->latest('order_date')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $orders,
        ]);
    }

    /**
     * Store a new order
     */
    public function store(Request $request, Restaurant $restaurant): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'customer_name' => 'nullable|string|max:255',
            'customer_phone' => 'nullable|string|max:20',
            'order_type' => 'required|in:sur_place,a_emporter,livraison',
            'table_number' => 'nullable|string|max:10',
            'payment_method' => 'required|string|max:50',
            'mobile_money_provider' => 'nullable|string|max:50',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.dish_id' => 'required|exists:dishes,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.special_instructions' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            DB::beginTransaction();

            // Create order
            $order = Order::create([
                'restaurant_id' => $restaurant->id,
                'user_id' => $request->user()?->id,
                'customer_name' => $request->customer_name,
                'customer_phone' => $request->customer_phone,
                'order_type' => $request->order_type,
                'table_number' => $request->table_number,
                'payment_method' => $request->payment_method,
                'mobile_money_provider' => $request->mobile_money_provider,
                'notes' => $request->notes,
                'status' => 'pending',
            ]);

            // Create order items
            foreach ($request->items as $item) {
                $dish = Dish::findOrFail($item['dish_id']);

                // Verify dish belongs to restaurant
                if ($dish->restaurant_id !== $restaurant->id) {
                    throw new \Exception("Le plat {$dish->nom} n'appartient pas à ce restaurant");
                }

                // Verify dish is available
                if (!$dish->disponibilite) {
                    throw new \Exception("Le plat {$dish->nom} n'est pas disponible");
                }

                OrderItem::create([
                    'order_id' => $order->id,
                    'dish_id' => $dish->id,
                    'quantity' => $item['quantity'],
                    'unit_price' => $dish->prix,
                    'special_instructions' => $item['special_instructions'] ?? null,
                ]);
            }

            // Calculer et sauvegarder le total de la commande
            $order->calculateTotal();

            DB::commit();

            // Broadcast temps réel (D11) — silencieux si Pusher non configuré
            try {
                broadcast(new OrderStatusChanged($order, 'order.created'));
            } catch (\Exception $broadcastEx) {
                \Illuminate\Support\Facades\Log::warning('Broadcast failed: ' . $broadcastEx->getMessage());
            }

            // Notification push FCM au restaurant (owner + topic staff)
            try {
                (new FcmNotificationService())->notifyNewOrder($restaurant, $order);
            } catch (\Exception $fcmEx) {
                \Illuminate\Support\Facades\Log::warning('FCM notifyNewOrder failed: ' . $fcmEx->getMessage());
            }

            return response()->json([
                'success' => true,
                'message' => 'Commande créée avec succès',
                'data' => $order->load(['items.dish:id,nom,prix'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 422);
        }
    }

    /**
     * Display the specified order
     */
    public function show(Restaurant $restaurant, Order $order): JsonResponse
    {
        $order->load(['items.dish:id,nom,prix,images', 'user:id,name,phone,email']);

        return response()->json([
            'success' => true,
            'data' => $order
        ]);
    }

    /**
     * Update order status
     */
    public function updateStatus(Request $request, Restaurant $restaurant, Order $order): JsonResponse
    {
        $this->authorize('manageOrders', $restaurant);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:pending,confirmed,preparing,ready,delivered,completed,cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        // Validation des transitions de statut
        if (!$order->canTransitionTo($request->status)) {
            return response()->json([
                'success' => false,
                'message' => "Transition vers '{$request->status}' non autorisée depuis '{$order->status}'.",
            ], 422);
        }

        $order->updateStatus($request->status);

        // Broadcast temps réel (D11) — silencieux si Pusher non configuré
        try {
            broadcast(new OrderStatusChanged($order->fresh(), 'order.updated'));
        } catch (\Exception $broadcastEx) {
            \Illuminate\Support\Facades\Log::warning('Broadcast failed: ' . $broadcastEx->getMessage());
        }

        // Notification push FCM au client (si connecté + token disponible)
        try {
            (new FcmNotificationService())->notifyOrderStatusChanged($order->fresh()->load('user'), $request->status);
        } catch (\Exception $fcmEx) {
            \Illuminate\Support\Facades\Log::warning('FCM notifyOrderStatusChanged failed: ' . $fcmEx->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'Statut mis à jour',
            'data' => $order->fresh()
        ]);
    }

    /**
     * Cancel order
     */
    public function cancel(Restaurant $restaurant, Order $order): JsonResponse
    {
        if (!$order->canBeCancelled()) {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande ne peut plus être annulée'
            ], 422);
        }

        $order->updateStatus('cancelled');

        // Broadcast temps réel (même comportement que updateStatus)
        try {
            broadcast(new OrderStatusChanged($order->fresh(), 'order.updated'));
        } catch (\Exception $broadcastEx) {
            \Illuminate\Support\Facades\Log::warning('Broadcast cancel failed: ' . $broadcastEx->getMessage());
        }

        // Notification FCM au client
        try {
            (new FcmNotificationService())->notifyOrderStatusChanged($order->fresh()->load('user'), 'cancelled');
        } catch (\Exception $fcmEx) {
            \Illuminate\Support\Facades\Log::warning('FCM cancel failed: ' . $fcmEx->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'Commande annulée',
            'data' => $order->fresh()
        ]);
    }

    /**
     * Get order statistics
     */
    public function statistics(Request $request, Restaurant $restaurant): JsonResponse
    {
        $dateFrom = $request->get('from', now()->startOfMonth());
        $dateTo = $request->get('to', now()->endOfMonth());

        $stats = [
            'total_orders' => $restaurant->orders()
                ->whereBetween('order_date', [$dateFrom, $dateTo])
                ->count(),
            'completed_orders' => $restaurant->orders()
                ->whereBetween('order_date', [$dateFrom, $dateTo])
                ->whereIn('status', ['delivered', 'completed'])
                ->count(),
            'cancelled_orders' => $restaurant->orders()
                ->whereBetween('order_date', [$dateFrom, $dateTo])
                ->where('status', 'cancelled')
                ->count(),
            'total_revenue' => $restaurant->orders()
                ->whereBetween('order_date', [$dateFrom, $dateTo])
                ->whereIn('status', ['delivered', 'completed'])
                ->sum('total_amount'),
            'average_order_value' => $restaurant->orders()
                ->whereBetween('order_date', [$dateFrom, $dateTo])
                ->whereIn('status', ['delivered', 'completed'])
                ->avg('total_amount') ?? 0,
            'orders_by_type' => $restaurant->orders()
                ->whereBetween('order_date', [$dateFrom, $dateTo])
                ->selectRaw('order_type, COUNT(*) as count')
                ->groupBy('order_type')
                ->pluck('count', 'order_type'),
            'orders_by_status' => $restaurant->orders()
                ->whereBetween('order_date', [$dateFrom, $dateTo])
                ->selectRaw('status, COUNT(*) as count')
                ->groupBy('status')
                ->pluck('count', 'status'),
            'top_dishes' => OrderItem::whereHas('order', function ($q) use ($restaurant, $dateFrom, $dateTo) {
                $q->where('restaurant_id', $restaurant->id)
                    ->whereBetween('order_date', [$dateFrom, $dateTo])
                    ->whereIn('status', ['delivered', 'completed']);
            })
                ->selectRaw('dish_id, SUM(quantity) as total_quantity, SUM(total_price) as total_revenue')
                ->groupBy('dish_id')
                ->with('dish:id,nom')
                ->orderByDesc('total_quantity')
                ->limit(10)
                ->get(),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats
        ]);
    }

    /**
     * Get pending orders count (for real-time updates)
     */
    public function pendingCount(Restaurant $restaurant): JsonResponse
    {
        $counts = $restaurant->orders()
            ->whereIn('status', ['pending', 'confirmed', 'preparing', 'ready'])
            ->selectRaw("status, COUNT(*) as total")
            ->groupBy('status')
            ->pluck('total', 'status');

        return response()->json([
            'success' => true,
            'data' => [
                'pending' => $counts['pending'] ?? 0,
                'confirmed' => $counts['confirmed'] ?? 0,
                'preparing' => $counts['preparing'] ?? 0,
                'ready' => $counts['ready'] ?? 0,
            ]
        ]);
    }

    /**
     * Endpoint public pour l'app mobile Flutter.
     * Accepte le format de payload natif Flutter (champs FR).
     *
     * Payload attendu :
     *   restaurant_id, telephone, type, moyen_paiement, table (opt),
     *   mobile_money_provider (opt), plats: [{id, quantite}]
     */
    public function storeMobile(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'restaurant_id' => 'required|integer|exists:restaurants,id',
            // Téléphone : chiffres, espaces, tirets, + autorisés — max 20 caractères
            'telephone' => ['nullable', 'string', 'max:20', 'regex:/^[\+0-9\s\-]{6,20}$/'],
            'type' => 'required|string|max:50',
            'moyen_paiement' => 'required|string|max:50',
            // Numéro de table : alphanumérique uniquement
            'table' => ['nullable', 'string', 'max:10', 'regex:/^[A-Za-z0-9\-]{1,10}$/'],
            'mobile_money_provider' => 'nullable|string|max:50',
            // Limiter le panier à 50 articles distincts pour éviter les abus
            'plats' => 'required|array|min:1|max:50',
            'plats.*.id' => 'required|integer|exists:dishes,id',
            // Quantité max raisonnable par plat
            'plats.*.quantite' => 'required|integer|min:1|max:100',
            // Adresse et coordonnées de livraison
            'delivery_address' => 'nullable|string|max:500',
            'delivery_lat' => 'nullable|numeric|between:-90,90',
            'delivery_lng' => 'nullable|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Données invalides',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Normaliser le type de commande (FR → snake_case)
        $typeMap = [
            'sur place' => 'sur_place',
            'surplace' => 'sur_place',
            'à emporter' => 'a_emporter',
            'a emporter' => 'a_emporter',
            'aemporter' => 'a_emporter',
            'livraison' => 'livraison',
            'delivery' => 'livraison',
            'sur_place' => 'sur_place',
            'a_emporter' => 'a_emporter',
        ];

        $typeRaw = strtolower(trim($request->type));
        $orderType = $typeMap[$typeRaw] ?? null;

        if (!$orderType) {
            return response()->json([
                'success' => false,
                'message' => "Type de commande invalide : {$request->type}",
            ], 422);
        }

        // Vérifier que le restaurant existe ET est actif
        $restaurant = Restaurant::where('id', $request->restaurant_id)
            ->where('is_active', true)
            ->first();

        if (!$restaurant) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurant non trouvé ou temporairement fermé.',
            ], 404);
        }

        // Vérifier l'unicité des plats pour éviter les doublons dans le payload
        $platIds = array_column($request->plats, 'id');
        if (count($platIds) !== count(array_unique($platIds))) {
            return response()->json([
                'success' => false,
                'message' => 'Le panier contient des plats en double. Veuillez regrouper les quantités.',
            ], 422);
        }

        try {
            DB::beginTransaction();

            $order = Order::create([
                'restaurant_id' => $restaurant->id,
                'user_id' => null,   // commande anonyme
                'customer_phone' => $request->telephone,
                'order_type' => $orderType,
                'table_number' => $request->table,
                'delivery_address' => $request->delivery_address,
                'delivery_lat' => $request->delivery_lat,
                'delivery_lng' => $request->delivery_lng,
                'payment_method' => $request->moyen_paiement,
                'mobile_money_provider' => $request->mobile_money_provider,
                'status' => 'pending',
            ]);

            foreach ($request->plats as $plat) {
                $dish = Dish::findOrFail($plat['id']);

                if ($dish->restaurant_id !== $restaurant->id) {
                    throw new \Exception("Le plat '{$dish->nom}' n'appartient pas à ce restaurant.");
                }

                if (!$dish->disponibilite) {
                    throw new \Exception("Le plat '{$dish->nom}' n'est plus disponible.");
                }

                OrderItem::create([
                    'order_id' => $order->id,
                    'dish_id' => $dish->id,
                    'quantity' => $plat['quantite'],
                    'unit_price' => $dish->prix,
                ]);
            }

            $order->calculateTotal();

            DB::commit();

            // Broadcast temps réel → dashboard reçoit la nouvelle commande
            try {
                broadcast(new OrderStatusChanged($order, 'order.created'));
            } catch (\Exception $broadcastEx) {
                \Illuminate\Support\Facades\Log::warning('Broadcast storeMobile failed: ' . $broadcastEx->getMessage());
            }

            // Notification push FCM au restaurant
            try {
                (new FcmNotificationService())->notifyNewOrder($restaurant, $order);
            } catch (\Exception $fcmEx) {
                \Illuminate\Support\Facades\Log::warning('FCM notifyNewOrder (mobile) failed: ' . $fcmEx->getMessage());
            }

            return response()->json([
                'success' => true,
                'message' => 'Commande créée avec succès',
                'id' => $order->id,
                'data' => $order->load(['items.dish:id,nom,prix']),
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }
}
