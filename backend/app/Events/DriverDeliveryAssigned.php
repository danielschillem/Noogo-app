<?php

namespace App\Events;

use App\Models\Delivery;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcasted sur le canal privé du livreur (private-driver.{userId})
 * quand une livraison lui est assignée.
 *
 * Déclenche l'alerte sonore et le dialog dans l'app livreur.
 */
class DriverDeliveryAssigned implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly Delivery $delivery,
        public readonly int $driverUserId,
    ) {
    }

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("driver.{$this->driverUserId}");
    }

    public function broadcastAs(): string
    {
        return 'delivery.assigned';
    }

    public function broadcastWith(): array
    {
        $order = $this->delivery->order;

        return [
            'delivery_id'   => $this->delivery->id,
            'order_id'      => $this->delivery->order_id,
            'customer_name' => $order?->customer_name,
            'address'       => $this->delivery->client_address,
            'fee'           => $this->delivery->fee,
            'status'        => $this->delivery->status,
        ];
    }
}
