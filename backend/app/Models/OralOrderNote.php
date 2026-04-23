<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OralOrderNote extends Model
{
    protected $fillable = [
        'restaurant_id',
        'user_id',
        'status',
        'title',
        'staff_comment',
        'validated_at',
        'converted_order_id',
    ];

    protected $casts = [
        'validated_at' => 'datetime',
    ];

    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function convertedOrder(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'converted_order_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(OralOrderNoteItem::class)->orderBy('id');
    }

    public function isDraft(): bool
    {
        return $this->status === 'draft';
    }

    public function isValidated(): bool
    {
        return $this->status === 'validated';
    }
}
