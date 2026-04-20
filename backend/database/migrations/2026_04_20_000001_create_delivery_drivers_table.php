<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('delivery_drivers', function (Blueprint $table) {
            $table->id();

            // Lien optionnel vers un compte utilisateur (rôle driver)
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('set null');

            // Identité du livreur
            $table->string('name');
            $table->string('phone', 20);
            $table->string('zone')->nullable();         // zone géographique de livraison

            // Statut opérationnel
            $table->enum('status', ['available', 'busy', 'offline'])->default('offline');

            // Dernière position GPS connue
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->timestamp('last_location_at')->nullable();

            // Token FCM pour les notifications push
            $table->string('fcm_token')->nullable();

            $table->timestamps();
            $table->softDeletes();

            // Index pour les requêtes fréquentes
            $table->index('status');
            $table->index('zone');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_drivers');
    }
};
