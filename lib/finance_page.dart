import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/api_service.dart';
import 'package:iftiinshe/Service/payment_api_service.dart';
import 'package:iftiinshe/models/expense_model.dart';
import '../models/student_model.dart';
import 'expenses_page.dart';
import 'receipt_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  String? selectedClass;
  String searchQuery = "";

  List<String> classes = [];
  List<StudentModel> students = [];
  double income = 0;
  Map<String, double> studentPaid = {};
  Map<String, double> studentDept = {};
  List<ExpenseItem> expenseList = [];

  @override
  void initState() {
    super.initState();
    loadClasses();
    loadStudents();
  }

  Future<void> loadClasses() async {
    final data = await ApiService.getAllClasses();
    setState(() {
      classes = data;
      if (classes.isNotEmpty) selectedClass = classes.first;
    });
  }

  Future<void> loadStudents() async {
    final data = await ApiService.getAllStudents();
    setState(() {
      students = data;
    });
    
    // Xogta ka soo jiid database-ka si aysan u tirtirmin
    for (var s in students) {
      if (s.id != null) {
        await fetchPaymentData(s);
      }
    }
  }

  Future<void> fetchPaymentData(StudentModel s) async {
    try {
      final payments = await PaymentApiService.getPaymentsByStudent(s.id!);
      double totalPaid = 0;
      double totalDept = 0;
      for (var p in payments) {
        totalPaid += double.tryParse(p['amount'].toString()) ?? 0;
        totalDept += double.tryParse(p['debt'].toString()) ?? 0;
      }
      setState(() {
        studentPaid[s.name] = totalPaid;
        studentDept[s.name] = totalDept;
      });
    } catch (e) {
      debugPrint("Error loading payments: $e");
    }
  }

  // Shaqada Reset All si loo tirtiro lacagaha ardayda oo loogu celiyo Unpaid
  Future<void> _resetAllPayments() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset All Payments"),
        content: const Text("Ma hubtaa inaad rabto inaad tirtirto dhammaan xogta lacag bixinta ardayda?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Jooji")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Haa, Reset All", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Wac API-ga tirtiraya dhammaan xogta lacagaha ee database-ka
        await PaymentApiService.resetAllPayments();

        setState(() {
          studentPaid.clear();
          studentDept.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Dhammaan xogta lacagaha waa laga tirtiray database-ka, ardayduna waxay noqdeen Unpaid!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Cilad ayaa dhacday marka la reset-gareynayay: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<StudentModel> get filteredStudents {
    if (selectedClass == null) return [];
    return students.where((s) {
      bool matchesClass = s.className == selectedClass;
      bool matchesSearch = s.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesClass && matchesSearch;
    }).toList();
  }

  double get totalExpenses =>
      expenseList.where((e) => e.isPaid).fold(0.0, (a, b) => a + b.amount);

  double get netProfit => income - totalExpenses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Finance Dashboard",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                DropdownButton(
                  value: selectedClass,
                  items: classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedClass = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExpensesPage(expenseList: expenseList)),
                      );
                      if (result != null) setState(() => expenseList = result);
                    },
                    icon: const Icon(Icons.list),
                    label: const Text("Expenses"),
                  ),
                ),
                // Badhanka Reset All oo la keydiyay lagana ag dhigay meel ku habboon
                ElevatedButton.icon(
                  onPressed: _resetAllPayments,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset All"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search student...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isDesktop = constraints.maxWidth >= 800;

                  final studentListWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Student List",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            Expanded(flex: 3, child: Text("Student Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 2, child: Text("Paid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 2, child: Text("Dept", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: filteredStudents.isEmpty
                            ? const Center(child: Text("No students found in this class"))
                            : ListView.builder(
                                itemCount: filteredStudents.length,
                                itemBuilder: (context, index) {
                                  return _buildStudentRow(filteredStudents[index]);
                                },
                              ),
                      ),
                    ],
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSVAmwrfy0UmZIlsgOXhljhBBXFmr7OtLzgIJG-D18pBg&s=10',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: studentListWidget,
                        ),
                      ],
                    );
                  } else {
                    return studentListWidget;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentRow(StudentModel s) {
    double paid = studentPaid[s.name] ?? 0;
    double dept = studentDept[s.name] ?? 0;
    String status = paid == 0 ? "Unpaid" : (dept > 0 ? "Debt" : "Paid");
    Color color = paid == 0 ? Colors.red : (dept > 0 ? Colors.orange : Colors.green);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Expanded(flex: 2, child: Text("\$$paid", style: const TextStyle(fontSize: 14))),
          Expanded(flex: 2, child: Text("\$$dept", style: const TextStyle(fontSize: 14, color: Colors.red))),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _pay(s),
                icon: const Icon(Icons.add_circle, color: Colors.blue, size: 22),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              IconButton(
                onPressed: () {
                  int id = (s.id != null) ? s.id! : 0;
                  _printReceipt(s.name, paid, dept, id);
                },
                icon: const Icon(Icons.print, color: Colors.grey, size: 22),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _printReceipt(String name, double paid, double dept, int studentId) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => ReceiptPage(name: name, paid: paid, dept: dept, studentId: studentId),
      ),
    );
  }

  void _pay(StudentModel s) {
    TextEditingController c = TextEditingController();
    TextEditingController deptController = TextEditingController();
    String transport = "No Bus";
    String month = "January";
    List<String> months = ["January","February","March","April","May","June","July","August","September","October","November","December"];

    showDialog(
      context: context,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField(value: month, items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => month = v.toString(), decoration: const InputDecoration(labelText: "Month", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField(value: transport, items: const [DropdownMenuItem(value: "Bus", child: Text("Bus +10")), DropdownMenuItem(value: "No Bus", child: Text("No Bus"))], onChanged: (v) => transport = v.toString(), decoration: const InputDecoration(labelText: "Transport", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: deptController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Dept", border: OutlineInputBorder())),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    double v = double.tryParse(c.text) ?? 0;
                    double d = double.tryParse(deptController.text) ?? 0;
                    if (transport == "Bus") v += 10;

                    try {
                      await PaymentApiService.addPayment(
                        studentId: s.id ?? 0,
                        amount: v,
                        debt: d,
                        month: month,
                        transport: transport,
                      );

                      // Dib u soo rar xogta si UI-ga u cusboonaado
                      await fetchPaymentData(s);
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Saved!")));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xff667eea), Color(0xff764ba2)]), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text("Save Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}