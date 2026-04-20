<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Delivery extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'order_id',
        'delivery_driver_id',
        'status',
        'assigned_at',
        'picked_up_at',
        'on_way_at',
        'delivered_at',
        'driver_lat',
        'driver_lng',
        'driver_location_at',
        'client_lat',
        'client_lng',
        'client_address',
        'distance_km',
        'fee',
        'notes',
        'failure_reason',
    ];

    protected $casts = [
        'assigned_at'        => 'datetime',
        'picked_up_at'       => 'datetime',
        'on_way_at'          => 'datetime',
        'delivered_at'       => 'datetime',
        'driver_location_at' => 'datetime',
        'driver_lat'         => 'float',
        'driver_lng'         => 'float',
        'client_lat'         => 'float',
        'client_lng'         => 'float',
        'distance_km'        => 'float',
        'fee'                => 'decimal:2',
    ];

    // Progression statuts (ordre)
    const STATUSES = [
        'pending_assignment' => 'En attente d\'assignation',
        'assigned'           => 'Assignée',
        'picked_up'          => 'Commande récupérée',
        'on_way'             => 'En route',
        'delivered'          => 'Livrée',
        'failed'             => 'Échec',
    ];

    // Transitions autorisées (statut actuel → statuts suivants valides)
    const TRANSITIONS = [
        'pending_assignment' => ['assigned', 'failed'],
        'assigned'           => ['picked_up', 'failed'],
        'picked_up'          => ['on_way', 'failed'],
        'on_way'             => ['delivered', 'failed'],
        'delivered'          => [],
        'failed'             => [],
    ];

    // ── Relations ────────────────────────────────────────────────────────────

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(DeliveryDriver::class, 'delivery_driver_id');
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    public function isTerminal(): bool
    {
        return in_array($this->status, ['delivered', 'failed']);
    }

    public function canTransitionTo(string $newStatus): bool
    {
        return in_array($newStatus, self::TRANSITIONS[$this->status] ?? []);
    }

    public function applyStatusTimestamp(string $status): void
    {
        match ($status) {
            'assigned'  => $this->assigned_at   = now(),
            'picked_up' => $this->picked_up_at  = now(),
            'on_way'    => $this->on_way_at      = now(),
            'delivered' => $this->delivered_at   = now(),
            default     => null,
        };
    }
}
