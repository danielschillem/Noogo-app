<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Delivery;
use App\Models\DeliveryDriver;
use App\Models\Dish;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Restaurant;
use App\Models\User;
use App\Services\FcmNotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests pour DeliveryController — Phase 8A
 *
 *   POST  /api/orders/{order}/request-delivery
 *   POST  /api/deliveries/{delivery}/assign
 *   PATCH /api/deliveries/{delivery}/status
 *   POST  /api/deliveries/{delivery}/driver-location
 *   GET   /api/deliveries/{delivery}
 *   GET   /api/deliveries/my-active
 *   GET   /api/deliveries/my-history
 *   PUT   /api/drivers/me/status
 *   GET   /api/drivers/me
 *   GET   /api/admin/deliveries
 *   GET   /api/admin/drivers
 *   POST  /api/admin/drivers
 *   PUT   /api/admin/drivers/{driver}
 *   DELETE /api/admin/drivers/{driver}
 */
class DeliveryControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private User $admin;
    private User $driverUser;
    private User $client;
    private Restaurant $restaurant;
    private Category $category;
    private Dish $dish;
    private DeliveryDriver $driver;

    protected function setUp(): void
    {
        parent::setUp();

        // Mock FCM to avoid real push notifications
        $this->app->instance(FcmNotificationService::class, new class {
            public function sendToToken(...$args)
            {
                return true;
            }
        });

        $this->owner = User::factory()->create(['is_admin' => false]);
        $this->admin = User::factory()->create(['is_admin' => true]);
        $this->driverUser = User::factory()->create(['is_admin' => false]);
        $this->client = User::factory()->create(['is_admin' => false]);

        $this->restaurant = Restaurant::create([
            'user_id' => $this->owner->id,
            'nom' => 'Maquis Test',
            'telephone' => '70000000',
            'adresse' => 'Ouagadougou',
            'latitude' => 12.3700,
            'longitude' => -1.5200,
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

        $this->driver = DeliveryDriver::create([
            'user_id' => $this->driverUser->id,
            'name' => 'Moussa',
            'phone' => '76000000',
            'zone' => 'Ouaga 2000',
            'status' => 'available',
        ]);
    }

    private function createDeliveryOrder(array $overrides = []): Order
    {
        $order = Order::create(array_merge([
            'restaurant_id' => $this->restaurant->id,
            'user_id' => $this->client->id,
            'status' => 'confirmed',
            'order_type' => 'livraison',
            'payment_method' => 'cash',
            'total_amount' => 3000,
            'order_date' => now(),
        ], $overrides));

        OrderItem::create([
            'order_id' => $order->id,
            'dish_id' => $this->dish->id,
            'quantity' => 2,
            'unit_price' => 1500,
            'total_price' => 3000,
        ]);

        return $order;
    }

    private function createDelivery(Order $order, array $overrides = []): Delivery
    {
        return Delivery::create(array_merge([
            'order_id' => $order->id,
            'status' => 'pending_assignment',
        ], $overrides));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/orders/{order}/request-delivery
    // ──────────────────────────────────────────────────────────────────────────

    public function test_owner_can_request_delivery(): void
    {
        $order = $this->createDeliveryOrder();

        $response = $this->actingAs($this->owner)
            ->postJson("/api/orders/{$order->id}/request-delivery", [
                'client_lat' => 12.37,
                'client_lng' => -1.52,
                'client_address' => '123 Rue de la Paix',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            // L'auto-assignation peut faire passer directement à "assigned"
            // si un livreur disponible existe.
            ->assertJsonPath('data.status', 'assigned')
            ->assertJsonPath('data.fee', '1000.00')
            ->assertJsonPath('data.order_id', $order->id);
    }

    public function test_delivery_fee_increases_above_five_km(): void
    {
        $order = $this->createDeliveryOrder();

        // ~6.67 km depuis (12.37,-1.52) -> extra ~1.67 km => 1000 + 1.67*115 ~= 1192.05 => 1193
        $response = $this->actingAs($this->owner)
            ->postJson("/api/orders/{$order->id}/request-delivery", [
                'client_lat' => 12.4300,
                'client_lng' => -1.5200,
                'client_address' => 'Zone plus éloignée',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.fee', '1193.00');
    }

    public function test_cannot_request_delivery_for_non_livraison_order(): void
    {
        $order = $this->createDeliveryOrder(['order_type' => 'sur_place']);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/orders/{$order->id}/request-delivery");

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_cannot_request_duplicate_delivery(): void
    {
        $order = $this->createDeliveryOrder();
        $this->createDelivery($order);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/orders/{$order->id}/request-delivery");

        $response->assertStatus(422);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/deliveries/{delivery}/assign
    // ──────────────────────────────────────────────────────────────────────────

    public function test_owner_can_assign_driver(): void
    {
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/deliveries/{$delivery->id}/assign", [
                'delivery_driver_id' => $this->driver->id,
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'assigned');

        $this->driver->refresh();
        $this->assertEquals('busy', $this->driver->status);
    }

    public function test_cannot_assign_busy_driver(): void
    {
        $this->driver->update(['status' => 'busy']);
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/deliveries/{$delivery->id}/assign", [
                'delivery_driver_id' => $this->driver->id,
            ]);

        $response->assertStatus(422);
    }

    public function test_cannot_assign_already_assigned_delivery(): void
    {
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order, [
            'status' => 'assigned',
            'delivery_driver_id' => $this->driver->id,
        ]);

        $newDriver = DeliveryDriver::create([
            'name' => 'Ali',
            'phone' => '76111111',
            'status' => 'available',
        ]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/deliveries/{$delivery->id}/assign", [
                'delivery_driver_id' => $newDriver->id,
            ]);

        $response->assertStatus(422);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // PATCH /api/deliveries/{delivery}/status
    // ──────────────────────────────────────────────────────────────────────────

    public function test_driver_can_advance_status(): void
    {
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order, [
            'status' => 'assigned',
            'delivery_driver_id' => $this->driver->id,
        ]);
        $this->driver->update(['status' => 'busy']);

        $response = $this->actingAs($this->driverUser)
            ->patchJson("/api/deliveries/{$delivery->id}/status", [
                'status' => 'picked_up',
            ]);

        $response->assertOk()
            ->assertJsonPath('data.status', 'picked_up');
    }

    public function test_full_delivery_lifecycle(): void
    {
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order, [
            'status' => 'assigned',
            'delivery_driver_id' => $this->driver->id,
        ]);
        $this->driver->update(['status' => 'busy']);

        // assigned → picked_up
        $this->actingAs($this->driverUser)
            ->patchJson("/api/deliveries/{$delivery->id}/status", ['status' => 'picked_up'])
            ->assertOk();

        // picked_up → on_way
        $this->actingAs($this->driverUser)
            ->patchJson("/api/deliveries/{$delivery->id}/status", ['status' => 'on_way'])
            ->assertOk();

        // on_way → delivered
        $this->actingAs($this->driverUser)
            ->patchJson("/api/deliveries/{$delivery->id}/status", ['status' => 'delivered'])
            ->assertOk();

        $delivery->refresh();
        $this->assertEquals('delivered', $delivery->status);
        $this->assertNotNull($delivery->delivered_at);

        // Driver should be available again
        $this->driver->refresh();
        $this->assertEquals('available', $this->driver->status);
    }

    public function test_invalid_status_transition_rejected(): void
    {
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order, [
            'status' => 'assigned',
            'delivery_driver_id' => $this->driver->id,
        ]);
        $this->driver->update(['status' => 'busy']);

        // assigned → delivered (skipping picked_up and on_way) should fail
        $response = $this->actingAs($this->driverUser)
            ->patchJson("/api/deliveries/{$delivery->id}/status", ['status' => 'delivered']);

        $response->assertStatus(422);
    }

    public function test_driver_can_mark_failed_with_reason(): void
    {
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order, [
            'status' => 'on_way',
            'delivery_driver_id' => $this->driver->id,
        ]);
        $this->driver->update(['status' => 'busy']);

        $response = $this->actingAs($this->driverUser)
            ->patchJson("/api/deliveries/{$delivery->id}/status", [
                'status' => 'failed',
                'failure_reason' => 'Client introuvable',
            ]);

        $response->assertOk()
            ->assertJsonPath('data.status', 'failed');

        $delivery->refresh();
        $this->assertEquals('Client introuvable', $delivery->failure_reason);

        $this->driver->refresh();
        $this->assertEquals('available', $this->driver->status);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/deliveries/{delivery}/driver-location
    // ──────────────────────────────────────────────────────────────────────────

    public function test_driver_can_push_location(): void
    {
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order, [
            'status' => 'on_way',
            'delivery_driver_id' => $this->driver->id,
        ]);
        $this->driver->update(['status' => 'busy']);

        $response = $this->actingAs($this->driverUser)
            ->postJson("/api/deliveries/{$delivery->id}/driver-location", [
                'lat' => 12.3801,
                'lng' => -1.5100,
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $delivery->refresh();
        $this->assertEquals(12.3801, $delivery->driver_lat);
        $this->assertEquals(-1.5100, $delivery->driver_lng);
    }

    public function test_cannot_push_location_for_completed_delivery(): void
    {
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order, [
            'status' => 'delivered',
            'delivery_driver_id' => $this->driver->id,
        ]);

        $response = $this->actingAs($this->driverUser)
            ->postJson("/api/deliveries/{$delivery->id}/driver-location", [
                'lat' => 12.38,
                'lng' => -1.51,
            ]);

        $response->assertStatus(422);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GET /api/deliveries/{delivery}
    // ──────────────────────────────────────────────────────────────────────────

    public function test_show_delivery(): void
    {
        $order = $this->createDeliveryOrder();
        $delivery = $this->createDelivery($order, [
            'delivery_driver_id' => $this->driver->id,
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/deliveries/{$delivery->id}");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $delivery->id);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GET /api/deliveries/my-active
    // ──────────────────────────────────────────────────────────────────────────

    public function test_driver_can_get_active_deliveries(): void
    {
        $order = $this->createDeliveryOrder();
        $this->createDelivery($order, [
            'status' => 'assigned',
            'delivery_driver_id' => $this->driver->id,
        ]);

        $response = $this->actingAs($this->driverUser)
            ->getJson('/api/deliveries/my-active');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data');
    }

    public function test_completed_deliveries_excluded_from_active(): void
    {
        $order = $this->createDeliveryOrder();
        $this->createDelivery($order, [
            'status' => 'delivered',
            'delivery_driver_id' => $this->driver->id,
        ]);

        $response = $this->actingAs($this->driverUser)
            ->getJson('/api/deliveries/my-active');

        $response->assertOk()
            ->assertJsonCount(0, 'data');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GET /api/deliveries/my-history
    // ──────────────────────────────────────────────────────────────────────────

    public function test_driver_can_get_history(): void
    {
        $order = $this->createDeliveryOrder();
        $this->createDelivery($order, [
            'status' => 'delivered',
            'delivery_driver_id' => $this->driver->id,
            'delivered_at' => now(),
        ]);

        $response = $this->actingAs($this->driverUser)
            ->getJson('/api/deliveries/my-history');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GET /api/drivers/me  &  PUT /api/drivers/me/status
    // ──────────────────────────────────────────────────────────────────────────

    public function test_driver_can_get_profile(): void
    {
        $response = $this->actingAs($this->driverUser)
            ->getJson('/api/drivers/me');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Moussa');
    }

    public function test_driver_can_toggle_availability(): void
    {
        $response = $this->actingAs($this->driverUser)
            ->putJson('/api/drivers/me/status', ['status' => 'offline']);

        $response->assertOk();

        $this->driver->refresh();
        $this->assertEquals('offline', $this->driver->status);
    }

    public function test_driver_cannot_go_offline_with_active_delivery(): void
    {
        $order = $this->createDeliveryOrder();
        $this->createDelivery($order, [
            'status' => 'on_way',
            'delivery_driver_id' => $this->driver->id,
        ]);

        $response = $this->actingAs($this->driverUser)
            ->putJson('/api/drivers/me/status', ['status' => 'offline']);

        $response->assertStatus(422);
    }

    public function test_non_driver_user_gets_404_for_profile(): void
    {
        $response = $this->actingAs($this->client)
            ->getJson('/api/drivers/me');

        $response->assertStatus(404);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Admin endpoints
    // ──────────────────────────────────────────────────────────────────────────

    public function test_admin_can_list_deliveries(): void
    {
        $order = $this->createDeliveryOrder();
        $this->createDelivery($order);

        $response = $this->actingAs($this->admin)
            ->getJson('/api/admin/deliveries');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_admin_can_list_drivers(): void
    {
        $response = $this->actingAs($this->admin)
            ->getJson('/api/admin/drivers');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_admin_can_create_driver(): void
    {
        $response = $this->actingAs($this->admin)
            ->postJson('/api/admin/drivers', [
                'name' => 'Amadou',
                'phone' => '76222222',
                'zone' => 'Koudougou',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.name', 'Amadou');
    }

    public function test_admin_can_update_driver(): void
    {
        $response = $this->actingAs($this->admin)
            ->putJson("/api/admin/drivers/{$this->driver->id}", [
                'zone' => 'Bobo-Dioulasso',
            ]);

        $response->assertOk();

        $this->driver->refresh();
        $this->assertEquals('Bobo-Dioulasso', $this->driver->zone);
    }

    public function test_admin_can_delete_driver(): void
    {
        $response = $this->actingAs($this->admin)
            ->deleteJson("/api/admin/drivers/{$this->driver->id}");

        $response->assertOk();
        $this->assertSoftDeleted('delivery_drivers', ['id' => $this->driver->id]);
    }

    public function test_non_admin_cannot_access_admin_endpoints(): void
    {
        $this->actingAs($this->owner)
            ->getJson('/api/admin/deliveries')
            ->assertStatus(403);

        $this->actingAs($this->owner)
            ->getJson('/api/admin/drivers')
            ->assertStatus(403);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Authorization
    // ──────────────────────────────────────────────────────────────────────────

    public function test_unauthenticated_user_cannot_access_delivery_endpoints(): void
    {
        $this->getJson('/api/deliveries/my-active')->assertStatus(401);
        $this->getJson('/api/deliveries/my-history')->assertStatus(401);
        $this->getJson('/api/drivers/me')->assertStatus(401);
    }
}
