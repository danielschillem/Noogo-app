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

        // Get user's restaurants
        $restaurantIds = Restaurant::forUser($user->id)->pluck('id');

        $today = Carbon::today();
        $thisMonth = Carbon::now()->startOfMonth();
        $lastMonth = Carbon::now()->subMonth()->startOfMonth();
        $lastMonthEnd = Carbon::now()->subMonth()->endOfMonth();

        $stats = [
            // Today's stats
            'today' => [
                'orders' => Order::whereIn('restaurant_id', $restaurantIds)
                    ->whereDate('order_date', $today)
                    ->count(),
                'revenue' => Order::whereIn('restaurant_id', $restaurantIds)
                    ->whereDate('order_date', $today)
                    ->whereNotIn('status', ['cancelled'])
                    ->sum('total_amount'),
                'pending_orders' => Order::whereIn('restaurant_id', $restaurantIds)
                    ->whereDate('order_date', $today)
                    ->where('status', 'pending')
                    ->count(),
            ],

            // This month stats
            'this_month' => [
                'orders' => Order::whereIn('restaurant_id', $restaurantIds)
                    ->where('order_date', '>=', $thisMonth)
                    ->count(),
                'revenue' => Order::whereIn('restaurant_id', $restaurantIds)
                    ->where('order_date', '>=', $thisMonth)
                    ->whereNotIn('status', ['cancelled'])
                    ->sum('total_amount'),
                'completed_orders' => Order::whereIn('restaurant_id', $restaurantIds)
                    ->where('order_date', '>=', $thisMonth)
                    ->whereIn('status', ['delivered', 'completed'])
                    ->count(),
            ],

            // Last month stats for comparison
            'last_month' => [
                'orders' => Order::whereIn('restaurant_id', $restaurantIds)
                    ->whereBetween('order_date', [$lastMonth, $lastMonthEnd])
                    ->count(),
                'revenue' => Order::whereIn('restaurant_id', $restaurantIds)
                    ->whereBetween('order_date', [$lastMonth, $lastMonthEnd])
                    ->whereNotIn('status', ['cancelled'])
                    ->sum('total_amount'),
            ],

            // General stats
            'total_restaurants' => Restaurant::forUser($user->id)->count(),
            'total_dishes' => Dish::whereIn('restaurant_id', $restaurantIds)->count(),
            'active_dishes' => Dish::whereIn('restaurant_id', $restaurantIds)
                ->where('disponibilite', true)
                ->count(),
        ];

        // Calculate growth percentages
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
            ->selectRaw('DATE(order_date) as date, COUNT(*) as count, SUM(CASE WHEN status != "cancelled" THEN total_amount ELSE 0 END) as revenue')
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
