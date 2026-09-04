// lib/super_admin_dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'school_detail_screen.dart';
import 'dashboard_screen.dart';
import 'Service/api_service.dart';

const String _baseUrl = 'https://smartschool-web.onrender.com';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard>
    with SingleTickerProviderStateMixin {
  List<dynamic> _tenants = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all' | 'active' | 'suspended' | 'expired'
  String _currentTab = 'Dashboard'; // 'Dashboard' | 'All Schools' | 'Active' | 'Suspended' | 'Billing'
  late AnimationController _fabAnim;
  final ScrollController _sidebarScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fetchTenants();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    _sidebarScrollCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────── API METHODS ───────────────────────────

  Future<void> _fetchTenants() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/admin/tenants'),
              headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tenants = data is List ? data : [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server error (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error:\n$e';
        _loading = false;
      });
    }
  }

  Future<void> _createTenant({
    required String name,
    required String email,
    required String username,
    required String password,
    required String plan,
    required int days,
    required double fee,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/tenants'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'admin_email': email,
              'admin_username': username,
              'admin_password': password,
              'subscription_plan': plan,
              'billing_cycle_days': days,
              'monthly_fee': fee,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 201) {
        final created = jsonDecode(response.body);
        await _fetchTenants();
        if (!mounted) return;
        _showCredentialsDialog(created);
      } else {
        if (!mounted) return;
        _snack('❌ Provisioning failed (${response.statusCode})', Colors.redAccent);
      }
    } catch (e) {
      _snack('❌ Connection error: $e', Colors.redAccent);
    }
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/admin/tenants/$id/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': newStatus}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        await _fetchTenants();
        if (!mounted) return;
        _snack('✅ Status updated to $newStatus', const Color(0xFF00E676));
      } else {
        _snack('❌ Failed (${response.statusCode})', Colors.redAccent);
      }
    } catch (e) {
      _snack('❌ Error: $e', Colors.redAccent);
    }
  }

  Future<void> _renewTenant(int id, {int days = 30}) async {
    try {
      _snack('⚡ Renewing subscription...', const Color(0xFF6C63FF));
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/tenants/$id/renew'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'days': days}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        await _fetchTenants();
        if (!mounted) return;
        _snack('🎉 Subscription renewed for $days days!', const Color(0xFF00E676));
      } else {
        _snack('❌ Renew failed (${response.statusCode})', Colors.redAccent);
      }
    } catch (e) {
      _snack('❌ Error: $e', Colors.redAccent);
    }
  }

  Future<void> _impersonateSchool(Map<String, dynamic> tenant) async {
    final int? tId = int.tryParse(tenant['id'].toString());
    final String tName = (tenant['name'] ?? 'School').toString();
    ApiService.currentTenantId = tId;
    ApiService.currentTenantName = tName;

    try {
      _snack('🚀 Logging in as $tName...', const Color(0xFF00D2FF));
      await http
          .post(
            Uri.parse('$_baseUrl/admin/tenants/${tenant['id']}/impersonate'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userRole: 'Admin',
            role: 'Admin',
            isImpersonating: true,
            impersonatedTenantName: tName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userRole: 'Admin',
            role: 'Admin',
            isImpersonating: true,
            impersonatedTenantName: tName,
          ),
        ),
      );
    }
  }

  Future<void> _deleteTenant(int id, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131826),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
          SizedBox(width: 12),
          Text('Delete School System?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Text('Ma ziada tahay inaad tirtirto "$name"? Dhammaan xogta iskuulkaas waa la tirtirayaa.',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http
            .delete(Uri.parse('$_baseUrl/admin/tenants/$id'))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          await _fetchTenants();
          if (!mounted) return;
          _snack('🗑️ School system deleted successfully', Colors.redAccent);
        }
      } catch (e) {
        _snack('❌ Error: $e', Colors.redAccent);
      }
    }
  }

  // ─────────────────────────── COMPUTED METRICS ───────────────────────────

  int get _totalCount => _tenants.length;
  int get _activeCount => _tenants.where((t) => (t['subscription_status'] ?? '') == 'active').length;
  int get _suspendedCount => _tenants.where((t) => (t['subscription_status'] ?? '') == 'suspended').length;
  int get _expiredCount => _tenants.where((t) {
        final exp = t['subscription_expires_at'];
        if (exp == null) return false;
        final d = DateTime.tryParse(exp);
        return d != null && d.isBefore(DateTime.now());
      }).length;

  double get _estimatedMrr => _tenants.fold(0.0, (sum, t) {
        if ((t['subscription_status'] ?? '') == 'active') {
          double fee = double.tryParse((t['monthly_fee'] ?? '50').toString()) ?? 50.0;
          return sum + fee;
        }
        return sum;
      });

  List<dynamic> get _filteredTenants {
    return _tenants.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final email = (t['admin_email'] ?? '').toString().toLowerCase();
      final user = (t['admin_username'] ?? '').toString().toLowerCase();
      final status = (t['subscription_status'] ?? '').toString().toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          user.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedFilter == 'active') return status == 'active';
      if (_selectedFilter == 'suspended') return status == 'suspended';
      if (_selectedFilter == 'expired') {
        final exp = t['subscription_expires_at'];
        if (exp == null) return false;
        final d = DateTime.tryParse(exp);
        return d != null && d.isBefore(DateTime.now());
      }
      return true; // 'all'
    }).toList();
  }

  // ─────────────────────────── DIALOGS & MODALS ───────────────────────────

  void _showCredentialsDialog(Map<String, dynamic> school) {
    final String loginUrl = "https://smartschool-web.onrender.com";
    final String payloadText =
        "🌐 SMARTMIND TECHNOLOGY - SCHOOL CREDENTIALS 🌐\n\n"
        "🏢 School: ${school['name']}\n"
        "🔗 Login Web Link: $loginUrl\n"
        "👤 Username: ${school['admin_username']}\n"
        "🔑 Password: ${school['admin_password']}\n"
        "🏷️ Plan: ${(school['subscription_plan'] ?? 'basic').toString().toUpperCase()}\n\n"
        "Fadlan u dir cinwaannadan maamulaha iskuulka.";

    final ScrollController dialogScrollCtrl = ScrollController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F1524), Color(0xFF1B233A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 2),
            ],
          ),
          child: RawScrollbar(
            controller: dialogScrollCtrl,
            thumbColor: const Color(0xFF00E676),
            radius: const Radius.circular(8),
            thickness: 6,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: dialogScrollCtrl,
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF00E676), size: 44),
                ),
                const SizedBox(height: 14),
                const Text('System Provisioned Successfully! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(school['name'] ?? '',
                    style: const TextStyle(color: Color(0xFF00D2FF), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                _credRow(Icons.link_rounded, 'Login URL', loginUrl),
                const SizedBox(height: 8),
                _credRow(Icons.person_rounded, 'Admin Username', school['admin_username'] ?? 'N/A'),
                const SizedBox(height: 8),
                _credRow(Icons.lock_rounded, 'Admin Password', school['admin_password'] ?? 'N/A'),
                const SizedBox(height: 8),
                _credRow(Icons.workspace_premium_rounded, 'Subscription Plan', (school['subscription_plan'] ?? 'basic').toUpperCase()),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'School Admin can now log in directly on the main login screen using these credentials.',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00D2FF),
                          side: const BorderSide(color: Color(0xFF00D2FF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: payloadText));
                          _snack('📋 Full Credentials Payload Copied!', const Color(0xFF6C63FF));
                        },
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Copy Payload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _credRow(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF00D2FF), size: 18),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Expanded(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white38, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              _snack('📋 $label copied!', const Color(0xFF6C63FF));
            },
          )
        ]),
      );

  // ─────────────────────────── SCROLLABLE 2-CARD SCHOOL REGISTRATION MODAL ───────────────────────────

  void _showAddSchoolDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '50.00');
    final ScrollController modalScrollCtrl = ScrollController();
    String plan = 'basic';
    int days = 30;
    bool saving = false;
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF171E31), Color(0xFF0D111A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), blurRadius: 15)
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Provision New School System',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('SmartMind Technology Multi-Tenant Provisioning',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white38),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
              const SizedBox(height: 16),

              Expanded(
                child: RawScrollbar(
                  controller: modalScrollCtrl,
                  thumbColor: const Color(0xFF6C63FF),
                  radius: const Radius.circular(8),
                  thickness: 6,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: modalScrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: formKey,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Unified Form Header inside Card
                            const Text('MACLUUMAADKA DIIWAANGELINTA ISKUULKA CUSUB',
                                style: TextStyle(color: Color(0xFF00D2FF), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            const SizedBox(height: 18),

                            _fieldLabel('School System Name *'),
                            _customField(nameCtrl, 'e.g. Al-Nuur International Academy', Icons.domain_rounded,
                                onChanged: (val) {
                                  if (userCtrl.text.isEmpty && val.trim().isNotEmpty) {
                                    String suggest = '${val.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_admin';
                                    setBS(() => userCtrl.text = suggest);
                                  }
                                },
                                validator: (v) => v == null || v.trim().isEmpty ? 'School name is required' : null),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Admin Username *'),
                                      _customField(userCtrl, 'e.g. alnuur_admin', Icons.person_rounded,
                                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Admin Email'),
                                      _customField(emailCtrl, 'admin@school.com', Icons.email_outlined,
                                          inputType: TextInputType.emailAddress),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            _fieldLabel('Temporary Password *'),
                            TextFormField(
                              controller: passCtrl,
                              obscureText: obscure,
                              style: const TextStyle(color: Colors.white),
                              validator: (v) => v == null || v.length < 4 ? 'Min 4 characters' : null,
                              decoration: InputDecoration(
                                hintText: 'Enter password',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF6C63FF), size: 20),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00D2FF), size: 18),
                                      tooltip: 'Auto Generate Password',
                                      onPressed: () {
                                        setBS(() => passCtrl.text = 'SchoolPass${(1000 + (DateTime.now().millisecond % 9000))}');
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                                      onPressed: () => setBS(() => obscure = !obscure),
                                    ),
                                  ],
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.07),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
                                errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.redAccent)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 16),

                            // SUBSCRIPTION & BILLING SECTION INSIDE THE UNIFIED CARD
                            const Text('QORSHAHA DIIWAANGELINTA & LACAGTA',
                                style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Subscription Plan'),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.07),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: plan,
                                            dropdownColor: const Color(0xFF171E31),
                                            style: const TextStyle(color: Colors.white),
                                            isExpanded: true,
                                            onChanged: (v) => setBS(() => plan = v!),
                                            items: const [
                                              DropdownMenuItem(value: 'basic', child: Text('Basic – Free Trial')),
                                              DropdownMenuItem(value: 'standard', child: Text('Standard – Monthly (\$50)')),
                                              DropdownMenuItem(value: 'premium', child: Text('Premium – Enterprise (\$100)')),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Monthly Fee (\$)'),
                                      _customField(feeCtrl, '50.00', Icons.attach_money_rounded, inputType: TextInputType.number),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            _fieldLabel('Initial Billing Cycle: $days Days'),
                            SliderTheme(
                              data: SliderTheme.of(ctx).copyWith(
                                activeTrackColor: const Color(0xFF6C63FF),
                                thumbColor: const Color(0xFF00D2FF),
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                                overlayColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                min: 7,
                                max: 365,
                                divisions: 20,
                                value: days.toDouble(),
                                onChanged: (v) => setBS(() => days = v.round()),
                              ),
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                  shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                                ),
                                onPressed: saving
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate()) return;
                                        setBS(() => saving = true);
                                        Navigator.pop(ctx);
                                        await _createTenant(
                                          name: nameCtrl.text.trim(),
                                          email: emailCtrl.text.trim(),
                                          username: userCtrl.text.trim(),
                                          password: passCtrl.text.trim(),
                                          plan: plan,
                                          days: days,
                                          fee: double.tryParse(feeCtrl.text.trim()) ?? 50.0,
                                        );
                                      },
                                child: saving
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.rocket_launch_rounded, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('PROVISION SCHOOL SYSTEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _customField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType inputType = TextInputType.text,
      void Function(String)? onChanged,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage(userRole: '',)),
      (route) => false,
    );
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'active':
        return const Color(0xFF00E676);
      case 'suspended':
        return Colors.amberAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white38;
    }
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'active':
        return Icons.check_circle_rounded;
      case 'suspended':
        return Icons.pause_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ─────────────────────────── SUPERADMIN SIDEBAR NAVIGATION ───────────────────────────

  Widget _buildSuperAdminSidebar() {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Color(0xFF0D121F),
        border: Border(right: BorderSide(color: Color(0xFF1E2842), width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo & Branding Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF172036), Color(0xFF1E2A47)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.hub_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMARTMIND',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Central Command Hub',
                        style: TextStyle(
                          color: Color(0xFF00D2FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Navigation List
          Expanded(
            child: RawScrollbar(
              controller: _sidebarScrollCtrl,
              thumbColor: const Color(0xFF6C63FF),
              thickness: 5,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                controller: _sidebarScrollCtrl,
                child: Column(
                  children: [
                    _sidebarNavItem(
                      id: 'Dashboard',
                      label: 'Dashboard Overview',
                      icon: Icons.dashboard_customize_rounded,
                      badge: '$_totalCount',
                      badgeColor: const Color(0xFF6C63FF),
                    ),
                    _sidebarNavItem(
                      id: 'All Schools',
                      label: 'All Schools (Dhammaan)',
                      icon: Icons.domain_rounded,
                      badge: '$_totalCount',
                      badgeColor: const Color(0xFF00D2FF),
                    ),
                    _sidebarNavItem(
                      id: 'Active',
                      label: 'Active Systems',
                      icon: Icons.check_circle_rounded,
                      badge: '$_activeCount',
                      badgeColor: const Color(0xFF00E676),
                    ),
                    _sidebarNavItem(
                      id: 'Suspended',
                      label: 'Suspended / Expired',
                      icon: Icons.pause_circle_rounded,
                      badge: '${_suspendedCount + _expiredCount}',
                      badgeColor: Colors.amberAccent,
                    ),
                    _sidebarNavItem(
                      id: 'Billing',
                      label: 'Subscriptions & MRR',
                      icon: Icons.payments_rounded,
                      badge: '\$${_estimatedMrr.toStringAsFixed(0)}',
                      badgeColor: const Color(0xFF00D2FF),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Divider(color: Colors.white12),
                    ),
                    ListTile(
                      onTap: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                        _showAddSchoolDialog();
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_rounded, color: Color(0xFF6C63FF), size: 18),
                      ),
                      title: const Text('Provision New School',
                          style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer Status & Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: Color(0xFF00E676), size: 10),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Multi-Tenant Engine Online',
                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  onTap: _handleLogout,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.redAccent.withValues(alpha: 0.08),
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  title: const Text('Logout Session', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarNavItem({
    required String id,
    required String label,
    required IconData icon,
    required String badge,
    required Color badgeColor,
  }) {
    final bool isSelected = _currentTab == id;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6C63FF).withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF6C63FF).withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        onTap: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
          setState(() {
            _currentTab = id;
            if (id == 'All Schools' || id == 'Dashboard') {
              _selectedFilter = 'all';
            } else if (id == 'Active') {
              _selectedFilter = 'active';
            } else if (id == 'Suspended') {
              _selectedFilter = 'suspended';
            }
          });
        },
        leading: Icon(icon, color: isSelected ? const Color(0xFF00D2FF) : Colors.white70, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00D2FF) : Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            badge,
            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── MAIN BUILD UI ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTenants;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        final Widget mainContentArea = SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
              : _error != null
                  ? _buildErrorView()
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Header Badge Title area
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: Color(0xFF00D2FF), size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'SMARTMIND TECHNOLOGY • CENTRAL COMMAND',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Showing ${filtered.length} of $_totalCount Systems',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Hero Metric Cards
                        if (_currentTab == 'Dashboard' || _currentTab == 'Billing')
                          SliverToBoxAdapter(child: _buildMetricCards()),

                        // Search & Filter Bar
                        SliverToBoxAdapter(child: _buildSearchAndFilterHeader()),

                        // School System Cards List (All Schools view)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          sliver: filtered.isEmpty
                              ? SliverFillRemaining(child: _buildEmptyView())
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, i) => _buildSchoolCard(filtered[i]),
                                    childCount: filtered.length,
                                  ),
                                ),
                        ),
                      ],
                    ),
        );

        return Scaffold(
          backgroundColor: const Color(0xFF090D16),
          drawer: !isDesktop ? Drawer(width: 270, child: _buildSuperAdminSidebar()) : null,
          floatingActionButton: ScaleTransition(
            scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
            child: FloatingActionButton.extended(
              onPressed: _showAddSchoolDialog,
              backgroundColor: const Color(0xFF6C63FF),
              elevation: 10,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              label: const Text('Provision New School',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
          appBar: AppBar(
            backgroundColor: const Color(0xFF111726),
            elevation: 0,
            leading: !isDesktop
                ? Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      tooltip: 'Open Command Menu',
                    ),
                  )
                : null,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SMARTMIND TECHNOLOGY COMMAND CENTER',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.8)),
                    Row(
                      children: [
                        Icon(Icons.fiber_manual_record, color: Color(0xFF00E676), size: 10),
                        SizedBox(width: 4),
                        Text('Platform Status: Operational (Multi-Tenant System)',
                            style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                tooltip: 'Refresh All Systems',
                onPressed: _fetchTenants,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                tooltip: 'Logout',
                onPressed: _handleLogout,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF090D16), Color(0xFF111726), Color(0xFF182035)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: isDesktop
                ? Row(
                    children: [
                      _buildSuperAdminSidebar(),
                      Expanded(child: mainContentArea),
                    ],
                  )
                : mainContentArea,
          ),
        );
      },
    );
  }

  // ─────────────────────────── UI COMPONENTS ───────────────────────────

  Widget _buildMetricCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 750;
          return GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isWide ? 1.8 : 1.45,
            children: [
              _metricTile('TOTAL SYSTEMS', _totalCount.toString(), Icons.domain_rounded,
                  const Color(0xFF6C63FF), 'All registered schools'),
              _metricTile('ACTIVE SYSTEMS', _activeCount.toString(), Icons.check_circle_rounded,
                  const Color(0xFF00E676), 'Operational & paid'),
              _metricTile('SUSPENDED / EXPIRED', '$_suspendedCount / $_expiredCount', Icons.pause_circle_rounded,
                  Colors.amberAccent, 'Pending renewal'),
              _metricTile('ESTIMATED MRR', '\$${_estimatedMrr.toStringAsFixed(0)}', Icons.payments_rounded,
                  const Color(0xFF00D2FF), 'Monthly Revenue'),
            ],
          );
        },
      ),
    );
  }

  Widget _metricTile(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('LIVE', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search school name, admin username, or email...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00D2FF)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip('all', '🔥 All Schools ($_totalCount)', Icons.apps_rounded),
                const SizedBox(width: 8),
                _filterChip('active', '🟢 Active ($_activeCount)', Icons.check_circle_rounded),
                const SizedBox(width: 8),
                _filterChip('suspended', '🟠 Suspended ($_suspendedCount)', Icons.pause_circle_rounded),
                const SizedBox(width: 8),
                _filterChip('expired', '🔴 Expired ($_expiredCount)', Icons.history_toggle_off_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label, IconData icon) {
    final selected = _selectedFilter == id;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedFilter = id),
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF00D2FF)),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      selectedColor: const Color(0xFF6C63FF),
      backgroundColor: const Color(0xFF1E2842),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? const Color(0xFF00D2FF) : const Color(0xFF334266), width: 1.5),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildSchoolCard(dynamic t) {
    final int id = t['id'] ?? 0;
    final String name = t['name'] ?? 'Unnamed School';
    final String status = t['subscription_status'] ?? 'unknown';
    final String plan = t['subscription_plan'] ?? 'basic';
    final String email = t['admin_email'] ?? '';
    final String user = t['admin_username'] ?? '';
    final String pass = t['admin_password'] ?? '';
    final expires = t['subscription_expires_at'];

    DateTime? expDate = expires != null ? DateTime.tryParse(expires) : null;
    final bool isExpired = expDate != null && expDate.isBefore(DateTime.now());
    final int daysLeft = expDate != null ? expDate.difference(DateTime.now()).inDays : 0;
    final String expiryStr = expDate != null ? "${expDate.year}-${expDate.month.toString().padLeft(2, '0')}-${expDate.day.toString().padLeft(2, '0')}" : 'N/A';

    final Color statusCol = isExpired ? Colors.redAccent : _statusColor(status);

    final String loginPayload =
        "🌐 SMARTMIND TECHNOLOGY SCHOOL LOGIN 🌐\n"
        "Link: https://smartschool-web.onrender.com\n"
        "Username: $user\n"
        "Password: $pass";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171E31), Color(0xFF1E2740)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusCol.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(color: statusCol.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Top Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (user.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D2FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('@$user', style: const TextStyle(color: Color(0xFF00D2FF), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          if (user.isNotEmpty && email.isNotEmpty) const SizedBox(width: 8),
                          if (email.isNotEmpty)
                            Expanded(
                              child: Text(email,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusCol.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusCol.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isExpired ? Icons.error_outline_rounded : _statusIcon(status), color: statusCol, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        isExpired ? 'EXPIRED' : status.toUpperCase(),
                        style: TextStyle(color: statusCol, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                  color: const Color(0xFF1B233A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (val) {
                    if (val == 'active' || val == 'suspended' || val == 'cancelled') {
                      _updateStatus(id, val);
                    } else if (val == 'delete') {
                      _deleteTenant(id, name);
                    } else if (val == 'copy') {
                      Clipboard.setData(ClipboardData(text: loginPayload));
                      _snack('📋 Credentials payload copied for $name!', const Color(0xFF6C63FF));
                    }
                  },
                  itemBuilder: (_) => [
                    _popupItem('active', Icons.check_circle_rounded, const Color(0xFF00E676), 'Activate System'),
                    _popupItem('suspended', Icons.pause_circle_rounded, Colors.amberAccent, 'Suspend System'),
                    _popupItem('copy', Icons.share_rounded, const Color(0xFF00D2FF), 'Copy Login Payload'),
                    const PopupMenuDivider(height: 1),
                    _popupItem('delete', Icons.delete_forever_rounded, Colors.redAccent, 'Delete System'),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

          // Impersonation & Renew & Copy Quick Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                // Login As School Button
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D2FF).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFF00D2FF),
                      elevation: 0,
                      side: BorderSide(color: const Color(0xFF00D2FF).withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _impersonateSchool(t),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('LOGIN AS SCHOOL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                // 1-Click Renew Button
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.15),
                      foregroundColor: const Color(0xFF00E676),
                      elevation: 0,
                      side: BorderSide(color: const Color(0xFF00E676).withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _renewTenant(id),
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('RENEW (+30d)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                // Copy Payload Button
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.share_rounded, color: Colors.white70, size: 18),
                  tooltip: 'Share Login Payload',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: loginPayload));
                    _snack('📋 Login details copied to clipboard!', const Color(0xFF6C63FF));
                  },
                ),
              ],
            ),
          ),

          // Sub Footer Row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
            child: Row(
              children: [
                _miniBadge(plan.toUpperCase(), const Color(0xFF6C63FF)),
                const SizedBox(width: 8),
                if (expDate != null)
                  Text(
                    isExpired ? 'Expired ($expiryStr)' : 'Expires in $daysLeft days ($expiryStr)',
                    style: TextStyle(color: isExpired ? Colors.redAccent : Colors.white54, fontSize: 11),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final res = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(builder: (_) => SchoolDetailScreen(tenant: t)),
                    );
                    if (res != null) _fetchTenants();
                  },
                  child: const Row(
                    children: [
                      Text('Full Details', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6C63FF), size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, Color col) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: col.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: col.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  PopupMenuItem<String> _popupItem(String val, IconData icon, Color color, String label) => PopupMenuItem(
        value: val,
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ]),
      );

  Widget _buildEmptyView() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('No Systems Found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty ? 'No school matching "$_searchQuery"' : 'Click "Add New School" to create your first system.',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _buildErrorView() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error ?? 'An unexpected error occurred',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
              onPressed: _fetchTenants,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
}
