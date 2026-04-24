<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Dish;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Restaurant;
use App\Models\RestaurantStaff;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests pour les endpoints OrderController (authentifiés) :
 *   GET  /api/restaurants/{restaurant}/orders
 *   POST /api/restaurants/{restaurant}/orders
 *   GET  /api/restaurants/{restaurant}/orders/{order}
 *   PATCH /api/restaurants/{restaurant}/orders/{order}/status
 *   POST /api/restaurants/{restaurant}/orders/{order}/cancel
 *   GET  /api/restaurants/{restaurant}/orders-statistics
 *   GET  /api/restaurants/{restaurant}/orders-pending-count
 */
class OrderControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private User $other;
    private Restaurant $restaurant;
    private Category $category;
    private Dish $dish;

    protected function setUp(): void
    {
        parent::setUp();

        $this->owner = User::factory()->create(['is_admin' => false]);
        $this->other = User::factory()->create(['is_admin' => false]);

        $this->restaurant = Restaurant::create([
            'user_id' => $this->owner->id,
            'nom' => 'Maquis Test',
            'telephone' => '70000000',
            'adresse' => 'Ouagadougou',
            'is_active' => true,
        ]);

        $this->category = Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Plats',
            'is_active' => true,
        ]);

        $this->dish = Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Riz gras',
            'prix' => 1500,
            'disponibilite' => true,
        ]);
    }

    /** Crée une commande avec un item pour les tests. */
    private function createOrder(array $overrides = []): Order
    {
        $order = Order::create(array_merge([
            'restaurant_id' => $this->restaurant->id,
            'status' => 'pending',
            'order_type' => 'sur_place',
            'payment_method' => 'cash',
            'total_amount' => 1500,
            'order_date' => now(),
        ], $overrides));

        OrderItem::create([
            'order_id' => $order->id,
            'dish_id' => $this->dish->id,
            'quantity' => 1,
            'unit_price' => 1500,
            'total_price' => 1500,
        ]);

        return $order;
    }

    private function attachStaff(User $user, string $role): RestaurantStaff
    {
        return RestaurantStaff::create([
            'user_id' => $user->id,
            'restaurant_id' => $this->restaurant->id,
            'role' => $role,
            'is_active' => true,
        ]);
    }

    // =========================================================================
    // INDEX
    // =========================================================================

    public function test_index_retourne_la_liste_des_commandes(): void
    {
        $this->createOrder();
        $this->createOrder();

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data.data');
    }

    public function test_index_filtre_par_status(): void
    {
        $this->createOrder(['status' => 'pending']);
        $this->createOrder(['status' => 'completed']);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders?status=pending");

        $response->assertStatus(200);
        $data = $response->json('data.data');
        $this->assertCount(1, $data);
        $this->assertEquals('pending', $data[0]['status']);
    }

    public function test_index_filtre_par_aujourd_hui(): void
    {
        $this->createOrder(['order_date' => now()]);
        $this->createOrder(['order_date' => now()->subDays(5)]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders?today=1");

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data.data'));
    }

    public function test_index_refuse_un_utilisateur_non_authentifie(): void
    {
        $this->getJson("/api/restaurants/{$this->restaurant->id}/orders")
            ->assertStatus(401);
    }

    // =========================================================================
    // STORE (authentifié dashboard)
    // =========================================================================

    public function test_store_cree_une_commande_valide(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/orders", [
                'order_type' => 'sur_place',
                'payment_method' => 'cash',
                'items' => [
                    ['dish_id' => $this->dish->id, 'quantity' => 2],
                ],
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.order_type', 'sur_place');

        $this->assertDatabaseHas('orders', [
            'restaurant_id' => $this->restaurant->id,
            'status' => 'pending',
        ]);
    }

    public function test_store_echoue_si_plat_indisponible(): void
    {
        $this->dish->update(['disponibilite' => false]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/orders", [
                'order_type' => 'sur_place',
                'payment_method' => 'cash',
                'items' => [
                    ['dish_id' => $this->dish->id, 'quantity' => 1],
                ],
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_store_echoue_si_plat_appartient_a_un_autre_restaurant(): void
    {
        $otherRestaurant = Restaurant::create([
            'user_id' => $this->other->id,
            'nom' => 'Autre resto',
            'telephone' => '71000000',
            'adresse' => 'Bobo',
            'is_active' => true,
        ]);
        $otherCat = Category::create([
            'restaurant_id' => $otherRestaurant->id,
            'nom' => 'Cat',
            'is_active' => true,
        ]);
        $foreignDish = Dish::create([
            'restaurant_id' => $otherRestaurant->id,
            'category_id' => $otherCat->id,
            'nom' => 'Poulet',
            'prix' => 2000,
            'disponibilite' => true,
        ]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/orders", [
                'order_type' => 'sur_place',
                'payment_method' => 'cash',
                'items' => [
                    ['dish_id' => $foreignDish->id, 'quantity' => 1],
                ],
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_store_echoue_sans_items(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/orders", [
                'order_type' => 'sur_place',
                'payment_method' => 'cash',
                'items' => [],
            ]);

        $response->assertStatus(422);
    }

    // =========================================================================
    // SHOW
    // =========================================================================

    public function test_show_retourne_une_commande(): void
    {
        $order = $this->createOrder();

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders/{$order->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $order->id);
    }

    public function test_show_refuse_une_commande_dun_autre_restaurant(): void
    {
        $otherRestaurant = Restaurant::create([
            'user_id' => $this->other->id,
            'nom' => 'Resto voisin',
            'telephone' => '72222222',
            'adresse' => 'Bobo',
            'is_active' => true,
        ]);

        $foreignOrder = Order::create([
            'restaurant_id' => $otherRestaurant->id,
            'status' => 'pending',
            'order_type' => 'sur_place',
            'payment_method' => 'cash',
            'total_amount' => 1000,
            'order_date' => now(),
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders/{$foreignOrder->id}");

        $response->assertStatus(404);
    }

    // =========================================================================
    // UPDATE STATUS
    // =========================================================================

    public function test_update_status_passe_en_confirmed(): void
    {
        $order = $this->createOrder(['status' => 'pending']);

        $response = $this->actingAs($this->owner)
            ->patchJson("/api/restaurants/{$this->restaurant->id}/orders/{$order->id}/status", [
                'status' => 'confirmed',
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'confirmed');

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'confirmed']);
    }

    public function test_update_status_echoue_avec_statut_invalide(): void
    {
        $order = $this->createOrder();

        $response = $this->actingAs($this->owner)
            ->patchJson("/api/restaurants/{$this->restaurant->id}/orders/{$order->id}/status", [
                'status' => 'inexistant',
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_update_status_refuse_un_utilisateur_non_authentifie(): void
    {
        $order = $this->createOrder();

        $this->patchJson("/api/restaurants/{$this->restaurant->id}/orders/{$order->id}/status", [
            'status' => 'confirmed',
        ])->assertStatus(401);
    }

    // =========================================================================
    // CANCEL
    // =========================================================================

    public function test_cancel_une_commande_pending(): void
    {
        $order = $this->createOrder(['status' => 'pending']);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/orders/{$order->id}/cancel");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'cancelled']);
    }

    public function test_cancel_une_commande_confirmed(): void
    {
        $order = $this->createOrder(['status' => 'confirmed']);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/orders/{$order->id}/cancel");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_cancel_refuse_une_commande_en_preparation(): void
    {
        $order = $this->createOrder(['status' => 'preparing']);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/orders/{$order->id}/cancel");

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_cancel_refuse_une_commande_deja_terminee(): void
    {
        $order = $this->createOrder(['status' => 'completed']);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/orders/{$order->id}/cancel");

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // STATISTICS
    // =========================================================================

    public function test_statistics_retourne_les_stats_du_mois(): void
    {
        $this->createOrder(['status' => 'completed', 'total_amount' => 3000, 'order_date' => now()]);
        $this->createOrder(['status' => 'cancelled', 'order_date' => now()]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders-statistics");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'total_orders',
                    'completed_orders',
                    'cancelled_orders',
                    'total_revenue',
                    'average_order_value',
                    'orders_by_type',
                    'orders_by_status',
                    'top_dishes',
                ]
            ]);
    }

    public function test_statistics_refuse_un_utilisateur_non_authentifie(): void
    {
        $this->getJson("/api/restaurants/{$this->restaurant->id}/orders-statistics")
            ->assertStatus(401);
    }

    public function test_statistics_refuse_le_role_waiter(): void
    {
        $waiter = User::factory()->create(['is_admin' => false]);
        $this->attachStaff($waiter, 'waiter');

        $response = $this->actingAs($waiter)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders-statistics");

        $response->assertStatus(403);
    }

    // =========================================================================
    // PENDING COUNT
    // =========================================================================

    public function test_pending_count_retourne_les_comptes_par_statut(): void
    {
        $this->createOrder(['status' => 'pending']);
        $this->createOrder(['status' => 'pending']);
        $this->createOrder(['status' => 'confirmed']);
        $this->createOrder(['status' => 'preparing']);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders-pending-count");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.pending', 2)
            ->assertJsonPath('data.confirmed', 1)
            ->assertJsonPath('data.preparing', 1)
            ->assertJsonPath('data.ready', 0);
    }

    public function test_waiter_peut_gerer_les_commandes_sans_acces_aux_stats(): void
    {
        $waiter = User::factory()->create(['is_admin' => false]);
        $this->attachStaff($waiter, 'waiter');
        $order = $this->createOrder(['status' => 'pending']);

        $this->actingAs($waiter)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders")
            ->assertStatus(200);

        $this->actingAs($waiter)
            ->patchJson("/api/restaurants/{$this->restaurant->id}/orders/{$order->id}/status", [
                'status' => 'confirmed',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'confirmed');

        $this->actingAs($waiter)
            ->getJson("/api/restaurants/{$this->restaurant->id}/orders-statistics")
            ->assertStatus(403);
    }
}
