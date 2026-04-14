<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Restaurant extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'nom',
        'telephone',
        'adresse',
        'email',
        'logo',
        'description',
        'heures_ouverture',
        'images',
        'is_active',
        'is_open_override',
        'qr_code',
        'latitude',
        'longitude',
    ];

    protected $casts = [
        'images' => 'array',
        'is_active' => 'boolean',
        'is_open_override' => 'boolean',
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    protected $appends = ['logo_url', 'is_open'];

    // Relations
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function categories(): HasMany
    {
        return $this->hasMany(Category::class)->orderBy('ordre');
    }

    public function dishes(): HasMany
    {
        return $this->hasMany(Dish::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function flashInfos(): HasMany
    {
        return $this->hasMany(FlashInfo::class);
    }

    // Accessors
    public function getLogoUrlAttribute(): ?string
    {
        if (!$this->logo) {
            return null;
        }

        if (str_starts_with($this->logo, 'http')) {
            return $this->logo;
        }

        return Storage::url($this->logo);
    }

    public function getIsOpenAttribute(): bool
    {
        // Override manuel prioritaire
        if ($this->is_open_override !== null) {
            return $this->is_open_override;
        }

        if (!$this->heures_ouverture) {
            return false;
        }

        try {
            $now = now();
            $currentTime = $now->format('H:i');
            $timeRanges = explode(',', $this->heures_ouverture);

            foreach ($timeRanges as $range) {
                $times = explode('-', trim($range));
                if (count($times) === 2) {
                    $openTime = trim($times[0]);
                    $closeTime = trim($times[1]);

                    if ($currentTime >= $openTime && $currentTime < $closeTime) {
                        return true;
                    }
                }
            }

            return false;
        } catch (\Exception $e) {
            return false;
        }
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    // Methods
    public function getMenuData(): array
    {
        $categories = $this->categories()
            ->with([
                'dishes' => function ($query) {
                    $query->where('disponibilite', true)->orderBy('ordre');
                }
            ])
            ->where('is_active', true)
            ->get();

        $platsDuJour = $this->dishes()
            ->where('is_plat_du_jour', true)
            ->where('disponibilite', true)
            ->get();

        return [
            'restaurant' => $this,
            'plats_du_jour' => $platsDuJour,
            'menu_par_categories' => $categories->map(function ($category) {
                return [
                    'categorie_id' => $category->id,
                    'categorie_nom' => $category->nom,
                    'categorie_description' => $category->description,
                    'categorie_image' => $category->image_url,
                    'plats' => $category->dishes,
                ];
            }),
        ];
    }
}
