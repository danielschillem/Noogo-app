<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use App\Models\User;

class AuthController extends Controller
{
    /**
     * Register a new user
     * Accepte "telephone" (app mobile) mappé sur la colonne "phone"
     */
    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'telephone' => 'nullable|string|max:20|unique:users,phone',
            'email' => 'nullable|string|email|max:255|unique:users',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'phone' => $request->telephone,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Utilisateur créé avec succès',
            'data' => [
                'user' => $user,
                'token' => $token,
                'token_type' => 'Bearer',
            ]
        ], 201);
    }

    /**
     * Login user
     * Accepte "telephone" + "password" (app mobile)
     * Accepte "email" + "password" (dashboard React)
     */
    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'telephone' => 'nullable|string',
            'email' => 'nullable|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        if (empty($request->telephone) && empty($request->email)) {
            return response()->json([
                'success' => false,
                'message' => 'Email ou numéro de téléphone requis',
                'errors' => ['login' => ['Email ou numéro de téléphone requis']]
            ], 422);
        }

        // Recherche par email (dashboard) ou par téléphone (app mobile)
        $user = $request->filled('email')
            ? User::where('email', $request->email)->first()
            : User::where('phone', $request->telephone)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiants incorrects'
            ], 401);
        }

        // Révoquer les anciens tokens pour éviter l'accumulation
        $user->tokens()->delete();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Connexion réussie',
            'data' => [
                'user' => $user,
                'token' => $token,
                'token_type' => 'Bearer',
            ]
        ]);
    }

    /**
     * Get authenticated user
     */
    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $request->user()
        ]);
    }

    /**
     * Logout user
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Déconnexion réussie'
        ]);
    }

    /**
     * Refresh token
     */
    public function refresh(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->currentAccessToken()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'token' => $token,
                'token_type' => 'Bearer',
            ]
        ]);
    }

    /**
     * Update user profile (nom, telephone, email)
     */
    public function updateUser(Request $request): JsonResponse
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'telephone' => 'sometimes|string|max:20|unique:users,phone,' . $user->id,
            'email' => 'sometimes|nullable|string|email|max:255|unique:users,email,' . $user->id,
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        if ($request->has('name'))
            $user->name = $request->name;
        if ($request->has('telephone'))
            $user->phone = $request->telephone;
        if ($request->has('email'))
            $user->email = $request->email;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profil mis à jour',
            'user' => $user->fresh()
        ]);
    }

    /**
     * Demande de réinitialisation du mot de passe
     * POST /api/auth/forgot-password
     *
     * Accepte "telephone" (app mobile) ou "email" (dashboard).
     * Le token est retourné directement dans la réponse (MVP sans serveur email/SMS).
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'telephone' => 'nullable|string',
            'email' => 'nullable|email',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        if (empty($request->telephone) && empty($request->email)) {
            return response()->json([
                'success' => false,
                'message' => 'Email ou numéro de téléphone requis',
            ], 422);
        }

        $user = $request->filled('email')
            ? User::where('email', $request->email)->first()
            : User::where('phone', $request->telephone)->first();

        // Ne pas révéler si le compte existe (protection énumération)
        if (!$user) {
            return response()->json([
                'success' => true,
                'message' => 'Si ce compte existe, un code de réinitialisation a été généré',
            ]);
        }

        // Clé primaire de password_reset_tokens : email de l'user, ou phone si pas d'email
        $resetKey = $user->email ?? $user->phone;
        $token = Str::random(60);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $resetKey],
            ['token' => $token, 'created_at' => now()]
        );

        return response()->json([
            'success' => true,
            'message' => 'Code de réinitialisation généré',
            'data' => ['reset_token' => $token],
        ]);
    }

    /**
     * Réinitialisation du mot de passe
     * POST /api/auth/reset-password
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'token' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
            'password_confirmation' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        $record = DB::table('password_reset_tokens')
            ->where('token', $request->token)
            ->first();

        if (!$record) {
            return response()->json([
                'success' => false,
                'message' => 'Token invalide ou expiré',
            ], 422);
        }

        // Vérification de l'expiration (60 minutes)
        if ((now()->timestamp - strtotime($record->created_at)) > 3600) {
            DB::table('password_reset_tokens')
                ->where('token', $request->token)
                ->delete();

            return response()->json([
                'success' => false,
                'message' => 'Token expiré, veuillez recommencer',
            ], 422);
        }

        // La colonne « email » stocke l'email OU le phone selon le type d'utilisateur
        $key = $record->email;
        $user = User::where('email', $key)->orWhere('phone', $key)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur introuvable',
            ], 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        // Révoquer tous les tokens Sanctum (bonne pratique après reset)
        $user->tokens()->delete();

        // Consommer le token de reset (usage unique)
        DB::table('password_reset_tokens')
            ->where('token', $request->token)
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'Mot de passe mis à jour avec succès',
        ]);
    }
}
