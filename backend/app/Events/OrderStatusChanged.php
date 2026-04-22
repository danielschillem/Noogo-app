<?php

namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Événement broadcasté via Pusher à chaque changement de statut de commande,
 * ou lors de la création d'une nouvelle commande.
 *
 * Canal privé : private-restaurant.{restaurantId}
 * (authentification requise — voir routes/channels.php)
 * Événements :
 *   - order.created  → nouvelle commande (status = pending)
 *   - order.updated  → changement de statut
 */
class OrderStatusChanged implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly Order $order,
        public readonly string $eventType = 'order.updated',
    ) {
    }

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("restaurant.{$this->order->restaurant_id}");
    }

    public function broadcastAs(): string
    {
        return $this->eventType;
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->order->id,
            'status' => $this->order->status,
            'order_type' => $this->order->order_type,
            'total_amount' => $this->order->total_amount,
            'table_number' => $this->order->table_number,
            'customer_name' => $this->order->customer_name,
            'customer_phone' => $this->order->customer_phone,
            'restaurant_id' => $this->order->restaurant_id,
            'order_date' => $this->order->order_date,
            'payment_method' => $this->order->payment_method,
            'event_type' => $this->eventType,
        ];
    }
}
