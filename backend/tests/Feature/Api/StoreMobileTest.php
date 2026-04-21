<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Dish;
use App\Models\Order;
use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

/**
 * Tests pour l'endpoint public storeMobile (POST /api/commandes).
 * Cet endpoint est intentionnellement sans authentification (commandes QR invité).
 */
class StoreMobileTest extends TestCase
{
    use RefreshDatabase;

    private Restaurant $restaurant;
    private Category $category;
    private Dish $dish;

    protected function setUp(): void
    {
        parent::setUp();

        // Vider le cache du rate limiter entre chaque test
        // (évite les 429 lorsque StoreMobileRateLimitTest précède ce fichier)
        Cache::flush();

        $user = User::factory()->create(['is_admin' => false]);

        $this->restaurant = Restaurant::create([
            'user_id' => $user->id,
            'nom' => 'Restaurant Test',
            'telephone' => '70000000',
            'adresse' => 'Ouagadougou',
            'is_active' => true,
        ]);

        $this->category = Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Plats chauds',
            'is_active' => true,
        ]);

        $this->dish = Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Riz sauce tomate',
            'prix' => 1500,
            'disponibilite' => true,
        ]);
    }

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'restaurant_id' => $this->restaurant->id,
            'type' => 'sur_place',
            'moyen_paiement' => 'cash',
            'plats' => [
                ['id' => $this->dish->id, 'quantite' => 2],
            ],
        ], $overrides);
    }

    public function test_commande_valide_cree_un_order_et_retourne_201(): void
    {
        $response = $this->postJson('/api/commandes', $this->payload());

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['id', 'data']);

        $this->assertDatabaseHas('orders', [
            'restaurant_id' => $this->restaurant->id,
            'order_type' => 'sur_place',
            'status' => 'pending',
        ]);
    }

    public function test_total_est_calcule_correctement(): void
    {
        $response = $this->postJson('/api/commandes', $this->payload([
            'plats' => [['id' => $this->dish->id, 'quantite' => 3]],
        ]));

        $response->assertStatus(201);

        $order = Order::latest()->first();
        // 3 × 1500 = 4500
        $this->assertEquals(4500, $order->total_amount);
    }

    public function test_retourne_422_si_restaurant_nexiste_pas(): void
    {
        $response = $this->postJson('/api/commandes', $this->payload([
            'restaurant_id' => 9999,
        ]));

        $response->assertStatus(422);
    }

    public function test_retourne_404_si_restaurant_inactif(): void
    {
        $this->restaurant->update(['is_active' => false]);

        $response = $this->postJson('/api/commandes', $this->payload());

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_retourne_422_si_plat_non_disponible(): void
    {
        $this->dish->update(['disponibilite' => false]);

        $response = $this->postJson('/api/commandes', $this->payload());

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_retourne_422_si_type_de_commande_invalide(): void
    {
        $response = $this->postJson('/api/commandes', $this->payload([
            'type' => 'teleportation',
        ]));

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_retourne_422_si_plats_vide(): void
    {
        $response = $this->postJson('/api/commandes', $this->payload([
            'plats' => [],
        ]));

        $response->assertStatus(422);
    }

    public function test_retourne_422_si_plats_en_double(): void
    {
        $response = $this->postJson('/api/commandes', $this->payload([
            'plats' => [
                ['id' => $this->dish->id, 'quantite' => 1],
                ['id' => $this->dish->id, 'quantite' => 2],
            ],
        ]));

        $response->assertStatus(422)
            ->assertJsonPath('success', false);

        // Aucune commande ne doit avoir été créée
        $this->assertDatabaseCount('orders', 0);
    }

    public function test_retourne_422_si_telephone_format_invalide(): void
    {
        $response = $this->postJson('/api/commandes', $this->payload([
            'telephone' => '<script>alert(1)</script>',
        ]));

        $response->assertStatus(422);
    }

    public function test_retourne_422_si_quantite_excessive(): void
    {
        $response = $this->postJson('/api/commandes', $this->payload([
            'plats' => [['id' => $this->dish->id, 'quantite' => 101]],
        ]));

        $response->assertStatus(422);
    }

    public function test_accepte_tous_les_types_de_commande_normalises(): void
    {
        $types = [
            'sur place' => 'sur_place',
            'a emporter' => 'a_emporter',
            'livraison' => 'livraison',
            'delivery' => 'livraison',
        ];

        foreach ($types as $input => $expected) {
            // Réinitialise les compteurs du rate limiter entre chaque itération
            // (la limite par IP+restaurant est 3/min, or on envoie 4 types différents)
            Cache::flush();
            Order::query()->forceDelete();

            $response = $this->postJson('/api/commandes', $this->payload([
                'type' => $input,
            ]));

            $this->assertEquals(201, $response->status(), "Type '$input' devrait être accepté");
            $this->assertDatabaseHas('orders', ['order_type' => $expected]);
        }
    }
}
