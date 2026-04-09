import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'vehicles_provider.dart';
import '../../core/theme/app_theme.dart';
import 'dart:async';

class VehicleSearchScreen extends ConsumerStatefulWidget {
  const VehicleSearchScreen({super.key});

  @override
  ConsumerState<VehicleSearchScreen> createState() => _VehicleSearchScreenState();
}

class _VehicleSearchScreenState extends ConsumerState<VehicleSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehicleSearchProvider.notifier).searchVehicles('');
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(vehicleSearchProvider.notifier).searchVehicles(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Vehicles'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search by Registration Number...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: vehicles.isEmpty
                ? const Center(child: Text('No vehicles found.'))
                : ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryRed,
                          child: Icon(Icons.directions_car, color: Colors.white),
                        ),
                        title: Text(
                          vehicle['registrationNumber'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(vehicle['model'] ?? 'Unknown Model'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          context.push('/vehicles/${vehicle['_id']}');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
