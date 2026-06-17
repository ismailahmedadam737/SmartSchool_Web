import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/teacher_ai_service.dart';
import 'package:intl/intl.dart';

class TeacherSalaryPage extends StatefulWidget {
  const TeacherSalaryPage({super.key});

  @override
  State<TeacherSalaryPage> createState() => _TeacherSalaryPageState();
}

class _TeacherSalaryPageState extends State<TeacherSalaryPage> {
  final List<String> _salaryOptions = ["200", "300", "400", "500", "600", "Manual"];
  final List<String> _paymentMethods = ["ZAAD", "E-Dahab", "Cash", "Premier Bank", "Dahabshiil", "IBS"];

  List<dynamic> _employees = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _currentFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // U xirida API-ga (Fetching)
  Future<void> _fetchData() async {
    try {
      final data = await TeacherService.getAllTeachers();
      setState(() {
        _employees = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Cillad xogta: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<dynamic> get _filteredEmployees {
    return _employees.where((emp) {
      final name = emp['name'].toString().toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      final matchesFilter = _currentFilter == "All" || emp['status'] == _currentFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      "https://images.unsplash.com/photo-1580519542036-c47de6196ba5?q=80&w=1000",
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(35),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.account_balance_wallet, color: Colors.amber, size: 40),
                          SizedBox(height: 15),
                          Text("HRM & Finance", style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Text("Maamul mushaharka iyo xogta shaqaalaha si fudud oo ammaan ah.", style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, right: 20, bottom: 20),
              child: Column(
                children: [
                  _buildTopStats(),
                  const SizedBox(height: 20),
                  _buildSearchAndFilter(),
                  const SizedBox(height: 15),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildEmployeeList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    int totalEmployees = _employees.length;
    int paidCount = _employees.where((emp) => emp['status'] == "Paid").length;
    int remainingCount = totalEmployees - paidCount;

    return Row(
      children: [
        _statCard("TOTAL EMPLOYEE", "$totalEmployees", Colors.blue.shade700, Icons.people_alt_rounded),
        const SizedBox(width: 15),
        _statCard("PAID TODAY", "$paidCount", Colors.green.shade700, Icons.check_circle),
        const SizedBox(width: 15),
        _statCard("REMAINING", "$remainingCount", Colors.orange.shade800, Icons.pending_actions),
      ],
    );
  }

  Widget _statCard(String title, String val, Color col, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(left: BorderSide(color: col, width: 5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: col.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: col, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      val,
                      style: TextStyle(color: col, fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() { _searchQuery = val; }),
            decoration: InputDecoration(
              hintText: "Raadi magaca shaqaalaha...",
              prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
              filled: true,
              fillColor: const Color(0xFFF8F9FD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ["All", "Paid", "Pending"].map((f) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(f),
                selected: _currentFilter == f,
                onSelected: (val) => setState(() { _currentFilter = f; }),
                selectedColor: Colors.blue.shade700,
                labelStyle: TextStyle(color: _currentFilter == f ? Colors.white : Colors.black87),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    return ListView.builder(
      itemCount: _filteredEmployees.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final emp = _filteredEmployees[index];
        bool isPaid = emp['status'] == "Paid";
        
        // Halkan xogta database-ka ee 'amount' ayaa toos loo akhrinayaa, haddii kalena '0.00'
        String salaryDisplay = (emp['amount'] ?? '0.00').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: isPaid ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                child: Text(emp['name'][0], style: TextStyle(color: isPaid ? Colors.green : Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(emp['role'] ?? "Teacher", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              // Marka la bixiyo waxay noqonaysaa Paid oo cagaar ah, haddii kalena lacagta ayay tuseysaa
              Text(
                isPaid ? "Paid" : "\$$salaryDisplay", 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18, 
                  color: isPaid ? Colors.green : Colors.blueGrey
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 90,
                child: ElevatedButton(
                  onPressed: isPaid ? null : () => _showPayDialog(emp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaid ? Colors.grey.shade100 : Colors.blue.shade700,
                    foregroundColor: isPaid ? Colors.green : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isPaid ? "Paid" : "Pay"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPayDialog(dynamic emp) {
    String selectedSalary = "300";
    String selectedMethod = "ZAAD";
    DateTime selectedDate = DateTime.now();
    bool isManual = false;
    final manualCtrl = TextEditingController();
    final bonusCtrl = TextEditingController(text: "0");
    final deductCtrl = TextEditingController(text: "0");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("Bixi Mushaharka: ${emp['name']}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setModalState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                        const SizedBox(width: 10),
                        Text(DateFormat('dd / MMM / yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedSalary,
                  decoration: const InputDecoration(labelText: "Basic Salary", prefixIcon: Icon(Icons.money)),
                  items: _salaryOptions.map((e) => DropdownMenuItem(value: e, child: Text(e == "Manual" ? "Gali gacanta" : "\$ $e"))).toList(),
                  onChanged: (val) => setModalState(() { selectedSalary = val!; isManual = (val == "Manual"); }),
                ),
                if (isManual) TextField(controller: manualCtrl, decoration: const InputDecoration(hintText: "Gali inta lacagta ah"), keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: TextField(controller: bonusCtrl, decoration: const InputDecoration(labelText: "Bonus (+)"), keyboardType: TextInputType.number)),
                    const SizedBox(width: 15),
                    Expanded(child: TextField(controller: deductCtrl, decoration: const InputDecoration(labelText: "Dhimis (-)"), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(labelText: "Payment Method", prefixIcon: Icon(Icons.payment)),
                  items: _paymentMethods.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setModalState(() => selectedMethod = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ka noqo", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                double base = double.tryParse(isManual ? manualCtrl.text : selectedSalary) ?? 0;
                double bonus = double.tryParse(bonusCtrl.text) ?? 0;
                double deduct = double.tryParse(deductCtrl.text) ?? 0;

                double finalAmount = (base + bonus) - deduct;

                Map<String, dynamic> payData = {
                  "amount": finalAmount,
                  "bonus": bonus,
                  "deduction": deduct,
                  "payment_method": selectedMethod,
                  "status": "Paid",
                  "payment_date": DateFormat('yyyy-MM-dd').format(selectedDate),
                };

                Navigator.pop(context);
                setState(() => _isLoading = true);

                try {
                  // U xirida API-ga (Payment)
                  await TeacherService.paySalary(emp['id'], payData);
                  _showSnackBar("Mushaharka waa la bixiyay: \$$finalAmount");
                  _fetchData(); 
                } catch (e) {
                  setState(() => _isLoading = false);
                  _showSnackBar("Cillad bixinta: $e");
                }
              },
              child: const Text("Xaqiiji Bixinta"),
            ),
          ],
        ),
      ),
    );
  }
}