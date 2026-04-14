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
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('restaurant_id')->constrained()->onDelete('cascade');
            // orange | moov | telecel | wave | cash
            $table->string('provider', 30);
            // pending | processing | completed | failed | expired | cancelled
            $table->string('status', 20)->default('pending');
            $table->string('phone', 20);           // numéro du payeur
            $table->decimal('amount', 12, 0);      // FCFA (entier)
            // Référence interne unique (envoyée à la gateway)
            $table->string('reference')->unique();
            // Identifiant renvoyé par l'opérateur/gateway (transaction côté opérateur)
            $table->string('operator_transaction_id')->nullable();
            // OTP saisi par le client (pour flow manuel)
            $table->string('otp_code', 10)->nullable();
            // Infos retournées par la gateway (corps du webhook ou réponse polling)
            $table->json('gateway_response')->nullable();
            // Horodatage de la confirmation
            $table->timestamp('confirmed_at')->nullable();
            // Expiration du paiement (15 min après création)
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'provider']);
            $table->index('reference');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
