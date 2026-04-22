import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class RestaurantSearchScreen extends StatefulWidget {
  final void Function(int restaurantId) onRestaurantSelected;

  const RestaurantSearchScreen({super.key, required this.onRestaurantSelected});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search(''); // load all active restaurants
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await ApiService.instance.searchRestaurants(query);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (kDebugMode) debugPrint('Search error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher un restaurant'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Nom ou adresse...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty && !_isLoading
                ? const Center(
                    child: Text('Aucun restaurant trouvé',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    itemCount: _results.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final r = _results[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: r['logo'] != null
                                ? NetworkImage(r['logo'].toString())
                                : null,
                            child: r['logo'] == null
                                ? const Icon(Icons.restaurant,
                                    color: AppColors.primary)
                                : null,
                          ),
                          title: Text(
                            r['nom']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            r['adresse']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: r['is_open_override'] == true
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${r['dishes_count'] ?? 0} plats',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          onTap: () {
                            final id = r['id'];
                            if (id != null) {
                              widget.onRestaurantSelected(id as int);
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
