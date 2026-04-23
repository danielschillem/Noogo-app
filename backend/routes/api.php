<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\RestaurantController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DishController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\FlashInfoController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\StaffController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\DeviceTokenController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\DeliveryController;
use App\Http\Controllers\Api\RatingController;
use App\Http\Controllers\Api\CouponController;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

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
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
});

// Routes publiques pour l'application Flutter
Route::prefix('restaurant')->group(function () {
    Route::get('/{restaurantId}/menu', [RestaurantController::class, 'menu']);
});

// Recherche publique de restaurants (Flutter client)
Route::get('/restaurants/search', [RestaurantController::class, 'publicSearch']);

// Portail de connexion restaurant — endpoints publics (aucune auth requise)
Route::prefix('portal')->group(function () {
    Route::get('/restaurants', [RestaurantController::class, 'portalList']);
    Route::get('/restaurants/{restaurant}', [RestaurantController::class, 'portalShow']);
});

// Offres actives (endpoint public pour Flutter)
Route::get('/offres/actives/{restaurantId}', [FlashInfoController::class, 'actives']);

// ============================================================================
// PAIEMENT MOBILE MONEY (public — l'app Flutter envoie sans token)
// ============================================================================
// Webhook (callback opérateur/CinetPay) — exclu de CSRF automatiquement (api.php)
Route::post('/payments/webhook', [PaymentController::class, 'webhook']);

// Initiation + OTP + polling : accessible sans connexion (app mobile client)
Route::middleware('throttle:30,1')->group(function () {
    Route::post('/payments/initiate', [PaymentController::class, 'initiate']);
    Route::post('/payments/{payment}/confirm-otp', [PaymentController::class, 'confirmOtp']);
    Route::get('/payments/{payment}/status', [PaymentController::class, 'status']);
    Route::delete('/payments/{payment}', [PaymentController::class, 'cancel']);
});

// ============================================================================
// ENDPOINT PUBLIC COMMANDES (app mobile Flutter, sans authentification)
// Limité via le rate-limiter nommé « order-mobile » (AppServiceProvider) :
//   - 10 commandes / minute par IP (anti-flood global)
//   - 3 commandes / minute par IP + restaurant (anti-spam ciblé)
// ============================================================================
Route::middleware('throttle:order-mobile')->post('/commandes', [OrderController::class, 'storeMobile']);

// Validation de coupon (app mobile Flutter — route publique, protégée par rate limiter anti-brute-force)
Route::middleware('throttle:coupon-validate')->post('/coupons/validate', [\App\Http\Controllers\Api\CouponController::class, 'validate']);


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
        Route::post('/change-password', [AuthController::class, 'changePassword']);
        // Retourne les restaurants accessibles (proprio + staff) — pour la vue propriétaire
        Route::get('/my-restaurants', [StaffController::class, 'myRestaurants']);
        // Token FCM : enregistrement au login, suppression au logout
        Route::post('/device-token', [DeviceTokenController::class, 'store']);
        Route::delete('/device-token', [DeviceTokenController::class, 'destroy']);
        // Historique de commandes du client connecté
        Route::get('/my-orders', [OrderController::class, 'myOrders']);
    });

    // Dashboard — limité à 120 requêtes/minute (protection contre scraping / boucles)
    Route::middleware('throttle:120,1')->prefix('dashboard')->group(function () {
        Route::get('/', [DashboardController::class, 'index']);
        Route::get('/pending-count', [DashboardController::class, 'pendingCount']);
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

        // Coupons / Codes promo
        Route::get('/coupons', [CouponController::class, 'index']);
        Route::post('/coupons', [CouponController::class, 'store']);
        Route::put('/coupons/{coupon}', [CouponController::class, 'update']);
        Route::delete('/coupons/{coupon}', [CouponController::class, 'destroy']);
        Route::post('/coupons/{coupon}/toggle-active', [CouponController::class, 'toggleActive']);

        // Ratings / Avis
        Route::get('/ratings', [RatingController::class, 'index']);
        Route::post('/orders/{order}/rate', [RatingController::class, 'store']);

        // Personnel du restaurant (owner + super admin uniquement)
        Route::get('/staff', [StaffController::class, 'index']);
        Route::post('/staff', [StaffController::class, 'store']);
        Route::put('/staff/{staff}', [StaffController::class, 'update']);
        Route::delete('/staff/{staff}', [StaffController::class, 'destroy']);
    });
    // Livraison — demande depuis une commande (gérant)
    Route::post('/orders/{order}/request-delivery', [DeliveryController::class, 'requestDelivery']);

    // Livraisons — accès protégé général
    Route::prefix('deliveries')->group(function () {
        Route::get('/my-active', [DeliveryController::class, 'myActive']);
        Route::get('/my-history', [DeliveryController::class, 'myHistory']);
        Route::get('/{delivery}', [DeliveryController::class, 'show']);
        Route::post('/{delivery}/assign', [DeliveryController::class, 'assign']);
        // C4 : réservé aux livreurs enregistrés
        Route::middleware('driver')->group(function () {
            Route::patch('/{delivery}/status', [DeliveryController::class, 'updateStatus']);
            Route::post('/{delivery}/accept', [DeliveryController::class, 'acceptDelivery']);
            Route::post('/{delivery}/reject', [DeliveryController::class, 'rejectDelivery']);
            Route::post('/{delivery}/driver-location', [DeliveryController::class, 'updateDriverLocation'])
                ->middleware('throttle:60,1');
        });
        // C5 : client partage sa position GPS au livreur
        Route::post('/{delivery}/client-location', [DeliveryController::class, 'updateClientLocation'])
            ->middleware('throttle:60,1');
    });

    // Livreur connecté — profil & disponibilité
    Route::prefix('drivers')->group(function () {
        Route::get('/me', [DeliveryController::class, 'myProfile']);
        Route::put('/me/status', [DeliveryController::class, 'updateMyStatus']);
    });
});

