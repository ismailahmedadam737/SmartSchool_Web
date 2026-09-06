import 'dart:async'; // Kani waa muhiim si loo maareeyo auto-scroll-ka
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iftiinshe/AdminMessagesPage.dart';
import 'package:iftiinshe/AtendancePage.dart';
import 'package:iftiinshe/Service/api_service.dart';
import 'package:iftiinshe/CommunicationsPage.dart';
import 'package:iftiinshe/ExamScheduleGeneratorPage.dart';
import 'package:iftiinshe/Income%20&%20Outcome.dart';
import 'package:iftiinshe/SalaryPage.dart';
import 'package:iftiinshe/UsersPage%20.dart';
import 'package:iftiinshe/buses_page.dart';
import 'package:iftiinshe/finance_page.dart';
import 'package:iftiinshe/examination_page.dart';
import 'package:iftiinshe/login_page.dart';
import 'package:iftiinshe/notes_page.dart';
import 'package:iftiinshe/reports_page.dart';
import 'package:iftiinshe/student_registration.dart';
import 'package:iftiinshe/teacher.dart';
import 'package:iftiinshe/super_admin_dashboard.dart';
import 'package:iftiinshe/ClassTimetablePage.dart';

class DashboardScreen extends StatefulWidget {
  final String userRole;
  final String role;
  final bool isImpersonating;
  final String impersonatedTenantName;
  final String tenantStatus;
  final String? subscriptionExpiresAt;

