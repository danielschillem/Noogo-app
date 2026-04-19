<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Restaurant;
use App\Models\Dish;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardController extends Controller
{
    /**
     * Get dashboard overview statistics
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        // Get user's restaurants (single query, reused below)
        $restaurantIds = Restaurant::forUser($user->id)->pluck('id');

        $today = Carbon::today();
        $thisMonth = Carbon::now()->startOfMonth();
        $lastMonth = Carbon::now()->subMonth()->startOfMonth();
        $lastMonthEnd = Carbon::now()->subMonth()->endOfMonth();

        // Single aggregate query instead of 9 separate ones
        $orderStats = Order::whereIn('restaurant_id', $restaurantIds)
            ->where('order_date', '>=', $lastMonth)
            ->selectRaw("
                COUNT(CASE WHEN DATE(order_date) = ? THEN 1 END) as today_orders,
                COALESCE(SUM(CASE WHEN DATE(order_date) = ? AND status != 'cancelled' THEN total_amount END), 0) as today_revenue,
                COUNT(CASE WHEN DATE(order_date) = ? AND status = 'pending' THEN 1 END) as today_pending,
                COUNT(CASE WHEN order_date >= ? THEN 1 END) as month_orders,
                COALESCE(SUM(CASE WHEN order_date >= ? AND status != 'cancelled' THEN total_amount END), 0) as month_revenue,
                COUNT(CASE WHEN order_date >= ? AND status IN ('delivered','completed') THEN 1 END) as month_completed,
                COUNT(CASE WHEN order_date >= ? AND order_date <= ? THEN 1 END) as last_month_orders,
                COALESCE(SUM(CASE WHEN order_date >= ? AND order_date <= ? AND status != 'cancelled' THEN total_amount END), 0) as last_month_revenue
            ", [$today, $today, $today, $thisMonth, $thisMonth, $thisMonth, $lastMonth, $lastMonthEnd, $lastMonth, $lastMonthEnd])
            ->first();

        // Single query for dish counts
        $dishStats = Dish::whereIn('restaurant_id', $restaurantIds)
            ->selectRaw("COUNT(*) as total, COUNT(CASE WHEN disponibilite = true THEN 1 END) as active")
            ->first();

        $stats = [
            'today' => [
                'orders' => $orderStats->today_orders,
                'revenue' => $orderStats->today_revenue,
                'pending_orders' => $orderStats->today_pending,
            ],
            'this_month' => [
                'orders' => $orderStats->month_orders,
                'revenue' => $orderStats->month_revenue,
                'completed_orders' => $orderStats->month_completed,
            ],
            'last_month' => [
                'orders' => $orderStats->last_month_orders,
                'revenue' => $orderStats->last_month_revenue,
            ],
            'total_restaurants' => count($restaurantIds),
            'total_dishes' => $dishStats->total,
            'active_dishes' => $dishStats->active,
        ];

        $stats['growth'] = [
            'orders' => $this->calculateGrowth(
                $stats['this_month']['orders'],
                $stats['last_month']['orders']
            ),
            'revenue' => $this->calculateGrowth(
                $stats['this_month']['revenue'],
                $stats['last_month']['revenue']
            ),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats
        ]);
    }

    /**
     * Get recent orders
     */
    public function recentOrders(Request $request): JsonResponse
    {
        $user = $request->user();
        $restaurantIds = Restaurant::forUser($user->id)->pluck('id');

        $orders = Order::whereIn('restaurant_id', $restaurantIds)
            ->with(['restaurant:id,nom', 'items.dish:id,nom'])
            ->latest('order_date')
            ->limit($request->get('limit', 10))
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders
        ]);
    }

    /**
     * Get orders chart data
     */
    public function ordersChart(Request $request): JsonResponse
    {
        $user = $request->user();
        $restaurantIds = Restaurant::forUser($user->id)->pluck('id');

        $days = $request->get('days', 7);
        $startDate = Carbon::now()->subDays($days - 1)->startOfDay();

        $orders = Order::whereIn('restaurant_id', $restaurantIds)
            ->where('order_date', '>=', $startDate)
            ->selectRaw("DATE(order_date) as date, COUNT(*) as count, SUM(CASE WHEN status != 'cancelled' THEN total_amount ELSE 0 END) as revenue")
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->keyBy('date');

        $data = [];
        for ($i = 0; $i < $days; $i++) {
            $date = $startDate->copy()->addDays($i)->format('Y-m-d');
            $data[] = [
                'date' => $date,
                'label' => Carbon::parse($date)->format('d/m'),
                'orders' => $orders[$date]->count ?? 0,
                'revenue' => $orders[$date]->revenue ?? 0,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $data
        ]);
    }

    /**
     * Get revenue chart data
     */
    public function revenueChart(Request $request): JsonResponse
    {
        $user = $request->user();
        $restaurantIds = Restaurant::forUser($user->id)->pluck('id');

        $months = $request->get('months', 6);
        $startDate = Carbon::now()->subMonths($months - 1)->startOfMonth();

        $driver = DB::getDriverName();
        $yearExpr = $driver === 'sqlite'
            ? "CAST(strftime('%Y', order_date) AS INTEGER)"
            : 'EXTRACT(YEAR FROM order_date)';
        $monthExpr = $driver === 'sqlite'
            ? "CAST(strftime('%m', order_date) AS INTEGER)"
            : 'EXTRACT(MONTH FROM order_date)';

        $revenues = Order::whereIn('restaurant_id', $restaurantIds)
            ->where('order_date', '>=', $startDate)
            ->whereNotIn('status', ['cancelled'])
            ->selectRaw("$yearExpr as year, $monthExpr as month, SUM(total_amount) as revenue, COUNT(*) as orders")
            ->groupBy('year', 'month')
            ->orderBy('year')
            ->orderBy('month')
            ->get();

        $data = [];
        for ($i = 0; $i < $months; $i++) {
            $date = $startDate->copy()->addMonths($i);
            $year = $date->year;
            $month = $date->month;

            $monthData = $revenues->first(function ($item) use ($year, $month) {
                return $item->year == $year && $item->month == $month;
            });

            $data[] = [
                'year' => $year,
                'month' => $month,
                'label' => $date->format('M Y'),
                'revenue' => $monthData?->revenue ?? 0,
                'orders' => $monthData?->orders ?? 0,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $data
        ]);
    }

    /**
     * Get top dishes
     */
    public function topDishes(Request $request): JsonResponse
    {
        $user = $request->user();
        $restaurantIds = Restaurant::forUser($user->id)->pluck('id');
        $limit = $request->get('limit', 5);

        $topDishes = DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('dishes', 'order_items.dish_id', '=', 'dishes.id')
            ->whereIn('orders.restaurant_id', $restaurantIds)
            ->whereIn('orders.status', ['delivered', 'completed'])
            ->select(
                'dishes.id',
                'dishes.nom',
                'dishes.prix',
                DB::raw('SUM(order_items.quantity) as total_quantity'),
                DB::raw('SUM(order_items.total_price) as total_revenue')
            )
            ->groupBy('dishes.id', 'dishes.nom', 'dishes.prix')
            ->orderByDesc('total_quantity')
            ->limit($limit)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $topDishes
        ]);
    }

    /**
     * Lightweight pending count for sidebar badge (avoids full stats query)
     */
    public function pendingCount(Request $request): JsonResponse
    {
        $user = $request->user();
        $restaurantIds = Restaurant::forUser($user->id)->pluck('id');

        $count = Order::whereIn('restaurant_id', $restaurantIds)
            ->whereDate('order_date', Carbon::today())
            ->where('status', 'pending')
            ->count();

        return response()->json([
            'success' => true,
            'data' => ['pending_orders' => $count]
        ]);
    }

    /**
     * Calculate growth percentage
     */
    private function calculateGrowth(float $current, float $previous): float
    {
        if ($previous == 0) {
            return $current > 0 ? 100 : 0;
        }
        return round((($current - $previous) / $previous) * 100, 2);
    }
}
