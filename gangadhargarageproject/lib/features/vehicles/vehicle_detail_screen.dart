import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vehicles_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prevent the UUID error by checking if the ID is valid before watching the provider
    if (vehicleId == 'null' || vehicleId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Invalid Vehicle ID provided.')),
      );
    }

    final vehicleAsync = ref.watch(vehicleDetailProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
      ),
      body: vehicleAsync.when(
        data: (vehicle) {
          final visits = List.from(vehicle['visits'] ?? []);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildVehicleHeader(context, vehicle),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Service History Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                visits.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No service history found.'),
                      )
                    : _buildTimeline(visits, context),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildVehicleHeader(BuildContext context, Map<String, dynamic> vehicle) {
    return Container(
      color: Theme.of(context).cardTheme.color,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicle['registration_number'] ?? 'Unknown',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRed,
            ),
          ),
          const SizedBox(height: 8),
          Text('Model: ${vehicle['model'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
          Text('Owner: ${vehicle['owner_name'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
          if (vehicle['owner_phone'] != null)
             Text('Phone: ${vehicle['owner_phone']}', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTimeline(List visits, BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        
        DateTime date;
        try {
          date = DateTime.parse(visit['date'] ?? visit['created_at']).toLocal();
        } catch (_) {
          date = DateTime.now();
        }
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(visit['description'] ?? 'No description'),
            children: [
              if (visit['parts'] != null && visit['parts'].isNotEmpty)
                _buildPartsList(visit['parts']),
              if (visit['labour_charge'] != null)
                ListTile(
                  title: const Text('Labour Charge'),
                  trailing: Text('₹${(visit['labour_charge'] as num).toStringAsFixed(2)}'),
                ),
              // Bills are joined as a list (bills table has visit_id FK)
              if (visit['bills'] != null && (visit['bills'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text('View Bill (₹${((visit['bills'] as List)[0]['total'] as num).toStringAsFixed(2)})'),
                    onPressed: () {
                       context.push('/bills/view/${(visit['bills'] as List)[0]['id']}');
                    },
                  ),
                ),
              // Image handling would go here
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartsList(List parts) {
    return Column(
      children: parts.map((part) => ListTile(
        dense: true,
        title: Text(part['name'] ?? 'Part'),
        subtitle: Text('Qty: ${part['quantity']} @ ₹${(part['unit_price'] as num).toStringAsFixed(2)}'),
        trailing: Text('₹${((part['quantity'] as num) * (part['unit_price'] as num)).toStringAsFixed(2)}'),
      )).toList(),
    );
  }
}
