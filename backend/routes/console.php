<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// ── Tâches planifiées ──────────────────────────────────────────────────

// Nettoyer les tokens de réinitialisation expirés (> 60 min)
Schedule::call(function () {
    $deleted = DB::table('password_reset_tokens')
        ->where('created_at', '<', now()->subMinutes(60))
        ->delete();
    if ($deleted > 0)
        Log::info("Nettoyage: $deleted token(s) reset expiré(s) supprimé(s)");
})->hourly()->name('cleanup-reset-tokens');

// Fermer auto les restaurants qui dépassent l'heure de fermeture
Schedule::call(function () {
    // Guard: colonne ajoutée par migration 2026_04_22_210000 — ignorer si absente
    if (!\Illuminate\Support\Facades\Schema::hasColumn('restaurants', 'horaire_fermeture')) {
        return;
    }
    $count = \App\Models\Restaurant::where('is_active', true)
        ->whereNotNull('horaire_fermeture')
        ->whereRaw("horaire_fermeture <= ?", [now()->format('H:i')])
        ->where('is_open_override', true)
        ->update(['is_open_override' => false]);
    if ($count > 0)
        Log::info("Auto-fermeture: $count restaurant(s)");
})->everyFiveMinutes()->name('auto-close-restaurants');

// Nettoyer les anciennes notifications de livraison terminées depuis 7 jours
Schedule::call(function () {
    $count = \App\Models\Delivery::whereIn('status', ['delivered', 'failed'])
        ->where('updated_at', '<', now()->subDays(30))
        ->whereNotNull('driver_lat')
        ->update(['driver_lat' => null, 'driver_lng' => null]);
    if ($count > 0)
        Log::info("Nettoyage GPS: $count livraison(s)");
})->daily()->name('cleanup-delivery-gps');

// Relancer le traitement des jobs échoués
Schedule::command('queue:retry all')->daily()->name('retry-failed-jobs');
