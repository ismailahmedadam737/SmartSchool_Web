// lib/school_detail_screen.dart
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart';
import 'Service/backup_service.dart';

const String _baseUrl = 'https://smartschool-web.onrender.com';

class SchoolDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tenant;

  const SchoolDetailScreen({Key? key, required this.tenant}) : super(key: key);

  @override
  State<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends State<SchoolDetailScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _tenant;
  bool _updatingStatus = false;
  late TabController _tabController;

  // Stats from main API
  int _studentsCount = 0;
  int _teachersCount = 0;
  int _busCount = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _tenant = Map<String, dynamic>.from(widget.tenant);
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/api/students')).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$_baseUrl/api/teachers')).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('$_baseUrl/api/buses')).timeout(const Duration(seconds: 10)),
      ]);
      if (mounted) {
        setState(() {
          _studentsCount = _parseCount(results[0]);
          _teachersCount = _parseCount(results[1]);
          _busCount      = _parseCount(results[2]);
          _statsLoading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  int _parseCount(http.Response r) {
    try {
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        if (d is List) return d.length;
        if (d is Map && d['data'] is List) return (d['data'] as List).length;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updatingStatus = true);
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/admin/tenants/${_tenant['id']}/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': newStatus}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final updated = jsonDecode(response.body);
        setState(() {
          _tenant = Map<String, dynamic>.from(updated);
          _updatingStatus = false;
        });

        if (!mounted) return;
        if (newStatus == 'suspended') {
          _showSuspensionDialog();
        } else {
          _snack('✅ Status updated to $newStatus', Colors.green.shade600);
        }
      } else {
        setState(() => _updatingStatus = false);
        _snack('❌ Failed (${response.statusCode})', Colors.redAccent);
      }
    } catch (e) {
      setState(() => _updatingStatus = false);
      _snack('❌ Error: $e', Colors.redAccent);
    }
  }

  Future<void> _renewSubscription() async {
    setState(() => _updatingStatus = true);
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/tenants/${_tenant['id']}/renew'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'days': 30}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tenant = Map<String, dynamic>.from(data['tenant'] ?? _tenant);
          _updatingStatus = false;
        });
        if (!mounted) return;
        _snack('⚡ Subscription extended for 30 days!', Colors.green.shade600);
      } else {
        setState(() => _updatingStatus = false);
        _snack('❌ Renew failed (${response.statusCode})', Colors.redAccent);
      }
    } catch (e) {
      setState(() => _updatingStatus = false);
      _snack('❌ Error: $e', Colors.redAccent);
    }
  }

  Future<void> _impersonateSchool() async {
    try {
      _snack('🔄 Logging in as ${_tenant['name']}...', const Color(0xFF6C63FF));
      await http
          .post(
            Uri.parse('$_baseUrl/admin/tenants/${_tenant['id']}/impersonate'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userRole: 'Admin',
            role: 'Admin',
            isImpersonating: true,
            impersonatedTenantName: _tenant['name'] ?? 'School',
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userRole: 'Admin',
            role: 'Admin',
            isImpersonating: true,
            impersonatedTenantName: _tenant['name'] ?? 'School',
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _downloadBackup() async {
    final int? tId = int.tryParse(_tenant['id']?.toString() ?? '');
    final String tName = (_tenant['name'] ?? 'School').toString();
    if (tId == null) return;
    _snack('⚡ Soo dhalaalinaya backup-ka $tName...', const Color(0xFF6C63FF));
    try {
      final data = await BackupService.fetchSchoolBackupData(tId, tName);
      BackupService.downloadBackupFile(data, tName);
      if (!mounted) return;
      _snack('💾 Backup-ka $tName si guul leh ayaa loo soo download-gareeyay!', const Color(0xFF43E97B));
    } catch (e) {
      if (!mounted) return;
      _snack('❌ Backup dhicitaankiisu waayi galay: $e', Colors.redAccent);
    }
  }

  void _pickJsonFile(TextEditingController controller, void Function(void Function()) setDlgState, {void Function(String)? onLoaded}) {
    if (kIsWeb) {
      try {
        final uploadInput = html.FileUploadInputElement();
        uploadInput.accept = '.json,application/json';
        uploadInput.click();

        uploadInput.onChange.listen((e) {
          final files = uploadInput.files;
          if (files != null && files.isNotEmpty) {
            final file = files[0];
            final reader = html.FileReader();
            reader.readAsText(file);
            reader.onLoadEnd.listen((e) {
              final String? result = reader.result as String?;
              if (result != null && result.isNotEmpty) {
                setDlgState(() {
                  controller.text = result;
                });
                if (onLoaded != null) {
                  onLoaded(file.name);
                }
              }
            });
          }
        });
      } catch (e) {
        log("Error picking JSON file: $e");
      }
    }
  }

  void _showRestoreDialog() {
    final int? tId = int.tryParse(_tenant['id']?.toString() ?? '');
    final String tName = (_tenant['name'] ?? 'School').toString();
    if (tId == null) return;
    final jsonCtrl = TextEditingController();
    bool restoring = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF131826),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.settings_backup_restore_rounded, color: Color(0xFF00D2FF), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Restore Backup: $tName',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Soo xul faylka JSON-ka ee ka jira computer-kaaga ama dhaji xogta si dib loogu soo celiyo.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D2FF).withOpacity(0.15),
                      foregroundColor: const Color(0xFF00D2FF),
                      side: const BorderSide(color: Color(0xFF00D2FF), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      _pickJsonFile(jsonCtrl, setDlgState, onLoaded: (fileName) {
                        _snack('📁 Faylka JSON-ka ($fileName) si guul leh ayaa loo soo akhriyay!', const Color(0xFF43E97B));
                      });
                    },
                    icon: const Icon(Icons.folder_open_rounded, size: 20),
                    label: const Text('📁 SOO XUL FAYLKA JSON-KA (SELECT FILE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('AMA / OR PASTE JSON TEXT', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jsonCtrl,
                  maxLines: 7,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'Paste backup JSON content here...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF00D2FF), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: restoring ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D2FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: restoring
                  ? null
                  : () async {
                      final rawText = jsonCtrl.text.trim();
                      if (rawText.isEmpty) {
                        _snack('⚠️ Fadlan soo geli xogta JSON-ka', Colors.amberAccent);
                        return;
                      }
                      setDlgState(() => restoring = true);
                      try {
                        final parsed = jsonDecode(rawText);
                        if (parsed is! Map<String, dynamic>) {
                          throw const FormatException('Invalid JSON payload structure');
                        }
                        final success = await BackupService.restoreSchoolBackup(tId, tName, parsed);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        if (success) {
                          _snack('🎉 Data si guul leh ayaa loogu soo celiyay $tName!', const Color(0xFF43E97B));
                          _loadStats();
                        } else {
                          _snack('❌ Restore-ka waa shaqayn waayay', Colors.redAccent);
                        }
                      } catch (e) {
                        setDlgState(() => restoring = false);
                        _snack('❌ JSON-ka ma habsona: $e', Colors.redAccent);
                      }
                    },
              child: restoring
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('RESTORE DATA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuspensionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause_circle_rounded,
                    color: Colors.orangeAccent, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('School Suspended',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Xiriirka la xidh:',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SmartMind Tech',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nidaamkaaga waa la joojiyay.\nFadlan la xiriir shirkadda SmartMind Tech\nsi aad u sii wato adeegga.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email_outlined,
                            color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 6),
                        const Text('support@smartmindtech.com',
                            style: TextStyle(
                                color: Colors.orangeAccent, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Okay, Got it',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('📋 $label copied!', const Color(0xFF6C63FF));
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'active':
        return const Color(0xFF43E97B);
      case 'suspended':
        return Colors.orangeAccent;
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

  @override
  Widget build(BuildContext context) {
    final name     = _tenant['name'] ?? 'Unknown School';
    final status   = _tenant['subscription_status'] ?? 'unknown';
    final plan     = _tenant['subscription_plan'] ?? 'basic';
    final email    = _tenant['admin_email'] ?? 'N/A';
    final username = _tenant['admin_username'] ?? 'N/A';
    final password = _tenant['admin_password'] ?? 'N/A';
    final expires  = _tenant['subscription_expires_at'];
    final expiryStr = expires != null
        ? (DateTime.tryParse(expires)?.toLocal().toString().split(' ').first ?? expires)
        : 'N/A';
    final createdAt = _tenant['created_at'];
    final createdStr = createdAt != null
        ? (DateTime.tryParse(createdAt)?.toLocal().toString().split(' ').first ?? createdAt)
        : 'N/A';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, _tenant),
        ),
        title: Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_updatingStatus)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: _updateStatus,
              itemBuilder: (_) => [
                _menuItem('active', Icons.check_circle_rounded,
                    const Color(0xFF43E97B), 'Activate'),
                _menuItem('suspended', Icons.pause_circle_rounded,
                    Colors.orangeAccent, 'Suspend'),
                _menuItem('cancelled', Icons.cancel_rounded,
                    Colors.redAccent, 'Cancel'),
              ],
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero Header ──
              _buildHero(name, status, plan, createdStr),

              // ── Stats Row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _statTile('Students', _studentsCount, Icons.people_alt_rounded,
                      const Color(0xFF6C63FF)),
                  const SizedBox(width: 10),
                  _statTile('Teachers', _teachersCount, Icons.school_rounded,
                      const Color(0xFF00D2FF)),
                  const SizedBox(width: 10),
                  _statTile('Buses', _busCount, Icons.directions_bus_rounded,
                      const Color(0xFF43E97B)),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Info Cards ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _sectionTitle('📋 School Information'),
                  const SizedBox(height: 10),
                  _infoCard(Icons.calendar_today_rounded,
                      'Registration Date', createdStr, null),
                  _infoCard(Icons.schedule_rounded,
                      'Expires On', expiryStr, null),
                  _infoCard(Icons.email_outlined,
                      'Admin Email', email, null),
                  const SizedBox(height: 16),

                  _sectionTitle('🔐 Login Credentials'),
                  const SizedBox(height: 10),
                  _infoCard(Icons.person_rounded, 'Username', username,
                      () => _copyToClipboard(username, 'Username')),
                  _infoCard(Icons.lock_rounded, 'Password', password,
                      () => _copyToClipboard(password, 'Password')),

                  const SizedBox(height: 24),

                  // Data Backup & Protection Section
                  _sectionTitle('🛡️ Data Protection & Backup'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                            foregroundColor: const Color(0xFF00D2FF),
                            side: const BorderSide(color: Color(0xFF6C63FF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _downloadBackup,
                          icon: const Icon(Icons.cloud_download_rounded, size: 18),
                          label: const Text('BACKUP DATA (JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D2FF).withOpacity(0.15),
                            foregroundColor: const Color(0xFF00D2FF),
                            side: const BorderSide(color: Color(0xFF00D2FF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _showRestoreDialog,
                          icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                          label: const Text('RESTORE BACKUP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Impersonation & Renew Main Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: _impersonateSchool,
                      icon: const Icon(Icons.login_rounded, color: Colors.white),
                      label: const Text('LOGIN AS SCHOOL ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43E97B).withOpacity(0.2),
                        foregroundColor: const Color(0xFF43E97B),
                        side: const BorderSide(color: Color(0xFF43E97B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _renewSubscription,
                      icon: const Icon(Icons.bolt_rounded, color: Color(0xFF43E97B)),
                      label: const Text('RENEW SUBSCRIPTION (+30 DAYS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Action Buttons
                  _sectionTitle('⚙️ Subscription Status Control'),
                  const SizedBox(height: 10),
                  Row(children: [
                    _actionBtn('Activate', Icons.check_circle_rounded,
                        const Color(0xFF43E97B), 'active', status == 'active'),
                    const SizedBox(width: 10),
                    _actionBtn('Suspend', Icons.pause_circle_rounded,
                        Colors.orangeAccent, 'suspended', status == 'suspended'),
                    const SizedBox(width: 10),
                    _actionBtn('Cancel', Icons.cancel_rounded,
                        Colors.redAccent, 'cancelled', status == 'cancelled'),
                  ]),
                  const SizedBox(height: 32),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(String name, String status, String plan, String since) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.6),
            const Color(0xFF302B63).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: _statusColor(status).withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.3),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 14),
          Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _badge(status.toUpperCase(), _statusColor(status),
                  _statusIcon(status)),
              const SizedBox(width: 8),
              _badge(plan.toUpperCase(), const Color(0xFF6C63FF),
                  Icons.workspace_premium_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _statTile(String label, int val, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(children: [
            _statsLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color))
                : Text(val.toString(),
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(label,
                style:
                    TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
          ]),
        ),
      );

  Widget _sectionTitle(String title) => Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  Widget _infoCard(IconData icon, String label, String value,
      VoidCallback? onCopy) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white38, size: 18),
              onPressed: onCopy,
              tooltip: 'Copy',
            )
        ]),
      );

  Widget _actionBtn(String label, IconData icon, Color color, String statusVal,
      bool isActive) =>
      Expanded(
        child: GestureDetector(
          onTap: isActive || _updatingStatus ? null : () => _updateStatus(statusVal),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.25) : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isActive ? color : color.withOpacity(0.25),
                  width: isActive ? 1.5 : 1),
            ),
            child: Column(children: [
              Icon(icon,
                  color: isActive ? color : color.withOpacity(0.5), size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: isActive ? color : color.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal)),
            ]),
          ),
        ),
      );

  PopupMenuItem<String> _menuItem(
          String val, IconData icon, Color color, String label) =>
      PopupMenuItem(
        value: val,
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white)),
        ]),
      );
}
