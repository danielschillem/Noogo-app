<?php

namespace Tests\Feature\Api;

use App\Models\AdminAuditLog;
use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_peut_mettre_a_jour_la_licence_d_un_restaurant(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $owner = User::factory()->create(['is_admin' => false]);
        $restaurant = Restaurant::create([
            'user_id' => $owner->id,
            'nom' => 'Resto licence',
            'telephone' => '70000000',
            'adresse' => 'Ouaga',
            'is_active' => true,
        ]);

        $response = $this->actingAs($admin)
            ->putJson("/api/admin/restaurants/{$restaurant->id}/license", [
                'license_status' => 'suspended',
                'license_plan' => 'pro',
                'license_max_staff' => 20,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.license_status', 'suspended')
            ->assertJsonPath('data.license_plan', 'pro')
            ->assertJsonPath('data.license_max_staff', 20);
    }

    public function test_admin_peut_consulter_les_journaux_d_audit(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        AdminAuditLog::create([
            'admin_user_id' => $admin->id,
            'action' => 'admin.test.action',
            'target_type' => 'restaurant',
            'target_id' => 1,
            'metadata' => ['foo' => 'bar'],
        ]);

        $response = $this->actingAs($admin)
            ->getJson('/api/admin/audit-logs');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.data.0.action', 'admin.test.action');
    }

    public function test_non_admin_ne_peut_pas_gerer_les_licences(): void
    {
        $user = User::factory()->create(['is_admin' => false]);
        $restaurant = Restaurant::create([
            'user_id' => $user->id,
            'nom' => 'Resto non admin',
            'telephone' => '71111111',
            'adresse' => 'Bobo',
            'is_active' => true,
        ]);

        $this->actingAs($user)
            ->putJson("/api/admin/restaurants/{$restaurant->id}/license", [
                'license_status' => 'active',
            ])
            ->assertStatus(403);
    }
}

