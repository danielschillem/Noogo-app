<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('oral_order_note_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('oral_order_note_id')->constrained('oral_order_notes')->cascadeOnDelete();
            $table->foreignId('dish_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedInteger('quantity')->default(1);
            $table->string('dish_nom_snapshot');
            $table->decimal('unit_price_snapshot', 12, 2);
            $table->timestamps();

            $table->index('oral_order_note_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('oral_order_note_items');
    }
};
