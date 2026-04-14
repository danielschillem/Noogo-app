<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('restaurant_staff', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('restaurant_id')->constrained()->onDelete('cascade');
            // owner = proprio du resto (géré par user_id sur restaurants)
            // manager = gérant (menu, catégories, plats, commandes)
            // cashier = caissier (commandes + paiements)
            // waiter = serveur (commandes de sa table seulement)
            $table->enum('role', ['owner', 'manager', 'cashier', 'waiter'])->default('waiter');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            // Un utilisateur ne peut avoir qu'un seul rôle par restaurant
            $table->unique(['user_id', 'restaurant_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('restaurant_staff');
    }
};