  const DashboardScreen({
    super.key, 
    this.userRole = '', 
    this.role = '',
    this.isImpersonating = false,
    this.impersonatedTenantName = '',
    this.tenantStatus = 'active',
    this.subscriptionExpiresAt,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedMenu = "Dashboard";
  bool isDarkMode = false;
  final ScrollController _imageScrollController = ScrollController();
  final ScrollController _sidebarScrollController = ScrollController();
  Timer? _timer;

  List<String> _bannerImages = [
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSzeE-WPoZYslQCRQKKV4ue8uiPlI28wElSRGsTMfmOPySxzUDXZNDYIqiK&s=10",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTFoIq3RM4xn7mlu4qXJXAIiKGqzoq9haAZSYBl0KZzumbspkbHdorZMmc&s=10",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRXZbfZq23Fr-6Fkv0washqLKd9u6-_lGuFF4HZ5kGPkA&s=10",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJ4ubfnrwFjKz0xaLkrM8kBn13H1DBScz1ug&s",
    "https://static.vecteezy.com/system/resources/previews/008/734/694/large_2x/happy-school-children-in-front-of-building-school-vector.jpg",
    "https://i.ytimg.com/vi/1RJEOsbOyE4/hq720.jpg?sqp=-oaymwE7CK4FEIIDSFryq4qpAy0IARUAAAAAGAElAADIQj0AgKJD8AEB-AH-CYAC0AWKAgwIABABGEsgTyhlMA8=&rs=AOn4CLBRnx_rWtjn5Dk_tzdNnqnQAWIWiw",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRT8ryhfF9HVfusWZhVGw6qSZmsysP2PBHh3A&s",
  ];

  void _loadSavedBannerImages() {
    try {
      final String? stored = ApiService.readStorage('dashboard_banner_images');
      if (stored != null && stored.isNotEmpty) {
        final List<dynamic> list = jsonDecode(stored);
        final List<String> loaded = list.map((e) => e.toString()).toList();
        if (loaded.isNotEmpty) {
          _bannerImages = loaded;
        }
      }
    } catch (e) {
      debugPrint("Error loading saved dashboard banner images: $e");
    }
  }

  void _saveBannerImages() {
    try {
      ApiService.savePersistentSetting('dashboard_banner_images', _bannerImages);
    } catch (e) {
      debugPrint("Error saving dashboard banner images: $e");
    }
  }

  void _resetDefaultBannerImages() {
    setState(() {
      _bannerImages = [
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSzeE-WPoZYslQCRQKKV4ue8uiPlI28wElSRGsTMfmOPySxzUDXZNDYIqiK&s=10",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTFoIq3RM4xn7mlu4qXJXAIiKGqzoq9haAZSYBl0KZzumbspkbHdorZMmc&s=10",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRXZbfZq23Fr-6Fkv0washqLKd9u6-_lGuFF4HZ5kGPkA&s=10",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJ4ubfnrwFjKz0xaLkrM8kBn13H1DBScz1ug&s",
        "https://static.vecteezy.com/system/resources/previews/008/734/694/large_2x/happy-school-children-in-front-of-building-school-vector.jpg",
        "https://i.ytimg.com/vi/1RJEOsbOyE4/hq720.jpg?sqp=-oaymwE7CK4FEIIDSFryq4qpAy0IARUAAAAAGAElAADIQj0AgKJD8AEB-AH-CYAC0AWKAgwIABABGEsgTyhlMA8=&rs=AOn4CLBRnx_rWtjn5Dk_tzdNnqnQAWIWiw",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRT8ryhfF9HVfusWZhVGw6qSZmsysP2PBHh3A&s",
      ];
      _saveBannerImages();
    });
  }

  String get activeRole {
    String r = (widget.userRole.isNotEmpty ? widget.userRole : widget.role).trim();
    if (r.isEmpty) return 'SuperAdmin';
    return r;
  }

  String get effectiveStatus {
    String s = widget.tenantStatus.trim().toLowerCase();
    if (s.isEmpty || s == 'unknown') {
      s = (ApiService.currentTenantStatus ?? 'active').trim().toLowerCase();
    }
    return s;
  }

  int? get remainingDays {
    final exp = widget.subscriptionExpiresAt ?? ApiService.currentTenantExpiresAt;
    if (exp == null || exp.isEmpty) return null;
    final d = DateTime.tryParse(exp);
    if (d == null) return null;
    return d.difference(DateTime.now()).inDays;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedBannerImages();
    String r = activeRole.toLowerCase();
    if (r == 'user' || r.contains('student') || r.contains('parent') || r.contains('ardey') || r.contains('waalid')) {
      selectedMenu = "Attendance";
    } else {
      selectedMenu = "Dashboard";
    }

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_imageScrollController.hasClients) {
        double maxScroll = _imageScrollController.position.maxScrollExtent;
        double currentScroll = _imageScrollController.position.pixels;
        double delta = 320.0;

        if (currentScroll >= maxScroll) {
          _imageScrollController.jumpTo(0);
        } else {
          _imageScrollController.animateTo(currentScroll + delta,
              duration: const Duration(seconds: 1), curve: Curves.easeInOut);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _imageScrollController.dispose();
    _sidebarScrollController.dispose();
    super.dispose();
  }

  Color get bgColor => isDarkMode ? const Color(0xFF121212) : const Color(0xFFF0F2F5);
  Color get cardColor => isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;

  void _performLogout() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthPage(userRole: '',)), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (effectiveStatus == 'suspended' || effectiveStatus == 'cancelled') {
      return _buildSuspendedScreen();
    }
    return PopScope(
      canPop: selectedMenu == "Dashboard",
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedMenu != "Dashboard") {
          setState(() => selectedMenu = "Dashboard");
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 900;
          final double paddingVal = constraints.maxWidth < 600 ? 12.0 : 25.0;

          Widget content;
          if (selectedMenu == "Dashboard") {
            content = _buildDashboardHome();
          } else {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopNavHeader(isDesktop),
                const SizedBox(height: 10),
                Expanded(child: _buildBodyContent()),
              ],
            );
          }

          if (isDesktop) {
            return Scaffold(
              backgroundColor: bgColor,
              body: Row(
                children: [
                  SizedBox(width: 260, child: _buildSidebar()),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(paddingVal),
                      child: content,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Scaffold(
              backgroundColor: bgColor,
              drawer: Drawer(
                width: 260,
                child: _buildSidebar(),
              ),
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(paddingVal),
                  child: content,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSuspendedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B1522), Color(0xFF0F1524)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block_rounded, color: Colors.redAccent, size: 54),
              ),
              const SizedBox(height: 20),
              const Text(
                "SYSTEM HAKAD LAGU SHUMIYAY",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.impersonatedTenantName.isNotEmpty
                    ? widget.impersonatedTenantName.toUpperCase()
                    : (ApiService.currentTenantName ?? "ISKUULKA"),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  "Maamule/Isticmaale, Nidaamka Iskuulkiina wuu hakad ku jiraa ama waa la joojiyay (Suspended/Cancelled).\n\n"
                  "Fadlan la xidhiidh Shirkadda SmartMind Technology si nidaamka dib loogu soo celiyo ama subscribtion-ka loogu cusboonaysiiyo.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthPage(userRole: '')),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text("Dib u Noqo Login"),
                    ),
                  ),
                  if (widget.isImpersonating) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          ApiService.currentTenantId = null;
                          ApiService.currentTenantName = null;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
                          );
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text("SuperAdmin Hub"),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpirationWarningBanner() {
    final days = remainingDays;
    if (days == null || days > 7) return const SizedBox.shrink();

    final bool isExpired = days <= 0;
    final Color bannerColor = isExpired ? Colors.redAccent : Colors.amber;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpired ? Icons.error_outline_rounded : Icons.hourglass_top_rounded,
              color: bannerColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? "⚠️ DIGNIIN: Subscribtion-ka Iskuulkiina Wuu Ka Dhacay!"
                      : "⚠️ DIGNIIN: Subscribtion-ka Waxaa Ka Dhiman $days Maalmood!",
                  style: TextStyle(
                    color: bannerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isExpired
                      ? "Fadlan la xidhiidh SmartMind Technology si aad u cusboonaysiiso."
                      : "Subscribtion-ku wuu dhowyahay inuu ka dhaco. Fadlan la xidhiidh SmartMind Technology.",
                  style: TextStyle(
                    color: bannerColor.withOpacity(0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavHeader(bool isDesktop) {
    bool isNotDashboard = selectedMenu != "Dashboard";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (!isDesktop)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: Icon(Icons.menu, color: textColor, size: 24),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    tooltip: "Open Drawer",
                  ),
                ),
              if (isNotDashboard)
                IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor, size: 22),
                  onPressed: () => setState(() => selectedMenu = "Dashboard"),
                  tooltip: "Dib u noqo Dashboard",
                ),
              if (!isDesktop || isNotDashboard) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  selectedMenu,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: !isDesktop ? 18 : 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: textColor, size: 22),
              onPressed: () => setState(() => isDarkMode = !isDarkMode),
            ),
            SizedBox(width: !isDesktop ? 2 : 15),
            _profileMenu(),
          ],
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    String r = activeRole;
    switch (selectedMenu.trim()) {
      case "Dashboard": return _buildDashboardHome();
      case "Students": return const StudentRegistrationPage();
      case "Users": return UsersPage(currentRole: r);
      case "Teachers": return TeachersPage(userRole: r);
      case "Teacher Salary": return const TeacherSalaryPage();
      case "Attendance": return AttendancePage(userRole: r);
      case "Fees & Accounting": return FinancePage();
      case "Income & Outcome": return IncomePage();
      case "Buses": return const BusesPage();
      case "Exam & Results": return ExaminationPage(userRole: r);
      case "Exam Schedule": return const ExamScheduleGeneratorPage();
      case "Class Timetable": return ClassTimetablePage(userRole: r);
      case "Communications": return const SchoolCommunicationsPage();
      case "Admin Messages": return const AdminMessagesPage();
      case "General Reports": return const ReportsPage();
      case "Notes": return const NotesPage();
      default: 
        if (r.toLowerCase() == 'user' || r.toLowerCase().contains('student') || r.toLowerCase().contains('parent')) {
          return const AttendancePage();
        }
        return _buildDashboardHome();
    }
  }

  Widget _buildImpersonationBanner() {
    // Hidden completely so local school admin cannot see or cancel SuperAdmin access
    return const SizedBox.shrink();
  }

  Widget _buildDashboardHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImpersonationBanner(),
          _buildExpirationWarningBanner(),
          _buildHeader(),
          const SizedBox(height: 20),
          _buildScrollingImagesRow(),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  children: [
                    Expanded(flex: 6, child: _lineChartCard()),
                    const SizedBox(width: 30),
                    Expanded(flex: 4, child: _buildPieChart()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _lineChartCard(),
                    const SizedBox(height: 20),
                    _buildPieChart(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),
          _buildSmartMindFooter(),
        ],
      ),
    );
  }

  Widget _buildSmartMindFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.85),
              ),
              children: const [
                TextSpan(text: 'Powered & Designed by '),
                TextSpan(
                  text: 'SmartMind Technology',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    letterSpacing: 0.5,
                  ),
                ),
                TextSpan(text: ' © 2026'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickImageFromComputer(BuildContext dialogContext) {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((e) {
            final String? result = reader.result as String?;
            if (result != null && result.isNotEmpty) {
              setState(() {
                _bannerImages.insert(0, result);
                _saveBannerImages();
              });
              if (mounted && Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Sawirka xaflada iskuulka si guul leh ayaa loo kaysiyay (Permanently Saved)! ✨"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _showUploadImageDialog() {
    final TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.add_photo_alternate_rounded, color: Colors.cyanAccent),
              const SizedBox(width: 10),
              Text(
                "Soo Gali Sawir / Upload Photo",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Waad ka soo xuli kartaa sawirada xaflada ama dhacdooyinka iskuulka Computer-kaaga (Documents, Pictures, Downloads):",
                  style: TextStyle(color: textColor.withOpacity(0.85), fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImageFromComputer(ctx),
                    icon: const Icon(Icons.folder_open_rounded, size: 22),
                    label: const Text(
                      "📁 Ka Xul Computer-ka (Documents/Pictures)",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D2FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "AMA / OR",
                        style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: urlController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: "URL Link Sawirka",
                    hintText: "https://example.com/image.jpg",
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.link, color: Colors.cyanAccent),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _resetDefaultBannerImages();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sawirada asalka ah ayaa dib loo soo celiyay!"),
                        backgroundColor: Colors.blueAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.restore_rounded, size: 16, color: Colors.orangeAccent),
                  label: const Text(
                    "Soo Celin Sawirada Asalka Ah (Reset Defaults)",
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Baaq / Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: const Text("Gali Link-ka"),
              onPressed: () {
                final text = urlController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _bannerImages.insert(0, text);
                    _saveBannerImages();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Sawirka cusub si guul leh ayaa loo soo geliyey oo loo kaysiyay! ✨"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildScrollingImagesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 10),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF00D2FF), Color(0xFF928DFF), Color(0xFF00E676)],
                              ).createShader(bounds),
                              child: const Text(
                                "Welcome to Dashboard 👋",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Smart School Management & Gallery Overview",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showUploadImageDialog,
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: const Text(
                "Upload File / Soo Gali Sawir",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            controller: _imageScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _bannerImages.length,
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: cardColor,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _bannerImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                          tooltip: "Tirtir Sawirka",
                          onPressed: () {
                            setState(() {
                              _bannerImages.removeAt(index);
                              _saveBannerImages();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showDrawerBtn = MediaQuery.of(context).size.width < 900;
        final bool isNotDashboard = selectedMenu != "Dashboard";
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (showDrawerBtn)
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: Icon(Icons.menu, color: textColor),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                        tooltip: "Open Menu",
                      ),
                    ),
                  if (isNotDashboard)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => setState(() => selectedMenu = "Dashboard"),
                      tooltip: "Dib u noqo Dashboard",
                    ),
                  if (showDrawerBtn || isNotDashboard) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      selectedMenu,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: showDrawerBtn ? 20 : 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: textColor),
                  onPressed: () => setState(() => isDarkMode = !isDarkMode),
                ),
                SizedBox(width: showDrawerBtn ? 2 : 20),
                _profileMenu(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _profileMenu() {
    String r = activeRole;
    final bool isSmall = MediaQuery.of(context).size.width < 600;
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) {
        if (value == 'logout') {
          _performLogout();
        } else if (value == 'exit_impersonation') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
            (route) => false,
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'profile', child: Row(children: [const Icon(Icons.security, size: 20, color: Colors.blueAccent), const SizedBox(width: 10), Text("Role: $r", style: const TextStyle(fontWeight: FontWeight.bold))])),
        if (widget.isImpersonating)
          const PopupMenuItem(
            value: 'exit_impersonation',
            child: Row(
              children: [
                Icon(Icons.dashboard_customize_rounded, size: 20, color: Color(0xFF6C63FF)),
                SizedBox(width: 10),
                Text("Return to SuperAdmin Dashboard", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 10), Text("Log Out", style: TextStyle(color: Colors.red))])),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: 6),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(backgroundColor: Colors.blueAccent, radius: isSmall ? 15 : 18, child: Icon(Icons.person, color: Colors.white, size: isSmall ? 16 : 20)),
            if (!isSmall) ...[
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }
 Widget _lineChartCard() {
    return Container(
      height: 255,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Student Growth", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 1: return const Text('Jan');
                          case 3: return const Text('Mar');
                          case 5: return const Text('May');
                          case 7: return const Text('Jul');
                          case 9: return const Text('Sep');
                          case 11: return const Text('Nov');
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 3000),
                      FlSpot(3, 4500),
                      FlSpot(5, 4000),
                      FlSpot(7, 7000),
                      FlSpot(9, 6500),
                      FlSpot(11, 9500),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(colors: [const Color(0xFFFF512F).withOpacity(0.2), const Color(0xFFDD2476).withOpacity(0.0)]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildPieChart() {
  return Container(
    height: 255,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
    child: Column(children: [
      Text("Class Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      Expanded(
        child: PieChart(PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(color: Colors.lightBlue, value: 40, title: '', radius: 30),
            PieChartSectionData(color: Colors.green, value: 30, title: '', radius: 30),
            PieChartSectionData(color: Colors.redAccent, value: 30, title: '', radius: 30),
          ],
        )),
      ),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Text("● Students", style: TextStyle(color: Colors.lightBlue)),
        Text("● Classes", style: TextStyle(color: Colors.green)),
        Text("● Teachers", style: TextStyle(color: Colors.redAccent)),
      ])
    ]),
  );
}

  List<Map<String, dynamic>> _getNavItemsForRole() {
    String r = activeRole.toLowerCase();

    if (r.contains('cashier') || r.contains('qasnaji')) {
      return [
        {"icon": Icons.grid_view_rounded, "title": "Dashboard"},
        {"icon": Icons.people_alt_rounded, "title": "Students"},
        {"icon": Icons.payments_rounded, "title": "Teacher Salary"},
        {"icon": Icons.how_to_reg, "title": "Attendance"},
        {"icon": Icons.account_balance_wallet_rounded, "title": "Fees & Accounting"},
        {"icon": Icons.account_balance_wallet_rounded, "title": "Income & Outcome"},
      ];
    } else if (r.contains('teacher') || r.contains('macalin')) {
      return [
        {"icon": Icons.grid_view_rounded, "title": "Dashboard"},
        {"icon": Icons.school_rounded, "title": "Teachers"},
        {"icon": Icons.calendar_month_rounded, "title": "Class Timetable"},
        {"icon": Icons.how_to_reg, "title": "Attendance"},
        {"icon": Icons.chat_rounded, "title": "Communications"},
        {"icon": Icons.book, "title": "Exam & Results"},
      ];
    } else if (r == 'user' || r.contains('student') || r.contains('parent') || r.contains('ardey') || r.contains('waalid')) {
      return [
        {"icon": Icons.calendar_month_rounded, "title": "Class Timetable"},
        {"icon": Icons.how_to_reg, "title": "Attendance"},
        {"icon": Icons.chat_rounded, "title": "Communications"},
        {"icon": Icons.book, "title": "Exam & Results"},
      ];
    } else if (r == 'admin') {
      return [
        {"icon": Icons.grid_view_rounded, "title": "Dashboard"},
        {"icon": Icons.people_alt_rounded, "title": "Students"},
        {"icon": Icons.school_rounded, "title": "Teachers"},
        {"icon": Icons.payments_rounded, "title": "Teacher Salary"},
        {"icon": Icons.how_to_reg, "title": "Attendance"},
        {"icon": Icons.calendar_month_rounded, "title": "Class Timetable"},
        {"icon": Icons.account_balance_wallet_rounded, "title": "Fees & Accounting"},
        {"icon": Icons.bus_alert, "title": "Buses"},
        {"icon": Icons.book, "title": "Exam & Results"},
        {"icon": Icons.edit_calendar_rounded, "title": "Exam Schedule"},
        {"icon": Icons.account_balance_wallet_rounded, "title": "Income & Outcome"},
        {"icon": Icons.bar_chart_rounded, "title": "General Reports"},
        {"icon": Icons.chat_rounded, "title": "Communications"},
        {"icon": Icons.mark_as_unread_rounded, "title": "Admin Messages"},
        {"icon": Icons.note_alt_rounded, "title": "Notes"},
        {"icon": Icons.person, "title": "Users"},
      ];
    } else {
      // SuperAdmin or default
      return [
        {"icon": Icons.grid_view_rounded, "title": "Dashboard"},
        {"icon": Icons.people_alt_rounded, "title": "Students"},
        {"icon": Icons.school_rounded, "title": "Teachers"},
        {"icon": Icons.payments_rounded, "title": "Teacher Salary"},
        {"icon": Icons.how_to_reg, "title": "Attendance"},
        {"icon": Icons.calendar_month_rounded, "title": "Class Timetable"},
        {"icon": Icons.account_balance_wallet_rounded, "title": "Fees & Accounting"},
        {"icon": Icons.bus_alert, "title": "Buses"},
        {"icon": Icons.book, "title": "Exam & Results"},
        {"icon": Icons.edit_calendar_rounded, "title": "Exam Schedule"},
        {"icon": Icons.account_balance_wallet_rounded, "title": "Income & Outcome"},
        {"icon": Icons.bar_chart_rounded, "title": "General Reports"},
        {"icon": Icons.chat_rounded, "title": "Communications"},
        {"icon": Icons.mark_as_unread_rounded, "title": "Admin Messages"},
        {"icon": Icons.note_alt_rounded, "title": "Notes"},
        {"icon": Icons.person, "title": "Users"},
      ];
    }
  }

  Widget _buildSidebar() {
    final navItems = _getNavItemsForRole();
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1E1E2C)),
      child: Column(children: [
        const SizedBox(height: 50),
        _buildSidebarLogo(),
        const SizedBox(height: 40),
        Expanded(
          child: RawScrollbar(
            controller: _sidebarScrollController,
            thumbColor: Colors.amber,
            thickness: 6.0,
            thumbVisibility: true,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              controller: _sidebarScrollController,
              child: Column(
                children: navItems.map((item) => _navItem(item["icon"] as IconData, item["title"] as String)).toList(),
              ),
            ),
          ),
        ),
        const Divider(color: Colors.white10),
        if (widget.isImpersonating) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: ListTile(
              onTap: () {
                ApiService.currentTenantId = null;
                ApiService.currentTenantName = null;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
                );
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.cyanAccent.withOpacity(0.1),
              leading: const Icon(Icons.arrow_back_rounded, color: Colors.cyanAccent, size: 20),
              title: const Text('Back to SuperAdmin Hub', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
        _navItem(Icons.logout, "Log Out"),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.25)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hub_rounded, color: Color(0xFF00D2FF), size: 12),
              SizedBox(width: 6),
              Text(
                "POWERED BY SMARTMIND TECHNOLOGY",
                style: TextStyle(
                  color: Color(0xFF00D2FF),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16)
      ]),
    );
  }

  Widget _buildSidebarLogo() {
    String schoolName = widget.impersonatedTenantName.trim();
    if ((schoolName.isEmpty || schoolName.toLowerCase() == 'ismail' || schoolName.toLowerCase() == 'admin') && 
        ApiService.currentTenantName != null && ApiService.currentTenantName!.trim().isNotEmpty) {
      schoolName = ApiService.currentTenantName!.trim();
    }
    if (schoolName.isEmpty || schoolName.toLowerCase() == 'ismail' || schoolName.toLowerCase() == 'admin') {
      schoolName = "AL-NUUR INTERNATIONAL ACADEMY";
    }
    final String logoText = schoolName.toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161E36), Color(0xFF0F1526)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                "VERIFIED SCHOOL",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            logoText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF00D2FF),
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              height: 1.3,
              shadows: [
                Shadow(
                  color: Color(0xFF00D2FF),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _navItem(IconData icon, String title) {
  bool isActive = selectedMenu == title;
  return ListTile(
    onTap: () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (title == "Log Out") {
        _performLogout();
      } else {
        setState(() => selectedMenu = title);
      }
    },
    leading: Icon(icon, color: isActive ? Colors.cyanAccent : Colors.white60),
    title: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white60)),
    tileColor: isActive ? Colors.white.withValues(alpha: 0.05) : Colors.transparent
  );
}
}