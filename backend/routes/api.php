<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\RestaurantController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DishController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\FlashInfoController;
use App\Http\Controllers\Api\DashboardController;

/*
|--------------------------------------------------------------------------
| API Routes - Noogo Dashboard
|--------------------------------------------------------------------------
|
| Routes pour l'application mobile Flutter et le dashboard React
|
*/

// ============================================================================
// ROUTES PUBLIQUES (pas d'authentification requise)
// ============================================================================

// Authentication — limitées à 10 tentatives par minute pour contrer le brute-force
Route::middleware('throttle:10,1')->prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

// Routes publiques pour l'application Flutter
Route::prefix('restaurant')->group(function () {
    Route::get('/{restaurantId}/menu', [RestaurantController::class, 'menu']);
});

// Offres actives (endpoint public pour Flutter)
Route::get('/offres/actives/{restaurantId}', [FlashInfoController::class, 'actives']);

// ============================================================================
// ENDPOINT PUBLIC COMMANDES (app mobile Flutter, sans authentification)
// Limité à 30 commandes/minute par IP pour contrer les abus
// ============================================================================
Route::middleware('throttle:30,1')->post('/commandes', [OrderController::class, 'storeMobile']);


// ============================================================================
// ROUTES PROTÉGÉES (authentification requise)
// ============================================================================

Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::prefix('auth')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::post('/refresh', [AuthController::class, 'refresh']);
        Route::put('/user/update', [AuthController::class, 'updateUser']);
    });

    // Dashboard — limité à 120 requêtes/minute (protection contre scraping / boucles)
    Route::middleware('throttle:120,1')->prefix('dashboard')->group(function () {
        Route::get('/', [DashboardController::class, 'index']);
        Route::get('/recent-orders', [DashboardController::class, 'recentOrders']);
        Route::get('/orders-chart', [DashboardController::class, 'ordersChart']);
        Route::get('/revenue-chart', [DashboardController::class, 'revenueChart']);
        Route::get('/top-dishes', [DashboardController::class, 'topDishes']);
    });

    // Restaurants
    Route::apiResource('restaurants', RestaurantController::class);
    Route::prefix('restaurants/{restaurant}')->group(function () {
        Route::post('/toggle-active', [RestaurantController::class, 'toggleActive']);
        Route::post('/toggle-open', [RestaurantController::class, 'toggleOpen']);
        Route::get('/statistics', [RestaurantController::class, 'statistics']);
        Route::post('/generate-qr', [RestaurantController::class, 'generateQrCode']);

        // Categories
        Route::apiResource('categories', CategoryController::class);
        Route::post('/categories/reorder', [CategoryController::class, 'reorder']);
        Route::post('/categories/{category}/toggle-active', [CategoryController::class, 'toggleActive']);

        // Dishes
        Route::apiResource('dishes', DishController::class);
        Route::post('/dishes/reorder', [DishController::class, 'reorder']);
        Route::post('/dishes/{dish}/toggle-availability', [DishController::class, 'toggleAvailability']);
        Route::post('/dishes/{dish}/toggle-plat-du-jour', [DishController::class, 'togglePlatDuJour']);
        Route::get('/plats-du-jour', [DishController::class, 'platsDuJour']);

        // Orders
        Route::apiResource('orders', OrderController::class)->only(['index', 'store', 'show']);
        Route::patch('/orders/{order}/status', [OrderController::class, 'updateStatus']);
        Route::post('/orders/{order}/cancel', [OrderController::class, 'cancel']);
        Route::get('/orders-statistics', [OrderController::class, 'statistics']);
        Route::get('/orders-pending-count', [OrderController::class, 'pendingCount']);

        // Flash Infos / Offres
        Route::apiResource('flash-infos', FlashInfoController::class);
        Route::post('/flash-infos/{flashInfo}/toggle-active', [FlashInfoController::class, 'toggleActive']);
    });
});

// Health check
Route::get('/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'Noogo API is running',
        'version' => '1.0.0',
        'timestamp' => now()->toISOString()
    ]);
});
