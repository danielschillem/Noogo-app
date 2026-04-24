<?php

namespace Tests\Feature\Api;

use App\Models\Restaurant;
use App\Models\RestaurantStaff;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests pour les endpoints staff (gestion du personnel) :
 *   GET    /api/restaurants/{restaurant}/staff
 *   POST   /api/restaurants/{restaurant}/staff
 *   PUT    /api/restaurants/{restaurant}/staff/{staff}
 *   DELETE /api/restaurants/{restaurant}/staff/{staff}
 *   GET    /api/auth/my-restaurants
 */
class StaffControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private User $other;
    private Restaurant $restaurant;

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
    }

    /** Crée un membre du personnel pour le restaurant courant. */
    private function createStaff(User $user, string $role = 'waiter', bool $isActive = true): RestaurantStaff
    {
        return RestaurantStaff::create([
            'user_id' => $user->id,
            'restaurant_id' => $this->restaurant->id,
            'role' => $role,
            'is_active' => $isActive,
        ]);
    }

    // =========================================================================
    // GET /api/restaurants/{restaurant}/staff
    // =========================================================================

    public function test_index_retourne_la_liste_du_personnel(): void
    {
        $staff = User::factory()->create();
        $this->createStaff($staff, 'waiter');

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/staff");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'user_id', 'name', 'role', 'role_label', 'permissions', 'is_active'],
                ],
                'roles',
            ]);
    }

    public function test_index_refuse_un_utilisateur_non_proprietaire(): void
    {
        $response = $this->actingAs($this->other)
            ->getJson("/api/restaurants/{$this->restaurant->id}/staff");

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_index_refuse_un_utilisateur_non_authentifie(): void
    {
        $response = $this->getJson("/api/restaurants/{$this->restaurant->id}/staff");

        $response->assertStatus(401);
    }

    public function test_index_retourne_vide_sans_personnel(): void
    {
        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/staff");

        $response->assertStatus(200)
            ->assertJsonCount(0, 'data');
    }

    // =========================================================================
    // POST /api/restaurants/{restaurant}/staff
    // =========================================================================

    public function test_store_cree_un_nouveau_membre_avec_nouveau_compte(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/staff", [
                'name' => 'Jean Serveur',
                'email' => 'jean@noogo.bf',
                'role' => 'waiter',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.role', 'waiter');

        $this->assertDatabaseHas('users', ['email' => 'jean@noogo.bf']);
        $this->assertDatabaseHas('restaurant_staff', [
            'restaurant_id' => $this->restaurant->id,
            'role' => 'waiter',
        ]);
    }

    public function test_store_rattache_un_utilisateur_existant(): void
    {
        $existing = User::factory()->create(['email' => 'existing@noogo.bf']);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/staff", [
                'name' => $existing->name,
                'email' => 'existing@noogo.bf',
                'role' => 'cashier',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user_id', $existing->id);
    }

    public function test_store_echoue_si_utilisateur_a_deja_un_role(): void
    {
        $member = User::factory()->create(['email' => 'member@noogo.bf']);
        $this->createStaff($member, 'waiter');

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/staff", [
                'name' => $member->name,
                'email' => 'member@noogo.bf',
                'role' => 'cashier',
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_store_refuse_le_role_owner(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/staff", [
                'name' => 'Nouvel Owner',
                'email' => 'owner2@noogo.bf',
                'role' => 'owner',
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_store_echoue_si_role_invalide(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/staff", [
                'name' => 'Bob',
                'email' => 'bob@noogo.bf',
                'role' => 'chef_etoile',
            ]);

        $response->assertStatus(422);
    }

    public function test_store_echoue_sans_email(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/staff", [
                'name' => 'Alice',
                'role' => 'waiter',
            ]);

        $response->assertStatus(422);
    }

    public function test_store_refuse_un_non_proprietaire(): void
    {
        $response = $this->actingAs($this->other)
            ->postJson("/api/restaurants/{$this->restaurant->id}/staff", [
                'name' => 'Eve',
                'email' => 'eve@noogo.bf',
                'role' => 'waiter',
            ]);

        $response->assertStatus(403);
    }

    // =========================================================================
    // PUT /api/restaurants/{restaurant}/staff/{staff}
    // =========================================================================

    public function test_update_modifie_le_role_du_personnel(): void
    {
        $member = User::factory()->create();
        $staff = $this->createStaff($member, 'waiter');

        $response = $this->actingAs($this->owner)
            ->putJson("/api/restaurants/{$this->restaurant->id}/staff/{$staff->id}", [
                'role' => 'cashier',
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.role', 'cashier');

        $this->assertDatabaseHas('restaurant_staff', [
            'id' => $staff->id,
            'role' => 'cashier',
        ]);
    }

    public function test_update_peut_desactiver_un_membre(): void
    {
        $member = User::factory()->create();
        $staff = $this->createStaff($member, 'manager');

        $response = $this->actingAs($this->owner)
            ->putJson("/api/restaurants/{$this->restaurant->id}/staff/{$staff->id}", [
                'is_active' => false,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.is_active', false);
    }

    public function test_update_refuse_role_invalide(): void
    {
        $member = User::factory()->create();
        $staff = $this->createStaff($member, 'waiter');

        $response = $this->actingAs($this->owner)
            ->putJson("/api/restaurants/{$this->restaurant->id}/staff/{$staff->id}", [
                'role' => 'directeur',
            ]);

        $response->assertStatus(422);
    }

    public function test_update_refuse_un_non_proprietaire(): void
    {
        $member = User::factory()->create();
        $staff = $this->createStaff($member, 'waiter');

        $response = $this->actingAs($this->other)
            ->putJson("/api/restaurants/{$this->restaurant->id}/staff/{$staff->id}", [
                'role' => 'cashier',
            ]);

        $response->assertStatus(403);
    }

    // =========================================================================
    // DELETE /api/restaurants/{restaurant}/staff/{staff}
    // =========================================================================

    public function test_destroy_retire_un_membre_du_personnel(): void
    {
        $member = User::factory()->create();
        $staff = $this->createStaff($member, 'waiter');

        $response = $this->actingAs($this->owner)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/staff/{$staff->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('restaurant_staff', ['id' => $staff->id]);
    }

    public function test_destroy_refuse_de_supprimer_le_proprietaire_principal(): void
    {
        // Créer une entrée staff pour le propriétaire lui-même
        $ownerStaff = RestaurantStaff::create([
            'user_id' => $this->owner->id,
            'restaurant_id' => $this->restaurant->id,
            'role' => 'owner',
            'is_active' => true,
        ]);

        $response = $this->actingAs($this->owner)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/staff/{$ownerStaff->id}");

        $response->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertDatabaseHas('restaurant_staff', ['id' => $ownerStaff->id]);
    }

    public function test_destroy_refuse_un_non_proprietaire(): void
    {
        $member = User::factory()->create();
        $staff = $this->createStaff($member, 'waiter');

        $response = $this->actingAs($this->other)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/staff/{$staff->id}");

        $response->assertStatus(403);
    }

    public function test_destroy_refuse_suppression_personnel_autre_restaurant(): void
    {
        $otherRestaurant = Restaurant::create([
            'user_id' => $this->other->id,
            'nom' => 'Autre Maquis',
            'telephone' => '71111111',
            'adresse' => 'Bobo',
            'is_active' => true,
        ]);
        $member = User::factory()->create();
        $foreignStaff = RestaurantStaff::create([
            'user_id' => $member->id,
            'restaurant_id' => $otherRestaurant->id,
            'role' => 'waiter',
            'is_active' => true,
        ]);

        $response = $this->actingAs($this->owner)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/staff/{$foreignStaff->id}");

        // Le staff appartient à un autre restaurant → le contrôleur retourne 404 (ressource introuvable)
        $response->assertStatus(404);
    }

    // =========================================================================
    // GET /api/auth/my-restaurants
    // =========================================================================

    public function test_my_restaurants_retourne_les_restaurants_du_proprietaire(): void
    {
        $response = $this->actingAs($this->owner)
            ->getJson('/api/auth/my-restaurants');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'nom', 'role', 'role_label', 'permissions'],
                ],
            ]);

        $ids = collect($response->json('data'))->pluck('id');
        $this->assertTrue($ids->contains($this->restaurant->id));
    }

    public function test_my_restaurants_inclut_les_restaurants_staff(): void
    {
        $staffUser = User::factory()->create();
        $this->createStaff($staffUser, 'manager');

        $response = $this->actingAs($staffUser)
            ->getJson('/api/auth/my-restaurants');

        $response->assertStatus(200);
        $ids = collect($response->json('data'))->pluck('id');
        $this->assertTrue($ids->contains($this->restaurant->id));
    }

    public function test_my_restaurants_refuse_un_utilisateur_non_authentifie(): void
    {
        $response = $this->getJson('/api/auth/my-restaurants');

        $response->assertStatus(401);
    }

    public function test_my_restaurants_expose_kitchen_display_pour_waiter(): void
    {
        $waiter = User::factory()->create();
        $this->createStaff($waiter, 'waiter');

        $response = $this->actingAs($waiter)
            ->getJson('/api/auth/my-restaurants');

        $response->assertStatus(200);
        $restaurant = collect($response->json('data'))->firstWhere('id', $this->restaurant->id);

        $this->assertNotNull($restaurant);
        $this->assertContains('manage_orders', $restaurant['permissions']);
        $this->assertContains('kitchen_display', $restaurant['permissions']);
        $this->assertNotContains('view_stats', $restaurant['permissions']);
    }
}
