<?php

namespace App\Events;

use App\Models\Delivery;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcasted sur delivery.{orderId} à chaque mise à jour de position GPS du livreur.
 *
 * Événement : driver.location
 * Fréquence : toutes les 10 secondes (envoyé par l'app livreur)
 */
class DriverLocationUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly int $orderId,
        public readonly int $driverId,
        public readonly float $lat,
        public readonly float $lng,
    ) {
    }

    public function broadcastOn(): Channel
    {
        return new Channel("delivery.{$this->orderId}");
    }

    public function broadcastAs(): string
    {
        return 'driver.location';
    }

    public function broadcastWith(): array
    {
        return [
            'order_id'   => $this->orderId,
            'driver_id'  => $this->driverId,
            'lat'        => $this->lat,
            'lng'        => $this->lng,
            'updated_at' => now()->toISOString(),
        ];
    }
}
