<?php

namespace App\Http\Controllers\Api;

use App\Events\DeliveryStatusChanged;
use App\Events\DriverDeliveryAssigned;
use App\Events\DriverLocationUpdated;
use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\DeliveryDriver;
use App\Models\Order;
use App\Services\FcmNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DeliveryController extends Controller
{
    public function __construct(private FcmNotificationService $fcm)
    {
    }

    // ─── DEL-B06 : Demander une livraison pour une commande ─────────────────

    /**
     * POST /api/orders/{order}/request-delivery
     *
     * Crée une entrée de livraison (pending_assignment) pour la commande.
     * La commande doit être de type 'livraison' et ne pas déjà avoir de livraison active.
     */
    public function requestDelivery(Request $request, Order $order): JsonResponse
    {
        $this->authorize('update', $order->restaurant);

        if ($order->order_type !== 'livraison') {
            return response()->json([
                'success' => false,
                'message' => 'Seules les commandes de type livraison peuvent être prises en charge.',
            ], 422);
        }

        if ($order->delivery()->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Une livraison existe déjà pour cette commande.',
            ], 422);
        }

        $validated = $request->validate([
            'client_lat' => 'nullable|numeric|between:-90,90',
            'client_lng' => 'nullable|numeric|between:-180,180',
            'client_address' => 'nullable|string|max:255',
            'fee' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string|max:500',
        ]);

        $delivery = Delivery::create([
            'order_id' => $order->id,
            'status' => 'pending_assignment',
            'client_lat' => $validated['client_lat'] ?? null,
            'client_lng' => $validated['client_lng'] ?? null,
            'client_address' => $validated['client_address'] ?? null,
            'fee' => $validated['fee'] ?? 0,
            'notes' => $validated['notes'] ?? null,
        ]);

        // Auto-assignation : trouver un livreur disponible
        $availableDriver = DeliveryDriver::where('status', 'available')->first();
        if ($availableDriver) {
            DB::transaction(function () use ($delivery, $availableDriver) {
                $delivery->update([
                    'delivery_driver_id' => $availableDriver->id,
                    'status' => 'assigned',
                    'assigned_at' => now(),
                ]);
                $availableDriver->markBusy();
            });

            broadcast(new DeliveryStatusChanged($delivery->fresh()->load('driver'), 'delivery.assigned'));

            // Notifier le livreur sur son canal privé (déclenche son+dialog dans l'app)
            if ($availableDriver->user_id) {
                broadcast(new DriverDeliveryAssigned($delivery->fresh(), $availableDriver->user_id));
            }

            if ($availableDriver->fcm_token) {
                $this->fcm->sendToToken(
                    $availableDriver->fcm_token,
                    'Nouvelle livraison assignée',
                    "Commande #{$order->id} — {$order->customer_name}",
                    ['type' => 'delivery.assigned', 'delivery_id' => (string) $delivery->id],
                );
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Livraison créée, en attente d\'assignation.',
            'data' => $delivery->load('driver'),
        ], 201);
    }

    // ─── DEL-B04 : Assignation manuelle d'un livreur ────────────────────────

    /**
     * POST /api/deliveries/{delivery}/assign
     *
     * Assigne un livreur disponible à la livraison.
     */
    public function assign(Request $request, Delivery $delivery): JsonResponse
    {
        $this->authorize('assign', $delivery);

        if ($delivery->status !== 'pending_assignment') {
            return response()->json([
                'success' => false,
                'message' => 'La livraison n\'est pas en attente d\'assignation.',
            ], 422);
        }

        $validated = $request->validate([
            'delivery_driver_id' => 'required|exists:delivery_drivers,id',
        ]);

        $driver = DeliveryDriver::findOrFail($validated['delivery_driver_id']);

        if (!$driver->isAvailable()) {
            return response()->json([
                'success' => false,
                'message' => 'Ce livreur n\'est pas disponible actuellement.',
            ], 422);
        }

        DB::transaction(function () use ($delivery, $driver) {
            $delivery->update([
                'delivery_driver_id' => $driver->id,
                'status' => 'assigned',
                'assigned_at' => now(),
            ]);
            $driver->markBusy();
        });

        $delivery->load('driver');
        broadcast(new DeliveryStatusChanged($delivery, 'delivery.assigned'));

        // Notifier le livreur sur son canal privé (déclenche son+dialog dans l'app)
        if ($driver->user_id) {
            broadcast(new DriverDeliveryAssigned($delivery->fresh(), $driver->user_id));
        }

        // DEL-B11 : FCM au livreur — nouvelle commande assignée
        if ($driver->fcm_token) {
            $order = $delivery->order;
            $this->fcm->sendToToken(
                $driver->fcm_token,
                'Nouvelle livraison assignée',
                "Commande #{$order->id} — {$order->customer_name}",
                ['type' => 'delivery.assigned', 'delivery_id' => (string) $delivery->id],
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Livreur assigné avec succès.',
            'data' => $delivery,
        ]);
    }

    // ─── DEL-B07 : Mise à jour statut par le livreur ────────────────────────

    /**
     * PATCH /api/deliveries/{delivery}/status
     */
    public function updateStatus(Request $request, Delivery $delivery): JsonResponse
    {
        $this->authorize('updateStatus', $delivery);

        $validated = $request->validate([
            'status' => 'required|string|in:picked_up,on_way,delivered,failed',
            'failure_reason' => 'required_if:status,failed|nullable|string|max:500',
        ]);

        $newStatus = $validated['status'];

        if (!$delivery->canTransitionTo($newStatus)) {
            return response()->json([
                'success' => false,
                'message' => "Transition vers '{$newStatus}' non autorisée depuis '{$delivery->status}'.",
            ], 422);
        }

        $delivery->applyStatusTimestamp($newStatus);
        $delivery->status = $newStatus;

        if ($newStatus === 'failed') {
            $delivery->failure_reason = $validated['failure_reason'] ?? null;
        }

        $delivery->save();

        // Libérer le livreur si livraison terminée
        if ($delivery->isTerminal() && $delivery->driver) {
            $delivery->driver->markAvailable();
        }

        $eventName = "delivery.{$newStatus}";
        broadcast(new DeliveryStatusChanged($delivery->load('driver'), $eventName));

        // DEL-B12 : FCM au client — en route ou livré
        if (in_array($newStatus, ['on_way', 'delivered'])) {
            $clientUser = $delivery->order?->user;
            if ($clientUser?->fcm_token) {
                $messages = [
                    'on_way' => ['Le livreur est en route !', 'Votre commande arrive bientôt.'],
                    'delivered' => ['Commande livrée !', 'Votre commande a été livrée avec succès. Bon appétit !'],
                ];
                [$title, $body] = $messages[$newStatus];
                $this->fcm->sendToToken(
                    $clientUser->fcm_token,
                    $title,
                    $body,
                    ['type' => $eventName, 'order_id' => (string) $delivery->order_id],
                );
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Statut mis à jour.',
            'data' => $delivery,
        ]);
    }

    // ─── DEL-B09 : Push position GPS du livreur ─────────────────────────────

    /**
     * POST /api/deliveries/{delivery}/driver-location
     */
    public function updateDriverLocation(Request $request, Delivery $delivery): JsonResponse
    {
        $this->authorize('updateLocation', $delivery);

        if ($delivery->isTerminal()) {
            return response()->json([
                'success' => false,
                'message' => 'La livraison est terminée.',
            ], 422);
        }

        $validated = $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);

        $delivery->update([
            'driver_lat' => $validated['lat'],
            'driver_lng' => $validated['lng'],
            'driver_location_at' => now(),
        ]);

        if ($delivery->driver) {
            $delivery->driver->updateLocation($validated['lat'], $validated['lng']);
        }

        broadcast(new DriverLocationUpdated(
            $delivery->order_id,
            $delivery->delivery_driver_id,
            $validated['lat'],
            $validated['lng'],
        ));

        return response()->json(['success' => true]);
    }

    // ─── Client : partage de position GPS vers le livreur ───────────────────

    /**
     * POST /api/deliveries/{delivery}/client-location
     *
     * Permet au client de pousser sa position GPS afin que le livreur puisse
     * naviguer vers lui. Met à jour client_lat/client_lng sur la livraison.
     */
    public function updateClientLocation(Request $request, Delivery $delivery): JsonResponse
    {
        $this->authorize('view', $delivery);

        if ($delivery->isTerminal()) {
            return response()->json([
                'success' => false,
                'message' => 'La livraison est terminée.',
            ], 422);
        }

        $validated = $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $delivery->update([
            'client_lat' => $validated['latitude'],
            'client_lng' => $validated['longitude'],
        ]);

        return response()->json(['success' => true]);
    }

    // ─── Admin : liste toutes les livraisons ────────────────────────────────

    /**
     * GET /api/deliveries  (admin seulement)
     */
    public function index(Request $request): JsonResponse
    {
        $query = Delivery::with(['order.restaurant', 'driver'])
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->driver_id, fn($q) => $q->where('delivery_driver_id', $request->driver_id))
            ->latest();

        return response()->json([
            'success' => true,
            'data' => $query->paginate(20),
        ]);
    }

    /**
     * GET /api/deliveries/{delivery}
     */
    public function show(Delivery $delivery): JsonResponse
    {
        $this->authorize('view', $delivery);

        return response()->json([
            'success' => true,
            'data' => $delivery->load(['order.items.dish', 'order.restaurant', 'driver']),
        ]);
    }

    // ─── CRUD Livreurs (admin) ───────────────────────────────────────────────

    /**
     * GET /api/drivers
     */
    public function listDrivers(Request $request): JsonResponse
    {
        $drivers = DeliveryDriver::withCount('activeDelivery as active_delivery_count')
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->zone, fn($q) => $q->where('zone', $request->zone))
            ->when($request->search, fn($q) => $q->where(function ($q) use ($request) {
                $search = '%' . $request->search . '%';
                $q->where('name', 'like', $search)
                    ->orWhere('phone', 'like', $search);
            }))
            ->latest()
            ->paginate(20);

        return response()->json(['success' => true, 'data' => $drivers]);
    }

    /**
     * POST /api/drivers
     */
    public function storeDriver(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'phone' => 'required|string|max:20',
            'zone' => 'nullable|string|max:100',
            'user_id' => 'nullable|exists:users,id',
        ]);

        $driver = DeliveryDriver::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Livreur créé avec succès.',
            'data' => $driver,
        ], 201);
    }

    /**
     * PUT /api/drivers/{driver}
     */
    public function updateDriver(Request $request, DeliveryDriver $driver): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:100',
            'phone' => 'sometimes|string|max:20',
            'zone' => 'nullable|string|max:100',
            'status' => 'sometimes|in:available,busy,offline',
        ]);

        $driver->update($validated);

        return response()->json(['success' => true, 'data' => $driver]);
    }

    /**
     * DELETE /api/drivers/{driver}
     */
    public function destroyDriver(DeliveryDriver $driver): JsonResponse
    {
        $driver->delete();

        return response()->json(['success' => true, 'message' => 'Livreur supprimé.']);
    }

    // ─── Livraisons actives du livreur connecté ────────────────────────────

    /**
     * POST /api/deliveries/{delivery}/accept
     * Le livreur accepte la livraison assignée.
     */
    public function acceptDelivery(Delivery $delivery): JsonResponse
    {
        $user = request()->user();
        $driver = DeliveryDriver::where('user_id', $user->id)->first();

        if (!$driver || $delivery->delivery_driver_id !== $driver->id) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        if ($delivery->status !== 'assigned') {
            return response()->json(['success' => false, 'message' => 'La livraison n\'est pas en attente d\'acceptation.'], 422);
        }

        $delivery->update(['accepted_at' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'Livraison acceptée.',
            'data' => $delivery->load('driver'),
        ]);
    }

    /**
     * POST /api/deliveries/{delivery}/reject
     * Le livreur refuse la livraison — retour en pending_assignment.
     */
    public function rejectDelivery(Request $request, Delivery $delivery): JsonResponse
    {
        $user = $request->user();
        $driver = DeliveryDriver::where('user_id', $user->id)->first();

        if (!$driver || $delivery->delivery_driver_id !== $driver->id) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        if ($delivery->status !== 'assigned') {
            return response()->json(['success' => false, 'message' => 'La livraison n\'est pas en attente d\'acceptation.'], 422);
        }

        DB::transaction(function () use ($delivery, $driver) {
            $delivery->update([
                'delivery_driver_id' => null,
                'status' => 'pending_assignment',
                'assigned_at' => null,
            ]);
            $driver->markAvailable();
        });

        broadcast(new DeliveryStatusChanged($delivery->fresh()->load('driver'), 'delivery.rejected'));

        return response()->json([
            'success' => true,
            'message' => 'Livraison refusée, remise en attente.',
            'data' => $delivery->fresh(),
        ]);
    }

    /**
     * GET /api/deliveries/my-active
     *
     * Retourne les livraisons en cours du livreur (non terminées).
     */
    public function myActive(Request $request): JsonResponse
    {
        $user = $request->user();
        $driver = DeliveryDriver::where('user_id', $user->id)->first();

        if (!$driver) {
            return response()->json(['success' => true, 'data' => []]);
        }

        $deliveries = Delivery::with(['order.restaurant', 'order.items.dish'])
            ->where('delivery_driver_id', $driver->id)
            ->whereNotIn('status', ['delivered', 'failed'])
            ->latest()
            ->get();

        return response()->json(['success' => true, 'data' => $deliveries]);
    }

    // ─── Historique livreur (livreur connecté) ───────────────────────────────

    /**
     * GET /api/deliveries/my-history
     */
    public function myHistory(Request $request): JsonResponse
    {
        $user = $request->user();
        $driver = DeliveryDriver::where('user_id', $user->id)->first();

        if (!$driver) {
            return response()->json(['success' => true, 'data' => []]);
        }

        $deliveries = Delivery::with(['order.restaurant'])
            ->where('delivery_driver_id', $driver->id)
            ->whereIn('status', ['delivered', 'failed'])
            ->latest()
            ->paginate(20);

        return response()->json(['success' => true, 'data' => $deliveries]);
    }

    // ─── Profil & statut du livreur connecté ────────────────────────────────

    /**
     * GET /api/drivers/me
     */
    public function myProfile(Request $request): JsonResponse
    {
        $user = $request->user();
        $driver = DeliveryDriver::where('user_id', $user->id)->first();

        if (!$driver) {
            return response()->json([
                'success' => false,
                'message' => 'Aucun profil livreur trouvé.',
            ], 404);
        }

        return response()->json(['success' => true, 'data' => $driver]);
    }

    /**
     * PUT /api/drivers/me/status
     */
    public function updateMyStatus(Request $request): JsonResponse
    {
        $user = $request->user();
        $driver = DeliveryDriver::where('user_id', $user->id)->first();

        if (!$driver) {
            return response()->json([
                'success' => false,
                'message' => 'Aucun profil livreur trouvé.',
            ], 404);
        }

        $validated = $request->validate([
            'status' => 'required|in:available,offline',
        ]);

        // Ne pas passer offline si livraison en cours
        if ($validated['status'] === 'offline') {
            $hasActive = Delivery::where('delivery_driver_id', $driver->id)
                ->whereNotIn('status', ['delivered', 'failed'])
                ->exists();

            if ($hasActive) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de passer hors ligne avec une livraison en cours.',
                ], 422);
            }
        }

        $driver->update(['status' => $validated['status']]);

        return response()->json(['success' => true, 'data' => $driver]);
    }
}
