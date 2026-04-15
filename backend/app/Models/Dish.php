<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class Dish extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'restaurant_id',
        'category_id',
        'nom',
        'description',
        'prix',
        'images',
        'disponibilite',
        'is_plat_du_jour',
        'temps_preparation',
        'ordre',
    ];

    protected $casts = [
        'prix' => 'decimal:2',
        'images' => 'array',
        'disponibilite' => 'boolean',
        'is_plat_du_jour' => 'boolean',
    ];

    protected $appends = ['image_url', 'formatted_price', 'categorie'];

    // Relations
    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    // Accessors
    public function getImageUrlAttribute(): ?string
    {
        if (!$this->images || empty($this->images)) {
            return null;
        }

        $firstImage = is_array($this->images) ? ($this->images[0] ?? null) : $this->images;

        if (!$firstImage) {
            return null;
        }

        if (str_starts_with($firstImage, 'http')) {
            return $firstImage;
        }

        // Use R2 when configured, otherwise fall back to public disk
        $disk = config('filesystems.disks.r2.endpoint') ? 'r2' : 'public';

        return Storage::disk($disk)->url($firstImage);
    }

    public function getFormattedPriceAttribute(): string
    {
        return number_format($this->prix, 0, ',', ' ') . ' FCFA';
    }

    public function getCategorieAttribute(): string
    {
        return $this->category?->nom ?? '';
    }

    // Scopes
    public function scopeAvailable($query)
    {
        return $query->where('disponibilite', true);
    }

    public function scopePlatDuJour($query)
    {
        return $query->where('is_plat_du_jour', true);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('ordre');
    }

    public function scopeForCategory($query, $categoryId)
    {
        return $query->where('category_id', $categoryId);
    }
}
