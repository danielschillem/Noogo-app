import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/geolocation_service.dart';
import '../utils/app_colors.dart';

/// Résultat retourné par le LocationPickerScreen
class DeliveryLocation {
  final String address;
  final double latitude;
  final double longitude;

  const DeliveryLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

/// Écran de sélection de position GPS sur carte pour la livraison.
/// L'utilisateur peut :
/// - Utiliser sa position GPS actuelle (bouton principal)
/// - Déplacer le marqueur sur la carte
/// - Saisir une adresse manuellement en complément
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();

  // Position par défaut : Ouagadougou centre
  LatLng _selectedPosition = const LatLng(12.3714, -1.5197);
  bool _isLoading = false;
  bool _hasGpsPosition = false;
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    final position = await GeolocationService.getCurrentPosition();

    if (position != null && mounted) {
      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _hasGpsPosition = true;
        _isLoading = false;
      });
      _mapController.move(_selectedPosition, 17.0);
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS indisponible. Déplacez le marqueur sur la carte.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPosition = point;
      _hasGpsPosition = true;
    });
  }

  void _confirmLocation() {
    final addressText = _addressController.text.trim();

    // Construire l'adresse : texte saisi + coordonnées
    String finalAddress;
    if (addressText.isNotEmpty) {
      finalAddress = addressText;
    } else {
      finalAddress =
          'GPS: ${_selectedPosition.latitude.toStringAsFixed(5)}, ${_selectedPosition.longitude.toStringAsFixed(5)}';
    }

    Navigator.pop(
      context,
      DeliveryLocation(
        address: finalAddress,
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Position de livraison'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: _currentZoom,
              onTap: _onMapTap,
              onPositionChanged: (pos, _) {
                if (pos.zoom != null) _currentZoom = pos.zoom!;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.quickdevit.noogo',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Indicateur de chargement
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 12),
                      Text('Localisation en cours...'),
                    ],
                  ),
                ),
              ),
            ),

          // Instruction en haut
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Touchez la carte pour déplacer le marqueur',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton GPS (recentrer)
          Positioned(
            right: 16,
            bottom: 240,
            child: FloatingActionButton.small(
              heroTag: 'gps_btn',
              onPressed: _isLoading ? null : _getCurrentLocation,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Panel bas : adresse + confirmer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Coordonnées GPS
                  Row(
                    children: [
                      const Icon(Icons.gps_fixed,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedPosition.latitude.toStringAsFixed(5)}, ${_selectedPosition.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (_hasGpsPosition)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle,
                              size: 16, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Champ adresse (optionnel)
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Précision (optionnel)',
                      hintText: 'Ex: Porte bleue à côté de la pharmacie',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    maxLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Bouton Confirmer
                  ElevatedButton.icon(
                    onPressed: _hasGpsPosition ? _confirmLocation : null,
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'Confirmer cette position',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