// Health check
Route::get('/health', function () {
    $disk = config('filesystems.disks.r2.endpoint') ? 'r2' : 'public';
    $sampleLogoPath = DB::table('restaurants')
        ->whereNotNull('logo')
        ->orderByDesc('id')
        ->value('logo');

    $sampleAccessible = null;
    if (is_string($sampleLogoPath) && $sampleLogoPath !== '') {
        try {
            $sampleAccessible = Storage::disk($disk)->exists($sampleLogoPath);
        } catch (\Throwable $e) {
            $sampleAccessible = false;
        }
    }

    return response()->json([
        'success' => true,
        'message' => 'Noogo API is running',
        'version' => '1.0.0',
        'timestamp' => now()->toISOString(),
        'storage' => [
            'active_disk' => $disk,
            'sample_logo_path' => $sampleLogoPath,
            'sample_logo_accessible' => $sampleAccessible,
        ],
    ]);
});

// ============================================================================
// SUPER ADMIN ROUTES
// ============================================================================
Route::middleware(['auth:sanctum', 'admin'])->prefix('admin')->group(function () {
    Route::get('/stats', [AdminController::class, 'stats']);

    // Users
    Route::get('/users', [AdminController::class, 'listUsers']);
    Route::post('/users', [AdminController::class, 'createUser']);
    Route::put('/users/{user}', [AdminController::class, 'updateUser']);
    Route::delete('/users/{user}', [AdminController::class, 'deleteUser']);
    Route::post('/users/{user}/toggle-admin', [AdminController::class, 'toggleAdmin']);

    // Restaurants
    Route::get('/restaurants', [AdminController::class, 'listRestaurants']);
    Route::post('/restaurants/{restaurant}/toggle-active', [AdminController::class, 'toggleRestaurantActive']);

    // Livreurs (CRUD admin)
    Route::get('/deliveries', [DeliveryController::class, 'index']);
    Route::get('/drivers', [DeliveryController::class, 'listDrivers']);
    Route::post('/drivers', [DeliveryController::class, 'storeDriver']);
    Route::put('/drivers/{driver}', [DeliveryController::class, 'updateDriver']);
    Route::delete('/drivers/{driver}', [DeliveryController::class, 'destroyDriver']);

    // Création compte livreur (protégé admin — évite les auto-inscriptions)
    Route::post('/auth/register-driver', [AuthController::class, 'registerDriver']);
});
