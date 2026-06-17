import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iftiinshe/Income%20&%20Outcome.dart';
import 'package:iftiinshe/student_registration.dart';
import 'package:iftiinshe/teacher.dart';
import 'package:iftiinshe/Service/api_service.dart';
import 'package:iftiinshe/Service/payment_api_service.dart'; // Hubi inuu sax yahay
import 'finance_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool isLoading = true;

  int totalStudents = 0;
  int totalTeachers = 0;
  int totalClasses = 0;
  double totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final stats = await ApiService.getDashboardStats();
      final income = await PaymentApiService.getTotalIncome();
      
      setState(() {
        totalStudents = stats['totalStudents'] ?? 0;
        totalTeachers = stats['totalTeachers'] ?? 0;
        totalClasses = stats['totalClasses'] ?? 0;
        totalRevenue = income;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Waa laga dhiqi waayay in xogta Dashboard-ka la soo aqriyo"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF512F)))
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: const Color(0xFFFF512F),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "GENERAL REPORT  ",
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFFFF512F)),
                          onPressed: _fetchDashboardData,
                        )
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            "Ardayda Diwaangashan",
                            totalStudents.toString(),
                            Icons.school,
                            Colors.blue,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationPage())),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _summaryCard(
                            "Tirada Macalimiinta",
                            totalTeachers.toString(),
                            Icons.person,
                            Colors.orange,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeachersPage())),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _summaryCard(
                            "Tirada Fasalada",
                            totalClasses.toString(),
                            Icons.room,
                            Colors.green,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationPage())),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _summaryCard(
                            "Dakhliga Dugsiga",
                            "\$${totalRevenue.toStringAsFixed(2)}",
                            Icons.monetization_on_outlined,
                            const Color.fromARGB(255, 2, 253, 52),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomePage())),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 900) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: _lineChartCard()),
                              const SizedBox(width: 20),
                              Expanded(flex: 4, child: _pieChartCard()),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _lineChartCard(),
                              const SizedBox(height: 20),
                              _pieChartCard(),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        hoverColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lineChartCard() {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Koraanka Dakhliga (Bishii)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
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

  Widget _pieChartCard() {
    double totalEntries = totalStudents.toDouble() + totalTeachers.toDouble() + totalClasses.toDouble();

    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Saamiga Dugsiga", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const SizedBox(height: 20),
          Expanded(
            child: totalEntries == 0
                ? const Center(child: Text("Xogta horta waa eber"))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 45,
                      sections: [
                        PieChartSectionData(
                          color: Colors.blue,
                          value: totalStudents == 0 ? 0.1 : totalStudents.toDouble(),
                          title: '$totalStudents',
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: totalTeachers == 0 ? 0.1 : totalTeachers.toDouble(),
                          title: '$totalTeachers',
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                        PieChartSectionData(
                          color: Colors.green,
                          value: totalClasses == 0 ? 0.1 : totalClasses.toDouble(),
                          title: '$totalClasses',
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendIndicator(Colors.blue, "Arday"),
              _legendIndicator(Colors.orange, "Macalin"),
              _legendIndicator(Colors.green, "Fasalo"),
            ],
          )
        ],
      ),
    );
  }

  Widget _legendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      ],
    );
  }
}