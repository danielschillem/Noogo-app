<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Concerns\UsesStorageDisk;
use App\Models\Dish;
use App\Models\Restaurant;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class DishController extends Controller
{
    use UsesStorageDisk;
    /**
     * Display dishes for a restaurant
     */
    public function index(Request $request, Restaurant $restaurant): JsonResponse
    {
        $query = $restaurant->dishes()->with('category:id,nom');

        // Filter by category
        if ($request->has('category_id')) {
            $query->forCategory($request->category_id);
        }

        // Filter by availability
        if ($request->has('available')) {
            $query->where('disponibilite', $request->boolean('available'));
        }

        // Filter by plat du jour
        if ($request->has('plat_du_jour')) {
            $query->platDuJour();
        }

        // Search
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('nom', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $dishes = $query->ordered()->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $dishes
        ]);
    }

    /**
     * Store a new dish
     */
    public function store(Request $request, Restaurant $restaurant): JsonResponse
    {
        $this->authorize('update', $restaurant);

        $validator = Validator::make($request->all(), [
            'category_id' => 'required|exists:categories,id',
            'nom' => 'required|string|max:255',
            'description' => 'nullable|string',
            'prix' => 'required|numeric|min:0',
            'images' => 'nullable|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif|max:2048',
            'temps_preparation' => 'nullable|integer|min:1',
            'is_plat_du_jour' => 'nullable|boolean',
            'ordre' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        // Verify category belongs to restaurant
        $category = Category::find($request->category_id);
        if ($category->restaurant_id !== $restaurant->id) {
            return response()->json([
                'success' => false,
                'message' => 'La catégorie n\'appartient pas à ce restaurant'
            ], 422);
        }

        $data = $request->except('images');
        $data['restaurant_id'] = $restaurant->id;

        // Set order to last position if not provided
        if (!isset($data['ordre'])) {
            $data['ordre'] = $restaurant->dishes()->forCategory($request->category_id)->max('ordre') + 1;
        }

        // Handle images upload
        if ($request->hasFile('images')) {
            $images = [];
            foreach ($request->file('images') as $image) {
                $images[] = $image->store('dishes', $this->disk());
            }
            $data['images'] = $images;
        }

        $dish = $restaurant->dishes()->create($data);

        return response()->json([
            'success' => true,
            'message' => 'Plat créé avec succès',
            'data' => $dish->load('category:id,nom')
        ], 201);
    }

    /**
     * Display the specified dish
     */
    public function show(Restaurant $restaurant, Dish $dish): JsonResponse
    {
        $dish->load('category:id,nom');

        return response()->json([
            'success' => true,
            'data' => $dish
        ]);
    }

    /**
     * Update the specified dish
     */
    public function update(Request $request, Restaurant $restaurant, Dish $dish): JsonResponse
    {
        $this->authorize('update', $restaurant);

        $validator = Validator::make($request->all(), [
            'category_id' => 'sometimes|required|exists:categories,id',
            'nom' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'prix' => 'sometimes|required|numeric|min:0',
            'images' => 'nullable|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif|max:2048',
            'disponibilite' => 'nullable|boolean',
            'temps_preparation' => 'nullable|integer|min:1',
            'is_plat_du_jour' => 'nullable|boolean',
            'ordre' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        // Verify category belongs to restaurant if provided
        if ($request->has('category_id')) {
            $category = Category::find($request->category_id);
            if ($category->restaurant_id !== $restaurant->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'La catégorie n\'appartient pas à ce restaurant'
                ], 422);
            }
        }

        $data = $request->except('images');

        // Handle images upload
        if ($request->hasFile('images')) {
            // Delete old images
            if ($dish->images) {
                foreach ($dish->images as $oldImage) {
                    Storage::disk($this->disk())->delete($oldImage);
                }
            }
            $images = [];
            foreach ($request->file('images') as $image) {
                $images[] = $image->store('dishes', $this->disk());
            }
            $data['images'] = $images;
        }

        $dish->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Plat mis à jour avec succès',
            'data' => $dish->fresh()->load('category:id,nom')
        ]);
    }

    /**
     * Remove the specified dish
     */
    public function destroy(Restaurant $restaurant, Dish $dish): JsonResponse
    {
        $this->authorize('update', $restaurant);

        // Delete images
        if ($dish->images) {
            foreach ($dish->images as $image) {
                Storage::disk($this->disk())->delete($image);
            }
        }

        $dish->delete();

        return response()->json([
            'success' => true,
            'message' => 'Plat supprimé avec succès'
        ]);
    }

    /**
     * Toggle dish availability
     */
    public function toggleAvailability(Restaurant $restaurant, Dish $dish): JsonResponse
    {
        $dish->update(['disponibilite' => !$dish->disponibilite]);

        return response()->json([
            'success' => true,
            'message' => $dish->disponibilite ? 'Plat disponible' : 'Plat indisponible',
            'data' => $dish
        ]);
    }

    /**
     * Toggle plat du jour
     */
    public function togglePlatDuJour(Restaurant $restaurant, Dish $dish): JsonResponse
    {
        $dish->update(['is_plat_du_jour' => !$dish->is_plat_du_jour]);

        return response()->json([
            'success' => true,
            'message' => $dish->is_plat_du_jour ? 'Marqué comme plat du jour' : 'Retiré des plats du jour',
            'data' => $dish
        ]);
    }

    /**
     * Get plats du jour
     */
    public function platsDuJour(Restaurant $restaurant): JsonResponse
    {
        $dishes = $restaurant->dishes()
            ->platDuJour()
            ->available()
            ->with('category:id,nom')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $dishes
        ]);
    }

    /**
     * Reorder dishes
     */
    public function reorder(Request $request, Restaurant $restaurant): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'dishes' => 'required|array',
            'dishes.*.id' => 'required|exists:dishes,id',
            'dishes.*.ordre' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        foreach ($request->dishes as $item) {
            Dish::where('id', $item['id'])
                ->where('restaurant_id', $restaurant->id)
                ->update(['ordre' => $item['ordre']]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Ordre des plats mis à jour'
        ]);
    }
}
