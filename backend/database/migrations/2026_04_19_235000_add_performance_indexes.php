<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->index(['restaurant_id', 'order_date']);
            $table->index(['restaurant_id', 'status']);
            $table->index('order_date');
        });

        Schema::table('dishes', function (Blueprint $table) {
            $table->index(['restaurant_id', 'disponibilite']);
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex(['restaurant_id', 'order_date']);
            $table->dropIndex(['restaurant_id', 'status']);
            $table->dropIndex(['order_date']);
        });

        Schema::table('dishes', function (Blueprint $table) {
            $table->dropIndex(['restaurant_id', 'disponibilite']);
        });
    }
};
