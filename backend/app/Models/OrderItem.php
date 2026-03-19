<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'dish_id',
        'quantity',
        'unit_price',
        'total_price',
        'special_instructions',
    ];

    protected $casts = [
        'unit_price' => 'decimal:2',
        'total_price' => 'decimal:2',
    ];

    protected $appends = ['formatted_total'];

    // Relations
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function dish(): BelongsTo
    {
        return $this->belongsTo(Dish::class);
    }

    // Accessors
    public function getFormattedTotalAttribute(): string
    {
        return number_format($this->total_price, 0, ',', ' ') . ' FCFA';
    }

    // Boot
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($item) {
            if (!$item->unit_price && $item->dish) {
                $item->unit_price = $item->dish->prix;
            }
            $item->total_price = $item->unit_price * $item->quantity;
        });

        static::updating(function ($item) {
            $item->total_price = $item->unit_price * $item->quantity;
        });

        static::saved(function ($item) {
            $item->order->calculateTotal();
        });

        static::deleted(function ($item) {
            $item->order->calculateTotal();
        });
    }
}
