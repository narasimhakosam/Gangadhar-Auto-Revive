import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../billing/billing_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isLoading = false;
  List<dynamic> _pendingBills = [];
  List<dynamic> _completedBills = [];

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    setState(() => _isLoading = true);
    try {
      final billing = ref.read(billingProvider);
      final pending = await billing.getBillsByStatus('Pending');
      final completed = await billing.getBillsByStatus('Completed');

      setState(() {
        _pendingBills = pending;
        _completedBills = completed;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final billing = ref.read(billingProvider);
      await billing.updateBillStatus(id, status);
      _fetchBills();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _sendMessage(dynamic bill, bool isWhatsApp) async {
    final phone = bill['vehicle']['ownerPhone'];
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number found for this vehicle.')));
      return;
    }

    final regNo = bill['vehicle']['registrationNumber'];
    final total = bill['total'].toStringAsFixed(2);
    final message = "Hello, your vehicle ($regNo) is ready for pickup! Total bill is ₹$total. - Gangadhar Auto Revive";

    // Sanitize phone number (remove all non-digits)
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    
    // If it's 10 digits, add the 91 prefix
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    } 
    // If it has 12 digits and starts with 91, keep it. 
    // If it's anything else, just use it as is but warn if possible.

    Uri url;
    if (isWhatsApp) {
      url = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
    } else {
      url = Uri.parse("sms:+$cleanPhone?body=${Uri.encodeComponent(message)}");
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch messaging app.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Business Reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
              Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBills),
          ],
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                _buildBillList(_pendingBills, true),
                _buildBillList(_completedBills, false),
              ],
            ),
      ),
    );
  }

  Widget _buildBillList(List<dynamic> bills, bool isPending) {
    if (bills.isEmpty) {
      return Center(child: Text('No ${isPending ? 'pending' : 'completed'} bills found.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchBills,
      child: ListView.builder(
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          final isPending = bill['status'] == 'Pending';
          
          final date = DateTime.parse(bill['createdAt']).toLocal();
          final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
          
          String? completedDate;
          if (bill['completedAt'] != null) {
            final cDate = DateTime.parse(bill['completedAt']).toLocal();
            completedDate = DateFormat('dd MMM yyyy, hh:mm a').format(cDate);
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isPending ? Colors.orange.shade200.withOpacity(0.5) : AppTheme.accentPink.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
              title: Text(bill['vehicle']['registrationNumber'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white, fontSize: 18)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Veh: ${bill['vehicle']['registrationNumber']}'),
                  Text('Created: $formattedDate'),
                  if (completedDate != null)
                    Text('Completed: $completedDate', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Text('Total: ₹${bill['total'].toStringAsFixed(2)}'),
                ],
              ),
              leading: Icon(
                isPending ? Icons.pending_actions : Icons.check_circle,
                color: isPending ? Colors.orange : Colors.green,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPending) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.white),
                      onPressed: () async {
                        await context.push('/bills/edit/${bill['id']}');
                        _fetchBills();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.message, color: AppTheme.accentPink),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Theme.of(context).cardTheme.color,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Notify Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.white)),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(Icons.wechat, color: Colors.green, size: 32),
                                  title: const Text('Send via WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _sendMessage(bill, true);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.sms, color: Colors.blue, size: 32),
                                  title: const Text('Send via SMS', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _sendMessage(bill, false);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                     IconButton(
                       icon: const Icon(Icons.visibility, color: AppTheme.primaryRed),
                       onPressed: () => context.push('/bills/view/${bill['id']}'),
                     ),
                  ],
                  Chip(
                    label: Text(bill['status']),
                    backgroundColor: isPending ? Colors.orange.withOpacity(0.15) : AppTheme.accentPink.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isPending ? Colors.orange.shade800 : AppTheme.accentPink, 
                      fontWeight: FontWeight.bold
                    ),
                    side: BorderSide.none,
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Owner: ${bill['vehicle']['ownerName'] ?? 'N/A'}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      Text('Phone: ${bill['vehicle']['ownerPhone'] ?? 'N/A'}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      Text('Model: ${bill['vehicle']['model'] ?? 'N/A'}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      ...?bill['items']?.map<Widget>((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item['name']} x ${item['quantity']}', style: const TextStyle(fontSize: 15)),
                            Text('₹${item['totalPrice'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )).toList(),
                      const SizedBox(height: 12),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('₹${bill['total'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryRed)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isPending)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(bill['id'], 'Completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRed,
                            ),
                            child: const Text('MARK AS COMPLETED', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}


