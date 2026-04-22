<?php

use App\Models\Delivery;
use App\Models\Order;
use App\Models\Restaurant;
use App\Models\RestaurantStaff;
use Illuminate\Support\Facades\Broadcast;

/**
 * Autorisations des canaux Pusher privés.
 *
 * Canal private-restaurant.{restaurantId} :
 *   - Admin Noogo   → accès total
 *   - Propriétaire  → accès au restaurant qu'il possède
 *   - Staff         → accès au restaurant auquel il est rattaché
 *
 * Canal private-delivery.{orderId} :
 *   - Client auteur de la commande
 *   - Livreur assigné à la livraison
 *   - Propriétaire / staff du restaurant concerné
 *   - Admin Noogo
 */
Broadcast::channel('restaurant.{restaurantId}', function ($user, int $restaurantId): bool {
    if ($user->is_admin) {
        return true;
    }

    $restaurant = Restaurant::find($restaurantId);
    if (!$restaurant) {
        return false;
    }

    if ($restaurant->user_id === $user->id) {
        return true;
    }

    return RestaurantStaff::where('user_id', $user->id)
        ->where('restaurant_id', $restaurantId)
        ->where('is_active', true)
        ->exists();
});

Broadcast::channel('delivery.{orderId}', function ($user, int $orderId): bool {
    if ($user->is_admin) {
        return true;
    }

    $order = Order::with(['delivery.driver.user', 'restaurant'])->find($orderId);
    if (!$order) {
        return false;
    }

    // Client propriétaire de la commande
    if ($order->user_id === $user->id) {
        return true;
    }

    // Livreur assigné
    $delivery = $order->delivery;
    if ($delivery && $delivery->driver?->user_id === $user->id) {
        return true;
    }

    // Propriétaire du restaurant
    if ($order->restaurant?->user_id === $user->id) {
        return true;
    }

    // Staff actif du restaurant avec droit manage_orders
    $staff = RestaurantStaff::where('user_id', $user->id)
        ->where('restaurant_id', $order->restaurant_id)
        ->where('is_active', true)
        ->first();

    return $staff?->canManageOrders() ?? false;
});
