<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Delivery;
use App\Models\DeliveryDriver;
use App\Models\Dish;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Restaurant;
use App\Models\RestaurantStaff;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests d'autorisation des canaux Pusher privés (routes/channels.php)
 *
 *   Canal private-restaurant.{restaurantId} :
 *     - Admin Noogo      → 200
 *     - Propriétaire     → 200
 *     - Staff manager actif → 200
 *     - Staff inactif    → 403
 *     - Utilisateur tiers → 403
 *     - Restaurant inexistant → 403
 *     - Non authentifié  → 403
 *
 *   Canal private-delivery.{orderId} :
 *     - Admin Noogo      → 200
 *     - Client auteur    → 200
 *     - Livreur assigné  → 200
 *     - Propriétaire du restaurant → 200
 *     - Staff manage_orders → 200
 *     - Utilisateur tiers → 403
 *     - Commande inexistante → 403
 */
class ChannelAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private User $owner;
    private User $client;
    private User $stranger;
    private Restaurant $restaurant;

    protected function setUp(): void
    {
        parent::setUp();

        // L'auth de canal Pusher est calculée localement (HMAC-SHA256 avec le secret)
        // → pas de connexion réseau réelle, faux credentials suffisent.
        config([
            'broadcasting.default' => 'pusher',
            'broadcasting.connections.pusher.key' => 'test-key',
            'broadcasting.connections.pusher.secret' => 'test-secret-000000000000',
            'broadcasting.connections.pusher.app_id' => '000001',
            'broadcasting.connections.pusher.options' => [
                'cluster' => 'eu',
                'useTLS' => false,
                'host' => '127.0.0.1',
                'port' => 6001,
                'scheme' => 'http',
            ],
        ]);

        $this->admin = User::factory()->create(['is_admin' => true]);
        $this->owner = User::factory()->create(['is_admin' => false]);
        $this->client = User::factory()->create(['is_admin' => false]);
        $this->stranger = User::factory()->create(['is_admin' => false]);

        $this->restaurant = Restaurant::create([
            'user_id' => $this->owner->id,
            'nom' => 'Maquis Test',
            'telephone' => '70000001',
            'adresse' => 'Ouagadougou',
            'is_active' => true,
        ]);
    }

    // ─── Helper ──────────────────────────────────────────────────────────────

    private function authChannel(User $user, string $channelName): \Illuminate\Testing\TestResponse
    {
        return $this->actingAs($user, 'sanctum')
            ->postJson('/broadcasting/auth', [
                'socket_id' => '1234.5678',
                'channel_name' => $channelName,
            ]);
    }

    private function createOrderAndDelivery(): array
    {
        $category = Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Plats',
            'is_active' => true,
        ]);

        $dish = Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $category->id,
            'nom' => 'Riz gras',
            'prix' => 1500,
            'disponibilite' => true,
        ]);

        $order = Order::create([
            'user_id' => $this->client->id,
            'restaurant_id' => $this->restaurant->id,
            'status' => 'confirmed',
            'order_type' => 'livraison',
            'payment_method' => 'cash',
            'total_amount' => 1500,
            'order_date' => now(),
        ]);

        OrderItem::create([
            'order_id' => $order->id,
            'dish_id' => $dish->id,
            'quantity' => 1,
            'unit_price' => 1500,
            'total_price' => 1500,
        ]);

        $driverUser = User::factory()->create(['is_admin' => false]);
        $driver = DeliveryDriver::create([
            'user_id' => $driverUser->id,
            'name' => 'Moussa',
            'phone' => '76111111',
            'zone' => 'Ouaga 2000',
            'status' => 'busy',
        ]);

        $delivery = Delivery::create([
            'order_id' => $order->id,
            'delivery_driver_id' => $driver->id,
            'status' => 'assigned',
        ]);

        return [$order, $delivery, $driverUser, $driver];
    }

    // =========================================================================
    // Canal private-restaurant.{restaurantId}
    // =========================================================================

    public function test_admin_peut_acceder_canal_restaurant(): void
    {
        $this->authChannel($this->admin, 'private-restaurant.' . $this->restaurant->id)
            ->assertStatus(200);
    }

    public function test_proprietaire_peut_acceder_son_canal_restaurant(): void
    {
        $this->authChannel($this->owner, 'private-restaurant.' . $this->restaurant->id)
            ->assertStatus(200);
    }

    public function test_staff_manager_actif_peut_acceder_canal_restaurant(): void
    {
        $staffUser = User::factory()->create(['is_admin' => false]);
        RestaurantStaff::create([
            'user_id' => $staffUser->id,
            'restaurant_id' => $this->restaurant->id,
            'role' => 'manager',
            'is_active' => true,
        ]);

        $this->authChannel($staffUser, 'private-restaurant.' . $this->restaurant->id)
            ->assertStatus(200);
    }

    public function test_staff_inactif_ne_peut_pas_acceder_canal_restaurant(): void
    {
        $staffUser = User::factory()->create(['is_admin' => false]);
        RestaurantStaff::create([
            'user_id' => $staffUser->id,
            'restaurant_id' => $this->restaurant->id,
            'role' => 'manager',
            'is_active' => false,
        ]);

        $this->authChannel($staffUser, 'private-restaurant.' . $this->restaurant->id)
            ->assertStatus(403);
    }

    public function test_utilisateur_tiers_ne_peut_pas_acceder_canal_restaurant(): void
    {
        $this->authChannel($this->stranger, 'private-restaurant.' . $this->restaurant->id)
            ->assertStatus(403);
    }

    public function test_restaurant_inexistant_retourne_403(): void
    {
        $this->authChannel($this->owner, 'private-restaurant.99999')
            ->assertStatus(403);
    }

    public function test_non_authentifie_recoit_403_sur_canal_restaurant(): void
    {
        $this->postJson('/broadcasting/auth', [
            'socket_id' => '1234.5678',
            'channel_name' => 'private-restaurant.' . $this->restaurant->id,
        ])->assertStatus(403);
    }

    // =========================================================================
    // Canal private-delivery.{orderId}
    // =========================================================================

    public function test_admin_peut_acceder_canal_delivery(): void
    {
        [$order] = $this->createOrderAndDelivery();

        $this->authChannel($this->admin, 'private-delivery.' . $order->id)
            ->assertStatus(200);
    }

    public function test_client_auteur_peut_acceder_canal_delivery(): void
    {
        [$order] = $this->createOrderAndDelivery();

        $this->authChannel($this->client, 'private-delivery.' . $order->id)
            ->assertStatus(200);
    }

    public function test_livreur_assigne_peut_acceder_canal_delivery(): void
    {
        [$order, $delivery, $driverUser] = $this->createOrderAndDelivery();

        $this->authChannel($driverUser, 'private-delivery.' . $order->id)
            ->assertStatus(200);
    }

    public function test_proprietaire_restaurant_peut_acceder_canal_delivery(): void
    {
        [$order] = $this->createOrderAndDelivery();

        $this->authChannel($this->owner, 'private-delivery.' . $order->id)
            ->assertStatus(200);
    }

    public function test_staff_manage_orders_peut_acceder_canal_delivery(): void
    {
        [$order] = $this->createOrderAndDelivery();

        $staffUser = User::factory()->create(['is_admin' => false]);
        RestaurantStaff::create([
            'user_id' => $staffUser->id,
            'restaurant_id' => $this->restaurant->id,
            'role' => 'manager',
            'is_active' => true,
        ]);

        $this->authChannel($staffUser, 'private-delivery.' . $order->id)
            ->assertStatus(200);
    }

    public function test_utilisateur_tiers_ne_peut_pas_acceder_canal_delivery(): void
    {
        [$order] = $this->createOrderAndDelivery();

        $this->authChannel($this->stranger, 'private-delivery.' . $order->id)
            ->assertStatus(403);
    }

    public function test_commande_inexistante_retourne_403_sur_canal_delivery(): void
    {
        $this->authChannel($this->client, 'private-delivery.99999')
            ->assertStatus(403);
    }
}
