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
            vehicle['registrationNumber'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRed,
            ),
          ),
          const SizedBox(height: 8),
          Text('Model: ${vehicle['model'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
          Text('Owner: ${vehicle['ownerName'] ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
          if (vehicle['ownerPhone'] != null)
             Text('Phone: ${vehicle['ownerPhone']}', style: const TextStyle(fontSize: 16)),
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
        final date = DateTime.parse(visit['date']).toLocal();
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(visit['description']),
            children: [
              if (visit['parts'] != null && visit['parts'].isNotEmpty)
                _buildPartsList(visit['parts']),
              if (visit['labourCharge'] != null)
                ListTile(
                  title: const Text('Labour Charge'),
                  trailing: Text('₹${visit['labourCharge']}'),
                ),
              if (visit['bill'] != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('View Bill'),
                    onPressed: () {
                       context.push('/bills/view/${visit['bill']['_id']}');
                    },
                  ),
                ),
              if (visit['images'] != null && visit['images'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text('View ${visit['images'].length} Images'),
                    onPressed: () {
                       // context.push('/images/viewer', extra: visit['images']);
                    },
                  ),
                )
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
        title: Text(part['name']),
        subtitle: Text('Qty: ${part['quantity']} @ ₹${part['unitPrice']}'),
        trailing: Text('₹${(part['quantity'] * part['unitPrice']).toStringAsFixed(2)}'),
      )).toList(),
    );
  }
}
