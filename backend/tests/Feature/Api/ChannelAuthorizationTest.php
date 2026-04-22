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
use Illuminate\Support\Facades\Broadcast;
use Tests\TestCase;

/**
 * Tests d'autorisation des canaux Pusher privés (routes/channels.php)
 *
 * On invoque directement les callbacks de canal via getChannels() sur le broadcaster,
 * sans passer par le HTTP /broadcasting/auth (qui nécessiterait un socket_id Pusher valide).
 *
 *   Canal restaurant.{restaurantId}  — admin, owner, staff actif ✓ / stranger, staff inactif ✗
 *   Canal delivery.{orderId}          — admin, client, driver, owner, staff manage_orders ✓ / stranger ✗
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

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /**
     * Résout l'autorisation d'un canal en appelant directement son callback.
     * @param  string  $pattern  ex: 'restaurant.{restaurantId}'
     */
    private function callChannel(string $pattern, User $user, array $params): bool
    {
        $channels = app('Illuminate\Broadcasting\BroadcastManager')
            ->driver()
            ->getChannels();

        if (!$channels->has($pattern)) {
            return false;
        }

        $result = ($channels->get($pattern))($user, ...$params);

        return $result === true;
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
    // Canal restaurant.{restaurantId}
    // =========================================================================

    public function test_admin_peut_acceder_canal_restaurant(): void
    {
        $this->assertTrue($this->callChannel('restaurant.{restaurantId}', $this->admin, [$this->restaurant->id]));
    }

    public function test_proprietaire_peut_acceder_son_canal_restaurant(): void
    {
        $this->assertTrue($this->callChannel('restaurant.{restaurantId}', $this->owner, [$this->restaurant->id]));
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

        $this->assertTrue($this->callChannel('restaurant.{restaurantId}', $staffUser, [$this->restaurant->id]));
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

        $this->assertFalse($this->callChannel('restaurant.{restaurantId}', $staffUser, [$this->restaurant->id]));
    }

    public function test_utilisateur_tiers_ne_peut_pas_acceder_canal_restaurant(): void
    {
        $this->assertFalse($this->callChannel('restaurant.{restaurantId}', $this->stranger, [$this->restaurant->id]));
    }

    public function test_restaurant_inexistant_retourne_false(): void
    {
        $this->assertFalse($this->callChannel('restaurant.{restaurantId}', $this->owner, [99999]));
    }

    // =========================================================================
    // Canal delivery.{orderId}
    // =========================================================================

    public function test_admin_peut_acceder_canal_delivery(): void
    {
        [$order] = $this->createOrderAndDelivery();
        $this->assertTrue($this->callChannel('delivery.{orderId}', $this->admin, [$order->id]));
    }

    public function test_client_auteur_peut_acceder_canal_delivery(): void
    {
        [$order] = $this->createOrderAndDelivery();
        $this->assertTrue($this->callChannel('delivery.{orderId}', $this->client, [$order->id]));
    }

    public function test_livreur_assigne_peut_acceder_canal_delivery(): void
    {
        [$order, $delivery, $driverUser] = $this->createOrderAndDelivery();
        $this->assertTrue($this->callChannel('delivery.{orderId}', $driverUser, [$order->id]));
    }

    public function test_proprietaire_restaurant_peut_acceder_canal_delivery(): void
    {
        [$order] = $this->createOrderAndDelivery();
        $this->assertTrue($this->callChannel('delivery.{orderId}', $this->owner, [$order->id]));
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

        $this->assertTrue($this->callChannel('delivery.{orderId}', $staffUser, [$order->id]));
    }

    public function test_utilisateur_tiers_ne_peut_pas_acceder_canal_delivery(): void
    {
        [$order] = $this->createOrderAndDelivery();
        $this->assertFalse($this->callChannel('delivery.{orderId}', $this->stranger, [$order->id]));
    }

    public function test_commande_inexistante_retourne_false_sur_canal_delivery(): void
    {
        $this->assertFalse($this->callChannel('delivery.{orderId}', $this->client, [99999]));
    }
}
