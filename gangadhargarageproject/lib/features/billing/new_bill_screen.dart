import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'billing_provider.dart';

import 'package:intl/intl.dart';

class NewBillScreen extends ConsumerStatefulWidget {
  final String? billId;
  const NewBillScreen({super.key, this.billId});

  @override
  ConsumerState<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends ConsumerState<NewBillScreen> {
  final _regNoController = TextEditingController();
  final _modelController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _labourController = TextEditingController();
  
  List<Map<String, dynamic>> _parts = [];
  bool _isGstEnabled = true;
  bool _isLoading = false;
  Map<String, dynamic>? _existingVehicle;

  @override
  void initState() {
    super.initState();
    if (widget.billId != null) {
      _fetchBillData();
    }
  }

  Future<void> _fetchBillData() async {
    setState(() => _isLoading = true);
    try {
      final billing = ref.read(billingProvider);
      final bill = await billing.getBill(widget.billId!);
      
      setState(() {
        // The vehicles join now includes 'id'
        _existingVehicle = bill['vehicles'];
        if (_existingVehicle != null) {
          _regNoController.text = _existingVehicle!['registration_number'] ?? '';
          _modelController.text = _existingVehicle!['model'] ?? '';
          _ownerNameController.text = _existingVehicle!['owner_name'] ?? '';
          _phoneController.text = _existingVehicle!['owner_phone'] ?? '';
        }

        // Load description from the visit join
        final visit = bill['visits'];
        if (visit != null && visit is Map) {
          _descController.text = visit['description'] ?? '';
        }

        final items = bill['bill_items'] as List? ?? [];
        _parts = items.map<Map<String, dynamic>>((item) {
          final m = item as Map<String, dynamic>;
          return {
            'name': m['name'] ?? 'Part',
            'quantity': m['quantity'] ?? 1,
            'unitPrice': (m['unit_price'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();

        _labourController.text = (bill['labour_charge'] as num?)?.toString() ?? '0';
        _isGstEnabled = bill['is_gst_enabled'] ?? true;
      });
    } catch (e) {
      debugPrint('Error loading bill: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading bill: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _addPart() {
    _partDialog();
  }

  void _partDialog({int? editIndex}) {
    final nameCtrl = TextEditingController(text: editIndex != null ? _parts[editIndex]['name'] : '');
    final qtyCtrl = TextEditingController(text: editIndex != null ? _parts[editIndex]['quantity'].toString() : '1');
    final priceCtrl = TextEditingController(text: editIndex != null ? _parts[editIndex]['unitPrice'].toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editIndex != null ? 'Edit Spare Part' : 'Add Spare Part'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Part Name')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Unit Price'), keyboardType: TextInputType.number)),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                setState(() {
                  final newPart = {
                    'name': nameCtrl.text,
                    'quantity': int.parse(qtyCtrl.text),
                    'unitPrice': double.parse(priceCtrl.text),
                  };
                  if (editIndex != null) {
                    _parts[editIndex] = newPart;
                  } else {
                    _parts.add(newPart);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(editIndex != null ? 'Update' : 'Add'),
          )
        ],
      )
    );
  }

  double get _subtotal {
    double total = double.tryParse(_labourController.text) ?? 0;
    for (var p in _parts) {
      total += (p['quantity'] as int) * (p['unitPrice'] as double);
    }
    return total;
  }

  double get _gst => _isGstEnabled ? _subtotal * 0.18 : 0;
  double get _total => _subtotal + _gst;

  Future<void> _fetchVehicleDetails(String regNo) async {
    try {
      final data = await supabase
          .from('vehicles')
          .select('''
            *,
            visits (
              id, date, description,
              parts ( * )
            )
          ''')
          .ilike('registration_number', regNo)
          .limit(1);

      final List results = data as List;
      if (results.isNotEmpty) {
        final v = results[0] as Map<String, dynamic>;
        setState(() {
          _existingVehicle = v;
          _modelController.text = v['model'] ?? '';
          _ownerNameController.text = v['owner_name'] ?? '';
          _phoneController.text = v['owner_phone'] ?? '';
        });
      } else {
        setState(() => _existingVehicle = null);
      }
    } catch (e) {
      debugPrint('Error fetching vehicle: $e');
    }
  }

  Future<void> _submit() async {
    if (_regNoController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final regNo = _regNoController.text.trim().toUpperCase();
      final labour = double.tryParse(_labourController.text) ?? 0;
      String vehicleId;

      final vehicleData = {
        'registration_number': regNo,
        'model': _modelController.text.trim(),
        'owner_name': _ownerNameController.text.trim(),
        'owner_phone': _phoneController.text.trim(),
      };

      // 1. Create or update vehicle
      if (_existingVehicle != null) {
        vehicleId = _existingVehicle!['id'];
        await supabase.from('vehicles').update({
          'model': vehicleData['model'],
          'owner_name': vehicleData['owner_name'],
          'owner_phone': vehicleData['owner_phone'],
        }).eq('id', vehicleId);
      } else {
        final row = await supabase.from('vehicles').upsert(vehicleData).select().single();
        vehicleId = row['id'];
      }

      // 2. Create visit
      final workerId = supabase.auth.currentUser?.id;
      final visitRow = await supabase.from('visits').insert({
        'vehicle_id': vehicleId,
        'worker_id': workerId,
        'description': _descController.text.trim(),
        'labour_charge': labour,
      }).select().single();
      final visitId = visitRow['id'];

      // 3. Create visit parts
      if (_parts.isNotEmpty) {
        final partsData = _parts.map((p) => {
          'visit_id': visitId,
          'name': p['name'],
          'quantity': p['quantity'],
          'unit_price': p['unitPrice'],
        }).toList();
        await supabase.from('parts').insert(partsData);
      }

      // 4. Create bill using BillingService
      final billing = ref.read(billingProvider);
      final processedItems = _parts.map((p) => {
        'name': p['name'],
        'quantity': p['quantity'],
        'unit_price': (p['unitPrice'] as num).toDouble(),
        'total_price': (p['quantity'] as int) * (p['unitPrice'] as double),
      }).toList();

      String billId = widget.billId ?? '';
      if (widget.billId != null) {
        // Update existing bill
        await supabase.from('bills').update({
          'labour_charge': labour,
          'is_gst_enabled': _isGstEnabled,
        }).eq('id', widget.billId!);
        await supabase.from('bill_items').delete().eq('bill_id', widget.billId!);
        await supabase.from('bill_items').insert(processedItems.map((i) => {
          ...i, 'bill_id': widget.billId,
        }).toList());
      } else {
        final success = await billing.createBill(
          vehicleId: vehicleId,
          visitId: visitId,
          workerId: workerId,
          items: processedItems,
          labourCharge: labour,
          isGstEnabled: _isGstEnabled,
        );
        if (!success) throw Exception('Bill creation failed');
        // Get the latest bill for this vehicle to navigate to it
        final latestBill = await supabase
            .from('bills')
            .select('id')
            .eq('vehicle_id', vehicleId)
            .order('created_at', ascending: false)
            .limit(1)
            .single();
        billId = latestBill['id'];
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.billId != null ? 'Bill updated!' : 'Bill created!'),
        ));
        context.replace('/bills/view/$billId');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.billId != null ? 'Edit Service Bill' : 'New Service Bill'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (option) => option['registration_number'] ?? '',
              optionsBuilder: (textEditingValue) async {
                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                final data = await supabase
                    .from('vehicles')
                    .select('id, registration_number, model, owner_name, owner_phone')
                    .ilike('registration_number', '%${textEditingValue.text}%')
                    .limit(10);
                return (data as List).cast<Map<String, dynamic>>();
              },
              onSelected: (option) {
                _regNoController.text = option['registration_number'];
                _fetchVehicleDetails(option['registration_number']);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (controller.text != _regNoController.text && _regNoController.text.isNotEmpty) {
                   controller.text = _regNoController.text;
                }
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number *',
                    hintText: 'Enter vehicle number',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (val) {
                    _regNoController.text = val;
                    if (val.isEmpty) setState(() => _existingVehicle = null);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(labelText: 'Model Name'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _ownerNameController,
                    decoration: const InputDecoration(labelText: 'Owner Name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixText: '+91 '),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            if (_existingVehicle != null && _existingVehicle!['visits'] != null && (_existingVehicle!['visits'] as List).isNotEmpty) ...[
               Container(
                 decoration: BoxDecoration(
                   color: Theme.of(context).cardTheme.color,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: AppTheme.accentPink.withOpacity(0.3)),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.2),
                       blurRadius: 10,
                       offset: const Offset(0, 4),
                     )
                   ]
                 ),
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Row(
                         children: [
                           Icon(Icons.history, color: AppTheme.accentPink, size: 20),
                           SizedBox(width: 8),
                           Text('Last Service Info', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white, fontSize: 16)),
                         ],
                       ),
                       const SizedBox(height: 12),
                       Builder(builder: (context) {
                         String dateStr = 'N/A';
                         try {
                           final raw = _existingVehicle!['visits'][0]['created_at'] ?? _existingVehicle!['visits'][0]['date'];
                           if (raw != null) {
                             dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(raw.toString()).toLocal());
                           }
                         } catch (_) {}
                         return Text('Date: $dateStr', style: TextStyle(color: Colors.white.withOpacity(0.7)));
                       }),
                       const SizedBox(height: 4),
                       Text('Work: ${_existingVehicle!['visits'][0]['description'] ?? 'N/A'}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                     ],
                   ),
                 ),
               ),
               const SizedBox(height: 24),
            ],


            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Complaint / Work Description *'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Spare Parts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white)),
                TextButton.icon(
                  onPressed: _addPart, 
                  icon: const Icon(Icons.add, color: AppTheme.accentPink), 
                  label: const Text('Add Part', style: TextStyle(color: AppTheme.accentPink, fontWeight: FontWeight.bold))
                ),
              ],
            ),
            const Divider(),
            ..._parts.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: Text('Qty: ${p['quantity']} x ₹${p['unitPrice']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${p['quantity'] * p['unitPrice']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.white)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: AppTheme.white),
                      onPressed: () => _partDialog(editIndex: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                      onPressed: () => setState(() => _parts.removeAt(index)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _labourController,
              decoration: const InputDecoration(labelText: 'Labour Charge (₹)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState((){}),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: SwitchListTile(
                title: const Text('Apply 18% GST', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _isGstEnabled,
                onChanged: (val) => setState(() => _isGstEnabled = val),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Subtotal', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)), Text('₹${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16))],
              ),
            ),
            if (_isGstEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('GST (18%)', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)), Text('₹${_gst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16))],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.white)), 
                  Text('₹${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.primaryRed))
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.billId != null ? 'UPDATE BILL' : 'GENERATE BILL'),
            )
          ],
        )
      ),
    );
  }
}
