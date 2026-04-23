<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AdminController extends Controller
{
    // ── Platform statistics ──────────────────────────────────────────────────

    public function stats(): JsonResponse
    {
        $totalRevenue = Order::whereNotIn('status', ['cancelled'])->sum('total_amount');
        $monthRevenue = Order::whereNotIn('status', ['cancelled'])
            ->where('order_date', '>=', now()->startOfMonth())
            ->sum('total_amount');

        return response()->json([
            'success' => true,
            'data' => [
                'users' => [
                    'total' => User::count(),
                    'admins' => User::where('is_admin', true)->count(),
                    'this_month' => User::where('created_at', '>=', now()->startOfMonth())->count(),
                ],
                'restaurants' => [
                    'total' => Restaurant::count(),
                    'active' => Restaurant::where('is_active', true)->count(),
                    'this_month' => Restaurant::where('created_at', '>=', now()->startOfMonth())->count(),
                ],
                'orders' => [
                    'total' => Order::count(),
                    'today' => Order::whereDate('order_date', today())->count(),
                    'pending' => Order::where('status', 'pending')->count(),
                ],
                'revenue' => [
                    'total' => (float) $totalRevenue,
                    'this_month' => (float) $monthRevenue,
                ],
            ],
        ]);
    }

    // ── Users ────────────────────────────────────────────────────────────────

    public function listUsers(Request $request): JsonResponse
    {
        $query = User::withCount('restaurants')->orderByDesc('created_at');

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        if ($request->filled('is_admin')) {
            $query->where('is_admin', filter_var($request->get('is_admin'), FILTER_VALIDATE_BOOLEAN));
        }

        return response()->json([
            'success' => true,
            'data' => $query->paginate((int) $request->get('per_page', 20)),
        ]);
    }

    public function createUser(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string|max:30',
            'password' => ['required', Password::min(8)],
            'is_admin' => 'boolean',
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'password' => Hash::make($data['password']),
        ]);
        // is_admin hors fillable (protection mass-assignment) → assignation directe
        $user->is_admin = $data['is_admin'] ?? false;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Utilisateur créé avec succès.',
            'data' => $user->loadCount('restaurants'),
        ], 201);
    }

    public function updateUser(Request $request, User $user): JsonResponse
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => "sometimes|email|unique:users,email,{$user->id}",
            'phone' => 'sometimes|nullable|string|max:30',
            'is_admin' => 'sometimes|boolean',
            'password' => ['sometimes', Password::min(8)],
        ]);

        if (isset($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }

        // is_admin hors fillable → extraire et assigner directement
        $isAdmin = $data['is_admin'] ?? null;
        unset($data['is_admin']);
        $user->update($data);
        if ($isAdmin !== null) {
            $user->is_admin = (bool) $isAdmin;
            $user->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Utilisateur mis à jour.',
            'data' => $user->fresh()->loadCount('restaurants'),
        ]);
    }

    public function deleteUser(Request $request, User $user): JsonResponse
    {
        if ($request->user()->id === $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez pas supprimer votre propre compte.',
            ], 422);
        }

        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'Utilisateur supprimé.',
        ]);
    }

    public function toggleAdmin(Request $request, User $user): JsonResponse
    {
        if ($request->user()->id === $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez pas modifier vos propres droits admin.',
            ], 422);
        }

        // is_admin hors fillable → assignation directe
        $user->is_admin = !$user->is_admin;
        $user->save();

        return response()->json([
            'success' => true,
            'data' => $user->fresh()->loadCount('restaurants'),
            'message' => $user->is_admin ? 'Droits admin accordés.' : 'Droits admin retirés.',
        ]);
    }

    // ── Restaurants ──────────────────────────────────────────────────────────

    public function listRestaurants(Request $request): JsonResponse
    {
        $query = Restaurant::with('user:id,name,email')
            ->withCount(['orders', 'dishes'])
            ->orderByDesc('created_at');

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('nom', 'like', "%{$search}%")
                    ->orWhere('adresse', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->filled('is_active')) {
            $query->where('is_active', filter_var($request->get('is_active'), FILTER_VALIDATE_BOOLEAN));
        }

        return response()->json([
            'success' => true,
            'data' => $query->paginate((int) $request->get('per_page', 20)),
        ]);
    }

    public function toggleRestaurantActive(Restaurant $restaurant): JsonResponse
    {
        $restaurant->update(['is_active' => !$restaurant->is_active]);

        return response()->json([
            'success' => true,
            'data' => $restaurant->fresh(),
            'message' => $restaurant->is_active ? 'Restaurant activé.' : 'Restaurant désactivé.',
        ]);
    }
}
