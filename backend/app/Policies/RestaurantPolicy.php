<?php

namespace App\Policies;

use App\Models\Restaurant;
use App\Models\RestaurantStaff;
use App\Models\User;

class RestaurantPolicy
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
     * Determine whether the user can view any restaurants.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can view the restaurant.
     */
    public function view(User $user, Restaurant $restaurant): bool
    {
        return $user->id === $restaurant->user_id || $this->hasStaffAccess($user, $restaurant);
    }

    /**
     * Determine whether the user can create restaurants.
     */
    public function create(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can update the restaurant.
     */
    public function update(User $user, Restaurant $restaurant): bool
    {
        if ($user->id === $restaurant->user_id) {
            return true;
        }
        $staff = $this->getStaff($user, $restaurant);
        return $staff !== null && $staff->canEditRestaurant();
    }

    /**
     * Determine whether the user can delete the restaurant.
     */
    public function delete(User $user, Restaurant $restaurant): bool
    {
        return $user->id === $restaurant->user_id;
    }

    /**
     * Determine whether the user can manage the menu (dishes, categories).
     */
    public function manageMenu(User $user, Restaurant $restaurant): bool
    {
        if ($user->id === $restaurant->user_id) {
            return true;
        }
        $staff = $this->getStaff($user, $restaurant);
        return $staff !== null && $staff->canManageMenu();
    }

    /**
     * Commandes (liste, création guichet, détail, statuts, annulation), compteur file
     * d’attente, et notes de prise de commande orale (API oral-order-notes).
     */
    public function manageOrders(User $user, Restaurant $restaurant): bool
    {
        if ($user->id === $restaurant->user_id) {
            return true;
        }
        $staff = $this->getStaff($user, $restaurant);
        return $staff !== null && $staff->canManageOrders();
    }

    /**
     * Statistiques chiffrées (CA, volumes) : GET restaurants/…/statistics
     * et GET restaurants/…/orders-statistics — exclut le rôle serveur (waiter).
     */
    public function viewStats(User $user, Restaurant $restaurant): bool
    {
        if ($user->id === $restaurant->user_id) {
            return true;
        }
        $staff = $this->getStaff($user, $restaurant);
        return $staff !== null && $staff->canViewStats();
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private function getStaff(User $user, Restaurant $restaurant): ?RestaurantStaff
    {
        return RestaurantStaff::where('user_id', $user->id)
            ->where('restaurant_id', $restaurant->id)
            ->where('is_active', true)
            ->first();
    }

    private function hasStaffAccess(User $user, Restaurant $restaurant): bool
    {
        return RestaurantStaff::where('user_id', $user->id)
            ->where('restaurant_id', $restaurant->id)
            ->where('is_active', true)
            ->exists();
    }
}
