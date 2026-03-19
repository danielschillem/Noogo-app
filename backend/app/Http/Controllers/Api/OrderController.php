<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Restaurant;
use App\Models\Dish;
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

            DB::commit();

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

        $order->updateStatus($request->status);

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

        return response()->json([
            'success' => true,
            'message' => 'Commande annulée',
            'data' => $order
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
        $counts = [
            'pending' => $restaurant->orders()->where('status', 'pending')->count(),
            'confirmed' => $restaurant->orders()->where('status', 'confirmed')->count(),
            'preparing' => $restaurant->orders()->where('status', 'preparing')->count(),
            'ready' => $restaurant->orders()->where('status', 'ready')->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => $counts
        ]);
    }
}
