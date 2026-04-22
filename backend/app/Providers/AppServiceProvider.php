<?php

namespace App\Providers;

use App\Models\Delivery;
use App\Models\Restaurant;
use App\Policies\DeliveryPolicy;
use App\Policies\RestaurantPolicy;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(Restaurant::class, RestaurantPolicy::class);
        Gate::policy(Delivery::class, DeliveryPolicy::class);

        $this->configureRateLimiting();
    }

    /**
     * Configure rate limiters personnalisés.
     *
     * order-mobile : protège POST /commandes (storeMobile)
     *   - 10 commandes / minute par IP (limite globale)
     *   - 3 commandes / minute par IP + restaurant (limite par restaurant)
     *
     * Si les deux limites sont dépassées, le plus restrictif s'applique en premier.
     */
    protected function configureRateLimiting(): void
    {
        RateLimiter::for('order-mobile', function (Request $request) {
            $ip = $request->ip();
            $restaurantId = $request->input('restaurant_id', '');

            return [
                // 10 commandes / minute depuis cette IP (anti-flood global)
                Limit::perMinute(10)->by('order-ip:' . $ip)
                    ->response(fn() => response()->json([
                        'success' => false,
                        'message' => 'Trop de commandes. Veuillez patienter quelques instants avant de réessayer.',
                    ], 429)),

                // 3 commandes / minute depuis cette IP vers ce restaurant
                Limit::perMinute(3)->by('order-ip-restaurant:' . $ip . ':' . $restaurantId)
                    ->response(fn() => response()->json([
                        'success' => false,
                        'message' => 'Commande trop fréquente sur ce restaurant.',
                    ], 429)),
            ];
        });

        // coupon-validate : protège POST /coupons/validate (public, sans auth)
        //   - 20 validations / minute par IP (anti-brute-force sur les codes)
        RateLimiter::for('coupon-validate', function (Request $request) {
            return Limit::perMinute(20)->by('coupon-ip:' . $request->ip())
                ->response(fn() => response()->json([
                    'success' => false,
                    'message' => 'Trop de tentatives. Veuillez patienter avant de réessayer.',
                ], 429));
        });
    }
}
