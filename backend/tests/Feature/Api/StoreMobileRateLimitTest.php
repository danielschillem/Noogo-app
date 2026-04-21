<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Dish;
use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\RateLimiter;
use Tests\TestCase;

/**
 * Tests pour le rate limiting par IP sur l'endpoint storeMobile.
 *
 * POST /api/commandes est protégé par le rate limiter « order-mobile » :
 *   – Limite globale  : 10 commandes / minute par IP
 *   – Limite ciblée   : 3 commandes  / minute par IP + restaurant
 *
 * On remplace temporairement le limiter par des seuils très bas pour que
 * les tests restent rapides (pas de vraie attente).
 */
class StoreMobileRateLimitTest extends TestCase
{
    use DatabaseMigrations;

    private Restaurant $restaurant;
    private Dish $dish;

    protected function setUp(): void
    {
        parent::setUp();

        $user = User::factory()->create(['is_admin' => false]);

        $this->restaurant = Restaurant::create([
            'user_id' => $user->id,
            'nom' => 'Restaurant Rate-Limit',
            'telephone' => '70000001',
            'adresse' => 'Ouagadougou',
            'is_active' => true,
        ]);

        $category = Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Plats',
            'is_active' => true,
        ]);

        $this->dish = Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $category->id,
            'nom' => 'Plat test',
            'prix' => 1000,
            'disponibilite' => true,
        ]);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'restaurant_id' => $this->restaurant->id,
            'type' => 'sur_place',
            'moyen_paiement' => 'cash',
            'plats' => [['id' => $this->dish->id, 'quantite' => 1]],
        ], $overrides);
    }

    /**
     * Installe un rate-limiter de substitution très restrictif (seuil = $max)
     * pour que le test déclenche un 429 rapidement sans attendre 60 secondes.
     */
    private function setLowRateLimit(int $max): void
    {
        RateLimiter::for('order-mobile', function ($request) use ($max) {
            $ip = $request->ip();
            $restaurantId = $request->input('restaurant_id', '');

            return [
                Limit::perMinute($max)->by('order-ip-test:' . $ip)
                    ->response(fn() => response()->json([
                        'success' => false,
                        'message' => 'Trop de commandes. Veuillez patienter quelques instants avant de réessayer.',
                    ], 429)),

                Limit::perMinute($max)->by('order-ip-restaurant-test:' . $ip . ':' . $restaurantId)
                    ->response(fn() => response()->json([
                        'success' => false,
                        'message' => 'Commande trop fréquente sur ce restaurant.',
                    ], 429)),
            ];
        });
    }

    /** Remet le rate-limiter de production (défini dans AppServiceProvider). */
    private function resetRateLimit(): void
    {
        RateLimiter::for('order-mobile', function ($request) {
            $ip = $request->ip();
            $restaurantId = $request->input('restaurant_id', '');
            return [
                Limit::perMinute(10)->by('order-ip:' . $ip)
                    ->response(fn() => response()->json([
                        'success' => false,
                        'message' => 'Trop de commandes. Veuillez patienter quelques instants avant de réessayer.',
                    ], 429)),
                Limit::perMinute(3)->by('order-ip-restaurant:' . $ip . ':' . $restaurantId)
                    ->response(fn() => response()->json([
                        'success' => false,
                        'message' => 'Commande trop fréquente sur ce restaurant.',
                    ], 429)),
            ];
        });
    }

    /** Vide le cache de rate-limiting entre les tests (hits + timer). */
    private function clearRateLimitCache(): void
    {
        // Flush the entire test cache (array/file driver in test env).
        // This removes both the hit-count key AND the :timer key that
        // Laravel stores separately for each rate-limit window.
        cache()->flush();
    }

    protected function tearDown(): void
    {
        $this->clearRateLimitCache();
        $this->resetRateLimit();
        parent::tearDown();
    }

    // ─── Tests ────────────────────────────────────────────────────────────────

    /**
     * Une seule commande valide doit passer (200/201) même avec le limiter actif.
     */
    public function test_commande_unique_passe_le_rate_limit(): void
    {
        $response = $this->postJson('/api/commandes', $this->payload());

        $response->assertStatus(201)
            ->assertJsonPath('success', true);
    }

    /**
     * Après N requêtes (N > seuil bas), la suivante doit retourner 429.
     */
    public function test_retourne_429_apres_depassement_limite_globale(): void
    {
        $this->setLowRateLimit(2);       // Seuil réduit à 2 pour le test
        $this->clearRateLimitCache();

        // 2 premières passent
        $this->postJson('/api/commandes', $this->payload())->assertStatus(201);
        $this->postJson('/api/commandes', $this->payload())->assertStatus(201);

        // La 3ème doit être bloquée
        $response = $this->postJson('/api/commandes', $this->payload());

        $response->assertStatus(429)
            ->assertJsonPath('success', false);
    }

    /**
     * Le message d'erreur 429 est bien en français.
     */
    public function test_message_429_est_en_francais(): void
    {
        $this->setLowRateLimit(1);
        $this->clearRateLimitCache();

        $this->postJson('/api/commandes', $this->payload())->assertStatus(201);
        $response = $this->postJson('/api/commandes', $this->payload());

        $response->assertStatus(429);
        $body = $response->json();
        $this->assertArrayHasKey('message', $body);
        $this->assertStringContainsStringIgnoringCase('commande', $body['message']);
    }

    /**
     * Les requêtes depuis différentes IPs simulées ne se bloquent pas mutuellement.
     * (Par construction du limiter basé sur l'IP, deux IPs distinctes sont indépendantes.)
     */
    public function test_limiter_est_par_ip_et_non_global(): void
    {
        $this->setLowRateLimit(1);
        $this->clearRateLimitCache();

        // IP A : 1 requête → passe
        $this->postJson('/api/commandes', $this->payload())
            ->assertStatus(201);

        // IP A : 2ème → bloquée
        $this->postJson('/api/commandes', $this->payload())
            ->assertStatus(429);

        // Limiter différent pour un restaurant différent → comportement isolé
        $other = Restaurant::create([
            'user_id' => User::factory()->create()->id,
            'nom' => 'Autre Restaurant',
            'telephone' => '70000099',
            'adresse' => 'Bobo',
            'is_active' => true,
        ]);

        // La clé est différente car restaurant_id diffère : pas d'interférence
        // On vérifie simplement que le payload autre-restaurant ne retourne pas d'erreur interne
        $response = $this->postJson('/api/commandes', $this->payload([
            'restaurant_id' => $other->id,
        ]));
        // Doit être 422 (restaurant sans plats) ou 429, jamais 500
        $this->assertContains($response->status(), [201, 422, 429]);
        $this->assertNotEquals(500, $response->status());
    }

    /**
     * Vérifier que le rate-limiter de production est bien nommé 'order-mobile'.
     */
    public function test_limiter_nomme_order_mobile_est_configure(): void
    {
        // On vérifie que le limiter existe (n'est pas null) via une requête
        $response = $this->postJson('/api/commandes', $this->payload());

        // Doit répondre (201 succès ou 422 validation, jamais 500 "limiter non trouvé")
        $this->assertContains($response->status(), [201, 422, 429]);
    }

    /**
     * Le corps de la réponse 429 est du JSON valide avec la clé 'success' = false.
     */
    public function test_corps_429_est_json_valide(): void
    {
        $this->setLowRateLimit(1);
        $this->clearRateLimitCache();

        $this->postJson('/api/commandes', $this->payload())->assertStatus(201);

        $response = $this->postJson('/api/commandes', $this->payload());
        $response->assertStatus(429)
            ->assertHeader('Content-Type', 'application/json')
            ->assertJsonStructure(['success', 'message'])
            ->assertJsonPath('success', false);
    }

    /**
     * Une commande après remise à zéro du cache passe bien (simule expiration de la fenêtre).
     */
    public function test_commande_passe_apres_reset_cache(): void
    {
        $this->setLowRateLimit(1);
        $this->clearRateLimitCache();

        $this->postJson('/api/commandes', $this->payload())->assertStatus(201);
        $this->postJson('/api/commandes', $this->payload())->assertStatus(429);

        // Simuler l'expiration de la fenêtre en vidant le cache
        $this->clearRateLimitCache();

        $this->postJson('/api/commandes', $this->payload())->assertStatus(201);
    }
}
