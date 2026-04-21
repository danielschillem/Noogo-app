<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Concerns\UsesStorageDisk;
use App\Models\Category;
use App\Models\Restaurant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class CategoryController extends Controller
{
    use UsesStorageDisk;

    /**
     * Display categories for a restaurant
     */
    public function index(Request $request, Restaurant $restaurant): JsonResponse
    {
        $query = $restaurant->categories()->withCount('dishes');

        if ($request->has('active')) {
            $query->where('is_active', $request->boolean('active'));
        }

        $categories = $query->ordered()->get();

        return response()->json([
            'success' => true,
            'data' => $categories
        ]);
    }

    /**
     * Store a new category
     */
    public function store(Request $request, Restaurant $restaurant): JsonResponse
    {
        $this->authorize('update', $restaurant);

        $validator = Validator::make($request->all(), [
            'nom' => 'required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'ordre' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $request->except('image');
        $data['restaurant_id'] = $restaurant->id;

        // Set order to last position if not provided
        if (!isset($data['ordre'])) {
            $data['ordre'] = $restaurant->categories()->max('ordre') + 1;
        }

        // Handle image upload
        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image')->store('categories', $this->disk());
        }

        $category = $restaurant->categories()->create($data);

        return response()->json([
            'success' => true,
            'message' => 'Catégorie créée avec succès',
            'data' => $category
        ], 201);
    }

    /**
     * Display the specified category
     */
    public function show(Restaurant $restaurant, Category $category): JsonResponse
    {
        $category->loadCount('dishes');
        $category->load([
            'dishes' => function ($q) {
                $q->available()->ordered();
            }
        ]);

        return response()->json([
            'success' => true,
            'data' => $category
        ]);
    }

    /**
     * Update the specified category
     */
    public function update(Request $request, Restaurant $restaurant, Category $category): JsonResponse
    {
        $this->authorize('update', $restaurant);

        $validator = Validator::make($request->all(), [
            'nom' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'ordre' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $request->except('image');

        // Handle image upload
        if ($request->hasFile('image')) {
            // Delete old image
            if ($category->image) {
                Storage::disk($this->disk())->delete($category->image);
            }
            $data['image'] = $request->file('image')->store('categories', $this->disk());
        }

        $category->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Catégorie mise à jour avec succès',
            'data' => $category->fresh()
        ]);
    }

    /**
     * Remove the specified category
     */
    public function destroy(Restaurant $restaurant, Category $category): JsonResponse
    {
        $this->authorize('update', $restaurant);

        // Check if category has dishes
        if ($category->dishes()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer une catégorie contenant des plats'
            ], 422);
        }

        // Delete image
        if ($category->image) {
            Storage::disk($this->disk())->delete($category->image);
        }

        $category->delete();

        return response()->json([
            'success' => true,
            'message' => 'Catégorie supprimée avec succès'
        ]);
    }

    /**
     * Reorder categories
     */
    public function reorder(Request $request, Restaurant $restaurant): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'categories' => 'required|array',
            'categories.*.id' => 'required|exists:categories,id',
            'categories.*.ordre' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors',
                'errors' => $validator->errors()
            ], 422);
        }

        foreach ($request->categories as $item) {
            Category::where('id', $item['id'])
                ->where('restaurant_id', $restaurant->id)
                ->update(['ordre' => $item['ordre']]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Ordre des catégories mis à jour'
        ]);
    }

    /**
     * Toggle category active status
     */
    public function toggleActive(Restaurant $restaurant, Category $category): JsonResponse
    {
        $category->update(['is_active' => !$category->is_active]);

        return response()->json([
            'success' => true,
            'message' => $category->is_active ? 'Catégorie activée' : 'Catégorie désactivée',
            'data' => $category
        ]);
    }
}
