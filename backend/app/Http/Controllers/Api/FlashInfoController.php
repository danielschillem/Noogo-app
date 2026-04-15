<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Concerns\UsesStorageDisk;
use App\Models\FlashInfo;
use App\Models\Restaurant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class FlashInfoController extends Controller
{
    use UsesStorageDisk;

    /**
     * Display flash infos for a restaurant
     */
    public function index(Request $request, Restaurant $restaurant): JsonResponse
    {
        $query = $restaurant->flashInfos();

        // Filter by active status
        if ($request->has('active')) {
            $query->where('is_active', $request->boolean('active'));
        }

        // Filter by valid (currently active and within date range)
        if ($request->boolean('valid')) {
            $query->valid();
        }

        // Filter by type
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        $flashInfos = $query->latest()->get();

        return response()->json([
            'success' => true,
            'data' => $flashInfos
        ]);
    }

    /**
     * Get active flash infos (public endpoint for Flutter app)
     */
    public function actives(int $restaurantId): JsonResponse
    {
        $flashInfos = FlashInfo::forRestaurant($restaurantId)
            ->valid()
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $flashInfos
        ]);
    }

    /**
     * Store a new flash info
     */
    public function store(Request $request, Restaurant $restaurant): JsonResponse
    {
        $this->authorize('update', $restaurant);

        $validator = Validator::make($request->all(), [
            'titre' => 'required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'type' => 'required|in:promotion,info,event,offre',
            'reduction_percentage' => 'nullable|numeric|min:0|max:100',
            'prix_special' => 'nullable|numeric|min:0',
            'date_debut' => 'nullable|date',
            'date_fin' => 'nullable|date|after_or_equal:date_debut',
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

        // Handle image upload
        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image')->store('flash_infos', $this->disk());
        }

        $flashInfo = FlashInfo::create($data);

        return response()->json([
            'success' => true,
            'message' => 'Offre créée avec succès',
            'data' => $flashInfo
        ], 201);
    }

    /**
     * Display the specified flash info
     */
    public function show(Restaurant $restaurant, FlashInfo $flashInfo): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $flashInfo
        ]);
    }

    /**
     * Update the specified flash info
     */
    public function update(Request $request, Restaurant $restaurant, FlashInfo $flashInfo): JsonResponse
    {
        $this->authorize('update', $restaurant);

        $validator = Validator::make($request->all(), [
            'titre' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'type' => 'sometimes|required|in:promotion,info,event,offre',
            'reduction_percentage' => 'nullable|numeric|min:0|max:100',
            'prix_special' => 'nullable|numeric|min:0',
            'date_debut' => 'nullable|date',
            'date_fin' => 'nullable|date|after_or_equal:date_debut',
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
            if ($flashInfo->image) {
                Storage::disk($this->disk())->delete($flashInfo->image);
            }
            $data['image'] = $request->file('image')->store('flash_infos', $this->disk());
        }

        $flashInfo->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Offre mise à jour avec succès',
            'data' => $flashInfo->fresh()
        ]);
    }

    /**
     * Remove the specified flash info
     */
    public function destroy(Restaurant $restaurant, FlashInfo $flashInfo): JsonResponse
    {
        $this->authorize('update', $restaurant);

        // Delete image
        if ($flashInfo->image) {
            Storage::disk($this->disk())->delete($flashInfo->image);
        }

        $flashInfo->delete();

        return response()->json([
            'success' => true,
            'message' => 'Offre supprimée avec succès'
        ]);
    }

    /**
     * Toggle flash info active status
     */
    public function toggleActive(Restaurant $restaurant, FlashInfo $flashInfo): JsonResponse
    {
        $flashInfo->update(['is_active' => !$flashInfo->is_active]);

        return response()->json([
            'success' => true,
            'message' => $flashInfo->is_active ? 'Offre activée' : 'Offre désactivée',
            'data' => $flashInfo
        ]);
    }
}
