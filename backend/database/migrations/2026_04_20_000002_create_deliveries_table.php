<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('deliveries', function (Blueprint $table) {
            $table->id();

            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->foreignId('delivery_driver_id')->nullable()->constrained('delivery_drivers')->onDelete('set null');

            // Cycle de vie : pending_assignment → assigned → picked_up → on_way → delivered | failed
            $table->enum('status', [
                'pending_assignment',
                'assigned',
                'picked_up',
                'on_way',
                'delivered',
                'failed',
            ])->default('pending_assignment');

            // Timestamps métier
            $table->timestamp('assigned_at')->nullable();
            $table->timestamp('picked_up_at')->nullable();
            $table->timestamp('on_way_at')->nullable();
            $table->timestamp('delivered_at')->nullable();

            // Dernière position GPS du livreur (mise à jour en temps réel)
            $table->decimal('driver_lat', 10, 7)->nullable();
            $table->decimal('driver_lng', 10, 7)->nullable();
            $table->timestamp('driver_location_at')->nullable();

            // Position de livraison demandée par le client
            $table->decimal('client_lat', 10, 7)->nullable();
            $table->decimal('client_lng', 10, 7)->nullable();
            $table->string('client_address')->nullable();

            // Métriques
            $table->decimal('distance_km', 8, 3)->nullable();
            $table->decimal('fee', 10, 2)->default(0);

            $table->text('notes')->nullable();
            $table->text('failure_reason')->nullable();

            $table->timestamps();
            $table->softDeletes();

            // Un ordre ne peut avoir qu'une livraison active à la fois
            $table->unique('order_id');

            // Index fréquents
            $table->index('status');
            $table->index('delivery_driver_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('deliveries');
    }
};
