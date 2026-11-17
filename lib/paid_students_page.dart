import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/api_service.dart';
import 'package:iftiinshe/Service/payment_api_service.dart';
import 'package:iftiinshe/models/student_model.dart';
import 'package:iftiinshe/receipt_page.dart';

class PaidStudentsPage extends StatefulWidget {
  const PaidStudentsPage({super.key});

  @override
  State<PaidStudentsPage> createState() => _PaidStudentsPageState();
}

class _PaidStudentsPageState extends State<PaidStudentsPage> {
  bool isLoading = true;
  List<StudentModel> allStudents = [];
  List<String> classesList = [];

  // studentId -> totalPaid
  Map<int, double> studentPaidMap = {};
  // studentId -> totalDebt
  Map<int, double> studentDebtMap = {};

  String selectedClass = "All"; // "All" or class name
  String filterStatus = "all"; // "all", "paid", "debt", "unpaid"
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Haddii cache hore u jiro, isla markiiba ku bilow (0ms Instant Load)
    if (PaymentApiService.cachedPaidByStudentId.isNotEmpty) {
      studentPaidMap = Map<int, double>.from(PaymentApiService.cachedPaidByStudentId);
      studentDebtMap = Map<int, double>.from(PaymentApiService.cachedDebtByStudentId);
      isLoading = false;
    }
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    // Kaliya loading muuji haddii ardaydu eber tahay
    if (allStudents.isEmpty && studentPaidMap.isEmpty) {
      setState(() => isLoading = true);
    }
    try {
      // 1. Soo qaado ardayda iyo lacagaha isku mar (Parallel Fast)
      final results = await Future.wait([
        ApiService.getAllStudents(limit: 2000),
        PaymentApiService.syncAllPayments(),
      ]);

      if (!mounted) return;

      final students = results[0] as List<StudentModel>;

      // Fasallada kala sooc
      final classesSet = <String>{};
      for (var s in students) {
        if (s.className.trim().isNotEmpty) {
          classesSet.add(s.className.trim());
        }
      }
      final sortedClasses = classesSet.toList()..sort();

      Map<int, double> paidMap = Map<int, double>.from(PaymentApiService.cachedPaidByStudentId);
      Map<int, double> debtMap = Map<int, double>.from(PaymentApiService.cachedDebtByStudentId);

      // Haddii syncAllPayments eber tahay, fallback in parallel
      if (paidMap.isEmpty && students.isNotEmpty) {
        final futures = students.where((s) => s.id != null).map((s) async {
          try {
            final payments = await PaymentApiService.getPaymentsByStudent(s.id!);
            double totalPaid = 0;
            double totalDebt = 0;
            for (var p in payments) {
              totalPaid += double.tryParse(p['amount']?.toString() ?? '0') ?? 0;
              totalDebt += double.tryParse(p['debt']?.toString() ?? '0') ?? 0;
            }
            paidMap[s.id!] = totalPaid;
            debtMap[s.id!] = totalDebt;
          } catch (_) {}
        });
        await Future.wait(futures);
      }

      if (mounted) {
        setState(() {
          allStudents = students;
          classesList = ["All", ...sortedClasses];
          studentPaidMap = paidMap;
          studentDebtMap = debtMap;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Cilad xogta lacagaha: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Helitaanka xogta la shaandheeyey
  List<StudentModel> get filteredList {
    return allStudents.where((s) {
      // 1. Fasalka
      if (selectedClass != "All" && s.className.trim() != selectedClass.trim()) {
        return false;
      }

      // 2. Magaca / Raadinta
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final nameMatches = s.name.toLowerCase().contains(q);
        final classMatches = s.className.toLowerCase().contains(q);
        if (!nameMatches && !classMatches) return false;
      }

      final sId = s.id ?? 0;
      final paid = studentPaidMap[sId] ?? 0.0;
      final debt = studentDebtMap[sId] ?? 0.0;

      // 3. Xaaladda Lacagta (Status Filter)
      if (filterStatus == "paid") {
        return paid > 0 && debt == 0;
      } else if (filterStatus == "debt") {
        return debt > 0;
      } else if (filterStatus == "unpaid") {
        return paid == 0 && debt == 0;
      }

      return true; // "all"
    }).toList();
  }

  // Tirakoobka KPI
  int get countTotalStudents => allStudents.length;

  int get countAllPaid {
    return allStudents.where((s) {
      final sId = s.id ?? 0;
      final paid = studentPaidMap[sId] ?? 0.0;
      final debt = studentDebtMap[sId] ?? 0.0;
      return paid > 0 && debt == 0;
    }).length;
  }

  int get countDebtStudents {
    return allStudents.where((s) {
      final sId = s.id ?? 0;
      final debt = studentDebtMap[sId] ?? 0.0;
      return debt > 0;
    }).length;
  }

  int get countUnpaidStudents {
    return allStudents.where((s) {
      final sId = s.id ?? 0;
      final paid = studentPaidMap[sId] ?? 0.0;
      final debt = studentDebtMap[sId] ?? 0.0;
      return paid == 0 && debt == 0;
    }).length;
  }

  double get sumTotalPaid {
    double total = 0;
    for (var val in studentPaidMap.values) {
      total += val;
    }
    return total;
  }

  double get sumTotalDebt {
    double total = 0;
    for (var val in studentDebtMap.values) {
      total += val;
    }
    return total;
  }

  void _pay(StudentModel s) {
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController debtCtrl = TextEditingController();
    String transport = "No Bus";
    String month = "January";
    final months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payment_rounded, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Qaadashada Lacagta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(s.name, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Lacagta la bixinayo (\$):", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF10B981)),
                    hintText: "Tusaale: 20",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Baaqiga / Debt (\$):", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: debtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.money_off, color: Colors.orange),
                    hintText: "Haddii baaqi jiro: 10",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Bisha Lacagta:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: month,
                  items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setDialogState(() => month = val ?? month),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Gaadiidka (Bus):", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: transport,
                  items: const [
                    DropdownMenuItem(value: "No Bus", child: Text("No Bus (Bilaash)")),
                    DropdownMenuItem(value: "Bus", child: Text("Bus (+\$10)")),
                  ],
                  onChanged: (val) => setDialogState(() => transport = val ?? transport),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Jooji", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                double v = double.tryParse(amountCtrl.text) ?? 0;
                double d = double.tryParse(debtCtrl.text) ?? 0;
                if (transport == "Bus") v += 10;

                try {
                  await PaymentApiService.addPayment(
                    studentId: s.id ?? 0,
                    amount: v,
                    debt: d,
                    month: month,
                    transport: transport,
                  );

                  // Cusboonaysii xogta maxalliga ah
                  final sId = s.id ?? 0;
                  setState(() {
                    studentPaidMap[sId] = (studentPaidMap[sId] ?? 0.0) + v;
                    studentDebtMap[sId] = d;
                  });

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Lacagta \$${v.toStringAsFixed(0)} ee ${s.name} si guul leh ayaa loo kaydiyay!"),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Cilad: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Kaydi Lacagta"),
            ),
          ],
        ),
      ),
    );
  }

  void _printReceipt(StudentModel s) {
    final sId = s.id ?? 0;
    final paid = studentPaidMap[sId] ?? 0.0;
    final debt = studentDebtMap[sId] ?? 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPage(
          studentId: sId,
          name: s.name,
          paid: paid,
          dept: debt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dhammaan Ardayda Lacagta Bixisay",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              "Maamulka lacagaha, xaaladda ardayda, iyo baaqiyada",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Dib u cusboonaysii",
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6)),
            onPressed: _loadAllData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: (isLoading && allStudents.isEmpty)
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF10B981)),
                  SizedBox(height: 14),
                  Text("Fadlan sug, xogta lacagaha ardayda ayaa la soo rarayaa...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth >= 900;
                final list = filteredList;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 12,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(
                            color: Color(0xFF10B981),
                            backgroundColor: Color(0xFFE2E8F0),
                            minHeight: 3,
                          ),
                        ),
                      // 1. KPI SUMMARY CARDS (Dhammaan, Paid, Baaqi, Unpaid)
                      _buildSummaryCards(isDesktop),
                      const SizedBox(height: 20),

                      // 2. TOOLBAR: FASALKA SELECTOR & SEARCH BOX & FILTER CHIPS
                      _buildFilterToolbar(isDesktop),
                      const SizedBox(height: 16),

                      // 3. STUDENT TABLE / LIST VIEW
                      _buildStudentsContent(list, isDesktop),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // --- 1. KPI SUMMARY CARDS (Clean, Soft & Modern with Bottom Shade) ---
  Widget _buildSummaryCards(bool isDesktop) {
    final cards = [
      _buildKpiCard(
        id: "all",
        title: "Dhammaan Ardayda",
        value: "$countTotalStudents",
        subtitle: "Wadarta: \$${sumTotalPaid.toStringAsFixed(0)}",
        icon: Icons.groups_rounded,
        accentColor: const Color(0xFF2563EB), // Vibrant Blue
        softBgColor: const Color(0xFFEFF6FF), // Soft Blue tint
      ),
      _buildKpiCard(
        id: "paid",
        title: "All Paid (Bixiyay)",
        value: "$countAllPaid",
        subtitle: "La bixiyay: \$${sumTotalPaid.toStringAsFixed(0)}",
        icon: Icons.verified_rounded,
        accentColor: const Color(0xFF10B981), // Emerald Mint
        softBgColor: const Color(0xFFECFDF5), // Soft Mint tint
      ),
      _buildKpiCard(
        id: "debt",
        title: "Baaqi Lagu Leeyahay",
        value: "$countDebtStudents",
        subtitle: "Baaqiga: \$${sumTotalDebt.toStringAsFixed(0)}",
        icon: Icons.pending_actions_rounded,
        accentColor: const Color(0xFFF59E0B), // Warm Amber
        softBgColor: const Color(0xFFFFFBEB), // Soft Amber tint
      ),
      _buildKpiCard(
        id: "unpaid",
        title: "Aan Bixin (Unpaid)",
        value: "$countUnpaidStudents",
        subtitle: "Weli waxba ma bixin",
        icon: Icons.money_off_rounded,
        accentColor: const Color(0xFFEF4444), // Coral Red
        softBgColor: const Color(0xFFFEF2F2), // Soft Red tint
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.35,
        children: cards,
      );
    }
  }

  Widget _buildKpiCard({
    required String id,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color softBgColor,
  }) {
    final bool isSelected = filterStatus == id;
    return _KpiHoverCard(
      id: id,
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      accentColor: accentColor,
      softBgColor: softBgColor,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          filterStatus = isSelected && id != "all" ? "all" : id;
        });
      },
    );
  }

  // --- 2. TOOLBAR: CLASS DROPDOWN & SEARCH FIELD ---
  Widget _buildFilterToolbar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              children: [
                // Class Selector
                _buildClassDropdown(),
                const SizedBox(width: 14),
                // Search Input
                Expanded(child: _buildSearchTextField()),
              ],
            )
          else ...[
            _buildSearchTextField(),
            const SizedBox(height: 12),
            _buildClassDropdown(),
          ],
          const SizedBox(height: 14),
          // Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip("all", "Dhammaan ($countTotalStudents)", Icons.list_alt_rounded, const Color(0xFF3B82F6)),
              _buildFilterChip("paid", "✅ Bixiyay ($countAllPaid)", Icons.check_circle_rounded, const Color(0xFF10B981)),
              _buildFilterChip("debt", "⚠️ Baaqi ($countDebtStudents)", Icons.warning_rounded, const Color(0xFFF59E0B)),
              _buildFilterChip("unpaid", "❌ Aan Bixin ($countUnpaidStudents)", Icons.cancel_rounded, const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_rounded, color: Color(0xFF64748B), size: 18),
          const SizedBox(width: 8),
          const Text("Fasalka: ", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          DropdownButton<String>(
            value: selectedClass,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            items: classesList.map((c) {
              return DropdownMenuItem<String>(
                value: c,
                child: Text(c == "All" ? "Dhammaan Fasallada" : c),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => selectedClass = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => searchQuery = val),
      decoration: InputDecoration(
        hintText: "Raadi arday magac ama fasal ahaan...",
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() => searchQuery = "");
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildFilterChip(String id, String label, IconData icon, Color color) {
    final bool isSelected = filterStatus == id;
    return InkWell(
      onTap: () => setState(() => filterStatus = id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. STUDENTS CONTENT ---
  Widget _buildStudentsContent(List<StudentModel> list, bool isDesktop) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              "Wax arday ah lagama helin xulashadan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            const Text(
              "Fadlan beddel shaandhaynta ama raadinta ardayda.",
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 40, child: Text("#", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                  Expanded(flex: 3, child: Text("Magaca Ardayga", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                  Expanded(flex: 2, child: Text("Fasalka", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                  Expanded(flex: 2, child: Text("La Bixiyay (Paid)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                  Expanded(flex: 2, child: Text("Baaqi (Debt)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                  Expanded(flex: 2, child: Text("Xaaladda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                  SizedBox(width: 140, child: Text("Waxqabadka", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                ],
              ),
            ),
            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final s = list[index];
                return _buildTableRow(s, index + 1);
              },
            ),
          ],
        ),
      );
    } else {
      // Mobile List Cards
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final s = list[index];
          return _buildMobileCard(s, index + 1);
        },
      );
    }
  }

  Widget _buildTableRow(StudentModel s, int index) {
    final sId = s.id ?? 0;
    final paid = studentPaidMap[sId] ?? 0.0;
    final debt = studentDebtMap[sId] ?? 0.0;

    String statusText;
    Color statusColor;
    if (paid > 0 && debt == 0) {
      statusText = "Bixiyay";
      statusColor = const Color(0xFF10B981);
    } else if (debt > 0) {
      statusText = "Baaqi";
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusText = "Aan Bixin";
      statusColor = const Color(0xFFEF4444);
    }

    return _HoverTableRow(
      accentColor: statusColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text("$index", style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: statusColor.withOpacity(0.12),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0].toUpperCase() : "A",
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.className,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "\$${paid.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "\$${debt.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: debt > 0 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _pay(s),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14),
                        SizedBox(width: 4),
                        Text("Bixi", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: "Daabac Rasiidh",
                    icon: const Icon(Icons.print_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => _printReceipt(s),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCard(StudentModel s, int index) {
    final sId = s.id ?? 0;
    final paid = studentPaidMap[sId] ?? 0.0;
    final debt = studentDebtMap[sId] ?? 0.0;

    String statusText;
    Color statusColor;
    if (paid > 0 && debt == 0) {
      statusText = "Bixiyay";
      statusColor = const Color(0xFF10B981);
    } else if (debt > 0) {
      statusText = "Baaqi";
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusText = "Aan Bixin";
      statusColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: statusColor.withOpacity(0.12),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : "A",
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Fasalka: ${s.className}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Row(
                children: [
                  Text("Bixiyay: \$${paid.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  const SizedBox(width: 10),
                  Text("Baaqi: \$${debt.toStringAsFixed(0)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: debt > 0 ? const Color(0xFFEF4444) : Colors.grey)),
                ],
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _printReceipt(s),
                icon: const Icon(Icons.print_rounded, size: 14),
                label: const Text("Rasiidh", style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _pay(s),
                icon: const Icon(Icons.payment_rounded, size: 14),
                label: const Text("Bixi Lacag", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiHoverCard extends StatefulWidget {
  final String id;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color softBgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _KpiHoverCard({
    required this.id,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.softBgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_KpiHoverCard> createState() => _KpiHoverCardState();
}

class _KpiHoverCardState extends State<_KpiHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? (Matrix4.identity()..translate(0.0, -5.0, 0.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accentColor
                  : _isHovered
                      ? widget.accentColor.withOpacity(0.4)
                      : const Color(0xFFE2E8F0),
              width: widget.isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              // Ambient soft shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              // Soft bottom colored glow shadow (shade hoose)
              BoxShadow(
                color: widget.accentColor.withOpacity(highlighted ? 0.22 : 0.09),
                blurRadius: highlighted ? 22 : 12,
                spreadRadius: highlighted ? 1 : 0,
                offset: Offset(0, highlighted ? 8 : 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                // Soft bottom gradient shade
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor.withOpacity(0.0),
                          widget.accentColor.withOpacity(highlighted ? 0.09 : 0.04),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Card Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: Title + Icon Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                if (widget.isSelected)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: widget.accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    widget.title,
                                    style: TextStyle(
                                      color: widget.isSelected
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedScale(
                            scale: _isHovered ? 1.12 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.softBgColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.accentColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(widget.icon, color: widget.accentColor, size: 18),
                            ),
                          ),
                        ],
                      ),

                      // Middle: Value (Count)
                      Text(
                        widget.value,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      // Bottom: Subtitle with soft badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: widget.softBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.accentColor.withOpacity(0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: widget.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Colored Accent Strip (Shade-ka hoose ee aadka u quruxda badan)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 3.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor,
                          widget.accentColor.withOpacity(0.5),
                        ],
                      ),
                    ),
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

class _HoverTableRow extends StatefulWidget {
  final Widget child;
  final Color accentColor;

  const _HoverTableRow({required this.child, required this.accentColor});

  @override
  State<_HoverTableRow> createState() => _HoverTableRowState();
}

class _HoverTableRowState extends State<_HoverTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF1F5F9).withOpacity(0.65) : Colors.white,
          border: Border(
            left: BorderSide(
              color: _isHovered ? widget.accentColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

