import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'worker_provider.dart';
import '../../core/theme/app_theme.dart';

class ManageWorkersScreen extends ConsumerStatefulWidget {
  const ManageWorkersScreen({super.key});

  @override
  ConsumerState<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends ConsumerState<ManageWorkersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'Worker';

  void _showWorkerDialog({Map<String, dynamic>? worker}) {
    final isEdit = worker != null;
    
    _nameCtrl.text = isEdit ? worker['name'] ?? '' : '';
    _emailCtrl.text = isEdit ? worker['email'] ?? '' : '';
    _passwordCtrl.text = '';
    _selectedRole = isEdit ? worker['role'] ?? 'Worker' : 'Worker';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Edit User' : 'Add New User',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.white),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required field' : null,
                  enabled: !isEdit, // Email shouldn't be edited for Auth users
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'New Password (leave blank to keep current)' : 'Password',
                  ),
                  obscureText: true,
                  validator: (v) => !isEdit && v!.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  dropdownColor: Theme.of(context).cardTheme.color,
                  items: ['Worker', 'Admin'].map((String role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      bool success;
                      if (isEdit) {
                        success = await ref.read(workerProvider.notifier).updateWorker(
                          worker['id'],
                          _nameCtrl.text,
                          _emailCtrl.text,
                          _selectedRole,
                          _passwordCtrl.text,
                        );
                      } else {
                        success = await ref.read(workerProvider.notifier).addWorker(
                          _nameCtrl.text,
                          _emailCtrl.text,
                          _passwordCtrl.text,
                          _selectedRole,
                        );
                      }
                      
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save worker context. If adding a new worker, use the Supabase Dashboard to create their Auth account with this email first.')));
                      }
                    }
                  },
                  child: Text(isEdit ? 'UPDATE USER' : 'CREATE USER'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
  }

  void _deletePrompt(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text('Delete User?', style: TextStyle(color: AppTheme.white)),
        content: const Text('Are you sure you want to permanently delete this user profile?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(workerProvider.notifier).deleteWorker(id);
            },
            child: const Text('DELETE', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final workerState = ref.watch(workerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Workers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(workerProvider.notifier).fetchWorkers(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkerDialog(),
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          final contentWidth = isDesktop ? 1000.0 : constraints.maxWidth;

          return workerState.when(
            data: (workers) {
              if (workers.isEmpty) return const Center(child: Text('No workers found.'));
              
              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: isDesktop 
                    ? _buildWorkerGrid(workers)
                    : _buildWorkerList(workers),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        }
      ),
    );
  }

  Widget _buildWorkerList(List<dynamic> workers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workers.length,
      itemBuilder: (context, index) => _buildWorkerCard(workers[index]),
    );
  }

  Widget _buildWorkerGrid(List<dynamic> workers) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: workers.length,
      itemBuilder: (context, index) => _buildWorkerCard(workers[index]),
    );
  }

  Widget _buildWorkerCard(dynamic worker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: worker['role'] == 'Admin' ? AppTheme.primaryRed : Colors.blueGrey,
          child: Icon(worker['role'] == 'Admin' ? Icons.admin_panel_settings : Icons.engineering, color: AppTheme.white),
        ),
        title: Text(worker['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.white)),
        subtitle: Text('${worker['role']} • ${worker['email']}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.white),
              onPressed: () => _showWorkerDialog(worker: worker),
            ),
            if (worker['is_main_admin'] != true)
              IconButton(
                icon: const Icon(Icons.delete, color: AppTheme.accentPink),
                onPressed: () => _deletePrompt(worker['id']),
              ),
          ],
        ),
      ),
    );
  }
}
