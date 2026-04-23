<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OralOrderNoteItem extends Model
{
    protected $fillable = [
        'oral_order_note_id',
        'dish_id',
        'quantity',
        'dish_nom_snapshot',
        'unit_price_snapshot',
    ];

    protected $casts = [
        'unit_price_snapshot' => 'decimal:2',
    ];

    public function oralOrderNote(): BelongsTo
    {
        return $this->belongsTo(OralOrderNote::class);
    }

    public function dish(): BelongsTo
    {
        return $this->belongsTo(Dish::class);
    }
}
