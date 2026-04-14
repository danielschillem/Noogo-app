<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Dish;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests pour les endpoints du tableau de bord (tous authentifiés) :
 *   GET /api/dashboard/
 *   GET /api/dashboard/recent-orders
 *   GET /api/dashboard/orders-chart
 *   GET /api/dashboard/revenue-chart
 *   GET /api/dashboard/top-dishes
 */
class DashboardControllerTest extends TestCase
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
            'status' => 'delivered',
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

    // =========================================================================
    // GET /api/dashboard/
    // =========================================================================

    public function test_index_retourne_les_stats_du_dashboard(): void
    {
        $this->createOrder();

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'today' => ['orders', 'revenue', 'pending_orders'],
                    'this_month' => ['orders', 'revenue', 'completed_orders'],
                    'last_month' => ['orders', 'revenue'],
                    'total_restaurants',
                    'total_dishes',
                    'active_dishes',
                    'growth' => ['orders', 'revenue'],
                ],
            ]);
    }

    public function test_index_retourne_données_vides_sans_commandes(): void
    {
        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.today.orders', 0)
            ->assertJsonPath('data.today.revenue', 0)
            ->assertJsonPath('data.total_restaurants', 1)
            ->assertJsonPath('data.total_dishes', 1);
    }

    public function test_index_refuse_un_utilisateur_non_authentifie(): void
    {
        $response = $this->getJson('/api/dashboard/');

        $response->assertStatus(401);
    }

    public function test_index_isole_les_données_par_proprietaire(): void
    {
        // Commande du restaurant de l'autre user
        $otherRestaurant = Restaurant::create([
            'user_id' => $this->other->id,
            'nom' => 'Autre Maquis',
            'telephone' => '71111111',
            'adresse' => 'Bobo',
            'is_active' => true,
        ]);

        Order::create([
            'restaurant_id' => $otherRestaurant->id,
            'status' => 'delivered',
            'order_type' => 'sur_place',
            'payment_method' => 'cash',
            'total_amount' => 5000,
            'order_date' => now(),
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/');

        // Le owner ne voit pas les commandes de l'autre restaurant
        $response->assertStatus(200)
            ->assertJsonPath('data.today.orders', 0);
    }

    // =========================================================================
    // GET /api/dashboard/recent-orders
    // =========================================================================

    public function test_recent_orders_retourne_les_commandes_recentes(): void
    {
        $this->createOrder();
        $this->createOrder();

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/recent-orders');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data');
    }

    public function test_recent_orders_respecte_le_parametre_limit(): void
    {
        for ($i = 0; $i < 5; $i++) {
            $this->createOrder();
        }

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/recent-orders?limit=3');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');
    }

    public function test_recent_orders_retourne_vide_sans_commandes(): void
    {
        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/recent-orders');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(0, 'data');
    }

    public function test_recent_orders_refuse_un_utilisateur_non_authentifie(): void
    {
        $response = $this->getJson('/api/dashboard/recent-orders');

        $response->assertStatus(401);
    }

    // =========================================================================
    // GET /api/dashboard/orders-chart
    // =========================================================================

    public function test_orders_chart_retourne_les_données_des_7_derniers_jours(): void
    {
        $this->createOrder();

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/orders-chart');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(7, 'data');

        // Chaque entrée a les champs attendus
        $response->assertJsonStructure([
            'data' => [
                '*' => ['date', 'label', 'orders', 'revenue'],
            ],
        ]);
    }

    public function test_orders_chart_accepte_un_parametre_days(): void
    {
        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/orders-chart?days=14');

        $response->assertStatus(200)
            ->assertJsonCount(14, 'data');
    }

    public function test_orders_chart_refuse_un_utilisateur_non_authentifie(): void
    {
        $response = $this->getJson('/api/dashboard/orders-chart');

        $response->assertStatus(401);
    }

    // =========================================================================
    // GET /api/dashboard/revenue-chart
    // =========================================================================

    public function test_revenue_chart_retourne_les_données_des_6_derniers_mois(): void
    {
        $this->createOrder();

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/revenue-chart');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(6, 'data');

        $response->assertJsonStructure([
            'data' => [
                '*' => ['year', 'month', 'label', 'revenue', 'orders'],
            ],
        ]);
    }

    public function test_revenue_chart_accepte_un_parametre_months(): void
    {
        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/revenue-chart?months=3');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data');
    }

    public function test_revenue_chart_exclut_les_commandes_annulees(): void
    {
        // Commande livrée avec item à 2000 : incluse dans le revenu
        $order1 = Order::create([
            'restaurant_id' => $this->restaurant->id,
            'status' => 'delivered',
            'order_type' => 'sur_place',
            'payment_method' => 'cash',
            'total_amount' => 2000,
            'order_date' => now(),
        ]);
        // Le hook saved de OrderItem recalcule total_amount → doit donner 2000
        OrderItem::create([
            'order_id' => $order1->id,
            'dish_id' => $this->dish->id,
            'quantity' => 1,
            'unit_price' => 2000,
            'total_price' => 2000,
        ]);

        // Commande annulée avec item à 5000 : exclue du revenu
        $order2 = Order::create([
            'restaurant_id' => $this->restaurant->id,
            'status' => 'cancelled',
            'order_type' => 'sur_place',
            'payment_method' => 'cash',
            'total_amount' => 5000,
            'order_date' => now(),
        ]);
        OrderItem::create([
            'order_id' => $order2->id,
            'dish_id' => $this->dish->id,
            'quantity' => 1,
            'unit_price' => 5000,
            'total_price' => 5000,
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/revenue-chart');

        $response->assertStatus(200);

        // Le mois courant doit afficher 2000 (pas 7000)
        $currentMonth = now()->month;
        $data = $response->json('data');
        $current = collect($data)->first(fn($d) => $d['month'] == $currentMonth);
        $this->assertEquals(2000, $current['revenue']);
    }

    public function test_revenue_chart_refuse_un_utilisateur_non_authentifie(): void
    {
        $response = $this->getJson('/api/dashboard/revenue-chart');

        $response->assertStatus(401);
    }

    // =========================================================================
    // GET /api/dashboard/top-dishes
    // =========================================================================

    public function test_top_dishes_retourne_les_plats_les_plus_vendus(): void
    {
        $this->createOrder(['status' => 'delivered']);
        $this->createOrder(['status' => 'delivered']);

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/top-dishes');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'nom', 'prix', 'total_quantity', 'total_revenue'],
                ],
            ]);
    }

    public function test_top_dishes_respecte_le_parametre_limit(): void
    {
        // Créer 3 plats distincts
        $dish2 = Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Tô',
            'prix' => 500,
            'disponibilite' => true,
        ]);

        $dish3 = Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Haricots',
            'prix' => 700,
            'disponibilite' => true,
        ]);

        foreach ([$this->dish, $dish2, $dish3] as $dish) {
            $order = Order::create([
                'restaurant_id' => $this->restaurant->id,
                'status' => 'delivered',
                'order_type' => 'sur_place',
                'payment_method' => 'cash',
                'total_amount' => $dish->prix,
                'order_date' => now(),
            ]);
            OrderItem::create([
                'order_id' => $order->id,
                'dish_id' => $dish->id,
                'quantity' => 1,
                'unit_price' => $dish->prix,
                'total_price' => $dish->prix,
            ]);
        }

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/top-dishes?limit=2');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data');
    }

    public function test_top_dishes_exclut_les_commandes_non_livrees(): void
    {
        // Commandes pending/cancelled ne doivent pas compter
        foreach (['pending', 'cancelled'] as $status) {
            $order = Order::create([
                'restaurant_id' => $this->restaurant->id,
                'status' => $status,
                'order_type' => 'sur_place',
                'payment_method' => 'cash',
                'total_amount' => 1500,
                'order_date' => now(),
            ]);
            OrderItem::create([
                'order_id' => $order->id,
                'dish_id' => $this->dish->id,
                'quantity' => 1,
                'unit_price' => 1500,
                'total_price' => 1500,
            ]);
        }

        $response = $this->actingAs($this->owner)
            ->getJson('/api/dashboard/top-dishes');

        $response->assertStatus(200)
            ->assertJsonCount(0, 'data');
    }

    public function test_top_dishes_refuse_un_utilisateur_non_authentifie(): void
    {
        $response = $this->getJson('/api/dashboard/top-dishes');

        $response->assertStatus(401);
    }
}
