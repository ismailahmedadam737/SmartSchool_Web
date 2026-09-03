import 'dart:async'; // Kani waa muhiim si loo maareeyo auto-scroll-ka
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iftiinshe/AdminMessagesPage.dart';
import 'package:iftiinshe/AtendancePage.dart';
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
import 'package:iftiinshe/reports_page.dart' hide UsersPage;
import 'package:iftiinshe/student_registration.dart';
import 'package:iftiinshe/teacher.dart';

class DashboardScreen extends StatefulWidget {
  final String userRole;
  final String role;
  const DashboardScreen({super.key, this.userRole = '', this.role = ''});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedMenu = "Dashboard";
  bool isDarkMode = false;
  final ScrollController _sidebarController = ScrollController();
  final ScrollController _imageScrollController = ScrollController();
  Timer? _timer;

  String get activeRole {
    String r = (widget.userRole.isNotEmpty ? widget.userRole : widget.role).trim();
    if (r.isEmpty) return 'SuperAdmin';
    return r;
  }

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  Color get bgColor => isDarkMode ? const Color(0xFF121212) : const Color(0xFFF0F2F5);
  Color get cardColor => isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;

  void _performLogout() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthPage(userRole: '')), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          SizedBox(width: 260, child: _buildSidebar()),
          Expanded(child: Padding(padding: const EdgeInsets.all(30.0), child: _buildBodyContent())),
        ],
      ),
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

  Widget _buildDashboardHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildScrollingImagesRow(),
          const SizedBox(height: 20),
          Row(
            children: [
               Expanded(flex: 6, child: _lineChartCard()),
              const SizedBox(width: 30),
              Expanded(flex: 4, child: _buildPieChart()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScrollingImagesRow() {
    final List<String> adImages = [
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSzeE-WPoZYslQCRQKKV4ue8uiPlI28wElSRGsTMfmOPySxzUDXZNDYIqiK&s=10",
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTFoIq3RM4xn7mlu4qXJXAIiKGqzoq9haAZSYBl0KZzumbspkbHdorZMmc&s=10",
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRXZbfZq23Fr-6Fkv0washqLKd9u6-_lGuFF4HZ5kGPkA&s=10"
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJ4ubfnrwFjKz0xaLkrM8kBn13H1DBScz1ug&s",
      "https://static.vecteezy.com/system/resources/previews/008/734/694/large_2x/happy-school-children-in-front-of-building-school-vector.jpg",
      "https://i.ytimg.com/vi/1RJEOsbOyE4/hq720.jpg?sqp=-oaymwE7CK4FEIIDSFryq4qpAy0IARUAAAAAGAElAADIQj0AgKJD8AEB-AH-CYAC0AWKAgwIABABGEsgTyhlMA8=&rs=AOn4CLBRnx_rWtjn5Dk_tzdNnqnQAWIWiw",
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRT8ryhfF9HVfusWZhVGw6qSZmsysP2PBHh3A&s",
    ];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        controller: _imageScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: adImages.length,
        itemBuilder: (context, index) {
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.grey),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(adImages[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(selectedMenu, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
        ]),
        Row(children: [
          IconButton(icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: textColor), onPressed: () => setState(() => isDarkMode = !isDarkMode)),
          const SizedBox(width: 20),
          _profileMenu(),
        ]),
      ],
    );
  }

  Widget _profileMenu() {
    String r = activeRole;
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) { if (value == 'logout') _performLogout(); },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'profile', child: Row(children: [const Icon(Icons.security, size: 20, color: Colors.blueAccent), const SizedBox(width: 10), Text("Role: $r", style: const TextStyle(fontWeight: FontWeight.bold))])),
        const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 10), Text("Log Out", style: TextStyle(color: Colors.red))])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.blueAccent, radius: 18, child: Icon(Icons.person, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
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
// Ku dar ScrollController-ka kor ku xusan widget-kaaga
final ScrollController _sidebarScrollController = ScrollController();

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
        {"icon": Icons.how_to_reg, "title": "Attendance"},
        {"icon": Icons.chat_rounded, "title": "Communications"},
        {"icon": Icons.book, "title": "Exam & Results"},
      ];
    } else if (r == 'user' || r.contains('student') || r.contains('parent') || r.contains('ardey') || r.contains('waalid')) {
      return [
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
        _navItem(Icons.logout, "Log Out"),
        const SizedBox(height: 20)
      ]),
    );
  }

  Widget _buildSidebarLogo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)), borderRadius: BorderRadius.circular(10)),
      child: const Text("eSAHAL SCHOOL SYSTEM", style: TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

Widget _navItem(IconData icon, String title) {
  bool isActive = selectedMenu == title;
  return ListTile(
    onTap: () {
      if (title == "Log Out") _performLogout();
      else setState(() => selectedMenu = title);
    },
    leading: Icon(icon, color: isActive ? Colors.cyanAccent : Colors.white60),
    title: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white60)),
    tileColor: isActive ? Colors.white.withOpacity(0.05) : Colors.transparent
  );
}
}