<?php

namespace App\Http\Controllers\Api;

use App\Events\OrderStatusChanged;
use App\Http\Controllers\Controller;
use App\Models\Dish;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OralOrderNote;
use App\Models\Restaurant;
use App\Services\FcmNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OralOrderNoteController extends Controller
{
    public function index(Request $request, Restaurant $restaurant): JsonResponse
    {
        $this->authorize('manageOrders', $restaurant);

        $query = OralOrderNote::query()
            ->where('restaurant_id', $restaurant->id)
            ->with(['user:id,name', 'items', 'convertedOrder:id,status,total_amount'])
            ->orderByDesc('updated_at');

        if ($request->filled('status')) {
            $query->where('status', $request->string('status')->toString());
        }

        $perPage = min(max((int) $request->get('per_page', 20), 1), 100);
        $notes = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $notes,
        ]);
    }

    public function store(Request $request, Restaurant $restaurant): JsonResponse
    {
        $this->authorize('manageOrders', $restaurant);

        $validated = $request->validate([
            'title' => 'nullable|string|max:255',
            'staff_comment' => 'nullable|string|max:2000',
        ]);

        $note = OralOrderNote::create([
            'restaurant_id' => $restaurant->id,
            'user_id' => $request->user()->id,
            'status' => 'draft',
            'title' => $validated['title'] ?? null,
            'staff_comment' => $validated['staff_comment'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'data' => $note->load('items'),
        ], 201);
    }

    public function show(Restaurant $restaurant, OralOrderNote $oralOrderNote): JsonResponse
    {
        $this->authorize('manageOrders', $restaurant);
        $this->assertNoteBelongs($restaurant, $oralOrderNote);

        return response()->json([
            'success' => true,
            'data' => $oralOrderNote->load([
                'user:id,name',
                'items.dish:id,nom,prix,disponibilite,category_id',
                'convertedOrder:id,status,total_amount,order_date',
            ]),
        ]);
    }

    public function update(Request $request, Restaurant $restaurant, OralOrderNote $oralOrderNote): JsonResponse
    {
        $this->authorize('manageOrders', $restaurant);
        $this->assertNoteBelongs($restaurant, $oralOrderNote);

        if (!$oralOrderNote->isDraft()) {
            return response()->json([
                'success' => false,
                'message' => 'Cette prise de commande est déjà validée et ne peut plus être modifiée.',
            ], 422);
        }

        $validated = $request->validate([
            'title' => 'sometimes|nullable|string|max:255',
            'staff_comment' => 'sometimes|nullable|string|max:2000',
            'items' => 'sometimes|array',
            'items.*.dish_id' => 'required_with:items|integer|exists:dishes,id',
            'items.*.quantity' => 'required_with:items|integer|min:1|max:999',
        ]);

        DB::transaction(function () use ($validated, $oralOrderNote, $restaurant) {
            if (array_key_exists('title', $validated)) {
                $oralOrderNote->title = $validated['title'];
            }
            if (array_key_exists('staff_comment', $validated)) {
                $oralOrderNote->staff_comment = $validated['staff_comment'];
            }
            $oralOrderNote->save();

            if (!array_key_exists('items', $validated)) {
                return;
            }

            $oralOrderNote->items()->delete();

            foreach ($validated['items'] as $row) {
                $dish = Dish::query()
                    ->where('restaurant_id', $restaurant->id)
                    ->whereKey($row['dish_id'])
                    ->firstOrFail();

                $oralOrderNote->items()->create([
                    'dish_id' => $dish->id,
                    'quantity' => $row['quantity'],
                    'dish_nom_snapshot' => $dish->nom,
                    'unit_price_snapshot' => $dish->prix,
                ]);
            }
        });

        return response()->json([
            'success' => true,
            'data' => $oralOrderNote->fresh([
                'user:id,name',
                'items',
                'convertedOrder:id,status,total_amount',
            ]),
        ]);
    }

    public function validateNote(Restaurant $restaurant, OralOrderNote $oralOrderNote): JsonResponse
    {
        $this->authorize('manageOrders', $restaurant);
        $this->assertNoteBelongs($restaurant, $oralOrderNote);

        if (!$oralOrderNote->isDraft()) {
            return response()->json([
                'success' => false,
                'message' => 'Cette note est déjà validée.',
            ], 422);
        }

        if ($oralOrderNote->items()->count() === 0) {
            return response()->json([
                'success' => false,
                'message' => 'Cochez au moins un article avant de valider.',
            ], 422);
        }

        $oralOrderNote->update([
            'status' => 'validated',
            'validated_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $oralOrderNote->fresh([
                'user:id,name',
                'items',
                'convertedOrder:id,status,total_amount',
            ]),
        ]);
    }

    public function destroy(Restaurant $restaurant, OralOrderNote $oralOrderNote): JsonResponse
    {
        $this->authorize('manageOrders', $restaurant);
        $this->assertNoteBelongs($restaurant, $oralOrderNote);

        if (!$oralOrderNote->isDraft()) {
            return response()->json([
                'success' => false,
                'message' => 'Seules les notes en brouillon peuvent être supprimées.',
            ], 422);
        }

        $oralOrderNote->delete();

        return response()->json([
            'success' => true,
            'message' => 'Note supprimée.',
        ]);
    }

    /**
     * Crée une commande cuisine (Order) à partir d'une note orale déjà validée.
     * Réutilise les mêmes règles que OrderController@store (plats du restaurant, disponibles).
     */
    public function convertToOrder(Request $request, Restaurant $restaurant, OralOrderNote $oralOrderNote): JsonResponse
    {
        $this->authorize('manageOrders', $restaurant);
        $this->assertNoteBelongs($restaurant, $oralOrderNote);

        if (!$oralOrderNote->isValidated()) {
            return response()->json([
                'success' => false,
                'message' => 'Validez d’abord la note avant de l’envoyer en cuisine.',
            ], 422);
        }

        if ($oralOrderNote->converted_order_id) {
            return response()->json([
                'success' => false,
                'message' => 'Cette note a déjà été convertie en commande.',
                'data' => ['order_id' => $oralOrderNote->converted_order_id],
            ], 422);
        }

        $validated = $request->validate([
            'order_type' => 'required|in:sur_place,a_emporter,livraison',
            'payment_method' => 'required|string|max:50',
            'mobile_money_provider' => 'nullable|string|max:50',
            'customer_name' => 'nullable|string|max:255',
            'customer_phone' => 'nullable|string|max:20',
            'table_number' => 'nullable|string|max:10',
            'notes' => 'nullable|string',
        ]);

        $oralOrderNote->load('items');

        if ($oralOrderNote->items->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'La note ne contient aucune ligne.',
            ], 422);
        }

        $noteLines = [];
        foreach ($oralOrderNote->items as $line) {
            if (!$line->dish_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Une ligne ne référence plus de plat (plat supprimé). Corrigez la note ou recréez-la.',
                ], 422);
            }
            $noteLines[] = $line;
        }

        $mergedNotes = $this->mergeOrderNotes(
            $validated['notes'] ?? null,
            $oralOrderNote->title,
            $oralOrderNote->staff_comment
        );

        try {
            DB::beginTransaction();

            $order = Order::create([
                'restaurant_id' => $restaurant->id,
                'user_id' => $request->user()?->id,
                'customer_name' => $validated['customer_name'] ?? null,
                'customer_phone' => $validated['customer_phone'] ?? null,
                'order_type' => $validated['order_type'],
                'table_number' => $validated['table_number'] ?? null,
                'payment_method' => $validated['payment_method'],
                'mobile_money_provider' => $validated['mobile_money_provider'] ?? null,
                'notes' => $mergedNotes,
                'status' => 'pending',
            ]);

            foreach ($noteLines as $line) {
                $dish = Dish::query()
                    ->where('restaurant_id', $restaurant->id)
                    ->whereKey($line->dish_id)
                    ->firstOrFail();

                if (!$dish->disponibilite) {
                    throw new \Exception("Le plat « {$dish->nom} » n'est pas disponible. Réactivez-le ou modifiez la note.");
                }

                OrderItem::create([
                    'order_id' => $order->id,
                    'dish_id' => $dish->id,
                    'quantity' => $line->quantity,
                    'unit_price' => $dish->prix,
                    'special_instructions' => null,
                ]);
            }

            $order->calculateTotal();

            $oralOrderNote->update(['converted_order_id' => $order->id]);

            DB::commit();
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException) {
            DB::rollBack();

            return response()->json([
                'success' => false,
                'message' => 'Un plat de la note n’existe plus dans le menu de ce restaurant.',
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }

        $order->refresh()->load(['items.dish:id,nom,prix']);

        try {
            broadcast(new OrderStatusChanged($order, 'order.created'));
        } catch (\Exception $broadcastEx) {
            \Illuminate\Support\Facades\Log::warning('Broadcast failed: '.$broadcastEx->getMessage());
        }

        try {
            (new FcmNotificationService())->notifyNewOrder($restaurant, $order);
        } catch (\Exception $fcmEx) {
            \Illuminate\Support\Facades\Log::warning('FCM notifyNewOrder failed: '.$fcmEx->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'Commande créée à partir de la note orale.',
            'data' => [
                'order' => $order,
                'oral_order_note' => $oralOrderNote->fresh(['items', 'convertedOrder:id,status,total_amount']),
            ],
        ], 201);
    }

    private function mergeOrderNotes(?string $requestNotes, ?string $title, ?string $staffComment): ?string
    {
        $parts = array_filter([
            $requestNotes,
            $title !== null && $title !== '' ? '[Commande orale] '.$title : null,
            $staffComment !== null && $staffComment !== '' ? $staffComment : null,
        ], fn ($v) => $v !== null && $v !== '');

        if ($parts === []) {
            return null;
        }

        return implode("\n\n", $parts);
    }

    private function assertNoteBelongs(Restaurant $restaurant, OralOrderNote $note): void
    {
        if ((int) $note->restaurant_id !== (int) $restaurant->id) {
            abort(404);
        }
    }
}
