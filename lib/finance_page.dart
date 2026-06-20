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
                const Text("Finance Dashboard", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                DropdownButton(
                  value: selectedClass,
                  items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => selectedClass = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(hintText: "Search student...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredStudents.isEmpty
                  ? const Center(child: Text("No students found"))
                  : ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) => _buildStudentRow(filteredStudents[index]),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: Text(s.name)),
          Expanded(child: Text("\$$paid")),
          Expanded(child: Text("\$$dept", style: const TextStyle(color: Colors.red))),
          IconButton(onPressed: () => _pay(s), icon: const Icon(Icons.add_circle, color: Colors.blue)),
        ],
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
      builder: (_) => AlertDialog(
        title: Text(s.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount")),
            DropdownButtonFormField(value: month, items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => month = v.toString(), decoration: const InputDecoration(labelText: "Month")),
            DropdownButtonFormField(value: transport, items: const [DropdownMenuItem(value: "Bus", child: Text("Bus +10")), DropdownMenuItem(value: "No Bus", child: Text("No Bus"))], onChanged: (v) => transport = v.toString(), decoration: const InputDecoration(labelText: "Transport")),
            TextField(controller: deptController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Dept")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              double v = double.tryParse(c.text) ?? 0;
              double d = double.tryParse(deptController.text) ?? 0;
              if (transport == "Bus") v += 10;

              try {
                // Halkan ayaa la saxay: Hubi in PaymentApiService uu adeegsanayo https:// sax ah
                await PaymentApiService.addPayment(
                  studentId: s.id ?? 0,
                  amount: v,
                  debt: d,
                  month: month,
                  transport: transport,
                );
                await fetchPaymentData(s);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Saved!")));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Save Payment"),
          ),
        ],
      ),
    );
  }
}