<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('restaurants', function (Blueprint $table) {
            // null = utiliser les heures d'ouverture, true = forcé ouvert, false = forcé fermé
            $table->boolean('is_open_override')->nullable()->default(null)->after('is_active');
        });
    }

    public function down(): void
    {
        Schema::table('restaurants', function (Blueprint $table) {
            $table->dropColumn('is_open_override');
        });
    }
};
