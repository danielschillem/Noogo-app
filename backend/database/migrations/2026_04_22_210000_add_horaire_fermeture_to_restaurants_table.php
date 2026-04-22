<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Ajoute la colonne horaire_fermeture à la table restaurants.
 * Utilisée par la tâche planifiée auto-close-restaurants (routes/console.php).
 * Format attendu : 'HH:MM' (ex. '22:00').
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('restaurants', function (Blueprint $table): void {
            $table->string('horaire_fermeture', 5)->nullable()->after('heures_ouverture')
                ->comment('Heure de fermeture auto au format HH:MM (ex. 22:00)');
        });
    }

    public function down(): void
    {
        Schema::table('restaurants', function (Blueprint $table): void {
            $table->dropColumn('horaire_fermeture');
        });
    }
};
