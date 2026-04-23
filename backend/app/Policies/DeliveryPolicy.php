<?php

namespace App\Policies;

use App\Models\Delivery;
use App\Models\RestaurantStaff;
use App\Models\User;

class DeliveryPolicy
{
    /**
     * Admins bypass all policy checks.
     */
    public function before(User $user, string $ability): bool|null
    {
        if ($user->isAdmin()) {
            return true;
        }

        return null;
    }

    /**
     * Tout utilisateur authentifié peut voir les livraisons de ses commandes.
     */
    public function view(User $user, Delivery $delivery): bool
    {
        // Le client dont c'est la commande
        if ($delivery->order?->user_id === $user->id) {
            return true;
        }

        // Le livreur assigné
        if ($delivery->driver?->user_id === $user->id) {
            return true;
        }

        // Le gérant/staff du restaurant concerné
        return $delivery->order?->restaurant?->user_id === $user->id;
    }

    /**
     * Seul le livreur assigné peut mettre à jour le statut de sa livraison.
     */
    public function updateStatus(User $user, Delivery $delivery): bool
    {
        return $delivery->driver?->user_id === $user->id;
    }

    /**
     * Seul le livreur assigné peut pousser sa position GPS.
     */
    public function updateLocation(User $user, Delivery $delivery): bool
    {
        return $delivery->driver?->user_id === $user->id;
    }

    /**
     * Seul le gérant du restaurant (ou admin) peut assigner un livreur.
     * Le staff avec permission manage_orders est également autorisé.
     */
    public function assign(User $user, Delivery $delivery): bool
    {
        $restaurant = $delivery->order?->restaurant;
        if (!$restaurant) {
            return false;
        }

        if ($restaurant->user_id === $user->id) {
            return true;
        }

        $staff = RestaurantStaff::where('user_id', $user->id)
            ->where('restaurant_id', $restaurant->id)
            ->where('is_active', true)
            ->first();

        return $staff?->canManageOrders() ?? false;
    }
}
