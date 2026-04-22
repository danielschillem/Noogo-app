<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Models\Restaurant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CouponController extends Controller
{
    // ─── CRUD (restaurant owner / staff with manageMenu) ────────────────────

    /**
     * GET /api/restaurants/{restaurant}/coupons
     */
    public function index(Restaurant $restaurant): JsonResponse
    {
        $this->authorize('manageMenu', $restaurant);

        $coupons = $restaurant->coupons()->latest()->get();

        return response()->json(['success' => true, 'data' => $coupons]);
    }

    /**
     * POST /api/restaurants/{restaurant}/coupons
     */
    public function store(Request $request, Restaurant $restaurant): JsonResponse
    {
        $this->authorize('manageMenu', $restaurant);

        $validated = $request->validate([
            'code' => 'required|string|max:50|alpha_dash|uppercase',
            'type' => 'required|in:percentage,fixed',
            'value' => 'required|numeric|min:0',
            'min_order' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'max_uses' => 'nullable|integer|min:1',
            'starts_at' => 'nullable|date',
            'expires_at' => 'nullable|date|after_or_equal:starts_at',
            'is_active' => 'boolean',
        ]);

        if (
            Coupon::where('restaurant_id', $restaurant->id)
                ->where('code', strtoupper(trim($validated['code'])))
                ->exists()
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Ce code promo existe déjà pour ce restaurant.',
            ], 422);
        }

        $coupon = $restaurant->coupons()->create(array_merge($validated, [
            'code' => strtoupper(trim($validated['code'])),
        ]));

        return response()->json(['success' => true, 'data' => $coupon], 201);
    }

    /**
     * PUT /api/restaurants/{restaurant}/coupons/{coupon}
     */
    public function update(Request $request, Restaurant $restaurant, Coupon $coupon): JsonResponse
    {
        $this->authorize('manageMenu', $restaurant);
        abort_if($coupon->restaurant_id !== $restaurant->id, 404);

        $validated = $request->validate([
            'code' => 'sometimes|string|max:50|alpha_dash|uppercase',
            'type' => 'sometimes|in:percentage,fixed',
            'value' => 'sometimes|numeric|min:0',
            'min_order' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'max_uses' => 'nullable|integer|min:1',
            'starts_at' => 'nullable|date',
            'expires_at' => 'nullable|date',
            'is_active' => 'boolean',
        ]);

        if (isset($validated['code'])) {
            $validated['code'] = strtoupper(trim($validated['code']));
            $duplicate = Coupon::where('restaurant_id', $restaurant->id)
                ->where('code', $validated['code'])
                ->where('id', '!=', $coupon->id)
                ->exists();
            if ($duplicate) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce code promo existe déjà pour ce restaurant.',
                ], 422);
            }
        }

        $coupon->update($validated);

        return response()->json(['success' => true, 'data' => $coupon]);
    }

    /**
     * DELETE /api/restaurants/{restaurant}/coupons/{coupon}
     */
    public function destroy(Restaurant $restaurant, Coupon $coupon): JsonResponse
    {
        $this->authorize('manageMenu', $restaurant);
        abort_if($coupon->restaurant_id !== $restaurant->id, 404);

        $coupon->delete();

        return response()->json(['success' => true]);
    }

    /**
     * POST /api/restaurants/{restaurant}/coupons/{coupon}/toggle-active
     */
    public function toggleActive(Restaurant $restaurant, Coupon $coupon): JsonResponse
    {
        $this->authorize('manageMenu', $restaurant);
        abort_if($coupon->restaurant_id !== $restaurant->id, 404);

        $coupon->update(['is_active' => !$coupon->is_active]);

        return response()->json(['success' => true, 'data' => $coupon]);
    }

    // ─── Validation publique (app mobile Flutter) ───────────────────────────

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
