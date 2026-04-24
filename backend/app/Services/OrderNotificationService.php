<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Restaurant;
use App\Models\RestaurantStaff;
use App\Models\User;
use App\Models\UserNotification;

class OrderNotificationService
{
    public function notifyOrderCreated(Restaurant $restaurant, Order $order): void
    {
        $this->fanOutRestaurantNotification(
            $restaurant,
            'order_created',
            'Nouvelle commande',
            "Nouvelle commande #{$order->id}" . ($order->table_number ? " - Table {$order->table_number}" : ''),
            [
                'order_id' => $order->id,
                'order_status' => $order->status,
                'amount' => (float) $order->total_amount,
                'table_number' => $order->table_number,
                'customer_name' => $order->customer_name,
            ]
        );
    }

    public function notifyOrderStatusChanged(Restaurant $restaurant, Order $order): void
    {
        $this->fanOutRestaurantNotification(
            $restaurant,
            'order_updated',
            'Mise à jour commande',
            "Commande #{$order->id} {$order->status_text}",
            [
                'order_id' => $order->id,
                'order_status' => $order->status,
                'amount' => (float) $order->total_amount,
                'table_number' => $order->table_number,
                'customer_name' => $order->customer_name,
            ]
        );
    }

    private function fanOutRestaurantNotification(
        Restaurant $restaurant,
        string $type,
        string $title,
        string $message,
        array $payload = []
    ): void {
        $recipientIds = [];

        if ($restaurant->user_id) {
            $recipientIds[] = (int) $restaurant->user_id;
        }

        $staffIds = RestaurantStaff::query()
            ->where('restaurant_id', $restaurant->id)
            ->where('is_active', true)
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->toArray();

        $superAdminIds = User::query()
            ->where('role', 'super_admin')
            ->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->toArray();

        $recipientIds = array_values(array_unique(array_merge($recipientIds, $staffIds, $superAdminIds)));
        if (empty($recipientIds)) {
            return;
        }

        $now = now();
        $rows = array_map(function (int $userId) use ($restaurant, $type, $title, $message, $payload, $now) {
            return [
                'user_id' => $userId,
                'restaurant_id' => $restaurant->id,
                'type' => $type,
                'title' => $title,
                'message' => $message,
                'payload' => $payload,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }, $recipientIds);

        UserNotification::insert($rows);
    }
}
