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
import 'package:iftiinshe/reports_page.dart' hide UsersPage;
import 'package:iftiinshe/student_registration.dart';
import 'package:iftiinshe/teacher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required String userRole, required String role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedMenu = "Dashboard ";
  bool isDarkMode = false;
  final ScrollController _sidebarController = ScrollController();
  final ScrollController _imageScrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-scroll logic
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_imageScrollController.hasClients) {
        double maxScroll = _imageScrollController.position.maxScrollExtent;
        double currentScroll = _imageScrollController.position.pixels;
        double delta = 320.0; // Ballaca sawirka + margin

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
    switch (selectedMenu) {
      case "Dashboard": return _buildDashboardHome();
      case "Students": return const StudentRegistrationPage();
      case "Users": return const UsersPage(currentRole: '',);
      case "Teachers": return const TeachersPage();
      case "Teacher Salary": return const TeacherSalaryPage();
      case "Attendance": return const AttendancePage();
      case "Fees & Accounting": return FinancePage();
      case "Income & Outcome": return IncomePage();
      case "Buses": return const BusesPage();
      case "Exam & Results": return const ExaminationPage();
      case "Exam Schedule": return const ExamScheduleGeneratorPage();
      case "Communications": return const SchoolCommunicationsPage();
      case "Admin Messages": return const AdminMessagesPage();
      case "General Reports": return const ReportsPage();
      default: return _buildDashboardHome();
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
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) { if (value == 'logout') _performLogout(); },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 10), Text("Profile")])),
        const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 10), Text("Log Out", style: TextStyle(color: Colors.red))])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.blueAccent, radius: 18, child: Icon(Icons.person, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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

Widget _buildSidebar() {
  return Container(
    decoration: const BoxDecoration(color: Color(0xFF1E1E2C)),
    child: Column(children: [
      const SizedBox(height: 50),
      _buildSidebarLogo(),
      const SizedBox(height: 40),
      Expanded(
        child: RawScrollbar(
          controller: _sidebarScrollController,
          thumbColor: Colors.amber, // Midabka cad ee aad rabtay
          thickness: 6.0,
          thumbVisibility: true,
          radius: const Radius.circular(10),
          child: SingleChildScrollView(
            controller: _sidebarScrollController, // Ku xir controller-ka
            child: Column(children: [
              _navItem(Icons.grid_view_rounded, "Dashboard"),
              _navItem(Icons.people_alt_rounded, "Students"),
              _navItem(Icons.school_rounded, "Teachers"),
              _navItem(Icons.payments_rounded, "Teacher Salary"),
              _navItem(Icons.how_to_reg, "Attendance"),
              _navItem(Icons.account_balance_wallet_rounded, "Fees & Accounting"),
              _navItem(Icons.bus_alert, "Buses"),
              _navItem(Icons.book, "Exam & Results"),
              _navItem(Icons.edit_calendar_rounded, "Exam Schedule"),
              _navItem(Icons.account_balance_wallet_rounded, "Income & Outcome"),
              _navItem(Icons.bar_chart_rounded, "General Reports"),
              _navItem(Icons.chat_rounded, "Communications"),
              _navItem(Icons.mark_as_unread_rounded, "Admin Messages"),
              _navItem(Icons.person, "Users")
            ]),
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
    child: const Text(" eSAHAL SCHOOL SYSTEM", style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold))
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