<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class Payment extends Model
{
    protected $fillable = [
        'order_id',
        'restaurant_id',
        'provider',
        'status',
        'phone',
        'amount',
        'reference',
        'operator_transaction_id',
        'otp_code',
        'gateway_response',
        'confirmed_at',
        'expires_at',
    ];

    protected $casts = [
        'amount' => 'integer',
        'gateway_response' => 'array',
        'confirmed_at' => 'datetime',
        'expires_at' => 'datetime',
    ];

    // ─── Statuts ─────────────────────────────────────────────────────────────

    public const STATUS_PENDING = 'pending';
    public const STATUS_PROCESSING = 'processing';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_FAILED = 'failed';
    public const STATUS_EXPIRED = 'expired';
    public const STATUS_CANCELLED = 'cancelled';

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }
    public function isProcessing(): bool
    {
        return $this->status === self::STATUS_PROCESSING;
    }
    public function isCompleted(): bool
    {
        return $this->status === self::STATUS_COMPLETED;
    }
    public function isFailed(): bool
    {
        return $this->status === self::STATUS_FAILED;
    }
    public function isExpired(): bool
    {
        return $this->status === self::STATUS_EXPIRED;
    }

    public function isActive(): bool
    {
        return in_array($this->status, [self::STATUS_PENDING, self::STATUS_PROCESSING]);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    public static function generateReference(): string
    {
        return 'NGO-' . strtoupper(Str::random(8)) . '-' . now()->format('ymdHi');
    }

    // ─── Relations ────────────────────────────────────────────────────────────

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }
}
