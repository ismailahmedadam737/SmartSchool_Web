// lib/super_admin_dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  List<dynamic> _tenants = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTenants();
  }

  Future<void> _fetchTenants() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('https://smartschool-web.onrender.com/admin/tenants'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer <SUPERADMIN_TOKEN>',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tenants = data is List ? data : [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load schools (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(int tenantId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse(
            'https://smartschool-web.onrender.com/admin/tenants/$tenantId/status'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer <SUPERADMIN_TOKEN>',
        },
        body: jsonEncode({'status': newStatus}),
      );
      if (response.statusCode == 200) {
        await _fetchTenants();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update status (${response.statusCode})'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.greenAccent;
      case 'suspended':
        return Colors.orangeAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Super Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Refresh',
            onPressed: _fetchTenants,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchTenants,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _tenants.isEmpty
                      ? const Center(
                          child: Text(
                            'No schools registered yet.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _tenants.length,
                          itemBuilder: (context, index) {
                            final tenant = _tenants[index];
                            final status =
                                tenant['subscription_status'] ?? 'unknown';
                            final expires =
                                tenant['subscription_expires_at'] ?? 'N/A';
                            return Card(
                              color: Colors.white.withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                      color: Colors.white.withOpacity(0.12))),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      const Color(0xFF6C63FF).withOpacity(0.3),
                                  child: Text(
                                    (tenant['name'] ?? 'S')[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  tenant['name'] ?? 'Unnamed School',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: _statusColor(status),
                                              width: 1),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                              color: _statusColor(status),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text('Expires: $expires',
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.white70),
                                  color: const Color(0xFF302B63),
                                  onSelected: (value) async {
                                    await _updateStatus(
                                        tenant['id'] as int, value);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'active',
                                      child: Row(children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.greenAccent,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text('Activate',
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'suspended',
                                      child: Row(children: [
                                        Icon(Icons.pause_circle,
                                            color: Colors.orangeAccent,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text('Suspend',
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'cancelled',
                                      child: Row(children: [
                                        Icon(Icons.cancel,
                                            color: Colors.redAccent, size: 18),
                                        SizedBox(width: 8),
                                        Text('Cancel',
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
