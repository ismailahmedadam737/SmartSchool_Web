import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/api_service.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? selectedClass;
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  DateTime selectedDate = DateTime.now();
  
  List<String> activeClasses = [];
  List<Map<String, dynamic>> allStudentsFromDb = [];
  List<Map<String, dynamic>> displayList = [];
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isHistoryMode = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final classes = await ApiService.getAllClasses();
      final students = await ApiService.getAllStudents();
      setState(() {
        activeClasses = classes;
        allStudentsFromDb = students.map((s) => {"name": s.name, "class": s.className}).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showStatusDialog(String title, String message, Color color, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _checkAndLoadAttendance(String className, DateTime date) async {
    setState(() => _isLoading = true);
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final existingData = await ApiService.getDailyReport(className, formattedDate);

    setState(() {
      selectedClass = className;
      _isLoading = false;
      if (existingData.isNotEmpty) {
        displayList = existingData.map((h) => {"name": h['student_name'], "isPresent": h['status'] == 'Present', "remarks": h['remarks'] ?? ""}).toList();
      } else {
        displayList = allStudentsFromDb.where((s) => s['class'] == className).map((s) => {"name": s['name'], "isPresent": true, "remarks": ""}).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: AppBar(
        title: const Text("Attendance Management", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        backgroundColor: Colors.white, elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
            children: [
              _buildModeButtons(),
              _buildClassSelector(),
              _buildDateTimeInfo(),
              Expanded(child: displayList.isEmpty ? _buildEmptyState() : _buildStudentList()),
            ],
          ),
      floatingActionButton: displayList.isNotEmpty ? _buildSubmitFab() : null,
    );
  }

  Widget _buildModeButtons() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          _modeBtn("New", !_isHistoryMode, () => setState(() => _isHistoryMode = false)),
          _modeBtn("History", _isHistoryMode, () => setState(() => _isHistoryMode = true)),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isActive ? Colors.indigo : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: DropdownButtonFormField<String>(
        value: selectedClass,
        decoration: InputDecoration(
          hintText: "Select Class", filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          prefixIcon: const Icon(Icons.school, color: Colors.indigo),
        ),
        items: activeClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (val) => val != null ? _checkAndLoadAttendance(val, selectedDate) : null,
      ),
    );
  }

  Widget _buildDateTimeInfo() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selectedMonth, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            Text(DateFormat('EEEE, dd MMM').format(selectedDate), style: const TextStyle(color: Colors.grey)),
          ]),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.indigo),
            onPressed: () async {
              DateTime? p = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2024), lastDate: DateTime.now());
              if (p != null) { setState(() => selectedDate = p); if (selectedClass != null) _checkAndLoadAttendance(selectedClass!, p); }
            },
          )
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final s = displayList[index];
        bool isPresent = s['isPresent'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isPresent ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  child: Icon(isPresent ? Icons.person : Icons.person_off, color: isPresent ? Colors.green : Colors.red),
                ),
                title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isPresent ? "Present" : "Absent", style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                trailing: IconButton(
                  onPressed: () => setState(() => s['isPresent'] = !isPresent),
                  icon: Icon(
                    isPresent ? Icons.check_circle : Icons.cancel,
                    color: isPresent ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ),
              ),
              // Faallada waa ay muuqataa KALIYA haddii ardaygu maqan yahay
              if (!isPresent)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: TextField(
                    onChanged: (v) => s['remarks'] = v,
                    controller: TextEditingController(text: s['remarks']),
                    decoration: InputDecoration(
                      hintText: "Reason for absence...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.edit_note, size: 20, color: Colors.red),
                      filled: true,
                      fillColor: Colors.red.shade50,
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("Select a class to load student records", style: TextStyle(color: Colors.grey)));

  Widget _buildSubmitFab() {
    return FloatingActionButton.extended(
      backgroundColor: Colors.indigo,
      onPressed: _isSubmitting ? null : _submitAttendance,
      label: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Attendance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.cloud_upload, color: Colors.white),
    );
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSubmitting = true);
    bool ok = await ApiService.submitAttendance(displayList, selectedClass!, selectedMonth, DateFormat('yyyy-MM-dd').format(selectedDate));
    setState(() => _isSubmitting = false);
    if (ok) _showStatusDialog("Success", "Xogtii waa la kaydiyey!", Colors.green, Icons.done_all);
  }
}