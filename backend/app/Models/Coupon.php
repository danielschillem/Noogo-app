<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Coupon extends Model
{
    protected $fillable = [
        'restaurant_id',
        'code',
        'type',
        'value',
        'min_order',
        'max_discount',
        'max_uses',
        'used_count',
        'starts_at',
        'expires_at',
        'is_active',
    ];

    protected $casts = [
        'value' => 'decimal:2',
        'min_order' => 'decimal:2',
        'max_discount' => 'decimal:2',
        'starts_at' => 'datetime',
        'expires_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }

    public function isValid(float $orderTotal): bool
    {
        if (!$this->is_active)
            return false;
        if ($this->starts_at && now()->lt($this->starts_at))
            return false;
        if ($this->expires_at && now()->gt($this->expires_at))
            return false;
        if ($this->max_uses && $this->used_count >= $this->max_uses)
            return false;
        if ($this->min_order && $orderTotal < (float) $this->min_order)
            return false;
        return true;
    }

    public function calculateDiscount(float $orderTotal): float
    {
        $discount = $this->type === 'percentage'
            ? $orderTotal * ((float) $this->value / 100)
            : (float) $this->value;

        if ($this->max_discount) {
            $discount = min($discount, (float) $this->max_discount);
        }

        return round($discount, 2);
    }
}
