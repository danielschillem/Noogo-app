<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Restaurant;
use App\Models\RestaurantStaff;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class StaffController extends Controller
{
    // ─── Labels & permissions par rôle ───────────────────────────────────────

    private const ROLE_LABELS = [
        'owner' => 'Propriétaire',
        'manager' => 'Gérant',
        'cashier' => 'Caissier',
        'waiter' => 'Serveur',
    ];

    private const ROLE_PERMISSIONS = [
        'owner' => [
            'manage_staff',
            'edit_restaurant',
            'manage_menu',
            'manage_orders',
            'view_stats',
            'kitchen_display',
        ],
        'manager' => [
            'edit_restaurant',
            'manage_menu',
            'manage_orders',
            'view_stats',
            'kitchen_display',
        ],
        'cashier' => [
            'manage_orders',
            'view_stats',
            'kitchen_display',
        ],
        'waiter' => [
            'manage_orders',
            // Aligné sur RestaurantStaff::canViewKitchenDisplay (cuisine / KDS)
            'kitchen_display',
        ],
    ];

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /**
     * Vérifie que l'utilisateur authentifié peut gérer le personnel d'un restaurant.
     * Seuls le super admin et le propriétaire (owner) le peuvent.
     */
    private function canManageStaff(Request $request, Restaurant $restaurant): bool
    {
        $user = $request->user();
        if ($user->is_admin) {
            return true;
        }
        // Propriétaire via restaurants.user_id
        if ($restaurant->user_id === $user->id) {
            return true;
        }
        // Propriétaire via restaurant_staff.role = owner
        $staff = $restaurant->staff()->where('user_id', $user->id)->where('is_active', true)->first();
        return $staff !== null && $staff->role === 'owner';
    }

    private function formatStaff(RestaurantStaff $staff): array
    {
        return [
            'id' => $staff->id,
            'user_id' => $staff->user_id,
            'name' => $staff->user->name,
            'email' => $staff->user->email,
            'phone' => $staff->user->phone,
            'role' => $staff->role,
            'role_label' => self::ROLE_LABELS[$staff->role] ?? $staff->role,
            'permissions' => self::ROLE_PERMISSIONS[$staff->role] ?? [],
            'is_active' => $staff->is_active,
            'created_at' => $staff->created_at,
        ];
    }

    // ─── GET /restaurants/{restaurant}/staff ──────────────────────────────────

    public function index(Request $request, Restaurant $restaurant): JsonResponse
    {
        if (!$this->canManageStaff($request, $restaurant)) {
            return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
        }

        $staff = $restaurant->staff()
            ->with('user')
            ->orderBy('role')
            ->get()
            ->map(fn($s) => $this->formatStaff($s));

        return response()->json([
            'success' => true,
            'data' => $staff,
            'roles' => self::ROLE_LABELS,
        ]);
    }

    // ─── POST /restaurants/{restaurant}/staff ─────────────────────────────────
    // Crée un compte utilisateur + lui attribue un rôle dans ce restaurant.
    // Si l'email existe déjà, rattache simplement le rôle.

    public function store(Request $request, Restaurant $restaurant): JsonResponse
    {
        if (!$this->canManageStaff($request, $restaurant)) {
            return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
            'phone' => 'nullable|string|max:20',
            'role' => 'required|in:manager,cashier,waiter',
            'password' => 'nullable|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Vérifier qu'un owner ne peut pas créer un autre owner
        if ($request->role === 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible d\'assigner le rôle propriétaire. Ce rôle est réservé au super admin.',
            ], 422);
        }

        // Trouver ou créer l'utilisateur
        $user = User::where('email', $request->email)->first();

        if ($user) {
            // Vérifier que ce user n'a pas déjà un rôle dans ce restaurant
            $existing = $restaurant->staff()->where('user_id', $user->id)->first();
            if ($existing) {
                return response()->json([
                    'success' => false,
                    'message' => "{$user->name} a déjà le rôle '{$existing->role}' dans ce restaurant.",
                ], 422);
            }
        } else {
            // Créer un nouveau compte
            $password = $request->password ?? Str::random(12);
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'phone' => $request->phone,
                'password' => Hash::make($password),
            ]);
        }

        $staff = RestaurantStaff::create([
            'user_id' => $user->id,
            'restaurant_id' => $restaurant->id,
            'role' => $request->role,
            'is_active' => true,
        ]);

        $staff->load('user');

        return response()->json([
            'success' => true,
            'message' => "{$user->name} ajouté comme " . self::ROLE_LABELS[$request->role],
            'data' => $this->formatStaff($staff),
        ], 201);
    }

    // ─── PUT /restaurants/{restaurant}/staff/{staff} ──────────────────────────

    public function update(Request $request, Restaurant $restaurant, RestaurantStaff $staff): JsonResponse
    {
        if (!$this->canManageStaff($request, $restaurant)) {
            return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
        }

        if ($staff->restaurant_id !== $restaurant->id) {
            return response()->json(['success' => false, 'message' => 'Ressource introuvable'], 404);
        }

        $validator = Validator::make($request->all(), [
            'role' => 'sometimes|in:manager,cashier,waiter',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors(),
            ], 422);
        }

        $staff->update($request->only(['role', 'is_active']));
        $staff->load('user');

        return response()->json([
            'success' => true,
            'message' => 'Rôle mis à jour',
            'data' => $this->formatStaff($staff),
        ]);
    }

    // ─── DELETE /restaurants/{restaurant}/staff/{staff} ───────────────────────

    public function destroy(Request $request, Restaurant $restaurant, RestaurantStaff $staff): JsonResponse
    {
        if (!$this->canManageStaff($request, $restaurant)) {
            return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
        }

        if ($staff->restaurant_id !== $restaurant->id) {
            return response()->json(['success' => false, 'message' => 'Ressource introuvable'], 404);
        }

        // Empêcher la suppression du propriétaire principal
        if ($restaurant->user_id === $staff->user_id) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de retirer le propriétaire principal du restaurant.',
            ], 422);
        }

        $name = $staff->user->name;
        $staff->delete();

        return response()->json([
            'success' => true,
            'message' => "{$name} retiré de l'équipe",
        ]);
    }

    // ─── GET /auth/my-restaurant ──────────────────────────────────────────────
    // Retourne les restaurants accessibles par l'utilisateur connecté.

    public function myRestaurants(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->is_admin) {
            return response()->json([
                'success' => true,
                'is_admin' => true,
                'data' => [],
            ]);
        }

        // Restaurants dont il est propriétaire
        $owned = collect($user->restaurants()->with('staff.user')->get()->map(fn($r) => [
            'id' => $r->id,
            'nom' => $r->nom,
            'logo' => $r->logo,
            'adresse' => $r->adresse,
            'is_active' => $r->is_active,
            'role' => 'owner',
            'role_label' => 'Propriétaire',
            'permissions' => self::ROLE_PERMISSIONS['owner'],
        ])->all());

        // Restaurants où il est membre du personnel
        $staffed = collect($user->staffRoles()
            ->where('is_active', true)
            ->with('restaurant')
            ->get()
            ->map(fn($s) => [
                'id' => $s->restaurant->id,
                'nom' => $s->restaurant->nom,
                'logo' => $s->restaurant->logo,
                'adresse' => $s->restaurant->adresse,
                'is_active' => $s->restaurant->is_active,
                'role' => $s->role,
                'role_label' => self::ROLE_LABELS[$s->role] ?? $s->role,
                'permissions' => self::ROLE_PERMISSIONS[$s->role] ?? [],
            ])->all());

        $all = $owned->merge($staffed)->unique('id')->values();

        return response()->json([
            'success' => true,
            'is_admin' => false,
            'data' => $all,
        ]);
    }
}
