<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Service d'envoi de notifications push Firebase Cloud Messaging (v1 HTTP API).
 *
 * Utilise le SDK HTTP de Laravel pour appeler l'API FCM v1.
 * Configuration dans .env :
 *   FCM_SERVER_KEY=<votre_server_key_legacy>   (simple, recommandé pour démarrer)
 *   ou
 *   GOOGLE_APPLICATION_CREDENTIALS=<chemin_vers_service_account.json>  (v1 OAuth2)
 *
 * Pour commencer rapidement : utiliser la clé serveur legacy (console Firebase
 * → Paramètres du projet → Cloud Messaging → Clé du serveur).
 */
class FcmNotificationService
{
    private string $serverKey;
    private string $fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    public function __construct()
    {
        $this->serverKey = config('services.fcm.server_key', env('FCM_SERVER_KEY', ''));
    }

    // ─── Envoi ciblé (token individuel) ─────────────────────────────────────

    /**
     * Envoie une notification à un appareil spécifique via son FCM token.
     *
     * @param string $token       FCM device token
     * @param string $title       Titre de la notification
     * @param string $body        Corps de la notification
     * @param array  $data        Données supplémentaires (optionnel)
     * @param string $sound       Son ('default' ou nom de fichier)
     * @return bool
     */
    public function sendToToken(
        string $token,
        string $title,
        string $body,
        array $data = [],
        string $sound = 'default'
    ): bool {
        if (empty($this->serverKey)) {
            Log::warning('FCM: FCM_SERVER_KEY non configuré — notification ignorée');
            return false;
        }

        if (empty($token)) {
            return false;
        }

        try {
            $payload = [
                'to' => $token,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                    'sound' => $sound,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
                'data' => $data,
                'priority' => 'high',
                'content_available' => true,
            ];

            $response = Http::withHeaders([
                'Authorization' => 'key=' . $this->serverKey,
                'Content-Type' => 'application/json',
            ])->post($this->fcmUrl, $payload);

            if ($response->successful()) {
                $json = $response->json();
                if (($json['failure'] ?? 0) > 0) {
                    Log::warning('FCM token invalide ou expiré', [
                        'token' => substr($token, 0, 20) . '...',
                        'result' => $json['results'][0] ?? [],
                    ]);
                    return false;
                }
                return true;
            }

            Log::error('FCM HTTP error', ['status' => $response->status(), 'body' => $response->body()]);
            return false;

        } catch (\Throwable $e) {
            Log::error('FCM exception: ' . $e->getMessage());
            return false;
        }
    }

    // ─── Envoi par topic ─────────────────────────────────────────────────────

    /**
     * Envoie une notification à tous les abonnés d'un topic.
     * Ex: topic = "restaurant_12" pour tous les staff du restaurant 12.
     *
     * @param string $topic  Nom du topic (sans le préfixe /topics/)
     */
    public function sendToTopic(
        string $topic,
        string $title,
        string $body,
        array $data = []
    ): bool {
        if (empty($this->serverKey)) {
            Log::warning('FCM: FCM_SERVER_KEY non configuré — topic notification ignorée');
            return false;
        }

        try {
            $payload = [
                'to' => '/topics/' . $topic,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                    'sound' => 'default',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
                'data' => $data,
                'priority' => 'high',
            ];

            $response = Http::withHeaders([
                'Authorization' => 'key=' . $this->serverKey,
                'Content-Type' => 'application/json',
            ])->post($this->fcmUrl, $payload);

            return $response->successful();

        } catch (\Throwable $e) {
            Log::error('FCM topic exception: ' . $e->getMessage());
            return false;
        }
    }

    // ─── Helpers métier ──────────────────────────────────────────────────────

    /**
     * Notifie le staff d'un restaurant qu'une nouvelle commande vient d'arriver.
     */
    public function notifyNewOrder(
        \App\Models\Restaurant $restaurant,
        \App\Models\Order $order
    ): void {
        $orderType = match ($order->order_type) {
            'sur_place' => 'Sur place' . ($order->table_number ? " (Table {$order->table_number})" : ''),
            'a_emporter' => 'À emporter',
            'livraison' => 'Livraison',
            default => $order->order_type,
        };

        $amount = number_format($order->total_amount ?? 0, 0, ',', ' ') . ' FCFA';

        $title = "🍽️ Nouvelle commande #{$order->id}";
        $body = "{$orderType} · {$amount}";

        $data = [
            'type' => 'new_order',
            'order_id' => (string) $order->id,
            'restaurant_id' => (string) $restaurant->id,
            'order_type' => $order->order_type,
            'table_number' => $order->table_number ?? '',
            'amount' => (string) ($order->total_amount ?? 0),
        ];

        // 1. Notif via topic restaurant (pour le staff connecté à ce topic)
        $topicSent = $this->sendToTopic("restaurant_{$restaurant->id}", $title, $body, $data);

        // 2. Notif directe au propriétaire si token disponible
        if ($restaurant->user && $restaurant->user->fcm_token) {
            $this->sendToToken($restaurant->user->fcm_token, $title, $body, $data);
        }

        Log::info("FCM new_order envoyé", [
            'order_id' => $order->id,
            'restaurant_id' => $restaurant->id,
            'topic_sent' => $topicSent,
        ]);
    }

    /**
     * Notifie le client que le statut de sa commande a changé.
     */
    public function notifyOrderStatusChanged(
        \App\Models\Order $order,
        string $newStatus
    ): void {
        // Seulement si le client est connecté et a un token
        if (!$order->user || !$order->user->fcm_token) {
            return;
        }

        $label = match ($newStatus) {
            'confirmed' => ['✅ Commande confirmée !', 'Le restaurant a accepté votre commande'],
            'preparing' => ['👨‍🍳 En préparation', 'Votre commande est en cours de préparation'],
            'ready' => ['🔔 Commande prête !', 'Venez récupérer votre commande'],
            'delivered' => ['🚀 Commande livrée', 'Votre commande vous a été livrée'],
            'completed' => ['⭐ Merci !', 'Votre commande a été finalisée. Donnez-nous votre avis !'],
            'cancelled' => ['❌ Commande annulée', 'Votre commande a été annulée'],
            default => [null, null],
        };

        if ($label[0] === null)
            return;

        $this->sendToToken(
            $order->user->fcm_token,
            $label[0],
            $label[1],
            [
                'type' => 'order_status_changed',
                'order_id' => (string) $order->id,
                'status' => $newStatus,
                'restaurant_id' => (string) $order->restaurant_id,
            ]
        );
    }
}
