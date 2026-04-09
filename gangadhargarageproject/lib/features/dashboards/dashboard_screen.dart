import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _role;
  String? _userName;
  Map<String, dynamic>? _stats;

  @override

  void initState() {
    super.initState();
    _loadRole();
    _fetchStats();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('user_role');
      _userName = prefs.getString('user_name');
    });
  }

  Future<void> _fetchStats() async {
    try {
      final res = await apiClient.get('/billing/stats');
      setState(() {
        _stats = res.data;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_role != 'Admin' && _role != 'Worker') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Unauthorized Role', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Please contact your administrator.'),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _logout, child: const Text('LOGOUT'))
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.white.withOpacity(0.2),
              child: const Icon(Icons.person, color: AppTheme.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _userName ?? 'User',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _role ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchStats),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            final contentWidth = isDesktop ? 1000.0 : constraints.maxWidth;
            
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_role == 'Admin' || _role == 'Worker') ...[
                        _buildStatsRow(isDesktop),
                        const SizedBox(height: 24),
                      ],
                      
                      if (isDesktop) 
                        _buildDesktopGrid()
                      else
                        _buildMobileColumn(),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildMobileColumn() {
    return Column(
      children: [
        _buildActionCard(
          title: 'New Service Bill',
          icon: Icons.receipt_long,
          onTap: () => context.push('/bills/new'),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Vehicle Search History',
          icon: Icons.directions_car,
          onTap: () => context.push('/vehicles'),
        ),
        if (_role == 'Admin' || _role == 'Worker') ...[
          const SizedBox(height: 16),
          _buildActionCard(
            title: 'Business Reports',
            icon: Icons.bar_chart,
            onTap: () => context.push('/reports'),
          ),
        ],
        if (_role == 'Admin') ...[
          const SizedBox(height: 16),
          _buildActionCard(
            title: 'Manage Workers',
            icon: Icons.group,
            onTap: () => context.push('/workers'),
          ),
        ]
      ],
    );
  }

  Widget _buildDesktopGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 3.5,
      children: [
        _buildActionCard(
          title: 'New Service Bill',
          icon: Icons.receipt_long,
          onTap: () => context.push('/bills/new'),
        ),
        _buildActionCard(
          title: 'Vehicle Search History',
          icon: Icons.directions_car,
          onTap: () => context.push('/vehicles'),
        ),
        if (_role == 'Admin' || _role == 'Worker')
          _buildActionCard(
            title: 'Business Reports',
            icon: Icons.bar_chart,
            onTap: () => context.push('/reports'),
          ),
        if (_role == 'Admin')
          _buildActionCard(
            title: 'Manage Workers',
            icon: Icons.group,
            onTap: () => context.push('/workers'),
          ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDesktop) {
    final pending = _stats?['Pending']?['total'] ?? 0.0;
    final todayReceived = _stats?['TodayReceived']?['total'] ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Pending', 
            '₹${pending.toStringAsFixed(2)}', 
            Colors.orange, 
            Icons.hourglass_empty,
            isDesktop
          ),
        ),
        if (_role == 'Admin') ...[
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Today Received', 
              '₹${todayReceived.toStringAsFixed(2)}', 
              Colors.green, 
              Icons.account_balance_wallet,
              isDesktop
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isDesktop ? 32 : 28),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: isDesktop ? 28 : 24, fontWeight: FontWeight.bold, color: AppTheme.white)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: isDesktop ? 16 : 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }


  Widget _buildActionCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryRed, AppTheme.accentPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: AppTheme.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 24, color: AppTheme.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


