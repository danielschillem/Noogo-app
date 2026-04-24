<?php

namespace Tests\Feature\Api;

use App\Models\OralOrderNote;
use App\Models\Restaurant;
use App\Models\RestaurantStaff;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OralOrderNoteControllerTest extends TestCase
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
            'nom' => 'Resto notes orales',
            'telephone' => '70000000',
            'adresse' => 'Ouagadougou',
            'is_active' => true,
        ]);
    }

    private function attachStaff(User $user, string $role, ?Restaurant $restaurant = null): RestaurantStaff
    {
        return RestaurantStaff::create([
            'user_id' => $user->id,
            'restaurant_id' => ($restaurant ?? $this->restaurant)->id,
            'role' => $role,
            'is_active' => true,
        ]);
    }

    public function test_waiter_peut_lister_et_creer_des_notes_orales(): void
    {
        $waiter = User::factory()->create(['is_admin' => false]);
        $this->attachStaff($waiter, 'waiter');

        $this->actingAs($waiter)
            ->postJson("/api/restaurants/{$this->restaurant->id}/oral-order-notes", [
                'title' => 'Table 7',
                'staff_comment' => 'Sans piment',
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.title', 'Table 7');

        $this->actingAs($waiter)
            ->getJson("/api/restaurants/{$this->restaurant->id}/oral-order-notes")
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data.data');
    }

    public function test_utilisateur_sans_manage_orders_est_refuse_sur_notes_orales(): void
    {
        $response = $this->actingAs($this->other)
            ->getJson("/api/restaurants/{$this->restaurant->id}/oral-order-notes");

        $response->assertStatus(403);
    }

    public function test_show_refuse_une_note_dun_autre_restaurant(): void
    {
        $otherRestaurant = Restaurant::create([
            'user_id' => $this->other->id,
            'nom' => 'Autre resto',
            'telephone' => '71111111',
            'adresse' => 'Bobo',
            'is_active' => true,
        ]);

        $foreignNote = OralOrderNote::create([
            'restaurant_id' => $otherRestaurant->id,
            'user_id' => $this->other->id,
            'status' => 'draft',
            'title' => 'Note externe',
        ]);

        $response = $this->actingAs($this->owner)
            ->getJson("/api/restaurants/{$this->restaurant->id}/oral-order-notes/{$foreignNote->id}");

        $response->assertStatus(404);
    }
}
