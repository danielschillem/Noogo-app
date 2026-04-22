<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Order extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'restaurant_id',
        'user_id',
        'customer_name',
        'customer_phone',
        'status',
        'order_type',
        'table_number',
        'delivery_address',
        'delivery_lat',
        'delivery_lng',
        'total_amount',
        'payment_method',
        'transaction_id',
        'mobile_money_provider',
        'notes',
        'order_date',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
        'delivery_lat' => 'float',
        'delivery_lng' => 'float',
        'order_date' => 'datetime',
    ];

    protected $appends = ['status_text', 'order_type_text', 'formatted_total'];

    const STATUSES = [
        'pending' => 'En attente',
        'confirmed' => 'Confirmée',
        'preparing' => 'En préparation',
        'ready' => 'Prête',
        'delivered' => 'Livrée',
        'completed' => 'Terminée',
        'cancelled' => 'Annulée',
    ];

    const ORDER_TYPES = [
        'sur_place' => 'Sur place',
        'a_emporter' => 'À emporter',
        'livraison' => 'Livraison',
    ];

    // Relations
    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function delivery(): HasOne
    {
        return $this->hasOne(Delivery::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function ratings(): HasMany
    {
        return $this->hasMany(Rating::class);
    }

    // Accessors
    public function getStatusTextAttribute(): string
    {
        return self::STATUSES[$this->status] ?? $this->status;
    }

    public function getOrderTypeTextAttribute(): string
    {
        return self::ORDER_TYPES[$this->order_type] ?? $this->order_type;
    }

    public function getFormattedTotalAttribute(): string
    {
        return number_format($this->total_amount, 0, ',', ' ') . ' FCFA';
    }

    // Scopes
    public function scopeForRestaurant($query, $restaurantId)
    {
        return $query->where('restaurant_id', $restaurantId);
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeToday($query)
    {
        return $query->whereDate('order_date', today());
    }

    public function scopeStatus($query, $status)
    {
        return $query->where('status', $status);
    }

    // Methods
    public function calculateTotal(): void
    {
        $this->total_amount = $this->items->sum('total_price');
        $this->save();
    }

    public function updateStatus(string $status): void
    {
        if (array_key_exists($status, self::STATUSES)) {
            $this->update(['status' => $status]);
        }
    }

    public function canBeCancelled(): bool
    {
        return in_array($this->status, ['pending', 'confirmed']);
    }
}
