import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iftiinshe/Service/api_service.dart';
import 'package:iftiinshe/Service/payment_api_service.dart';
import 'package:iftiinshe/models/student_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  bool isLoading = true;
  String searchQuery = "";
  String? selectedClass;
  String selectedFilter = "All"; // "All", "Unpaid", "Debt (>50)"

  List<StudentModel> allStudents = [];
  List<String> classes = [];
  Map<String, double> studentPaidMap = {};
  Map<String, double> studentDebtMap = {};
  Map<String, String> studentNotesMap = {}; // Custom notes per student id/name
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final studentsList = await ApiService.getAllStudents();
      final classList = await ApiService.getAllClasses();

      Map<String, double> paidMap = {};
      Map<String, double> debtMap = {};

      for (var s in studentsList) {
        int studentId = s.id ?? int.tryParse(s.idString) ?? 0;
        if (studentId != 0) {
          try {
            final payments = await PaymentApiService.getPaymentsByStudent(studentId);
            double totalPaid = 0;
            double totalDept = 0;
            for (var p in payments) {
              totalPaid += double.tryParse(p['amount']?.toString() ?? '0') ?? 0;
              totalDept += double.tryParse(p['debt']?.toString() ?? '0') ?? 0;
            }
            paidMap[s.idString] = totalPaid;
            debtMap[s.idString] = totalDept;
          } catch (_) {}
        }
      }

      setState(() {
        allStudents = studentsList;
        classes = classList;
        studentPaidMap = paidMap;
        studentDebtMap = debtMap;
      });
    } catch (e) {
      debugPrint("Error loading fee notes data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<StudentModel> get filteredDebtorStudents {
    return allStudents.where((s) {
      double debt = studentDebtMap[s.idString] ?? 0;

      // Only show students with explicitly recorded debt > 0
      if (debt <= 0) return false;

      // Class filter
      if (selectedClass != null && selectedClass!.isNotEmpty && s.className != selectedClass) {
        return false;
      }

      // Search query
      if (searchQuery.isNotEmpty) {
        bool matchesName = s.name.toLowerCase().contains(searchQuery.toLowerCase());
        bool matchesPhone = s.phone.contains(searchQuery);
        if (!matchesName && !matchesPhone) return false;
      }

      // Filter tab
      if (selectedFilter == "Unpaid") {
        double paid = studentPaidMap[s.idString] ?? 0;
        return paid == 0;
      }

      return true;
    }).toList();
  }

  /// All students with debt > 0 (no search/class/tab filter) — used for metric cards
  List<StudentModel> get allDebtorStudents {
    return allStudents
        .where((s) => (studentDebtMap[s.idString] ?? 0) > 0)
        .toList();
  }

  double get totalOutstandingDebt {
    return allDebtorStudents.fold(
      0.0,
      (sum, s) => sum + (studentDebtMap[s.idString] ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile: isMobile),
              SizedBox(height: isMobile ? 12 : 20),
              _buildMetricsRow(isMobile: isMobile),
              SizedBox(height: isMobile ? 12 : 20),
              _buildFilterControls(isMobile: isMobile),
              const SizedBox(height: 15),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                    : filteredDebtorStudents.isEmpty
                        ? _buildEmptyState()
                        : _buildStudentNotesList(isMobile: isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    final int debtCount = allStudents
        .where((s) => (studentDebtMap[s.idString] ?? 0) > 0)
        .length;
    final bool hasDebts = debtCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Tooltip(
          message: hasDebts
              ? "$debtCount arday oo baaqi lagu leeyahay — Riix si liiska aad u aragto"
              : "Wax baaqi ah laguma leh",
          child: InkWell(
            onTap: _showDebtorNotificationsPanel,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasDebts
                    ? Colors.red.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasDebts
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: hasDebts
                    ? [BoxShadow(color: Colors.red.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)]
                    : [],
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: hasDebts ? Colors.redAccent : Colors.white38,
                size: 24,
              ),
            ),
          ),
        ),
        if (hasDebts)
          Positioned(
            top: -5,
            right: -5,
            child: GestureDetector(
              onTap: _showDebtorNotificationsPanel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 2),
                  ],
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
                child: Text(
                  debtCount > 99 ? "99+" : "$debtCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader({bool isMobile = false}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.note_alt_rounded, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fee Balance & Notes",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Maamulka baaqiga lacagaha ardayda",
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildNotificationBell(),
              ElevatedButton.icon(
                onPressed: _showAddNewDebtDialog,
                icon: const Icon(Icons.add_card_rounded, color: Colors.black, size: 16),
                label: const Text("+ Geli Baaqi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                label: const Text("Refresh", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.note_alt_rounded, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fee Balance & Notes Tracker",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Maamulka ogaysiisyada & baaqiga lacagaha ardayda",
                      style: TextStyle(fontSize: 13, color: Colors.white60),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            _buildNotificationBell(),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _showAddNewDebtDialog,
              icon: const Icon(Icons.add_card_rounded, color: Colors.black, size: 18),
              label: const Text("+ Geli Baaqi Arday"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🔔 Shows a popup panel listing all students with explicitly recorded debt
  void _showDebtorNotificationsPanel() {
    final debtors = allStudents
        .where((s) => (studentDebtMap[s.idString] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (studentDebtMap[b.idString] ?? 0).compareTo(studentDebtMap[a.idString] ?? 0));

    final ScrollController popupScrollController = ScrollController();
    final double totalDebt = debtors.fold(0.0, (sum, s) => sum + (studentDebtMap[s.idString] ?? 0));
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 50, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
            maxWidth: 680,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1740), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.45), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.25), blurRadius: 35, spreadRadius: 3)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Header ───
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.withValues(alpha: 0.18), Colors.transparent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                    border: Border(bottom: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Colors.redAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Ardayda Baaqiga lagu leeyahay",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("${debtors.length} arday · Wadarta: \$${totalDebt.toStringAsFixed(1)}",
                                style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 8)],
                        ),
                        child: Text("${debtors.length}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 22),
                      ),
                    ],
                  ),
                ),

                // ─── Student Cards List ───
                Flexible(
                  child: debtors.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(50),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 56),
                              SizedBox(height: 14),
                              Text("Majiraan arday baaqi laguleeyahay!",
                                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : RawScrollbar(
                          controller: popupScrollController,
                          thumbColor: Colors.redAccent.withValues(alpha: 0.5),
                          thickness: 5,
                          radius: const Radius.circular(10),
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: popupScrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 22, 12),
                            itemCount: debtors.length,
                            itemBuilder: (context, index) {
                              final s = debtors[index];
                              double debt = studentDebtMap[s.idString] ?? 0;
                              double paid = studentPaidMap[s.idString] ?? 0;
                              bool isUnpaid = paid == 0;
                              Color statusColor = isUnpaid ? Colors.redAccent : Colors.amberAccent;
                              Color cardBorder = isUnpaid
                                  ? Colors.redAccent.withValues(alpha: 0.3)
                                  : Colors.amber.withValues(alpha: 0.25);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUnpaid
                                      ? Colors.red.withValues(alpha: 0.06)
                                      : Colors.amber.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cardBorder, width: 1.2),
                                ),
                                child: Row(
                                  children: [
                                    // ── Rank number ──
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${index + 1}",
                                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // ── Avatar ──
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.indigo.withValues(alpha: 0.45),
                                      child: Text(
                                        s.name.isNotEmpty ? s.name[0].toUpperCase() : "S",
                                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // ── Name + Class ──
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.name,
                                              style: const TextStyle(
                                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.school_outlined, color: Colors.white38, size: 13),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(s.className,
                                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                    overflow: TextOverflow.ellipsis),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // ── Debt + Badge ──
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "\$${debt.toStringAsFixed(1)}",
                                          style: TextStyle(
                                              color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                          ),
                                          child: Text(
                                            isUnpaid ? "UNPAID" : "PENDING",
                                            style: TextStyle(
                                                color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),

                // ─── Footer ───
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Wadarta Baaqiga: \$${totalDebt.toStringAsFixed(1)}",
                            style: const TextStyle(
                                color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                        label: const Text("Xir"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white12,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow({bool isMobile = false}) {
    if (isMobile) {
      return Column(
        children: [
          _metricCard(
            title: "Ardayda Baaqiga lagu leeyahay",
            value: "${allDebtorStudents.length}",
            subtitle: "Wadarta ardayda baaqi lagu leeyahay",
            icon: Icons.people_outline_rounded,
            gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          ),
          const SizedBox(height: 10),
          _metricCard(
            title: "Wadarta Baaqiga (\$)",
            value: "\$${totalOutstandingDebt.toStringAsFixed(1)}",
            subtitle: "Total Outstanding Debt",
            icon: Icons.account_balance_wallet_outlined,
            gradientColors: [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
            isHighlighted: true,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            title: "Ardayda Baaqiga lagu leeyahay",
            value: "${allDebtorStudents.length}",
            subtitle: "Wadarta ardayda baaqi lagu leeyahay",
            icon: Icons.people_outline_rounded,
            gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _metricCard(
            title: "Wadarta Baaqiga (\$)",
            value: "\$${totalOutstandingDebt.toStringAsFixed(1)}",
            subtitle: "Total Outstanding Debt",
            icon: Icons.account_balance_wallet_outlined,
            gradientColors: [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
            isHighlighted: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterControls({bool isMobile = false}) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Raadi magaca ama taleefanka...",
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent, size: 20),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedClass,
                        dropdownColor: const Color(0xFF1E1B4B),
                        isExpanded: true,
                        hint: const Text("Fasallada", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyanAccent, size: 18),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("Dhammaan", style: TextStyle(color: Colors.white, fontSize: 12))),
                          ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 12)))),
                        ],
                        onChanged: (val) => setState(() => selectedClass = val),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip("Dhammaan", "All"),
                      const SizedBox(width: 6),
                      _filterChip("Unpaid", "Unpaid"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Raadi magaca ama taleefanka...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedClass,
                dropdownColor: const Color(0xFF1E1B4B),
                hint: const Text("Dhammaan Fasallada", style: TextStyle(color: Colors.white70)),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyanAccent),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Dhammaan Fasallada", style: TextStyle(color: Colors.white))),
                  ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))),
                ],
                onChanged: (val) => setState(() => selectedClass = val),
              ),
            ),
          ),
          const SizedBox(width: 15),
          _filterChip("Dhammaan", "All"),
          const SizedBox(width: 8),
          _filterChip("Baaqi Qeyb (Unpaid)", "Unpaid"),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final bool isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors.map((c) => c.withValues(alpha: isHighlighted ? 0.25 : 0.15)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors.first.withValues(alpha: isHighlighted ? 0.6 : 0.3),
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gradientColors.first.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gradientColors.first.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: gradientColors.first, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 44),
            ),
            const SizedBox(height: 12),
            const Text(
              "Wax baaqi ah laguma helin!",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Ma jiraan arday buuxisa shuruudaha raadinta ee hadda.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentNotesList({bool isMobile = false, bool shrinkWrap = false}) {
    return RawScrollbar(
      controller: _listScrollController,
      thumbColor: Colors.cyanAccent.withValues(alpha: 0.6),
      thickness: 6.0,
      radius: const Radius.circular(10),
      thumbVisibility: !shrinkWrap,
      child: ListView.builder(
        controller: _listScrollController,
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
        itemCount: filteredDebtorStudents.length,
        itemBuilder: (context, index) {
        final s = filteredDebtorStudents[index];
        double paid = studentPaidMap[s.idString] ?? 0;
        double debt = studentDebtMap[s.idString] ?? 0;
        String customNote = studentNotesMap[s.idString] ?? "";

        bool isUnpaid = paid == 0;
        Color badgeColor = isUnpaid ? Colors.redAccent : Colors.amberAccent;
        String badgeText = isUnpaid ? "UNPAID (0 Paid)" : "PENDING DEBT";

        if (isMobile) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.indigo.withValues(alpha: 0.5),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : "S",
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                          Text("${s.className} | ${s.phone}", style: const TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Lagu leeyahay: \$${debt.toStringAsFixed(1)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("La bixiyey: \$${paid.toStringAsFixed(1)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                  ],
                ),
                if (customNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text("Note: $customNote", style: const TextStyle(color: Colors.amber, fontSize: 11), overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showPayDebtDialog(s, debt),
                      icon: const Icon(Icons.payments_rounded, size: 14, color: Colors.black),
                      label: const Text("Bix", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.cyanAccent, size: 20),
                      onPressed: () => _showAddNoteDialog(s),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.greenAccent, size: 20),
                      onPressed: () => _showSmsModal(s, debt),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: const Icon(Icons.print_outlined, color: Colors.amberAccent, size: 20),
                      onPressed: () => _printReminderNote(s, paid, debt),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.indigo.withValues(alpha: 0.5),
                child: Text(
                  s.name.isNotEmpty ? s.name[0].toUpperCase() : "S",
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text("Fasalka: ${s.className}", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(width: 15),
                        const Icon(Icons.phone_outlined, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text(s.phone, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                    if (customNote.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Note: $customNote",
                                style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Lagu leeyahay: \$${debt.toStringAsFixed(1)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text("La bixiyey: \$${paid.toStringAsFixed(1)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Row(
                children: [
                  // 💚 Pay Debt Button
                  Tooltip(
                    message: "Bix Qeyb/Dhamaan Baaqiga",
                    child: ElevatedButton.icon(
                      onPressed: () => _showPayDebtDialog(s, debt),
                      icon: const Icon(Icons.payments_rounded, size: 16, color: Colors.black),
                      label: const Text("Bix", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: "Qor/Wax ka bedel Note",
                    icon: const Icon(Icons.edit_note_rounded, color: Colors.cyanAccent),
                    onPressed: () => _showAddNoteDialog(s),
                  ),
                  IconButton(
                    tooltip: "Ogeysiis WhatsApp/SMS",
                    icon: const Icon(Icons.send_rounded, color: Colors.greenAccent),
                    onPressed: () => _showSmsModal(s, debt),
                  ),
                  IconButton(
                    tooltip: "Print Statement",
                    icon: const Icon(Icons.print_outlined, color: Colors.amberAccent),
                    onPressed: () => _printReminderNote(s, paid, debt),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
  }

  void _showPayDebtDialog(StudentModel student, double currentDebt) {
    final TextEditingController payController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double payAmount = double.tryParse(payController.text) ?? 0;
          double remaining = (currentDebt - payAmount).clamp(0.0, double.infinity);

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1B4B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.payments_rounded, color: Colors.greenAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Bix Baaqi: ${student.name}",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Current debt display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Baaqiga Hadda:", style: TextStyle(color: Colors.white60, fontSize: 13)),
                      Text(
                        "\$${currentDebt.toStringAsFixed(1)}",
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text("Lacagta La Bixinaayo (\$):", style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: payController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: "Tusaale: ${currentDebt.toStringAsFixed(1)}",
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.greenAccent),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                // Remaining after payment
                if (payAmount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: remaining == 0
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: remaining == 0
                            ? Colors.greenAccent.withValues(alpha: 0.4)
                            : Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          remaining == 0 ? "✅ Baaqi Dhammaatay!" : "Waxaa hadhay:",
                          style: TextStyle(
                            color: remaining == 0 ? Colors.greenAccent : Colors.amberAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (remaining > 0)
                          Text(
                            "\$${remaining.toStringAsFixed(1)}",
                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Ka noqo", style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: payAmount <= 0
                    ? null
                    : () async {
                        int studentId = student.id ?? int.tryParse(student.idString) ?? 0;
                        if (studentId != 0) {
                          try {
                            double newDebt = (currentDebt - payAmount).clamp(0.0, double.infinity);
                            // Send payment and debt adjustment to backend DB
                            await PaymentApiService.addPayment(
                              studentId: studentId,
                              amount: payAmount,
                              debt: newDebt - currentDebt,
                              month: DateTime.now().month.toString(),
                              transport: 'Fee Payment',
                            );
                          } catch (e) {
                            debugPrint("Error saving payment to DB: $e");
                          }
                        }

                        if (mounted) {
                          Navigator.pop(context);
                          await _fetchData(); // Permanently reload from database
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green.shade700,
                              content: Text(
                                payAmount >= currentDebt
                                    ? "✅ ${student.name} — Baaqiga si buuxda ayaa loo bixiyey database-ka!"
                                    : "💰 ${student.name} — \$${payAmount.toStringAsFixed(1)} la bixiyey. Waxaa hadhay \$${(currentDebt - payAmount).toStringAsFixed(1)}",
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text("Xaqiiji Lacag Bixinta", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddNewDebtDialog() {
    StudentModel? selectedStudentForDebt;
    String? dialogSelectedClass;
    TextEditingController debtController = TextEditingController();
    TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter students by selected class in dialog
          final List<StudentModel> dialogStudents = dialogSelectedClass != null && dialogSelectedClass!.isNotEmpty
              ? allStudents.where((s) => s.className == dialogSelectedClass).toList()
              : allStudents;

          // Calculate total debt for selected student (if any)
          double currentDebt = selectedStudentForDebt != null
              ? (studentDebtMap[selectedStudentForDebt!.idString] ?? 0)
              : 0;
          double newDebtVal = double.tryParse(debtController.text) ?? 0;
          double totalDebt = currentDebt + newDebtVal;

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1B4B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.add_card_rounded, color: Colors.amberAccent),
                SizedBox(width: 10),
                Text("Geli Baaqi Arday", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Class Filter ---
                  const Text("Dooro Fasalka (optional):", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: dialogSelectedClass,
                        dropdownColor: const Color(0xFF1E1B4B),
                        isExpanded: true,
                        hint: const Text("Dhammaan Fasallada", style: TextStyle(color: Colors.white54)),
                        icon: const Icon(Icons.school_rounded, color: Colors.cyanAccent, size: 18),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text("Dhammaan Fasallada", style: TextStyle(color: Colors.white70)),
                          ),
                          ...classes.map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c, style: const TextStyle(color: Colors.white)),
                          )),
                        ],
                        onChanged: (val) => setDialogState(() {
                          dialogSelectedClass = val;
                          selectedStudentForDebt = null; // Reset student when class changes
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // --- Student Dropdown ---
                  const Text("Dooro Ardayga:", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<StudentModel>(
                        value: selectedStudentForDebt,
                        dropdownColor: const Color(0xFF1E1B4B),
                        isExpanded: true,
                        hint: const Text("Dooro Ardayga...", style: TextStyle(color: Colors.white54)),
                        items: dialogStudents.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text("${s.name} (${s.className})", style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: (val) => setDialogState(() {
                          selectedStudentForDebt = val;
                          // Pre-fill current debt
                          if (val != null) {
                            debtController.text = (studentDebtMap[val.idString] ?? 0).toStringAsFixed(1);
                          }
                        }),
                      ),
                    ),
                  ),
                  // Show total debt summary if student selected
                  if (selectedStudentForDebt != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Wadarta Baaqiga:", style: TextStyle(color: Colors.white60, fontSize: 12)),
                          Text(
                            "\$${totalDebt.toStringAsFixed(1)}",
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text("Lacagta Baaqiga (\$):", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: debtController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: "Tusaale: 50.0",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.redAccent),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text("Note / Faahfaahin:", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Tusaale: Baaqi bisha January...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Ka noqo", style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedStudentForDebt != null) {
                    double debtVal = double.tryParse(debtController.text) ?? 0;
                    int studentId = selectedStudentForDebt!.id ?? int.tryParse(selectedStudentForDebt!.idString) ?? 0;
                    
                    if (studentId != 0 && debtVal > 0) {
                      try {
                        double existingDebt = studentDebtMap[selectedStudentForDebt!.idString] ?? 0;
                        double debtToAdd = debtVal - existingDebt;
                        if (debtToAdd != 0) {
                          await PaymentApiService.addPayment(
                            studentId: studentId,
                            amount: 0.0,
                            debt: debtToAdd,
                            month: DateTime.now().month.toString(),
                            transport: noteController.text.trim().isNotEmpty ? noteController.text.trim() : 'Fee Note',
                          );
                        }
                      } catch (e) {
                        debugPrint("Error saving debt to database: $e");
                      }
                    }

                    if (noteController.text.isNotEmpty) {
                      studentNotesMap[selectedStudentForDebt!.idString] = noteController.text.trim();
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      await _fetchData(); // Permanently reload from database
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("✅ Baaqiga ardayga ${selectedStudentForDebt!.name} waa la kaydiyey database-ka (\$${debtVal.toStringAsFixed(1)})")),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                child: const Text("Kaydi Baaqiga", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddNoteDialog(StudentModel student) {
    TextEditingController debtController = TextEditingController(
      text: (studentDebtMap[student.idString] ?? 0).toStringAsFixed(1),
    );
    TextEditingController noteController = TextEditingController(
      text: studentNotesMap[student.idString] ?? "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.note_add_rounded, color: Colors.cyanAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Note & Baaqi: ${student.name}",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text("Lacagta Baaqiga (\$) :", style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: debtController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "0.0",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.attach_money, color: Colors.redAccent),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            const Text("Qor faahfaahinta ama wada-hadalka aabaha/waalidka:", style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Tusaale: Aabaha waa la wacay, wuxuu bixinayaa 5-ta bisha...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
      actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ka noqo", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              double newDebt = double.tryParse(debtController.text) ?? (studentDebtMap[student.idString] ?? 0);
              int studentId = student.id ?? int.tryParse(student.idString) ?? 0;
              
              if (studentId != 0) {
                try {
                  double currentDebt = studentDebtMap[student.idString] ?? 0;
                  double diff = newDebt - currentDebt;
                  if (diff != 0) {
                    await PaymentApiService.addPayment(
                      studentId: studentId,
                      amount: 0.0,
                      debt: diff,
                      month: DateTime.now().month.toString(),
                      transport: noteController.text.trim().isNotEmpty ? noteController.text.trim() : 'Note Update',
                    );
                  }
                } catch (e) {
                  debugPrint("Error updating note/debt in DB: $e");
                }
              }

              if (noteController.text.isNotEmpty) {
                studentNotesMap[student.idString] = noteController.text.trim();
              }

              if (mounted) {
                Navigator.pop(context);
                await _fetchData(); // Permanently reload from database
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Baaqiga iyo Note-ka waa la kaydiyey database-ka!")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            child: const Text("Kaydi Xogta", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSmsModal(StudentModel student, double debt) {
    String customNote = studentNotesMap[student.idString] ?? "";
    String formattedMessage = "OGAYSIIS BAAQI FEE:\n"
        "Ardayga: ${student.name}\n"
        "Fasalka: ${student.className}\n"
        "Baaqiga lagu leeyahay: \$${debt.toStringAsFixed(1)}\n"
        "${customNote.isNotEmpty ? 'Note: $customNote\n' : ''}"
        "Fadlan ku bixi xafiiska dugsiga sida ugu dhakhsaha badan.\nMahadsanid - IFTIINSHE SCHOOLS.";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.mark_chat_read_rounded, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Text("Ogeysiis: ${student.name}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: SelectableText(
                formattedMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: formattedMessage));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("📋 Farriinta waa la koobiyey (Copied to Clipboard)!")),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text("Koobiyeey Farriinta"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
          ),
        ],
      ),
    );
  }

  Future<void> _printReminderNote(StudentModel student, double paid, double debt) async {
    final doc = pw.Document();
    String note = studentNotesMap[student.idString] ?? "";

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("IFTIINSHE BILE SCHOOLS", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.Text("FEE REMINDER STATEMENT", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Student Name: ${student.name}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text("Class: ${student.className}"),
                    pw.Text("Phone: ${student.phone}"),
                    pw.Text("District: ${student.district} | Neighbor: ${student.neighbor}"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ["Description", "Amount (\$)"],
                data: [
                  ["Total Fee Paid", "\$${paid.toStringAsFixed(1)}"],
                  ["Remaining Unpaid Debt", "\$${debt.toStringAsFixed(1)}"],
                ],
              ),
              if (note.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                pw.Text("Admin Notes: $note", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey800)),
              ],
              pw.Spacer(),
              pw.Divider(),
              pw.Text("Fadlan ku bixi baaqiga sare ku xusan xafiiska maamulka dugsiga. Mahadsanid!"),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Fee_Note_${student.name}',
    );
  }
}