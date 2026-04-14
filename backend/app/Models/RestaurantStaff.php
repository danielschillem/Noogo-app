<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RestaurantStaff extends Model
{
    protected $table = 'restaurant_staff';

    protected $fillable = [
        'user_id',
        'restaurant_id',
        'role',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    // ─── Périmètres de permissions par rôle ───────────────────────────────────

    /**
     * Peut gérer le menu (plats, catégories, flash infos).
     */
    public function canManageMenu(): bool
    {
        return in_array($this->role, ['owner', 'manager']);
    }

    /**
     * Peut voir et mettre à jour le statut des commandes.
     */
    public function canManageOrders(): bool
    {
        return in_array($this->role, ['owner', 'manager', 'cashier', 'waiter']);
    }

    /**
     * Peut accéder aux statistiques et revenus.
     */
    public function canViewStats(): bool
    {
        return in_array($this->role, ['owner', 'manager', 'cashier']);
    }

    /**
     * Peut gérer le personnel (créer/modifier/supprimer des membres).
     */
    public function canManageStaff(): bool
    {
        return $this->role === 'owner';
    }

    /**
     * Peut modifier les informations du restaurant (profil, horaires…).
     */
    public function canEditRestaurant(): bool
    {
        return in_array($this->role, ['owner', 'manager']);
    }

    // ─── Relations ────────────────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }
}
