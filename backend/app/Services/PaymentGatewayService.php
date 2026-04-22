<?php

namespace App\Services;

use App\Models\Payment;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Service de paiement Mobile Money.
 *
 * Mode "simulation" (PAYMENT_GATEWAY=simulation dans .env) :
 *   - Initiation : renvoie immédiatement un faux transaction_id
 *   - OTP "1234" → paiement validé, tout autre code → échec
 *   - Permet de tester sans contrat gateway
 *
 * Mode "cinetpay" (PAYMENT_GATEWAY=cinetpay) :
 *   - Appelle l'API CinetPay (https://api-checkout.cinetpay.com)
 *   - Supporte Orange Money BF, Moov Africa BF
 *   - Webhook POST vers /api/payments/webhook pour les callbacks
 *
 * Pour passer en prod : PAYMENT_GATEWAY=cinetpay dans .env Render
 */
class PaymentGatewayService
{
    private string $mode;
    private string $cinetpayApiKey;
    private string $cinetpaySiteId;
    private string $cinetpayBaseUrl;

    public function __construct()
    {
        $this->mode = config('payment.gateway', 'simulation');
        $this->cinetpayApiKey = config('payment.cinetpay_api_key', '');
        $this->cinetpaySiteId = config('payment.cinetpay_site_id', '');
        $this->cinetpayBaseUrl = 'https://api-checkout.cinetpay.com/v2';
    }

    // ─── Initiation ───────────────────────────────────────────────────────────

    /**
     * Initie une demande de paiement Mobile Money.
     * Retourne ['success' => bool, 'message' => string, 'transaction_id' => string|null]
     */
    public function initiate(Payment $payment): array
    {
        return match ($this->mode) {
            'cinetpay' => $this->cinetpayInitiate($payment),
            'simulation' => $this->simulationInitiate($payment),
            default => $this->simulationInitiate($payment),
        };
    }

    /**
     * Vérifie le statut d'un paiement.
     * Retourne ['status' => 'pending'|'completed'|'failed', 'transaction_id' => string|null]
     */
    public function checkStatus(Payment $payment): array
    {
        return match ($this->mode) {
            'cinetpay' => $this->cinetpayCheckStatus($payment),
            'simulation' => $this->simulationCheckStatus($payment),
            default => $this->simulationCheckStatus($payment),
        };
    }

    /**
     * Vérifie un OTP saisi manuellement (flow manuel sans gateway push).
     * Retourne true si l'OTP est valide.
     */
    public function verifyOtp(Payment $payment, string $otp): bool
    {
        if ($this->mode === 'simulation') {
            // En simulation : OTP "1234" ou "000000" → OK
            return in_array($otp, ['1234', '000000', '123456']);
        }

        // En prod : le paiement est validé par webhook → on vérifie juste le statut
        return $payment->isCompleted();
    }

    // ─── Simulation ───────────────────────────────────────────────────────────

    private function simulationInitiate(Payment $payment): array
    {
        // Toujours réussit en simulation
        return [
            'success' => true,
            'message' => "[SIMULATION] Demande envoyée au {$payment->phone} ({$payment->provider})",
            'transaction_id' => 'SIM-' . strtoupper(substr(md5($payment->reference), 0, 8)),
        ];
    }

    private function simulationCheckStatus(Payment $payment): array
    {
        // En simulation : le statut COMPLETED est déjà défini par confirmOtp —
        // on ne relit plus l'OTP brut (il est stocké haché depuis S4).
        if ($payment->isCompleted()) {
            return ['status' => Payment::STATUS_COMPLETED, 'transaction_id' => $payment->operator_transaction_id];
        }

        if ($payment->isExpired()) {
            return ['status' => Payment::STATUS_EXPIRED, 'transaction_id' => null];
        }

        return ['status' => Payment::STATUS_PROCESSING, 'transaction_id' => null];
    }

    // ─── CinetPay ─────────────────────────────────────────────────────────────

    /**
     * Initie un paiement CinetPay (Mobile Money Burkina Faso).
     * Doc: https://developer.cinetpay.com
     */
    private function cinetpayInitiate(Payment $payment): array
    {
        try {
            // Mapping opérateurs → canaux CinetPay
            $channelMap = [
                'orange' => 'MOBILE_MONEY',
                'moov' => 'MOBILE_MONEY',
                'wave' => 'WAVE',
                'telecel' => 'MOBILE_MONEY',
            ];

            $channel = $channelMap[$payment->provider] ?? 'MOBILE_MONEY';

            $response = Http::timeout(15)->post("{$this->cinetpayBaseUrl}/payment", [
                'apikey' => $this->cinetpayApiKey,
                'site_id' => $this->cinetpaySiteId,
                'transaction_id' => $payment->reference,
                'amount' => $payment->amount,
                'currency' => 'XOF',
                'description' => "Commande Noogo #{$payment->order_id}",
                'customer_phone_number' => $payment->phone,
                'channels' => $channel,
                'notify_url' => url('/api/payments/webhook'),
                'return_url' => url('/'),
                'lang' => 'fr',
            ]);

            $data = $response->json();

            if ($response->successful() && isset($data['code']) && $data['code'] === '201') {
                return [
                    'success' => true,
                    'message' => 'Demande de paiement envoyée',
                    'transaction_id' => $data['data']['payment_token'] ?? null,
                    'payment_url' => $data['data']['payment_url'] ?? null,
                ];
            }

            Log::warning('[CinetPay] Initiation échouée', ['response' => $data]);

            return [
                'success' => false,
                'message' => $data['message'] ?? 'Erreur gateway de paiement',
            ];
        } catch (\Throwable $e) {
            Log::error('[CinetPay] Exception initiation', ['error' => $e->getMessage()]);
            return ['success' => false, 'message' => 'Impossible de contacter la gateway de paiement'];
        }
    }

    /**
     * Vérifie le statut d'un paiement CinetPay.
     */
    private function cinetpayCheckStatus(Payment $payment): array
    {
        try {
            $response = Http::timeout(10)->post("{$this->cinetpayBaseUrl}/payment/check", [
                'apikey' => $this->cinetpayApiKey,
                'site_id' => $this->cinetpaySiteId,
                'transaction_id' => $payment->reference,
            ]);

            $data = $response->json();

            if (!$response->successful()) {
                return ['status' => Payment::STATUS_PROCESSING, 'transaction_id' => null];
            }

            $cinetStatus = $data['data']['status'] ?? '';
            $txId = $data['data']['operator_id'] ?? $payment->operator_transaction_id;

            $status = match ($cinetStatus) {
                'ACCEPTED' => Payment::STATUS_COMPLETED,
                'REFUSED', 'FAILED' => Payment::STATUS_FAILED,
                'EXPIRED' => Payment::STATUS_EXPIRED,
                default => Payment::STATUS_PROCESSING,
            };

            return ['status' => $status, 'transaction_id' => $txId, 'raw' => $data];
        } catch (\Throwable $e) {
            Log::error('[CinetPay] Exception check status', ['error' => $e->getMessage()]);
            return ['status' => Payment::STATUS_PROCESSING, 'transaction_id' => null];
        }
    }

    public function getMode(): string
    {
        return $this->mode;
    }
}
