<?php

namespace Tests\Feature\Api;

use App\Models\Coupon;
use App\Models\Restaurant;
use App\Models\RestaurantStaff;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests pour CouponController
 *
 *   GET    /api/restaurants/{restaurant}/coupons            (index)
 *   POST   /api/restaurants/{restaurant}/coupons            (store)
 *   PUT    /api/restaurants/{restaurant}/coupons/{coupon}   (update)
 *   DELETE /api/restaurants/{restaurant}/coupons/{coupon}   (destroy)
 *   POST   /api/restaurants/{restaurant}/coupons/{coupon}/toggle-active
 *   POST   /api/coupons/validate                            (public, throttlé)
 */
class CouponControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private User $stranger;
    private Restaurant $restaurant;

    protected function setUp(): void
    {
        parent::setUp();

        $this->owner = User::factory()->create(['is_admin' => false]);
        $this->stranger = User::factory()->create(['is_admin' => false]);

        $this->restaurant = Restaurant::create([
            'user_id' => $this->owner->id,
            'nom' => 'Maquis Test',
            'telephone' => '70000000',
            'adresse' => 'Ouagadougou',
            'is_active' => true,
        ]);
    }

    private function makeCoupon(array $overrides = []): Coupon
    {
        return Coupon::create(array_merge([
            'restaurant_id' => $this->restaurant->id,
            'code' => 'TEST10',
            'type' => 'percentage',
            'value' => 10,
            'is_active' => true,
        ], $overrides));
    }

    // =========================================================================
    // GET /api/restaurants/{restaurant}/coupons  — index
    // =========================================================================

    public function test_proprietaire_peut_lister_ses_coupons(): void
    {
        $this->makeCoupon(['code' => 'PROMO10']);
        $this->makeCoupon(['code' => 'PROMO20', 'type' => 'fixed', 'value' => 500]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/coupons");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure([
                'data' => ['*' => ['id', 'code', 'type', 'value', 'is_active']],
            ]);
    }

    public function test_staff_manager_peut_lister_les_coupons(): void
    {
        $staffUser = User::factory()->create(['is_admin' => false]);
        RestaurantStaff::create([
            'user_id' => $staffUser->id,
            'restaurant_id' => $this->restaurant->id,
            'role' => 'manager',
            'is_active' => true,
        ]);
        $this->makeCoupon();

        $response = $this->actingAs($staffUser)
            ->getJson("/api/restaurants/{$this->restaurant->id}/coupons");

        $response->assertStatus(200)->assertJsonPath('success', true);
    }

    public function test_utilisateur_tiers_ne_peut_pas_lister_les_coupons(): void
    {
        $this->actingAs($this->stranger)
            ->getJson("/api/restaurants/{$this->restaurant->id}/coupons")
            ->assertStatus(403);
    }

    public function test_non_authentifie_ne_peut_pas_lister_les_coupons(): void
    {
        $this->getJson("/api/restaurants/{$this->restaurant->id}/coupons")
            ->assertStatus(401);
    }

    // =========================================================================
    // POST /api/restaurants/{restaurant}/coupons  — store
    // =========================================================================

    public function test_proprietaire_peut_creer_un_coupon_pourcentage(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/coupons", [
                'code' => 'WELCOME',
                'type' => 'percentage',
                'value' => 15,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.code', 'WELCOME')
            ->assertJsonPath('data.type', 'percentage');

        $this->assertDatabaseHas('coupons', ['code' => 'WELCOME', 'restaurant_id' => $this->restaurant->id]);
    }

    public function test_proprietaire_peut_creer_un_coupon_fixe(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/coupons", [
                'code' => 'FLAT500',
                'type' => 'fixed',
                'value' => 500,
                'min_order' => 2000,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.type', 'fixed')
            ->assertJsonPath('data.code', 'FLAT500');
    }

    public function test_le_code_est_automatiquement_mis_en_majuscules(): void
    {
        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/coupons", [
                'code' => 'welcome',
                'type' => 'percentage',
                'value' => 10,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.code', 'WELCOME');
    }

    public function test_code_duplique_retourne_422(): void
    {
        $this->makeCoupon(['code' => 'DUPLI']);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/coupons", [
                'code' => 'DUPLI',
                'type' => 'percentage',
                'value' => 5,
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_validation_echoue_sans_champs_obligatoires(): void
    {
        $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/coupons", [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['code', 'type', 'value']);
    }

    public function test_type_invalide_retourne_422(): void
    {
        $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/coupons", [
                'code' => 'INVALID',
                'type' => 'cashback',
                'value' => 10,
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['type']);
    }

    public function test_utilisateur_tiers_ne_peut_pas_creer_un_coupon(): void
    {
        $this->actingAs($this->stranger)
            ->postJson("/api/restaurants/{$this->restaurant->id}/coupons", [
                'code' => 'HACK',
                'type' => 'percentage',
                'value' => 100,
            ])
            ->assertStatus(403);
    }

    // =========================================================================
    // PUT /api/restaurants/{restaurant}/coupons/{coupon}  — update
    // =========================================================================

    public function test_proprietaire_peut_modifier_un_coupon(): void
    {
        $coupon = $this->makeCoupon(['code' => 'OLD10']);

        $response = $this->actingAs($this->owner)
            ->putJson("/api/restaurants/{$this->restaurant->id}/coupons/{$coupon->id}", [
                'value' => 20,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.value', '20.00');

        $this->assertDatabaseHas('coupons', ['id' => $coupon->id, 'value' => 20]);
    }

    public function test_mise_a_jour_vers_code_duplique_retourne_422(): void
    {
        $coupon1 = $this->makeCoupon(['code' => 'FIRST']);
        $coupon2 = $this->makeCoupon(['code' => 'SECOND']);

        $this->actingAs($this->owner)
            ->putJson("/api/restaurants/{$this->restaurant->id}/coupons/{$coupon2->id}", [
                'code' => 'FIRST',
            ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_coupon_appartenant_a_un_autre_restaurant_retourne_404(): void
    {
        $otherOwner = User::factory()->create(['is_admin' => false]);
        $otherRestaurant = Restaurant::create([
            'user_id' => $otherOwner->id,
            'nom' => 'Autre',
            'telephone' => '70000099',
            'adresse' => 'Bobo',
            'is_active' => true,
        ]);
        $otherCoupon = Coupon::create([
            'restaurant_id' => $otherRestaurant->id,
            'code' => 'FOREIGN',
            'type' => 'fixed',
            'value' => 100,
        ]);

        $this->actingAs($this->owner)
            ->putJson("/api/restaurants/{$this->restaurant->id}/coupons/{$otherCoupon->id}", [
                'value' => 50,
            ])
            ->assertStatus(404);
    }

    public function test_utilisateur_tiers_ne_peut_pas_modifier_un_coupon(): void
    {
        $coupon = $this->makeCoupon();

        $this->actingAs($this->stranger)
            ->putJson("/api/restaurants/{$this->restaurant->id}/coupons/{$coupon->id}", [
                'value' => 5,
            ])
            ->assertStatus(403);
    }

    // =========================================================================
    // DELETE /api/restaurants/{restaurant}/coupons/{coupon}  — destroy
    // =========================================================================

    public function test_proprietaire_peut_supprimer_un_coupon(): void
    {
        $coupon = $this->makeCoupon();

        $this->actingAs($this->owner)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/coupons/{$coupon->id}")
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('coupons', ['id' => $coupon->id]);
    }

    public function test_utilisateur_tiers_ne_peut_pas_supprimer_un_coupon(): void
    {
        $coupon = $this->makeCoupon();

        $this->actingAs($this->stranger)
            ->deleteJson("/api/restaurants/{$this->restaurant->id}/coupons/{$coupon->id}")
            ->assertStatus(403);
    }

    // =========================================================================
    // POST /api/restaurants/{restaurant}/coupons/{coupon}/toggle-active
    // =========================================================================

    public function test_proprietaire_peut_basculer_letat_actif(): void
    {
        $coupon = $this->makeCoupon(['is_active' => true]);

        $response = $this->actingAs($this->owner)
            ->postJson("/api/restaurants/{$this->restaurant->id}/coupons/{$coupon->id}/toggle-active");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.is_active', false);

        $this->assertDatabaseHas('coupons', ['id' => $coupon->id, 'is_active' => false]);
    }

    public function test_toggle_actif_twice_remet_is_active_a_true(): void
    {
        $coupon = $this->makeCoupon(['is_active' => true]);
        $base = "/api/restaurants/{$this->restaurant->id}/coupons/{$coupon->id}/toggle-active";

        $this->actingAs($this->owner)->postJson($base)->assertStatus(200);
        $this->actingAs($this->owner)->postJson($base)
            ->assertStatus(200)
            ->assertJsonPath('data.is_active', true);
    }

    // =========================================================================
    // POST /api/coupons/validate  — validation publique
    // =========================================================================

    public function test_coupon_valide_retourne_le_discount(): void
    {
        $coupon = $this->makeCoupon([
            'code' => 'SAVE10',
            'type' => 'percentage',
            'value' => 10,
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/coupons/validate', [
            'code' => 'SAVE10',
            'restaurant_id' => $this->restaurant->id,
            'order_total' => 5000,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.coupon_id', $coupon->id)
            ->assertJsonPath('data.discount', 500.0)
            ->assertJsonPath('data.new_total', 4500.0);
    }

    public function test_coupon_fixe_retourne_le_bon_discount(): void
    {
        $this->makeCoupon([
            'code' => 'FLAT200',
            'type' => 'fixed',
            'value' => 200,
        ]);

        $this->postJson('/api/coupons/validate', [
            'code' => 'FLAT200',
            'restaurant_id' => $this->restaurant->id,
            'order_total' => 3000,
        ])
            ->assertStatus(200)
            ->assertJsonPath('data.discount', 200.0)
            ->assertJsonPath('data.new_total', 2800.0);
    }

    public function test_coupon_avec_max_discount_est_plafonné(): void
    {
        $this->makeCoupon([
            'code' => 'CAP',
            'type' => 'percentage',
            'value' => 50,
            'max_discount' => 500,
        ]);

        $this->postJson('/api/coupons/validate', [
            'code' => 'CAP',
            'restaurant_id' => $this->restaurant->id,
            'order_total' => 5000,
        ])
            ->assertStatus(200)
            ->assertJsonPath('data.discount', 500.0);
    }

    public function test_code_inexistant_retourne_422(): void
    {
        $this->postJson('/api/coupons/validate', [
            'code' => 'INEXISTANT',
            'restaurant_id' => $this->restaurant->id,
            'order_total' => 1000,
        ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_coupon_inactif_retourne_422(): void
    {
        $this->makeCoupon(['code' => 'OFF', 'is_active' => false]);

        $this->postJson('/api/coupons/validate', [
            'code' => 'OFF',
            'restaurant_id' => $this->restaurant->id,
            'order_total' => 1000,
        ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_coupon_en_dessous_du_montant_minimum_retourne_422(): void
    {
        $this->makeCoupon(['code' => 'MINORD', 'min_order' => 3000]);

        $this->postJson('/api/coupons/validate', [
            'code' => 'MINORD',
            'restaurant_id' => $this->restaurant->id,
            'order_total' => 1000,
        ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_coupon_expire_retourne_422(): void
    {
        $this->makeCoupon([
            'code' => 'EXP',
            'expires_at' => now()->subDay(),
        ]);

        $this->postJson('/api/coupons/validate', [
            'code' => 'EXP',
            'restaurant_id' => $this->restaurant->id,
            'order_total' => 1000,
        ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_coupon_max_uses_atteint_retourne_422(): void
    {
        $this->makeCoupon([
            'code' => 'MAXED',
            'max_uses' => 5,
            'used_count' => 5,
        ]);

        $this->postJson('/api/coupons/validate', [
            'code' => 'MAXED',
            'restaurant_id' => $this->restaurant->id,
            'order_total' => 1000,
        ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_validation_sans_champs_obligatoires_retourne_422(): void
    {
        $this->postJson('/api/coupons/validate', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['code', 'restaurant_id', 'order_total']);
    }
}
