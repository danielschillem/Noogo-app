<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'is_admin',
        'fcm_token',
    ];

    /**
     * The attributes that should be hidden for serialization.
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
        ];
    }

    /**
     * Get the restaurants for the user.
     */
    public function restaurants(): HasMany
    {
        return $this->hasMany(Restaurant::class);
    }

    /**
     * Get the orders for the user.
     */
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    /**
     * Staff records (roles dans des restaurants tiers).
     */
    public function staffRoles(): HasMany
    {
        return $this->hasMany(RestaurantStaff::class);
    }

    /**
     * Retourne le rôle de l'utilisateur dans un restaurant donné, ou null s'il n'en a pas.
     */
    public function staffRoleFor(int $restaurantId): ?RestaurantStaff
    {
        return $this->staffRoles()
            ->where('restaurant_id', $restaurantId)
            ->where('is_active', true)
            ->first();
    }

    /**
     * Retourne tous les IDs de restaurants auxquels l'utilisateur a accès
     * (en tant que propriétaire via restaurants.user_id OU via restaurant_staff).
     */
    public function accessibleRestaurantIds(): array
    {
        $owned = $this->restaurants()->pluck('id')->toArray();
        $staffed = $this->staffRoles()->where('is_active', true)->pluck('restaurant_id')->toArray();
        return array_unique(array_merge($owned, $staffed));
    }
}
