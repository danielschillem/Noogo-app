<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

/**
 * Service FCM v1 HTTP API avec OAuth2 (service account).
 *
 * Configuration .env :
 *   FIREBASE_PROJECT_ID=noogo-568e6
 *   FIREBASE_CREDENTIALS_JSON=<contenu JSON du service account encodé en base64>
 *   ou
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 */
class FcmNotificationService
{
    private string $projectId;

    public function __construct()
    {
        $this->projectId = config('services.fcm.project_id', env('FIREBASE_PROJECT_ID', ''));
    }

    /**
     * Obtient un access token OAuth2 via le service account, mis en cache 50 min.
     */
    private function getAccessToken(): ?string
    {
        return Cache::remember('fcm_access_token', 3000, function () {
            $credentials = $this->loadCredentials();
            if (!$credentials)
                return null;

            try {
                $now = time();
                $header = $this->base64UrlEncode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
                $payload = $this->base64UrlEncode(json_encode([
                    'iss' => $credentials['client_email'],
                    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                    'aud' => 'https://oauth2.googleapis.com/token',
                    'iat' => $now,
                    'exp' => $now + 3600,
                ]));

                $key = openssl_pkey_get_private($credentials['private_key']);
                openssl_sign("$header.$payload", $signature, $key, OPENSSL_ALGO_SHA256);
                $jwt = "$header.$payload." . $this->base64UrlEncode($signature);

                $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt,
                ]);

                if ($response->successful()) {
                    return $response->json('access_token');
                }

                Log::error('FCM OAuth2 token error', ['body' => $response->body()]);
                return null;
            } catch (\Throwable $e) {
                Log::error('FCM OAuth2 exception: ' . $e->getMessage());
                return null;
            }
        });
    }

    private function loadCredentials(): ?array
    {
        // Option 1: Base64-encoded JSON in env
        $b64 = env('FIREBASE_CREDENTIALS_JSON');
        if ($b64) {
            $decoded = json_decode(base64_decode($b64), true);
            if ($decoded)
                return $decoded;
        }

        // Option 2: File path
        $path = env('GOOGLE_APPLICATION_CREDENTIALS');
        if ($path && file_exists($path)) {
            return json_decode(file_get_contents($path), true);
        }

        return null;
    }

    private function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    // ─── Envoi ciblé (token individuel) ─────────────────────────────────────

    public function sendToToken(
        string $token,
        string $title,
        string $body,
        array $data = [],
        string $sound = 'default'
    ): bool {
        if (empty($this->projectId)) {
            Log::warning('FCM: FIREBASE_PROJECT_ID non configuré — notification ignorée');
            return false;
        }

        if (empty($token))
            return false;

        $accessToken = $this->getAccessToken();
        if (!$accessToken) {
            Log::warning('FCM: impossible d\'obtenir un access token OAuth2');
            return false;
        }

        try {
            $payload = [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'sound' => $sound,
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        ],
                    ],
                    'data' => array_map('strval', $data),
                ],
            ];

            $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";
            $response = Http::withToken($accessToken)->post($url, $payload);

            if ($response->successful())
                return true;

            if ($response->status() === 404 || $response->status() === 400) {
                Log::warning('FCM token invalide ou expiré', [
                    'token' => substr($token, 0, 20) . '...',
                    'error' => $response->json('error.message') ?? $response->body(),
                ]);
                return false;
            }

            // Token OAuth expiré — invalider le cache et réessayer une fois
            if ($response->status() === 401) {
                Cache::forget('fcm_access_token');
                $accessToken = $this->getAccessToken();
                if ($accessToken) {
                    $retry = Http::withToken($accessToken)->post($url, $payload);
                    return $retry->successful();
                }
            }

            Log::error('FCM v1 HTTP error', ['status' => $response->status(), 'body' => $response->body()]);
            return false;
        } catch (\Throwable $e) {
            Log::error('FCM exception: ' . $e->getMessage());
            return false;
        }
    }

    // ─── Envoi par topic ─────────────────────────────────────────────────────

    public function sendToTopic(
        string $topic,
        string $title,
        string $body,
        array $data = []
    ): bool {
        if (empty($this->projectId)) {
            Log::warning('FCM: FIREBASE_PROJECT_ID non configuré — topic notification ignorée');
            return false;
        }

        $accessToken = $this->getAccessToken();
        if (!$accessToken)
            return false;

        try {
            $payload = [
                'message' => [
                    'topic' => $topic,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'sound' => 'default',
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        ],
                    ],
                    'data' => array_map('strval', $data),
                ],
            ];

            $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";
            $response = Http::withToken($accessToken)->post($url, $payload);

            return $response->successful();
        } catch (\Throwable $e) {
            Log::error('FCM topic exception: ' . $e->getMessage());
            return false;
        }
    }

    // ─── Helpers métier ──────────────────────────────────────────────────────

    /**
     * Notifie le staff du restaurant (serveurs) qu'une commande est prête à être servie.
     * Envoyé via le topic restaurant quand une commande passe à l'état 'ready'.
     */
    public function notifyOrderReady(
        \App\Models\Restaurant $restaurant,
        \App\Models\Order $order
    ): void {
        $tableInfo = $order->table_number ? " · Table {$order->table_number}" : '';
        $title = "🔔 Commande #{$order->id} prête{$tableInfo}";
        $body = 'La commande est prête, vous pouvez la servir.';

        $data = [
            'type' => 'order_ready',
            'order_id' => (string) $order->id,
            'restaurant_id' => (string) $restaurant->id,
            'table_number' => $order->table_number ?? '',
            'order_type' => $order->order_type,
        ];

        $this->sendToTopic("restaurant_{$restaurant->id}", $title, $body, $data);

        Log::info('FCM order_ready envoyé', [
            'order_id' => $order->id,
            'restaurant_id' => $restaurant->id,
        ]);
    }

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
