<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Dish;
use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests pour les endpoints CategoryController (authentifiés) :
 *   GET    /api/restaurants/{restaurant}/categories
 *   POST   /api/restaurants/{restaurant}/categories
 *   GET    /api/restaurants/{restaurant}/categories/{category}
 *   PUT    /api/restaurants/{restaurant}/categories/{category}
 *   DELETE /api/restaurants/{restaurant}/categories/{category}
 *   POST   /api/restaurants/{restaurant}/categories/reorder
 *   POST   /api/restaurants/{restaurant}/categories/{category}/toggle-active
 */
class CategoryControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private User $other;
    private Restaurant $restaurant;
    private Category $category;

    protected function setUp(): void
    {
        parent::setUp();

        $this->owner = User::factory()->create(['is_admin' => false]);
        $this->other = User::factory()->create(['is_admin' => false]);

        $this->restaurant = Restaurant::create([
            'user_id' => $this->owner->id,
            'nom' => 'Resto Test',
            'telephone' => '70000001',
            'adresse' => 'Ouagadougou',
            'is_active' => true,
        ]);

        $this->category = Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Entrées',
            'is_active' => true,
            'ordre' => 0,
        ]);
    }

    // =========================================================================
    // INDEX
    // =========================================================================

    public function test_index_retourne_les_categories_du_restaurant(): void
    {
        Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Plats',
            'is_active' => true,
            'ordre' => 1,
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/categories");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data');
    }

    public function test_index_filtre_par_active(): void
    {
        Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Desserts',
            'is_active' => false,
            'ordre' => 1,
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/categories?active=1");

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_index_non_authentifie_retourne_401(): void
    {
        $this->getJson("/api/restaurants/{$this->restaurant->id}/categories")
            ->assertStatus(401);
    }

    // =========================================================================
    // STORE
    // =========================================================================

    public function test_store_cree_une_categorie_valide(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/categories", [
                'nom' => 'Boissons',
                'description' => 'Toutes nos boissons',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.nom', 'Boissons');

        $this->assertDatabaseHas('categories', [
            'nom' => 'Boissons',
            'restaurant_id' => $this->restaurant->id,
        ]);
    }

    public function test_store_assigne_ordre_automatiquement(): void
    {
        // La catégorie setUp a ordre=0, donc la nouvelle doit être à 1
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/categories", [
                'nom' => 'Plats',
            ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('categories', [
            'nom' => 'Plats',
            'ordre' => 1,
        ]);
    }

    public function test_store_echoue_sans_nom(): void
    {
        $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/categories", [
                'description' => 'Sans nom',
            ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_store_interdit_pour_non_proprietaire(): void
    {
        $this->actingAs($this->other)
            ->postJson("/api/restaurants/{$this->restaurant->id}/categories", [
                'nom' => 'Tentative',
            ])
            ->assertStatus(403);
    }

    public function test_store_non_authentifie_retourne_401(): void
    {
        $this->postJson("/api/restaurants/{$this->restaurant->id}/categories", [
            'nom' => 'Test',
        ])->assertStatus(401);
    }

    // =========================================================================
    // SHOW
    // =========================================================================

    public function test_show_retourne_une_categorie(): void
    {
        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/categories/{$this->category->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $this->category->id)
            ->assertJsonPath('data.nom', 'Entrées');
    }

    public function test_show_charge_les_plats_disponibles(): void
    {
        Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Salade',
            'prix' => 1000,
            'disponibilite' => true,
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/categories/{$this->category->id}");

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.dishes');
    }

    // =========================================================================
    // UPDATE
    // =========================================================================

    public function test_update_modifie_une_categorie(): void
    {
        $response = $this->actingAs($this->owner)
            ->putJson("/api/restaurants/{$this->restaurant->id}/categories/{$this->category->id}", [
                'nom' => 'Entrées modifiées',
                'is_active' => false,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.nom', 'Entrées modifiées');

        $this->assertDatabaseHas('categories', [
            'id' => $this->category->id,
            'nom' => 'Entrées modifiées',
            'is_active' => false,
        ]);
    }

    public function test_update_interdit_pour_non_proprietaire(): void
    {
        $this->actingAs($this->other)
            ->putJson("/api/restaurants/{$this->restaurant->id}/categories/{$this->category->id}", [
                'nom' => 'Tentative modif',
            ])
            ->assertStatus(403);
    }

    // =========================================================================
    // DESTROY
    // =========================================================================

    public function test_destroy_supprime_une_categorie_vide(): void
    {
        $response = $this->actingAs($this->owner)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/categories/{$this->category->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertSoftDeleted('categories', ['id' => $this->category->id]);
    }

    public function test_destroy_echoue_si_categorie_contient_des_plats(): void
    {
        Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Plat bloquant',
            'prix' => 500,
            'disponibilite' => true,
        ]);

        $this->actingAs($this->owner)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/categories/{$this->category->id}")
            ->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertDatabaseHas('categories', ['id' => $this->category->id]);
    }

    public function test_destroy_interdit_pour_non_proprietaire(): void
    {
        $this->actingAs($this->other)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/categories/{$this->category->id}")
            ->assertStatus(403);
    }

    // =========================================================================
    // REORDER
    // =========================================================================

    public function test_reorder_met_a_jour_lordre_des_categories(): void
    {
        $cat2 = Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Plats',
            'is_active' => true,
            'ordre' => 1,
        ]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/categories/reorder", [
                'categories' => [
                    ['id' => $this->category->id, 'ordre' => 1],
                    ['id' => $cat2->id, 'ordre' => 0],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('categories', ['id' => $this->category->id, 'ordre' => 1]);
        $this->assertDatabaseHas('categories', ['id' => $cat2->id, 'ordre' => 0]);
    }

    public function test_reorder_echoue_avec_payload_invalide(): void
    {
        $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/categories/reorder", [
                'categories' => 'invalide',
            ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // TOGGLE ACTIVE
    // =========================================================================

    public function test_toggle_active_desactive_une_categorie_active(): void
    {
        // category is_active = true → toggle → false
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/categories/{$this->category->id}/toggle-active");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('categories', [
            'id' => $this->category->id,
            'is_active' => false,
        ]);
    }

    public function test_toggle_active_active_une_categorie_inactive(): void
    {
        $this->category->update(['is_active' => false]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/categories/{$this->category->id}/toggle-active");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('categories', [
            'id' => $this->category->id,
            'is_active' => true,
        ]);
    }
}
