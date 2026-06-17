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
              child: Row(
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
                          'data:image/png;base64,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',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
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
                    ),
                  ),
                ],
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