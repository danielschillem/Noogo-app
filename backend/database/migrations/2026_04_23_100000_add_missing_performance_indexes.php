<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Index sur orders.user_id — utilisé par myOrders() (historique client)
        Schema::table('orders', function (Blueprint $table) {
            $table->index('user_id', 'orders_user_id_index');
        });

        // Index sur deliveries.delivery_driver_id — utilisé par myActive() et myHistory() (livreur)
        Schema::table('deliveries', function (Blueprint $table) {
            $table->index('delivery_driver_id', 'deliveries_driver_id_index');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex('orders_user_id_index');
        });

        Schema::table('deliveries', function (Blueprint $table) {
            $table->dropIndex('deliveries_driver_id_index');
        });
    }
};
