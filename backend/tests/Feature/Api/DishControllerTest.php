<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Dish;
use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests pour les endpoints DishController (authentifiés) :
 *   GET    /api/restaurants/{restaurant}/dishes
 *   POST   /api/restaurants/{restaurant}/dishes
 *   GET    /api/restaurants/{restaurant}/dishes/{dish}
 *   PUT    /api/restaurants/{restaurant}/dishes/{dish}
 *   DELETE /api/restaurants/{restaurant}/dishes/{dish}
 *   POST   /api/restaurants/{restaurant}/dishes/{dish}/toggle-availability
 *   POST   /api/restaurants/{restaurant}/dishes/{dish}/toggle-plat-du-jour
 *   GET    /api/restaurants/{restaurant}/plats-du-jour
 *   POST   /api/restaurants/{restaurant}/dishes/reorder
 */
class DishControllerTest extends TestCase
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
            'nom' => 'Resto Test',
            'telephone' => '70000001',
            'adresse' => 'Ouagadougou',
            'is_active' => true,
        ]);

        $this->category = Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Entrées',
            'is_active' => true,
        ]);

        $this->dish = Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Salade César',
            'prix' => 1200,
            'disponibilite' => true,
            'is_plat_du_jour' => false,
        ]);
    }

    // =========================================================================
    // INDEX
    // =========================================================================

    public function test_index_retourne_la_liste_des_plats(): void
    {
        Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Soupe',
            'prix' => 800,
            'disponibilite' => true,
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/dishes");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data.data');
    }

    public function test_index_filtre_par_categorie(): void
    {
        $otherCat = Category::create([
            'restaurant_id' => $this->restaurant->id,
            'nom' => 'Desserts',
            'is_active' => true,
        ]);
        Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $otherCat->id,
            'nom' => 'Glace',
            'prix' => 500,
            'disponibilite' => true,
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/dishes?category_id={$this->category->id}");

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data.data'));
        $this->assertEquals('Salade César', $response->json('data.data.0.nom'));
    }

    public function test_index_filtre_par_disponibilite(): void
    {
        Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Plat indisponible',
            'prix' => 1000,
            'disponibilite' => false,
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/dishes?available=1");

        $response->assertStatus(200);
        foreach ($response->json('data.data') as $d) {
            $this->assertTrue($d['disponibilite']);
        }
    }

    public function test_index_refuse_sans_authentification(): void
    {
        $this->getJson("/api/restaurants/{$this->restaurant->id}/dishes")
            ->assertStatus(401);
    }

    // =========================================================================
    // STORE
    // =========================================================================

    public function test_store_cree_un_plat_valide(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes", [
                'category_id' => $this->category->id,
                'nom' => 'Brochettes de bœuf',
                'prix' => 2500,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.nom', 'Brochettes de bœuf');

        $this->assertDatabaseHas('dishes', [
            'nom' => 'Brochettes de bœuf',
            'restaurant_id' => $this->restaurant->id,
        ]);
    }

    public function test_store_echoue_si_categorie_appartient_a_un_autre_restaurant(): void
    {
        $otherRestaurant = Restaurant::create([
            'user_id' => $this->other->id,
            'nom' => 'Autre',
            'telephone' => '71000000',
            'adresse' => 'Bobo',
            'is_active' => true,
        ]);
        $foreignCat = Category::create([
            'restaurant_id' => $otherRestaurant->id,
            'nom' => 'Cat étrangère',
            'is_active' => true,
        ]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes", [
                'category_id' => $foreignCat->id,
                'nom' => 'Plat',
                'prix' => 1000,
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_store_echoue_si_prix_manquant(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes", [
                'category_id' => $this->category->id,
                'nom' => 'Plat sans prix',
            ]);

        $response->assertStatus(422);
    }

    public function test_store_refuse_un_utilisateur_non_proprietaire(): void
    {
        $response = $this->actingAs($this->other)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes", [
                'category_id' => $this->category->id,
                'nom' => 'Plat interdit',
                'prix' => 1000,
            ]);

        $response->assertStatus(403);
    }

    public function test_store_refuse_sans_authentification(): void
    {
        $this->postJson("/api/restaurants/{$this->restaurant->id}/dishes", [
            'category_id' => $this->category->id,
            'nom' => 'Plat',
            'prix' => 1000,
        ])->assertStatus(401);
    }

    // =========================================================================
    // SHOW
    // =========================================================================

    public function test_show_retourne_un_plat(): void
    {
        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/dishes/{$this->dish->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $this->dish->id)
            ->assertJsonPath('data.nom', 'Salade César');
    }

    // =========================================================================
    // UPDATE
    // =========================================================================

    public function test_update_modifie_le_nom_et_le_prix(): void
    {
        $response = $this->actingAs($this->owner)
            ->putJson("/api/restaurants/{$this->restaurant->id}/dishes/{$this->dish->id}", [
                'nom' => 'Salade Niçoise',
                'prix' => 1500,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.nom', 'Salade Niçoise')
            ->assertJsonPath('data.prix', '1500.00');

        $this->assertDatabaseHas('dishes', ['id' => $this->dish->id, 'nom' => 'Salade Niçoise']);
    }

    public function test_update_refuse_un_utilisateur_non_proprietaire(): void
    {
        $response = $this->actingAs($this->other)
            ->putJson("/api/restaurants/{$this->restaurant->id}/dishes/{$this->dish->id}", [
                'nom' => 'Tentative',
                'prix' => 999,
            ]);

        $response->assertStatus(403);
    }

    // =========================================================================
    // DESTROY
    // =========================================================================

    public function test_destroy_supprime_un_plat(): void
    {
        $response = $this->actingAs($this->owner)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/dishes/{$this->dish->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertSoftDeleted('dishes', ['id' => $this->dish->id]);
    }

    public function test_destroy_refuse_un_utilisateur_non_proprietaire(): void
    {
        $response = $this->actingAs($this->other)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/dishes/{$this->dish->id}");

        $response->assertStatus(403);
        $this->assertDatabaseHas('dishes', ['id' => $this->dish->id, 'deleted_at' => null]);
    }

    // =========================================================================
    // TOGGLE AVAILABILITY
    // =========================================================================

    public function test_toggle_availability_passe_indisponible(): void
    {
        $this->assertTrue($this->dish->disponibilite);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes/{$this->dish->id}/toggle-availability");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('dishes', ['id' => $this->dish->id, 'disponibilite' => false]);
    }

    public function test_toggle_availability_passe_disponible(): void
    {
        $this->dish->update(['disponibilite' => false]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes/{$this->dish->id}/toggle-availability");

        $response->assertStatus(200);
        $this->assertDatabaseHas('dishes', ['id' => $this->dish->id, 'disponibilite' => true]);
    }

    // =========================================================================
    // TOGGLE PLAT DU JOUR
    // =========================================================================

    public function test_toggle_plat_du_jour_active(): void
    {
        $this->assertFalse((bool) $this->dish->is_plat_du_jour);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes/{$this->dish->id}/toggle-plat-du-jour");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('dishes', ['id' => $this->dish->id, 'is_plat_du_jour' => true]);
    }

    public function test_toggle_plat_du_jour_desactive(): void
    {
        $this->dish->update(['is_plat_du_jour' => true]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes/{$this->dish->id}/toggle-plat-du-jour");

        $response->assertStatus(200);
        $this->assertDatabaseHas('dishes', ['id' => $this->dish->id, 'is_plat_du_jour' => false]);
    }

    // =========================================================================
    // PLATS DU JOUR
    // =========================================================================

    public function test_plats_du_jour_retourne_uniquement_les_plats_du_jour_disponibles(): void
    {
        $this->dish->update(['is_plat_du_jour' => true, 'disponibilite' => true]);

        // Plat non plat du jour
        Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Plat ordinaire',
            'prix' => 1000,
            'disponibilite' => true,
            'is_plat_du_jour' => false,
        ]);

        // Plat du jour mais indisponible
        Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'PDJ inactif',
            'prix' => 1000,
            'disponibilite' => false,
            'is_plat_du_jour' => true,
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/plats-du-jour");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals('Salade César', $data[0]['nom']);
    }

    // =========================================================================
    // REORDER
    // =========================================================================

    public function test_reorder_met_a_jour_l_ordre_des_plats(): void
    {
        $dish2 = Dish::create([
            'restaurant_id' => $this->restaurant->id,
            'category_id' => $this->category->id,
            'nom' => 'Plat 2',
            'prix' => 1000,
            'disponibilite' => true,
            'ordre' => 1,
        ]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes/reorder", [
                'dishes' => [
                    ['id' => $this->dish->id, 'ordre' => 10],
                    ['id' => $dish2->id, 'ordre' => 5],
                ],
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('dishes', ['id' => $this->dish->id, 'ordre' => 10]);
        $this->assertDatabaseHas('dishes', ['id' => $dish2->id, 'ordre' => 5]);
    }

    public function test_reorder_echoue_si_payload_invalide(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/dishes/reorder", [
                'dishes' => [
                    ['id' => $this->dish->id], // ordre manquant
                ],
            ]);

        $response->assertStatus(422);
    }
}
