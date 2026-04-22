<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class DeliveryDriver extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'name',
        'phone',
        'zone',
        'status',
        'lat',
        'lng',
        'last_location_at',
        'fcm_token',
    ];

    protected $casts = [
        'lat' => 'float',
        'lng' => 'float',
        'last_location_at' => 'datetime',
    ];

    const STATUSES = [
        'available' => 'Disponible',
        'busy' => 'En livraison',
        'offline' => 'Hors ligne',
    ];

    // ── Relations ────────────────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function activeDelivery(): HasOne
    {
        return $this->hasOne(Delivery::class)
            ->whereNotIn('status', ['delivered', 'failed'])
            ->latest();
    }

    /**
     * Toutes les livraisons (historique complet) de ce livreur.
     */
    public function deliveries(): HasMany
    {
        return $this->hasMany(Delivery::class);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    public function isAvailable(): bool
    {
        return $this->status === 'available';
    }

    public function markBusy(): void
    {
        $this->update(['status' => 'busy']);
    }

    public function markAvailable(): void
    {
        $this->update(['status' => 'available']);
    }

    public function updateLocation(float $lat, float $lng): void
    {
        $this->update([
            'lat' => $lat,
            'lng' => $lng,
            'last_location_at' => now(),
        ]);
    }
}
