<?php

namespace App\Events;

use App\Models\Delivery;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcasted sur delivery.{orderId} à chaque changement de statut de livraison.
 *
 * Événements :
 *   - delivery.assigned   → livreur assigné
 *   - delivery.picked_up  → commande récupérée au restaurant
 *   - delivery.on_way     → en route vers le client
 *   - delivery.delivered  → livraison effectuée
 *   - delivery.failed     → échec livraison
 */
class DeliveryStatusChanged implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly Delivery $delivery,
        public readonly string $eventType,
    ) {
    }

    public function broadcastOn(): Channel
    {
        return new Channel("delivery.{$this->delivery->order_id}");
    }

    public function broadcastAs(): string
    {
        return $this->eventType;
    }

    public function broadcastWith(): array
    {
        $driver = $this->delivery->driver;

        return [
            'delivery_id' => $this->delivery->id,
            'order_id'    => $this->delivery->order_id,
            'status'      => $this->delivery->status,
            'event_type'  => $this->eventType,
            'driver'      => $driver ? [
                'id'     => $driver->id,
                'name'   => $driver->name,
                'phone'  => $driver->phone,
                'lat'    => $driver->lat,
                'lng'    => $driver->lng,
            ] : null,
            'delivered_at'  => $this->delivery->delivered_at?->toISOString(),
            'picked_up_at'  => $this->delivery->picked_up_at?->toISOString(),
            'on_way_at'     => $this->delivery->on_way_at?->toISOString(),
        ];
    }
}
