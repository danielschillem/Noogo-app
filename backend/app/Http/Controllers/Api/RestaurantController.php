<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Concerns\UsesStorageDisk;
use App\Models\Restaurant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class RestaurantController extends Controller
{
    use UsesStorageDisk;
    /**
     * Display a listing of restaurants
     */
    public function index(Request $request): JsonResponse
    {
        $query = Restaurant::with(['user:id,name,email'])
            ->withCount(['categories', 'dishes', 'orders']);

        // Filter by user if authenticated and not admin
        if ($request->user() && !$request->user()->is_admin) {
            // Accès : proprio (user_id) OU membre du personnel
            $accessibleIds = $request->user()->accessibleRestaurantIds();
            $query->whereIn('id', $accessibleIds);
        }

        // Filter by active status
        if ($request->has('active')) {
            $query->where('is_active', $request->boolean('active'));
        }

        // Search
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('nom', 'like', "%{$search}%")
                    ->orWhere('adresse', 'like', "%{$search}%")
                    ->orWhere('telephone', 'like', "%{$search}%");
            });
        }

        $restaurants = $query->latest()->paginate($request->get('per_page', 15));

        return response()->json([
            'success' => true,
            'data' => $restaurants
        ]);
    }

    /**
     * Recherche publique de restaurants (pour l'app Flutter client).
     * GET /api/restaurants/search?q=term&lat=12.3&lng=-1.5
     */
    public function publicSearch(Request $request): JsonResponse
    {
        $query = Restaurant::where('is_active', true)
            ->select('id', 'nom', 'adresse', 'telephone', 'logo', 'latitude', 'longitude', 'is_open_override')
            ->withCount('dishes');

        if ($request->filled('q')) {
            $search = $request->q;
            $query->where(function ($q) use ($search) {
                $q->where('nom', 'ilike', "%{$search}%")
                    ->orWhere('adresse', 'ilike', "%{$search}%");
            });
        }

        $restaurants = $query->latest()->limit(50)->get();

        return response()->json([
            'success' => true,
            'data' => $restaurants,
        ]);
    }

    /**
     * Store a newly created restaurant
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nom' => 'required|string|max:255',
            'telephone' => 'required|string|max:20',
            'adresse' => 'required|string|max:500',
            'email' => 'nullable|email|max:255',
            'logo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'description' => 'nullable|string',
            'heures_ouverture' => 'nullable|string|max:100',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'images' => 'nullable|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $request->except(['logo', 'images']);
        $data['user_id'] = $request->user()->id;

        // Handle logo upload
        if ($request->hasFile('logo')) {
            $data['logo'] = $request->file('logo')->store('restaurants/logos', $this->disk());
        }

        // Handle images upload
        if ($request->hasFile('images')) {
            $images = [];
            foreach ($request->file('images') as $image) {
                $images[] = $image->store('restaurants/images', $this->disk());
            }
            $data['images'] = $images;
        }

        $restaurant = Restaurant::create($data);

        // Generate QR code
        $this->generateQrCode($restaurant);

        return response()->json([
            'success' => true,
            'message' => 'Restaurant créé avec succès',
            'data' => $restaurant->load('user:id,name,email')
        ], 201);
    }

    /**
     * Display the specified restaurant
     */
    public function show(Restaurant $restaurant): JsonResponse
    {
        $restaurant->load([
            'user:id,name,email',
            'categories' => function ($q) {
                $q->active()->ordered();
            },
            'flashInfos' => function ($q) {
                $q->valid();
            }
        ]);

        $restaurant->loadCount(['dishes', 'orders']);

        return response()->json([
            'success' => true,
            'data' => $restaurant
        ]);
    }

    /**
     * Update the specified restaurant
     */
    public function update(Request $request, Restaurant $restaurant): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'nom' => 'sometimes|required|string|max:255',
            'telephone' => 'sometimes|required|string|max:20',
            'adresse' => 'sometimes|required|string|max:500',
            'email' => 'nullable|email|max:255',
            'logo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'description' => 'nullable|string',
            'heures_ouverture' => 'nullable|string|max:100',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'is_active' => 'nullable|boolean',
            'is_open_override' => 'nullable|boolean',
            'images' => 'nullable|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif|max:2048',
            'delete_images' => 'nullable|array',
            'delete_images.*' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $request->except(['logo', 'images', 'delete_images']);

        // Handle logo upload
        if ($request->hasFile('logo')) {
            // Delete old logo
            if ($restaurant->logo) {
                Storage::disk($this->disk())->delete($restaurant->logo);
            }
            $data['logo'] = $request->file('logo')->store('restaurants/logos', $this->disk());
        }

        // Handle image gallery (append new + delete specified)
        $currentImages = $restaurant->images ?? [];
        $imagesModified = false;

        // Delete specified images (security: only delete paths owned by this restaurant)
        if ($request->has('delete_images') && is_array($request->delete_images)) {
            foreach ($request->delete_images as $path) {
                if (in_array($path, $currentImages, true)) {
                    Storage::disk($this->disk())->delete($path);
                    $currentImages = array_values(array_filter($currentImages, fn($img) => $img !== $path));
                    $imagesModified = true;
                }
            }
        }

        // Append new images (do not replace existing)
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $currentImages[] = $image->store('restaurants/images', $this->disk());
            }
            $imagesModified = true;
        }

        if ($imagesModified) {
            $data['images'] = $currentImages;
        }

        $restaurant->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Restaurant mis à jour avec succès',
            'data' => $restaurant->fresh()->load('user:id,name,email')
        ]);
    }

    /**
     * Remove the specified restaurant
     */
    public function destroy(Restaurant $restaurant): JsonResponse
    {
        $restaurant->delete();

        return response()->json([
            'success' => true,
            'message' => 'Restaurant supprimé avec succès'
        ]);
    }

    /**
     * Get restaurant menu (public endpoint for Flutter app)
     */
    public function menu(int $restaurantId): JsonResponse
    {
        $restaurant = Restaurant::findOrFail($restaurantId);
        $menuData = $restaurant->getMenuData();

        return response()->json([
            'success' => true,
            'data' => $menuData
        ]);
    }

    /**
     * Toggle restaurant active status
     */
    public function toggleActive(Restaurant $restaurant): JsonResponse
    {
        $restaurant->update(['is_active' => !$restaurant->is_active]);

        return response()->json([
            'success' => true,
            'message' => $restaurant->is_active ? 'Restaurant activé' : 'Restaurant désactivé',
            'data' => $restaurant
        ]);
    }

    /**
     * Toggle restaurant open/closed status (override manual)
     */
    public function toggleOpen(Restaurant $restaurant): JsonResponse
    {
        // Si aucun override, utiliser l'état calculé depuis les horaires comme point de départ
        $currentIsOpen = $restaurant->is_open;
        $restaurant->update(['is_open_override' => !$currentIsOpen]);

        return response()->json([
            'success' => true,
            'message' => $restaurant->fresh()->is_open ? 'Restaurant marqué comme ouvert' : 'Restaurant marqué comme fermé',
            'data' => $restaurant->fresh(),
        ]);
    }

    /**
     * Generate QR Code for restaurant
     */
    public function generateQrCode(Restaurant $restaurant): JsonResponse|bool
    {
        $qrContent = env('FRONTEND_URL', config('app.url')) . '/restaurant/' . $restaurant->id;
        $filename = 'qrcodes/restaurant-' . $restaurant->id . '.svg';

        // Generate QR code (using simple SVG generation)
        $qrCode = $this->generateSimpleQrSvg($qrContent);
        Storage::disk($this->disk())->put($filename, $qrCode);

        $restaurant->update(['qr_code' => $filename]);

        if (request()->wantsJson()) {
            return response()->json([
                'success' => true,
                'message' => 'QR Code généré avec succès',
                'data' => [
                    'qr_code_url' => Storage::disk($this->disk())->url($filename)
                ]
            ]);
        }

        return true;
    }

    /**
     * Get restaurant statistics
     */
    public function statistics(Restaurant $restaurant): JsonResponse
    {
        $stats = [
            'total_orders' => $restaurant->orders()->count(),
            'orders_today' => $restaurant->orders()->today()->count(),
            'pending_orders' => $restaurant->orders()->pending()->count(),
            'total_revenue' => $restaurant->orders()->where('status', '!=', 'cancelled')->sum('total_amount'),
            'revenue_today' => $restaurant->orders()->today()->where('status', '!=', 'cancelled')->sum('total_amount'),
            'total_dishes' => $restaurant->dishes()->count(),
            'available_dishes' => $restaurant->dishes()->available()->count(),
            'total_categories' => $restaurant->categories()->count(),
            'active_promotions' => $restaurant->flashInfos()->valid()->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats
        ]);
    }

    /**
     * Simple QR code SVG generator using chillerlan/php-qrcode
     */
    private function generateSimpleQrSvg(string $content): string
    {
        $options = new \chillerlan\QRCode\QROptions([
            'outputInterface' => \chillerlan\QRCode\Output\QRMarkupSVG::class,
            'eccLevel' => \chillerlan\QRCode\Common\EccLevel::L,
            'addQuietzone' => true,
            'outputBase64' => false,
        ]);

        return (new \chillerlan\QRCode\QRCode($options))->render($content);
    }
}
