<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * Tests pour les endpoints d'authentification :
 *   POST /api/auth/register
 *   POST /api/auth/login
 */
class AuthControllerTest extends TestCase
{
    use RefreshDatabase;

    // =========================================================================
    // REGISTER
    // =========================================================================

    public function test_register_cree_un_utilisateur_et_retourne_token(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Alice Test',
            'telephone' => '70123456',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['user', 'token', 'token_type']]);

        $this->assertDatabaseHas('users', ['phone' => '70123456']);
    }

    public function test_register_echoue_si_telephone_deja_utilise(): void
    {
        User::factory()->create(['phone' => '70999999']);

        $response = $this->postJson('/api/auth/register', [
            'name' => 'Bob',
            'telephone' => '70999999',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_register_echoue_si_password_confirmation_ne_correspond_pas(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Charlie',
            'telephone' => '71000000',
            'password' => 'secret123',
            'password_confirmation' => 'different',
        ]);

        $response->assertStatus(422);
    }

    public function test_register_echoue_si_password_trop_court(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Dan',
            'telephone' => '72000000',
            'password' => '12345',
            'password_confirmation' => '12345',
        ]);

        $response->assertStatus(422);
    }

    // =========================================================================
    // LOGIN
    // =========================================================================

    public function test_login_par_telephone_retourne_token(): void
    {
        User::factory()->create([
            'phone' => '75555555',
            'password' => bcrypt('monmotdepasse'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'telephone' => '75555555',
            'password' => 'monmotdepasse',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['token']]);
    }

    public function test_login_par_email_retourne_token(): void
    {
        User::factory()->create([
            'email' => 'admin@noogo.bf',
            'password' => bcrypt('adminpass'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'admin@noogo.bf',
            'password' => 'adminpass',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_login_echoue_avec_mauvais_mot_de_passe(): void
    {
        User::factory()->create([
            'phone' => '76000000',
            'password' => bcrypt('correct'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'telephone' => '76000000',
            'password' => 'incorrect',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_login_echoue_sans_telephone_ni_email(): void
    {
        $response = $this->postJson('/api/auth/login', [
            'password' => 'test1234',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_login_echoue_pour_utilisateur_inexistant(): void
    {
        $response = $this->postJson('/api/auth/login', [
            'telephone' => '99999999',
            'password' => 'nimporte',
        ]);

        $response->assertStatus(401);
    }

    // =========================================================================
    // FORGOT PASSWORD
    // =========================================================================

    public function test_forgot_password_par_telephone_retourne_token(): void
    {
        User::factory()->create(['phone' => '77001122', 'email' => null]);

        $response = $this->postJson('/api/auth/forgot-password', [
            'telephone' => '77001122',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['reset_token']]);

        $this->assertDatabaseHas('password_reset_tokens', ['email' => '77001122']);
    }

    public function test_forgot_password_par_email_retourne_token(): void
    {
        User::factory()->create(['email' => 'user@noogo.bf']);

        $response = $this->postJson('/api/auth/forgot-password', [
            'email' => 'user@noogo.bf',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['reset_token']]);

        $this->assertDatabaseHas('password_reset_tokens', ['email' => 'user@noogo.bf']);
    }

    public function test_forgot_password_compte_inexistant_ne_revele_pas_existence(): void
    {
        $response = $this->postJson('/api/auth/forgot-password', [
            'telephone' => '00000000',
        ]);

        // Doit renvoyer 200 pour ne pas révéler qu'aucun compte n'existe
        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('password_reset_tokens', ['email' => '00000000']);
    }

    public function test_forgot_password_sans_identifiant_echoue(): void
    {
        $response = $this->postJson('/api/auth/forgot-password', []);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // RESET PASSWORD
    // =========================================================================

    public function test_reset_password_avec_token_valide_met_a_jour_password(): void
    {
        $user = User::factory()->create([
            'phone' => '77112233',
            'email' => null,
            'password' => bcrypt('ancien'),
        ]);

        DB::table('password_reset_tokens')->insert([
            'email' => '77112233',
            'token' => 'tokenvalide123',
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/auth/reset-password', [
            'token' => 'tokenvalide123',
            'password' => 'nouveau123',
            'password_confirmation' => 'nouveau123',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        // Vérifier que l'ancien mot de passe ne fonctionne plus
        $this->assertFalse(
            \Illuminate\Support\Facades\Hash::check('ancien', $user->fresh()->password)
        );

        // Token consommé (usage unique)
        $this->assertDatabaseMissing('password_reset_tokens', ['token' => 'tokenvalide123']);
    }

    public function test_reset_password_avec_token_invalide_echoue(): void
    {
        $response = $this->postJson('/api/auth/reset-password', [
            'token' => 'tokenbidonnexistepas',
            'password' => 'nouveau123',
            'password_confirmation' => 'nouveau123',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_reset_password_avec_token_expire_echoue(): void
    {
        User::factory()->create(['phone' => '77223344', 'email' => null]);

        DB::table('password_reset_tokens')->insert([
            'email' => '77223344',
            'token' => 'tokenexpire999',
            'created_at' => now()->subMinutes(61),
        ]);

        $response = $this->postJson('/api/auth/reset-password', [
            'token' => 'tokenexpire999',
            'password' => 'nouveau123',
            'password_confirmation' => 'nouveau123',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);

        // Token supprimé même expiré
        $this->assertDatabaseMissing('password_reset_tokens', ['token' => 'tokenexpire999']);
    }

    public function test_reset_password_confirmation_invalide_echoue(): void
    {
        DB::table('password_reset_tokens')->insert([
            'email' => 'x@test.com',
            'token' => 'tokenconftestXXX',
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/auth/reset-password', [
            'token' => 'tokenconftestXXX',
            'password' => 'nouveau123',
            'password_confirmation' => 'different456',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_reset_password_sans_token_echoue(): void
    {
        $response = $this->postJson('/api/auth/reset-password', [
            'password' => 'nouveau123',
            'password_confirmation' => 'nouveau123',
        ]);

        $response->assertStatus(422);
    }
}
