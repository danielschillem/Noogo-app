<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class FlashInfo extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'restaurant_id',
        'titre',
        'description',
        'image',
        'type',
        'reduction_percentage',
        'prix_special',
        'date_debut',
        'date_fin',
        'is_active',
    ];

    protected $casts = [
        'reduction_percentage' => 'decimal:2',
        'prix_special' => 'decimal:2',
        'date_debut' => 'date',
        'date_fin' => 'date',
        'is_active' => 'boolean',
    ];

    protected $appends = ['image_url', 'is_valid'];

    const TYPES = [
        'promotion' => 'Promotion',
        'info' => 'Information',
        'event' => 'Événement',
        'offre' => 'Offre Spéciale',
    ];

    // Relations
    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }

    // Accessors
    public function getImageUrlAttribute(): ?string
    {
        if (!$this->image) {
            return null;
        }

        if (str_starts_with($this->image, 'http')) {
            return $this->image;
        }

        return Storage::url($this->image);
    }

    public function getIsValidAttribute(): bool
    {
        if (!$this->is_active) {
            return false;
        }

        $today = Carbon::today();

        if ($this->date_debut && $today->lt($this->date_debut)) {
            return false;
        }

        if ($this->date_fin && $today->gt($this->date_fin)) {
            return false;
        }

        return true;
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeValid($query)
    {
        $today = Carbon::today();
        
        return $query->where('is_active', true)
            ->where(function ($q) use ($today) {
                $q->whereNull('date_debut')
                    ->orWhere('date_debut', '<=', $today);
            })
            ->where(function ($q) use ($today) {
                $q->whereNull('date_fin')
                    ->orWhere('date_fin', '>=', $today);
            });
    }

    public function scopeForRestaurant($query, $restaurantId)
    {
        return $query->where('restaurant_id', $restaurantId);
    }
}
