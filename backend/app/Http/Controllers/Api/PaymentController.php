<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Payment;
use App\Services\PaymentGatewayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class PaymentController extends Controller
{
    public function __construct(private readonly PaymentGatewayService $gateway)
    {
    }

    // ─── POST /api/payments/initiate ─────────────────────────────────────────
    // Crée un enregistrement de paiement et demande l'initiation à la gateway.

    public function initiate(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'restaurant_id' => 'required|integer|exists:restaurants,id',
            'order_id' => 'nullable|integer|exists:orders,id',
            'provider' => 'required|in:orange,moov,telecel,wave,cash',
            'phone' => 'required|string|max:20',
            'amount' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Si la commande est déjà reliée à un paiement en cours, le retourner
        if ($request->order_id) {
            $existing = Payment::where('order_id', $request->order_id)
                ->whereIn('status', [Payment::STATUS_PENDING, Payment::STATUS_PROCESSING])
                ->latest()
                ->first();

            if ($existing && !$existing->isExpired()) {
                return response()->json([
                    'success' => true,
                    'message' => 'Paiement déjà en cours',
                    'data' => $this->formatPayment($existing),
                ]);
            }

            // ── C2 : Vérification que le montant = total de la commande ────────
            $order = \App\Models\Order::find($request->order_id);
            if ($order && $order->total_amount !== null) {
                $expected = (int) round((float) $order->total_amount);
                if ($request->amount !== $expected) {
                    Log::warning('[Payment] Montant invalide', [
                        'order_id' => $request->order_id,
                        'expected' => $expected,
                        'received' => $request->amount,
                    ]);
                    return response()->json([
                        'success' => false,
                        'message' => 'Le montant ne correspond pas au total de la commande.',
                    ], 422);
                }
            }
        }

        $payment = Payment::create([
            'order_id' => $request->order_id,
            'restaurant_id' => $request->restaurant_id,
            'provider' => $request->provider,
            'status' => Payment::STATUS_PENDING,
            'phone' => $request->phone,
            'amount' => $request->amount,
            'reference' => Payment::generateReference(),
            'expires_at' => now()->addMinutes(config('payment.payment_ttl_minutes', 15)),
        ]);

        // Appel gateway
        if ($request->provider === 'cash') {
            $payment->update(['status' => Payment::STATUS_COMPLETED, 'confirmed_at' => now()]);
            return response()->json([
                'success' => true,
                'message' => 'Paiement espèces enregistré',
                'data' => $this->formatPayment($payment->fresh()),
            ], 201);
        }

        $result = $this->gateway->initiate($payment);

        if (!$result['success']) {
            $payment->update(['status' => Payment::STATUS_FAILED]);
            return response()->json([
                'success' => false,
                'message' => $result['message'] ?? 'Erreur paiement',
            ], 502);
        }

        $payment->update([
            'status' => Payment::STATUS_PROCESSING,
            'operator_transaction_id' => $result['transaction_id'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => $result['message'] ?? 'Demande de paiement envoyée',
            'data' => $this->formatPayment($payment->fresh()),
            'mode' => $this->gateway->getMode(),
        ], 201);
    }

    // ─── POST /api/payments/{payment}/confirm-otp ─────────────────────────────
    // Flow OTP manuel : le client saisit le code reçu par USSD.

    public function confirmOtp(Request $request, Payment $payment): JsonResponse
    {
        if (!$payment->isActive()) {
            return response()->json([
                'success' => false,
                'message' => 'Ce paiement n\'est plus actif (statut: ' . $payment->status . ')',
            ], 422);
        }

        if ($payment->expires_at && now()->isAfter($payment->expires_at)) {
            $payment->update(['status' => Payment::STATUS_EXPIRED]);
            return response()->json([
                'success' => false,
                'message' => 'Le paiement a expiré. Veuillez recommencer.',
            ], 422);
        }

        $validator = Validator::make($request->all(), [
            'otp' => 'required|string|min:4|max:10',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Code OTP invalide',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Ne pas persister l'OTP ici :
        // - le flux de validation repose sur la gateway / logique verifyOtp
        // - evite les erreurs SQL sur anciens schemas (otp_code trop court)
        $valid = $this->gateway->verifyOtp($payment, $request->otp);

        if (!$valid) {
            return response()->json([
                'success' => false,
                'message' => 'Code OTP incorrect. Vérifiez et réessayez.',
            ], 422);
        }

        $payment->update([
            'status' => Payment::STATUS_COMPLETED,
            'confirmed_at' => now(),
        ]);

        // Marquer la commande comme payée si elle existe
        if ($payment->order_id) {
            Order::where('id', $payment->order_id)
                ->update([
                    'transaction_id' => $payment->reference,
                    'mobile_money_provider' => $payment->provider,
                ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Paiement confirmé avec succès',
            'data' => $this->formatPayment($payment->fresh()),
        ]);
    }

    // ─── GET /api/payments/{payment}/status ───────────────────────────────────
    // Polling : Flutter appelle cet endpoint toutes les 3-5 secondes.

    public function status(Payment $payment): JsonResponse
    {
        // Vérifier l'expiration
        if ($payment->isActive() && $payment->expires_at && now()->isAfter($payment->expires_at)) {
            $payment->update(['status' => Payment::STATUS_EXPIRED]);
        }

        // En mode gateway réelle, interroger la gateway si toujours en cours
        if ($payment->isProcessing() && $this->gateway->getMode() !== 'simulation') {
            $result = $this->gateway->checkStatus($payment);

            if ($result['status'] !== $payment->status) {
                $update = ['status' => $result['status']];
                if ($result['transaction_id']) {
                    $update['operator_transaction_id'] = $result['transaction_id'];
                }
                if ($result['status'] === Payment::STATUS_COMPLETED) {
                    $update['confirmed_at'] = now();
                    if ($payment->order_id) {
                        Order::where('id', $payment->order_id)->update([
                            'transaction_id' => $payment->reference,
                            'mobile_money_provider' => $payment->provider,
                        ]);
                    }
                }
                $payment->update($update);
            }
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatPayment($payment->fresh()),
        ]);
    }

    // ─── POST /api/payments/webhook ───────────────────────────────────────────
    // Callback CinetPay / opérateur. CSRF exclu via routes/api.php.

    public function webhook(Request $request): JsonResponse
    {
        Log::info('[Payment Webhook]', $request->all());

        // ── C1 : Vérification signature HMAC CinetPay ─────────────────────────
        if (config('payment.webhook_verify_signature') && config('payment.gateway') !== 'simulation') {
            $siteId = config('payment.cinetpay_site_id');
            $apiKey = config('payment.cinetpay_api_key');
            $transId = $request->input('cpm_trans_id', '');
            $amount = $request->input('cpm_amount', '');
            $currency = $request->input('cpm_currency', '');
            $expected = strtoupper(hash('sha256', $siteId . $apiKey . $transId . $amount . $currency));
            $received = (string) $request->input('cpm_pass', '');
            if (!hash_equals($expected, $received)) {
                Log::warning('[Payment Webhook] Signature invalide', ['ip' => $request->ip()]);
                return response()->json(['message' => 'invalid signature'], 403);
            }
            if ($request->input('cpm_site_id') !== $siteId) {
                Log::warning('[Payment Webhook] site_id inconnu', ['received' => $request->input('cpm_site_id')]);
                return response()->json(['message' => 'invalid site_id'], 403);
            }
        }

        $reference = $request->input('cpm_trans_id')    // CinetPay
            ?? $request->input('transaction_id')
            ?? $request->input('reference');

        if (!$reference) {
            return response()->json(['message' => 'reference missing'], 400);
        }

        $payment = Payment::where('reference', $reference)->first();

        if (!$payment) {
            Log::warning('[Payment Webhook] Paiement introuvable', ['reference' => $reference]);
            return response()->json(['message' => 'payment not found'], 404);
        }

        // Statut CinetPay
        $cpmResultSite = $request->input('cpm_result', '');
        $operatorTxId = $request->input('cpm_payid') ?? $request->input('cpm_trans_id');

        if ($cpmResultSite === '00') {
            $payment->update([
                'status' => Payment::STATUS_COMPLETED,
                'operator_transaction_id' => $operatorTxId,
                'confirmed_at' => now(),
                'gateway_response' => $request->all(),
            ]);

            if ($payment->order_id) {
                Order::where('id', $payment->order_id)->update([
                    'transaction_id' => $payment->reference,
                    'mobile_money_provider' => $payment->provider,
                ]);
            }
        } elseif (in_array($cpmResultSite, ['', null], false) === false) {
            $payment->update([
                'status' => Payment::STATUS_FAILED,
                'gateway_response' => $request->all(),
            ]);
        }

        return response()->json(['message' => 'ok']);
    }

    // ─── DELETE /api/payments/{payment} ──────────────────────────────────────
    // Annulation par le client.

    public function cancel(Payment $payment): JsonResponse
    {
        if (!$payment->isActive()) {
            return response()->json([
                'success' => false,
                'message' => 'Ce paiement ne peut pas être annulé (statut: ' . $payment->status . ')',
            ], 422);
        }

        $payment->update(['status' => Payment::STATUS_CANCELLED]);

        return response()->json(['success' => true, 'message' => 'Paiement annulé']);
    }

    // ─── Format ───────────────────────────────────────────────────────────────

    private function formatPayment(Payment $payment): array
    {
        return [
            'id' => $payment->id,
            'reference' => $payment->reference,
            'status' => $payment->status,
            'provider' => $payment->provider,
            'phone' => $payment->phone,
            'amount' => $payment->amount,
            'operator_transaction_id' => $payment->operator_transaction_id,
            'confirmed_at' => $payment->confirmed_at?->toIso8601String(),
            'expires_at' => $payment->expires_at?->toIso8601String(),
            'created_at' => $payment->created_at->toIso8601String(),
        ];
    }
}
