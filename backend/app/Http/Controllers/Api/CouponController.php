<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CouponController extends Controller
{
    /**
     * POST /api/coupons/validate
     * Valide un code promo pour un restaurant et un montant donnés.
     */
    public function validate(Request $request): JsonResponse
    {
        $request->validate([
            'code' => 'required|string|max:50',
            'restaurant_id' => 'required|integer|exists:restaurants,id',
            'order_total' => 'required|numeric|min:0',
        ]);

        $coupon = Coupon::where('restaurant_id', $request->restaurant_id)
            ->where('code', strtoupper(trim($request->code)))
            ->first();

        if (!$coupon) {
            return response()->json([
                'success' => false,
                'message' => 'Code promo invalide.',
            ], 422);
        }

        if (!$coupon->isValid((float) $request->order_total)) {
            $reason = 'Ce code promo n\'est pas valide.';
            if ($coupon->min_order && (float) $request->order_total < (float) $coupon->min_order) {
                $reason = "Commande minimum de {$coupon->min_order} FCFA requise.";
            } elseif ($coupon->expires_at && now()->gt($coupon->expires_at)) {
                $reason = 'Ce code promo a expiré.';
            } elseif ($coupon->max_uses && $coupon->used_count >= $coupon->max_uses) {
                $reason = 'Ce code promo a atteint sa limite d\'utilisation.';
            }

            return response()->json([
                'success' => false,
                'message' => $reason,
            ], 422);
        }

        $discount = $coupon->calculateDiscount((float) $request->order_total);

        return response()->json([
            'success' => true,
            'message' => 'Code promo valide !',
            'data' => [
                'coupon_id' => $coupon->id,
                'code' => $coupon->code,
                'type' => $coupon->type,
                'value' => $coupon->value,
                'discount' => $discount,
                'new_total' => max(0, (float) $request->order_total - $discount),
            ],
        ]);
    }
}
