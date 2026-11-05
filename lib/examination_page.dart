import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:iftiinshe/Service/api_service.dart';
import '../models/student_model.dart';

// Packages-ka daabacaadda iyo PDF-ka
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExaminationPage extends StatefulWidget {
  final String userRole;
  const ExaminationPage({super.key, this.userRole = ''});

  @override
  State<ExaminationPage> createState() => _ExaminationPageState();
}

class _ExaminationPageState extends State<ExaminationPage> {
  bool isTeacherView = true;
  String? selectedClass;
  StudentModel? selectedStudent;
  
  bool get isUserRole => widget.userRole.trim().toLowerCase() == 'user';
  bool get isTeacherRole => widget.userRole.trim().toLowerCase() == 'teacher';
  
  String selectedExamType = "Monthly Exam";
  final List<String> examTypes = ["Monthly Exam", "Term 1", "Pre-Final", "Final Exam"];
  
  Map<String, int> examMaxMarks = {
    "Monthly Exam": 10,
    "Term 1": 40,
    "Pre-Final": 20,
    "Final Exam": 30,
  };

  List<StudentModel> allStudents = []; 
  List<StudentModel> filteredStudents = []; 
  List<String> dynamicClasses = []; 
  List<Map<String, dynamic>> currentStudentResults = [];
  bool isLoading = false;

  final List<String> subjects = ["Math", "English", "Somali", "Arabic", "Islamic", "Science", "Social"];
  Map<String, num> scoresMap = {};

  String studentSearchQuery = '';
  final TextEditingController _studentSearchController = TextEditingController();

  @override
  void dispose() {
    _studentSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // User (Arday/Waalid) uun baa ku bilaabanaya Student view-ka (Read-Only)
    if (isUserRole) {
      isTeacherView = false;
    } else {
      isTeacherView = true;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final students = await ApiService.getAllStudents(limit: 1000);
      setState(() {
        allStudents = students;
        dynamicClasses = students.map((s) => s.className).toSet().toList()..sort();
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterStudentsByClass(String className) {
    setState(() {
      selectedClass = className;
      studentSearchQuery = '';
      _studentSearchController.clear();
      filteredStudents = allStudents.where((s) => s.className == className).toList();
    });
  }

  Future<void> _fetchResults(int studentId) async {
    setState(() => isLoading = true);
    try {
      final results = await ApiService.getStudentResults(studentId);
      setState(() {
        currentStudentResults = results;
        scoresMap = {for (var s in subjects) s: 0};
        for (var res in results) {
          if (res['exam_type'] == selectedExamType && scoresMap.containsKey(res['subject'])) {
            scoresMap[res['subject']] = (res['score'] is num ? (res['score'] as num) : (num.tryParse(res['score']?.toString() ?? '0') ?? 0));
          }
        }
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  num _calculateCurrentExamTotal() {
    num total = 0;
    var filtered = currentStudentResults.where((res) => res['exam_type'] == selectedExamType);
    for (var res in filtered) {
      total += (res['score'] is num ? (res['score'] as num) : (num.tryParse(res['score']?.toString() ?? '0') ?? 0));
    }
    return total;
  }

  num _calculateGrandTotal() {
    num total = 0;
    for (var res in currentStudentResults) {
      total += (res['score'] is num ? (res['score'] as num) : (num.tryParse(res['score']?.toString() ?? '0') ?? 0));
    }
    return total;
  }

  // >>> FUNCTION-KA DAABACAADDA (QAABKA LANDSCAPE SHAHAADO - PHOTOSHOP STYLE) <<<
  Future<void> _printStudentResult() async {
    if (selectedStudent == null) return;

    final doc = pw.Document();
    var filteredResults = currentStudentResults.where((res) => res['exam_type'] == selectedExamType).toList();
    int maxPerSubject = examMaxMarks[selectedExamType] ?? 10;
    int examTotalMax = maxPerSubject * 7;
    num currentTotal = _calculateCurrentExamTotal();
    String currentTotalStr = (currentTotal % 1 == 0) ? currentTotal.toInt().toString() : currentTotal.toString();

    // Palette-ka Midabada rasmiga ah ee Premium-ka ah
    final PdfColor primaryColor = PdfColor.fromHex('#0F172A');   // Slate madow/buluug ah (Aad u modern ah)
    final PdfColor goldColor = PdfColor.fromHex('#B45309');      // Amber/Gold boqortooyo ah
    final PdfColor lightBg = PdfColor.fromHex('#F8FAFC');       // Background jilicsan
    final PdfColor tableRowEven = PdfColor.fromHex('#F1F5F9');  // Safarka dhexda ah ee shaxda

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20), 
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // 1. BACKGROUND WATERMARK (Photoshop Effect)
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.03,
                    child: pw.Text(
                      ApiService.currentTenantName ?? "ELITE SCHOOLS",
                      style: pw.TextStyle(fontSize: 100, fontWeight: pw.FontWeight.bold, color: primaryColor),
                    ),
                  ),
                ),
              ),

              // 2. QAABDHISMEEDKA GUDAHA EE WARQADDA
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: primaryColor, width: 3),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: goldColor, width: 1.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 35),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      
                      // HEADER-KA / MADAXA SHAHAADADA (FULLY CENTERED)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // Meel bannaan oo bidixda ah si qoraalka dhexe u dheelitirmo
                          pw.SizedBox(width: 100), 
                          
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center, 
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                          pw.Text( "SCHOOL EXAMINATION CENTER",
  style: pw.TextStyle(
    fontSize: 24, 
    fontWeight: pw.FontWeight.bold, 
    color: PdfColors.lightBlue, // Halkan waxaa lagu beddelay PdfColors.lightBlue
    letterSpacing: 0.5,
  ),
),
pw.SizedBox(height: 4),
pw.Container(height: 2, width: 220, color: goldColor),
pw.SizedBox(height: 5),
pw.Text(
" Tel: 063-4871966 // 063-4732311 // 063-4868156",
  style: pw.TextStyle(fontSize: 16,fontWeight: pw.FontWeight.bold, color: PdfColors.black),
),
pw.Text(
"Hargeisa-Somaliland.",
  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
),

                              ],
                            ),
                          ),
                          
                          // Badge-ka rasmiga ah ee midigta xiga
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            decoration: pw.BoxDecoration(
                              color: goldColor,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              "OFFICIAL REPORT",
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1),
                            ),
                          )
                        ],
                      ),
                      
                      pw.SizedBox(height: 20),

                      // MACLUUMAADKA ARDAYGA (STUDENT PROFILE CARD)
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: lightBg,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          border: pw.Border.all(color: PdfColors.grey200, width: 1),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(children: [
                                  pw.Text("Student Name:  ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor, fontSize: 20)),
                                  pw.Text(selectedStudent!.name, style: pw.TextStyle(fontSize: 19, color: PdfColors.grey800)),
                                ]),
                                pw.SizedBox(height: 6),
                                pw.Row(children: [
                                  pw.Text("Class Name:    ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor, fontSize: 20)),
                                  pw.Text(selectedStudent!.className, style: pw.TextStyle(fontSize: 24,fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                                ]),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(children: [
                                  pw.Text("Exam type:  ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor, fontSize: 12)),
                                  pw.Text(selectedExamType, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                                ]),
                                pw.SizedBox(height: 6),
                                pw.Row(children: [
                                  pw.Text("Date Issued: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor, fontSize: 12)),
                                  pw.Text("${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 16),

                      // SHAXDA NATIIJADA (MODERN & CLEAN TABLE)
                      pw.Table(
                        border: null,
                        children: [
                          // Table Header
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: primaryColor,
                              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
                            ),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15), 
                                child: pw.Text("SUBJECT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10, letterSpacing: 0.5)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15), 
                                child: pw.Center(child: pw.Text("MAX MARKS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10, letterSpacing: 0.5))),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15), 
                                child: pw.Center(child: pw.Text("SCORE OBTAINED", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10, letterSpacing: 0.5))),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15), 
                                child: pw.Center(child: pw.Text("STATUS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10, letterSpacing: 0.5))),
                              ),
                            ],
                          ),
                          // Table Body (Alternating Rows)
                          ...filteredResults.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var res = entry.value;
                            num score = (res['score'] is num ? (res['score'] as num) : (num.tryParse(res['score']?.toString() ?? '0') ?? 0));
                            String scoreStr = (score % 1 == 0) ? score.toInt().toString() : score.toString();
                            bool isPassed = score >= (maxPerSubject * 0.5);

                            return pw.TableRow(
                              decoration: pw.BoxDecoration(
                                color: idx % 2 == 0 ? PdfColors.white : tableRowEven,
                                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))
                              ),
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 15), 
                                  child: pw.Text(res['subject'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey800, fontSize: 10)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 15), 
                                  child: pw.Center(child: pw.Text("$maxPerSubject", style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10))),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 15), 
                                  child: pw.Center(
                                    child: pw.Text(
                                      scoreStr, 
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold, 
                                        color: isPassed ? PdfColors.green800 : PdfColors.red800,
                                      ),
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 15), 
                                  child: pw.Center(
                                    child: pw.Text(
                                      isPassed ? "Passed" : "Failed", 
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold, 
                                        color: isPassed ? PdfColors.green700 : PdfColors.red700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                      // TOTAL BADGE
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            "TOTAL SCORE:   $currentTotalStr / $examTotalMax",
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                      
                      pw.Spacer(),

                      // SIGNATURES SECTION
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(width: 150, height: 1, color: PdfColors.grey400),
                              pw.SizedBox(height: 5),
                              pw.Text("Class Teacher Sign..", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Container(width: 150, height: 1, color: PdfColors.grey400),
                              pw.SizedBox(height: 5),
                              pw.Text("Principal ", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await doc.save();
    final String filename = 'Shahaado_${selectedStudent!.name}_$selectedExamType.pdf';

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Dooro Habka Natiijada", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 15),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.download_rounded, color: Colors.blue, size: 24),
              ),
              title: const Text("Soo Dajiso PDF (Download to Mobile)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Faylka toos ugu kaydi taleefankaaga / gallery-ga"),
              onTap: () async {
                Navigator.pop(context);
                await Printing.sharePdf(bytes: pdfBytes, filename: filename);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.print_rounded, color: Colors.purple, size: 24),
              ),
              title: const Text("Daabac Warqadda (Print)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("U dir printer-ka ama eeg preview-ka"),
              onTap: () async {
                Navigator.pop(context);
                await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: filename);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetYearlyRecords() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ma hubtaa?"),
        content: const Text("Dhammaan xogta imtixaanada ee sannadkan waa la tirtiri doonaa. Action-kan dib looguma noqon karo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Jooji")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Halkan kaga tirtir"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => isLoading = true);
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dhammaan xogta imtixaanada waa la tirtiray!"), backgroundColor: Colors.orange),
        );
      } catch (e) {
        debugPrint("Error resetting: $e");
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Settings"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Max Marks per Exam:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...examMaxMarks.keys.map((type) {
                return ListTile(
                  title: Text(type),
                  trailing: SizedBox(
                    width: 50,
                    child: TextFormField(
                      initialValue: examMaxMarks[type].toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => examMaxMarks[type] = int.tryParse(val) ?? 0,
                    ),
                  ),
                );
              }).toList(),
              const Divider(),
              const Text("Yearly Maintenance:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _resetYearlyRecords();
                },
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                label: const Text("Reset All Exam Records"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double paddingVal = constraints.maxWidth < 600 ? 12.0 : 25.0;
          return Padding(
            padding: EdgeInsets.all(paddingVal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : _buildMainFlow()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainFlow() {
    if (selectedClass == null) return _buildClassGrid();
    if (selectedStudent == null) return _buildStudentList();
    // User-ka (Arday/Waalid) weligii Student view uun ayuu arki karaa (Read-Only)
    if (isUserRole) return _buildStudentView();
    return (isTeacherView) ? _buildGradeEntryForm() : _buildStudentView();
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Exam Management",
              style: TextStyle(
                fontSize: isMobile ? 20 : 35,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isUserRole) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, color: Colors.blueAccent, size: isMobile ? 14 : 18),
                        const SizedBox(width: 6),
                        Text(
                          "Natiijada (Read-Only)",
                          style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTeacherView) ...[
                        _buildUploadResultsButton(isCompact: isMobile),
                        SizedBox(width: isMobile ? 4 : 8),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.grey), 
                          onPressed: _showSettings
                        ),
                      ],
                      SizedBox(width: isMobile ? 4 : 10),
                      ToggleButtons(
                        isSelected: [isTeacherView, !isTeacherView],
                        onPressed: (index) => setState(() {
                          isTeacherView = index == 0;
                          selectedClass = null;
                          selectedStudent = null;
                        }),
                        borderRadius: BorderRadius.circular(10),
                        fillColor: Colors.black,
                        selectedColor: Colors.white,
                        children: [
                          Padding(padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20), child: const Text("Teacher")),
                          Padding(padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20), child: const Text("Student"))
                        ],
                      ),
                    ],
                  ),
                ],
                if (!isTeacherView && selectedStudent != null && selectedExamType == "Final Exam")
                   Container(
                     margin: const EdgeInsets.only(top: 8),
                     padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                     decoration: BoxDecoration(
                       color: Colors.green.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(10),
                       border: Border.all(color: Colors.green)
                     ),
                     child: Text(
                       " Total: ${_calculateGrandTotal() % 1 == 0 ? _calculateGrandTotal().toInt() : _calculateGrandTotal()} / 700",
                       style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                     ),
                   ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildClassGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 6;
    if (screenWidth < 600) {
      crossAxisCount = 2;
    } else if (screenWidth < 900) {
      crossAxisCount = 4;
    }
    final double optionsWidth = screenWidth > 500 ? 450 : screenWidth - 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Global Student Search bar across all classes
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Autocomplete<StudentModel>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.trim().isEmpty) {
                return const Iterable<StudentModel>.empty();
              }
              final query = textEditingValue.text.trim().toLowerCase();
              return allStudents.where((s) => s.name.toLowerCase().contains(query));
            },
            displayStringForOption: (StudentModel s) => s.name,
            onSelected: (StudentModel s) async {
              _filterStudentsByClass(s.className);
              if (isUserRole) {
                _studentLoginAccess(s);
              } else {
                int studentId = s.id ?? int.tryParse(s.idString) ?? 0;
                await _fetchResults(studentId);
                setState(() => selectedStudent = s);
              }
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: "Raadi arday kasta magaciisa (dugsiga oo dhan)...",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.person_search_rounded, color: Color(0xFF1E3A8A), size: 20),
                  suffixIcon: textEditingController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          onPressed: () => textEditingController.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 13),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: optionsWidth,
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF1E3A8A),
                            child: Icon(Icons.person, size: 16, color: Colors.white),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text("Fasalka: ${s.className}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          onTap: () => onSelected(s),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: screenWidth < 600 ? 1.4 : 1.0,
            ),
            itemCount: dynamicClasses.length,
            itemBuilder: (context, index) => InkWell(
              onTap: () => _filterStudentsByClass(dynamicClasses[index]),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF1B5E20)]),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  dynamicClasses[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth < 600 ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList() {
    final displayedStudents = studentSearchQuery.trim().isEmpty
        ? filteredStudents
        : filteredStudents.where((s) => s.name.toLowerCase().contains(studentSearchQuery.trim().toLowerCase())).toList();

    return Column(
      children: [
        Row(children: [
          IconButton(onPressed: () => setState(() {
            selectedClass = null;
            studentSearchQuery = '';
            _studentSearchController.clear();
          }), icon: const Icon(Icons.arrow_back_ios)),
          Text("Students $selectedClass", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Spacer(),
          if(isTeacherView && !isUserRole) ...[
            _buildUploadResultsButton(),
            const SizedBox(width: 8),
            _buildExamTypeDropdown(),
          ],
        ]),
        const SizedBox(height: 10),
        // Search bar for class student list
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: _studentSearchController,
            onChanged: (val) => setState(() => studentSearchQuery = val),
            decoration: InputDecoration(
              hintText: "Raadi magaca ardayga ($selectedClass)...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A), size: 20),
              suffixIcon: studentSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () {
                        _studentSearchController.clear();
                        setState(() => studentSearchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5)),
            ),
          ),
        ),
        Expanded(
          child: displayedStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        studentSearchQuery.isNotEmpty ? "Arday magacaas leh lama helin" : "Fasalkan arday kuma jiraan",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: displayedStudents.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(displayedStudents[index].name),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      if (isUserRole) {
                        _studentLoginAccess(displayedStudents[index]);
                      } else {
                        int studentId = displayedStudents[index].id ?? int.tryParse(displayedStudents[index].idString) ?? 0;
                        await _fetchResults(studentId);
                        setState(() => selectedStudent = displayedStudents[index]);
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildExamTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: DropdownButton<String>(
        value: selectedExamType,
        underline: const SizedBox(),
        items: examTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (val) => setState(() => selectedExamType = val!),
      ),
    );
  }

  Widget _buildGradeEntryForm() {
    int maxAllowed = examMaxMarks[selectedExamType] ?? 100;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => selectedStudent = null),
                icon: const Icon(Icons.arrow_back_ios),
              ),
              Column(
                children: [
                  Text(selectedStudent!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  Text("$selectedExamType - Max: $maxAllowed", style: const TextStyle(color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  List<Map<String, dynamic>> finalGrades = subjects.map((s) => {
                    "subject": s,
                    "score": scoresMap[s] ?? 0,
                    "exam_type": selectedExamType
                  }).toList();

                  int studentId = selectedStudent!.id ?? int.tryParse(selectedStudent!.idString) ?? 0;
                  bool success = await ApiService.saveExamination(
                    studentId,
                    selectedStudent!.name,
                    finalGrades,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Waa la kaydiyey"), backgroundColor: Colors.green),
                    );
                    setState(() => selectedStudent = null);
                  }
                },
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Kaydi"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              String subject = subjects[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(_getSubjectIcon(subject), color: Colors.indigo),
                  title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: SizedBox(
                    width: 70,
                    child: TextFormField(
                      key: Key("${selectedExamType}_$subject"),
                      initialValue: (scoresMap[subject] != null && scoresMap[subject]! % 1 == 0)
                          ? scoresMap[subject]!.toInt().toString()
                          : (scoresMap[subject]?.toString() ?? '0'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "0-$maxAllowed",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        num value = _BulkUploadDialogState._parseScore(val) ?? 0;
                        if (value > maxAllowed) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Dhibcuhu kama badan karaan $maxAllowed!"),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          scoresMap[subject] = 0; 
                        } else {
                          scoresMap[subject] = value;
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentView() {
    int maxPerSubject = examMaxMarks[selectedExamType] ?? 10;
    int examTotalMax = maxPerSubject * 7; 
    num currentTotalKept = _calculateCurrentExamTotal();

    List<Map<String, dynamic>> displaySubjectList = subjects.map((subj) {
      final match = currentStudentResults.firstWhere(
        (res) => res['exam_type'] == selectedExamType && res['subject'].toString().toLowerCase() == subj.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      bool hasRecord = match.isNotEmpty && match.containsKey('score') && match['score'] != null;
      num score = hasRecord ? ((match['score'] is num ? (match['score'] as num) : (num.tryParse(match['score']?.toString() ?? '0') ?? 0))) : 0;
      return {
        'subject': subj,
        'score': score,
        'hasRecord': hasRecord,
      };
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth < 900;
    final int crossAxisCount = isMobile ? 2 : (isTablet ? 4 : 7);

    return Column(
          children: [
            // Top Bar with Back button, Student info, Print button, and Total score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() => selectedStudent = null),
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.indigo, size: 20),
                              tooltip: "Ddib u noqo",
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedStudent!.name,
                                    style: TextStyle(
                                      fontSize: isMobile ? 15 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A237E),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Fasalka: ${selectedStudent!.className} | $selectedExamType",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // PRINT REPORT BUTTON (Rasmiga ah ee Daabacaadda)
                      ElevatedButton.icon(
                        onPressed: _printStudentResult,
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: Text(isMobile ? "Daabac PDF" : "Daabac Natiijada (PDF)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A11CB),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Total Score Badge with Dynamic Status Color
                  Builder(
                    builder: (context) {
                      double overallPct = examTotalMax > 0 ? (currentTotalKept / examTotalMax) : 0.0;
                      List<Color> totalGradColors;
                      if (overallPct >= 0.8) {
                        totalGradColors = [const Color(0xFF11998E), const Color(0xFF38EF7D)]; // Green
                      } else if (overallPct >= 0.5) {
                        totalGradColors = [const Color(0xFFF2994A), const Color(0xFFF2C94C)]; // Yellow / Amber
                      } else {
                        totalGradColors = [const Color(0xFFFF416C), const Color(0xFFFF4B2B)]; // Red
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: totalGradColors),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.military_tech_rounded, color: Colors.amber, size: 18),
                                SizedBox(width: 6),
                                Text("Wadarta Dhibcaha:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            Text(
                              "$currentTotalKept / $examTotalMax",
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Grid View of Subject Scores
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,          
                  crossAxisSpacing: 10,       
                  mainAxisSpacing: 10,
                  childAspectRatio: isMobile ? 1.0 : (isTablet ? 0.82 : 0.78),     
                ),
                itemCount: displaySubjectList.length,
                itemBuilder: (context, index) {
                  final res = displaySubjectList[index];
                  bool hasRecord = res['hasRecord'] as bool;
                  num score = (res['score'] is num ? (res['score'] as num) : (num.tryParse(res['score']?.toString() ?? '0') ?? 0));
                  String scoreDisplay = (score % 1 == 0) ? score.toInt().toString() : score.toString();
                  
                  Color statusColor;
                  String statusText;

                  if (!hasRecord || score == 0) {
                    statusColor = Colors.blueGrey;
                    statusText = "No exam";
                  } else {
                    double percentage = (score / maxPerSubject);
                    if (percentage >= 0.8) {
                      statusColor = Colors.green; 
                      statusText = "Baasey";
                    } else if (percentage >= 0.5) {
                      statusColor = Colors.amber.shade800; 
                      statusText = "Dhexdhexaad";
                    } else {
                      statusColor = Colors.red; 
                      statusText = "Dhacay";
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14), 
                      border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getSubjectIcon(res['subject']), color: statusColor, size: isMobile ? 18 : 22),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            res['subject'], 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13, color: const Color(0xFF1A237E)), 
                            overflow: TextOverflow.ellipsis, 
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(hasRecord ? scoreDisplay : "-", style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: statusColor)),
                                Text("/$maxPerSubject", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'math': return Icons.calculate;
      case 'english': return Icons.translate;
      case 'somali': return Icons.menu_book;
      case 'arabic': return Icons.history_edu;
      case 'islamic': return Icons.mosque;
      case 'science': return Icons.science;
      case 'social': return Icons.public;
      default: return Icons.book;
    }
  }

  void _showStudentResultPopupDialog(StudentModel student) {
    int maxPerSubject = examMaxMarks[selectedExamType] ?? 10;
    int examTotalMax = maxPerSubject * 7;
    num currentTotal = _calculateCurrentExamTotal();
    double percentage = examTotalMax > 0 ? (currentTotal / examTotalMax) : 0.0;

    Color primaryThemeColor;
    List<Color> gradientColors;
    IconData headerIcon;
    String statusTitle;
    String statusSubtitle;

    if (percentage >= 0.8) {
      primaryThemeColor = Colors.green.shade700;
      gradientColors = [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      headerIcon = Icons.emoji_events_rounded;
      statusTitle = "🎉 Hambalyo! Waad Baastey!";
      statusSubtitle = "Waxaad keentay darajo sare oo heer sare ah (Distinction)!";
    } else if (percentage >= 0.5) {
      primaryThemeColor = Colors.amber.shade900;
      gradientColors = [const Color(0xFFF2994A), const Color(0xFFF2C94C)];
      headerIcon = Icons.thumb_up_alt_rounded;
      statusTitle = "👏 Hambalyo! Waad Baastey!";
      statusSubtitle = "Imtixaanka si caadi ah ayaad u gudubtay (Passed).";
    } else {
      primaryThemeColor = Colors.red.shade700;
      gradientColors = [const Color(0xFFFF416C), const Color(0xFFFF4B2B)];
      headerIcon = Icons.sentiment_very_dissatisfied_rounded;
      statusTitle = "⚠️ Ka Xunnahey! Waad Dhacday!";
      statusSubtitle = "Natiijadaadu waxay ka hooseysaa 50%. Fadlan dadaal dheeraad ah samee.";
    }

    int percentInt = (percentage * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Badge with Icon
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: primaryThemeColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6)),
                  ],
                ),
                child: Icon(headerIcon, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              
              // Status Title
              Text(
                statusTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryThemeColor,
                ),
              ),
              const SizedBox(height: 6),
              
              Text(
                statusSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),

              // Student & Marks Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryThemeColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryThemeColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Fasalka: ${student.className} | $selectedExamType",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 20, thickness: 0.8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("Wadarta Dhibcaha", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              "${(currentTotal % 1 == 0) ? currentTotal.toInt() : currentTotal} / $examTotalMax",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryThemeColor),
                            ),
                          ],
                        ),
                        Container(height: 30, width: 1, color: Colors.grey.shade300),
                        Column(
                          children: [
                            const Text("Boqolkiiba (%)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              "$percentInt%",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryThemeColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // CLOSE / VIEW DETAILS BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: const Text(
                    "Eeg Natiijada Maadooyinka (Close)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryThemeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _studentLoginAccess(StudentModel student) {
    String inputId = "";
    showDialog(
      context: context,
      barrierDismissible: true, 
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Doorashada Imtixaanka & Code-ka", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Dooro Nooca Imtixaanka:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: selectedExamType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                items: examTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedExamType = val);
                    setState(() => selectedExamType = val);
                  }
                },
              ),
              const SizedBox(height: 15),
              const Text("Geli Code-ka (4 digits):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 5),
              TextField(
                maxLength: 4, 
                obscureText: true, 
                keyboardType: TextInputType.number,
                autofillHints: const [], 
                autocorrect: false, 
                enableSuggestions: false, 
                enableInteractiveSelection: false, 
                onChanged: (val) => inputId = val,
                decoration: InputDecoration(
                  hintText: "****",
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ka noqo", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                String lastFour = student.phone.length >= 4 ? student.phone.substring(student.phone.length - 4) : student.phone;
                if (lastFour == inputId) {
                  Navigator.pop(context);
                  int studentId = student.id ?? int.tryParse(student.idString) ?? 0;
                  await _fetchResults(studentId);
                  setState(() => selectedStudent = student);
                  if (mounted) {
                    _showStudentResultPopupDialog(student);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Code-ku waa khaldan yahay!"), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text("Xaqiiji"),
            ),
          ],
        ),
      ),
    );
  }

  // >>> BULK EXAM RESULTS UPLOAD (WORD DOCUMENT) <<<

  Widget _buildUploadResultsButton({bool isCompact = false}) {
    return ElevatedButton.icon(
      onPressed: _openBulkUploadDialog,
      icon: const Icon(Icons.upload_file_rounded, size: 16, color: Colors.white),
      label: Text(
        isCompact ? "Upload" : "Upload Results",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A8A), // Professional Deep Navy Blue
        foregroundColor: Colors.white,
        elevation: 1.5,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openBulkUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BulkUploadDialog(
        availableClasses: dynamicClasses,
        initialClass: selectedClass ?? (dynamicClasses.isNotEmpty ? dynamicClasses.first : null),
        allStudents: allStudents,
        examTypes: examTypes,
        selectedExamType: selectedExamType,
        examMaxMarks: examMaxMarks,
        subjects: subjects,
        onImportCompleted: (String? importedClass, String? savedExamType, int? firstStudentId) async {
          if (savedExamType != null && savedExamType.isNotEmpty) {
            selectedExamType = savedExamType;
          }
          await _loadInitialData();
          if (importedClass != null) {
            _filterStudentsByClass(importedClass);
          } else if (selectedClass != null) {
            _filterStudentsByClass(selectedClass!);
          }
          if (firstStudentId != null) {
            final matches = allStudents.where((s) => (s.id ?? int.tryParse(s.idString)) == firstStudentId).toList();
            if (matches.isNotEmpty) {
              selectedStudent = matches.first;
              await _fetchResults(firstStudentId);
            }
          } else if (selectedStudent != null) {
            int sId = selectedStudent!.id ?? int.tryParse(selectedStudent!.idString) ?? 0;
            await _fetchResults(sId);
          }
          setState(() {});
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BULK UPLOAD MODAL DIALOG & DOCX PARSER
// ─────────────────────────────────────────────────────────────────────────────

class _ExtractedRow {
  String docId;
  String docName;
  num? docTotal;
  StudentModel? matchedStudent;
  Map<String, num?> scores;
  Map<String, TextEditingController> scoreControllers;
  bool isDuplicate = false;

  _ExtractedRow({
    this.docId = '',
    required this.docName,
    this.docTotal,
    this.matchedStudent,
    Map<String, num?>? scores,
  })  : scores = scores ?? {},
        scoreControllers = {};

  void initControllers(List<String> subjects) {
    scoreControllers.clear();
    for (var s in subjects) {
      num? val = scores[s];
      String text = val == null
          ? ''
          : ((val % 1 == 0) ? val.toInt().toString() : val.toString());
      scoreControllers[s] = TextEditingController(text: text);
    }
  }

  void dispose() {
    for (var c in scoreControllers.values) {
      c.dispose();
    }
  }

  bool hasExceedingScore(num maxAllowed, List<String> subjects) {
    for (var s in subjects) {
      num? score = scores[s];
      if (score != null && (score < 0 || score > maxAllowed)) return true;
    }
    return false;
  }
}

class _BulkUploadDialog extends StatefulWidget {
  final List<String> availableClasses;
  final String? initialClass;
  final List<StudentModel> allStudents;
  final List<String> examTypes;
  final String selectedExamType;
  final Map<String, int> examMaxMarks;
  final List<String> subjects;
  final Future<void> Function(String? importedClass, String? savedExamType, int? firstStudentId) onImportCompleted;

  const _BulkUploadDialog({
    required this.availableClasses,
    required this.initialClass,
    required this.allStudents,
    required this.examTypes,
    required this.selectedExamType,
    required this.examMaxMarks,
    required this.subjects,
    required this.onImportCompleted,
  });

  @override
  State<_BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkUploadDialogState extends State<_BulkUploadDialog> {
  String? currentClass;
  late String currentExamType;
  String? uploadedFileName;
  bool isProcessingFile = false;
  bool isSaving = false;
  double saveProgress = 0.0;
  String saveProgressText = '';
  String? errorMessage;

  List<List<List<String>>> _extractedTables = [];
  final List<_ExtractedRow> _parsedRows = [];

  @override
  void initState() {
    super.initState();
    currentClass = widget.initialClass ?? (widget.availableClasses.isNotEmpty ? widget.availableClasses.first : null);
    currentExamType = widget.selectedExamType;
  }

  @override
  void dispose() {
    for (var r in _parsedRows) {
      r.dispose();
    }
    super.dispose();
  }

  num get maxAllowed => widget.examMaxMarks[currentExamType] ?? 100;

  static num? _parseScore(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == '-' ||
        trimmed == '—' ||
        trimmed == '/' ||
        trimmed.toLowerCase() == 'n/a' ||
        trimmed.toLowerCase() == 'abs' ||
        trimmed.toLowerCase() == 'none' ||
        trimmed.toLowerCase() == 'x') {
      return null;
    }
    String cleaned = trimmed.replaceAll(',', '.');
    final match = RegExp(r'[0-9]+(?:\.[0-9]+)?').firstMatch(cleaned);
    if (match != null) {
      num? parsed = num.tryParse(match.group(0)!);
      if (parsed != null) {
        return (parsed % 1 == 0) ? parsed.toInt() : parsed;
      }
    }
    return null;
  }

  List<StudentModel> get currentClassStudents {
    if (currentClass == null) return [];
    final target = currentClass!.trim().toLowerCase();
    return widget.allStudents.where((s) {
      final cName = s.className?.trim().toLowerCase() ?? '';
      return cName == target ||
             cName.replaceAll(' ', '') == target.replaceAll(' ', '');
    }).toList();
  }

  static String _cleanSomaliName(String name) {
    String s = name.toLowerCase().trim();
    // Expand prefixes before removing punctuation (e.g. c/raxmaan -> cabdiraxmaan, a.qani -> abdiqani)
    s = s.replaceAll(RegExp(r'\bc[/\.]([a-z])'), 'cabdi\$1');
    s = s.replaceAll(RegExp(r'\bc[/\.]\s+([a-z])'), 'cabdi\$1');
    s = s.replaceAll(RegExp(r'\ba[/\.]([a-z])'), 'abdi\$1');
    s = s.replaceAll(RegExp(r'\ba[/\.]\s+([a-z])'), 'abdi\$1');
    s = s.replaceAll(RegExp(r"['`’‘\-]"), ' ');
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String _canonicalSomaliToken(String token) {
    String t = token.toLowerCase().trim();
    if (t.isEmpty) return t;

    if (t.startsWith('cabdi')) {
      t = 'abdi${t.substring(5)}';
    } else if (t.startsWith('cabd')) {
      t = 'abd${t.substring(4)}';
    }

    if (t == 'cali' || t == 'ali') return 'ali';
    if (t == 'cumar' || t == 'omar' || t == 'umar' || t == 'omer') return 'omar';
    if (t == 'cismaan' || t == 'cusmaan' || t == 'osman' || t == 'usman') return 'osman';
    if (t == 'maxamed' || t == 'mohamed' || t == 'muhamed' || t == 'muhammed' || t == 'mohamud' || t == 'maxamuud' || t == 'mohamd') return 'mohamed';
    if (t == 'axmed' || t == 'ahmed') return 'ahmed';
    if (t == 'xasan' || t == 'hassan' || t == 'hasan') return 'hassan';
    if (t == 'xuseen' || t == 'hussein' || t == 'huseen') return 'hussein';
    if (t == 'jaamac' || t == 'jama') return 'jama';
    if (t == 'faarax' || t == 'farah') return 'farah';
    if (t == 'yuusuf' || t == 'yusuf') return 'yusuf';
    if (t == 'yaasiin' || t == 'yasin' || t == 'yasiin') return 'yasin';
    if (t == 'khadar' || t == 'qadar' || t == 'khader') return 'qadar';
    if (t == 'daahir' || t == 'dahir' || t == 'tahar') return 'dahir';
    if (t == 'ismaaciil' || t == 'ismail') return 'ismail';
    if (t == 'ibraahim' || t == 'ibrahim') return 'ibrahim';
    if (t == 'aadan' || t == 'adan' || t == 'adem' || t == 'aadem') return 'adan';
    if (t == 'saleebaan' || t == 'suleyman' || t == 'sulaymaan' || t == 'suleiman') return 'suleiman';
    if (t == 'deeq' || t == 'deeqo') return 'deeq';
    if (t == 'yaxye' || t == 'yahye') return 'yahye';
    if (t == 'mustafe' || t == 'mustafa' || t == 'mostafa' || t == 'mustapha') return 'mustafe';
    if (t == 'muxumed' || t == 'muxumad') return 'muxumed';
    if (t == 'mawliid' || t == 'mawlid' || t == 'mowliid') return 'mawlid';
    if (t == 'idriis' || t == 'idiris') return 'idris';
    if (t == 'sudaysi' || t == 'sudeysi') return 'sudaysi';
    if (t == 'muuse' || t == 'muse' || t == 'musa') return 'muse';
    if (t == 'mataan' || t == 'matan') return 'mataan';
    if (t == 'nuur' || t == 'nur') return 'nur';
    if (t == 'nasriin' || t == 'nasrin') return 'nasrin';
    if (t == 'haani' || t == 'hani') return 'hani';
    if (t == 'nimcaan' || t == 'nimcan') return 'nimcan';

    t = t.replaceAll('aa', 'a')
         .replaceAll('ee', 'e')
         .replaceAll('ii', 'i')
         .replaceAll('oo', 'o')
         .replaceAll('uu', 'u');

    t = t.replaceAll('x', 'h');
    t = t.replaceAll('c', '');

    return t;
  }

  static StudentModel? _findBestStudentMatch(
    String docName,
    String docId,
    List<StudentModel> classStudents,
  ) {
    if (classStudents.isEmpty) return null;

    if (docId.isNotEmpty) {
      for (final s in classStudents) {
        if ((s.id != null && s.id.toString() == docId) ||
            s.idString == docId ||
            s.stringId == docId) {
          return s;
        }
      }
    }

    final cleanDoc = _cleanSomaliName(docName);
    if (cleanDoc.isEmpty) return null;

    final exactMatches = classStudents.where((s) => _cleanSomaliName(s.name) == cleanDoc).toList();
    if (exactMatches.length == 1) {
      return exactMatches.first;
    }

    final docTokens = cleanDoc.split(' ').where((t) => t.isNotEmpty).toList();
    if (docTokens.isEmpty) return null;
    final docCanonical = docTokens.map(_canonicalSomaliToken).toList();

    StudentModel? bestCandidate;
    double bestScore = 0.0;
    int candidatesWithBestScore = 0;

    for (final student in classStudents) {
      final cleanDb = _cleanSomaliName(student.name);
      final dbTokens = cleanDb.split(' ').where((t) => t.isNotEmpty).toList();
      if (dbTokens.isEmpty) continue;
      final dbCanonical = dbTokens.map(_canonicalSomaliToken).toList();

      int matchCount = 0;
      bool firstNameMatches = (docCanonical.isNotEmpty &&
          dbCanonical.isNotEmpty &&
          docCanonical[0] == dbCanonical[0]);

      for (int i = 0; i < docCanonical.length; i++) {
        if (dbCanonical.contains(docCanonical[i])) {
          matchCount++;
        }
      }

      int positionMatches = 0;
      int minLen = docCanonical.length < dbCanonical.length ? docCanonical.length : dbCanonical.length;
      for (int i = 0; i < minLen; i++) {
        if (docCanonical[i] == dbCanonical[i]) {
          positionMatches++;
        }
      }

      double tokenScore = matchCount / (docCanonical.length > dbCanonical.length ? docCanonical.length : dbCanonical.length);
      double posScore = positionMatches / (minLen > 0 ? minLen : 1);
      double totalScore = (tokenScore * 0.6) + (posScore * 0.4);

      if (firstNameMatches) {
        totalScore += 0.25;
      }

      bool isSufficientMatch = false;
      if (matchCount >= 2 && firstNameMatches && totalScore >= 0.60) {
        isSufficientMatch = true;
      } else if (matchCount >= 3 && totalScore >= 0.60) {
        isSufficientMatch = true;
      } else if (docCanonical.length == 1 && matchCount == 1 && dbCanonical.length == 1) {
        isSufficientMatch = true;
      }

      if (isSufficientMatch) {
        if (totalScore > bestScore + 0.05) {
          bestScore = totalScore;
          bestCandidate = student;
          candidatesWithBestScore = 1;
        } else if ((totalScore - bestScore).abs() <= 0.05) {
          candidatesWithBestScore++;
        }
      }
    }

    if (candidatesWithBestScore > 1) {
      debugPrint('[BulkUpload] Ambiguous match for "$docName". Leaving for manual confirmation.');
      return null;
    }

    return bestCandidate;
  }

  void _checkDuplicates() {
    final seenIds = <int>{};
    for (var r in _parsedRows) {
      if (r.matchedStudent != null) {
        int id = r.matchedStudent!.id ?? int.tryParse(r.matchedStudent!.idString) ?? -1;
        if (id != -1 && seenIds.contains(id)) {
          r.isDuplicate = true;
        } else {
          r.isDuplicate = false;
          if (id != -1) seenIds.add(id);
        }
      } else {
        r.isDuplicate = false;
      }
    }
  }

  Future<void> _pickAndParseWordDoc() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['docx'],
      );

      if (file == null) return;

      Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes.isEmpty) {
        setState(() {
          errorMessage = "Faylka lama akhrin karo ama waa madhan yahay (Cannot read file).";
        });
        return;
      }

      setState(() {
        isProcessingFile = true;
        uploadedFileName = file.name;
        errorMessage = null;
      });

      // 1. Unzip .docx and find word/document.xml
      final archive = ZipDecoder().decodeBytes(bytes);
      ArchiveFile? docXmlFile;
      for (final f in archive) {
        if (f.name == 'word/document.xml') {
          docXmlFile = f;
          break;
        }
      }

      if (docXmlFile == null) {
        throw Exception("Faylku maaha Microsoft Word document (.docx) sax ah.");
      }

      final List<int> rawBytes = docXmlFile.content;
      final xmlString = utf8.decode(rawBytes, allowMalformed: true);

      // 2. Extract tables from Word XML
      final extractedTables = _extractTablesFromWordXml(xmlString);

      if (extractedTables.isEmpty) {
        throw Exception("Wax natiijo ama shax ah lagama helin dokumentiga Word-ka ah.");
      }

      _extractedTables = extractedTables;
      _processExtractedData();
    } catch (e) {
      setState(() {
        errorMessage = "Khalad: $e";
      });
    } finally {
      setState(() {
        isProcessingFile = false;
      });
    }
  }

  static String? _getXmlAttr(XmlElement el, String name) {
    for (final attr in el.attributes) {
      if (attr.name.local == name || attr.name.qualified == name) {
        return attr.value;
      }
    }
    return null;
  }

  List<List<List<String>>> _extractTablesFromWordXml(String xmlString) {
    List<List<List<String>>> tables = [];
    try {
      final doc = XmlDocument.parse(xmlString);
      final tblElements = doc.findAllElements('w:tbl').toList();
      for (final tbl in tblElements) {
        List<List<String>> tableRows = [];
        // Only direct child rows to prevent nested duplication
        for (final tr in tbl.children.whereType<XmlElement>().where((e) => e.name.local == 'tr')) {
          List<String> rowCells = [];
          for (final tc in tr.children.whereType<XmlElement>().where((e) => e.name.local == 'tc')) {
            int span = 1;
            for (final tcPr in tc.children.whereType<XmlElement>().where((e) => e.name.local == 'tcPr')) {
              for (final gs in tcPr.children.whereType<XmlElement>().where((e) => e.name.local == 'gridSpan')) {
                final v = _getXmlAttr(gs, 'val');
                if (v != null) span = int.tryParse(v) ?? 1;
              }
            }

            final textList = tc.findAllElements('w:t').map((t) => t.innerText).toList();
            String cellText = textList.join('').replaceAll('\u00A0', ' ').trim();
            rowCells.add(cellText);
            for (int k = 1; k < span; k++) {
              rowCells.add('');
            }
          }
          if (rowCells.any((c) => c.isNotEmpty)) {
            tableRows.add(rowCells);
          }
        }
        if (tableRows.isNotEmpty) {
          tables.add(tableRows);
        }
      }
    } catch (e) {
      debugPrint('[BulkUpload] XmlDocument parse fallback: $e');
    }

    if (tables.isEmpty) {
      final tblReg = RegExp(r'<w:tbl(?:\s+[^>]*)?>(.*?)</w:tbl>', dotAll: true);
      final trReg = RegExp(r'<w:tr(?:\s+[^>]*)?>(.*?)</w:tr>', dotAll: true);
      final tcReg = RegExp(r'<w:tc(?:\s+[^>]*)?>(.*?)</w:tc>', dotAll: true);
      final tReg = RegExp(r'<w:t(?:\s+[^>]*)?>(.*?)</w:t>', dotAll: true);
      final spanReg = RegExp(r'<w:gridSpan[^>]*(?:w:)?val="(\d+)"');

      for (final tblMatch in tblReg.allMatches(xmlString)) {
        final tblXml = tblMatch.group(1) ?? '';
        List<List<String>> tableRows = [];
        for (final trMatch in trReg.allMatches(tblXml)) {
          final trXml = trMatch.group(1) ?? '';
          List<String> rowCells = [];
          for (final tcMatch in tcReg.allMatches(trXml)) {
            final tcXml = tcMatch.group(1) ?? '';
            int span = 1;
            final spanMatch = spanReg.firstMatch(tcXml);
            if (spanMatch != null) {
              span = int.tryParse(spanMatch.group(1)!) ?? 1;
            }

            final sb = StringBuffer();
            for (final tMatch in tReg.allMatches(tcXml)) {
              sb.write(tMatch.group(1) ?? '');
            }
            final clean = sb.toString()
                .replaceAll('&amp;', '&')
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .replaceAll('&quot;', '"')
                .replaceAll('&apos;', "'")
                .replaceAll('\u00A0', ' ')
                .trim();
            rowCells.add(clean);
            for (int k = 1; k < span; k++) {
              rowCells.add('');
            }
          }
          if (rowCells.any((c) => c.isNotEmpty)) {
            tableRows.add(rowCells);
          }
        }
        if (tableRows.isNotEmpty) {
          tables.add(tableRows);
        }
      }
    }

    return tables;
  }

  void _processExtractedData() {
    if (_extractedTables.isEmpty) return;

    // 1. Dictionaries for accurate detection
    final Map<String, List<String>> subjectKeywords = {
      "Math": [
        "xis", "xisaab", "xisab", "math", "mathematics", "maths", "hisab", "hisaab", "matematik"
      ],
      "English": [
        "eng", "english", "ingiriisi", "ingiris", "ing", "english language"
      ],
      "Somali": [
        "som", "somali", "soomaali", "af-soomaali", "af soomaali", "afsoomaali", "somalia", "hooyo", "afka hooyo"
      ],
      "Arabic": [
        "carab", "carabi", "carabiga", "arabic", "arab", "af-carabi", "af carabi", "luqada carabiga", "al-carabiya", "luqad carabi"
      ],
      "Islamic": [
        "diin", "diinta", "tarbiya", "tarbiyo", "tarbiyad", "tarbiyah", "tarbiya islamiyah",
        "islamic", "islamic studies", "islaam", "islam", "tawxiid", "fiqi", "diin & tarbiya", "tarbiya & diin", "tarbiyada"
      ],
      "Science": [
        "say", "saynis", "sayniska", "science", "sci", "general science", "saynis guud", "sayniska guud"
      ],
      "Social": [
        "c/b", "cb", "c.b", "c b", "c/bulshada", "cilmiga bulshada", "cilmi bulsho",
        "social", "social studies", "social science", "soc studies", "soc science", "soc sci", "soc",
        "bulsho", "bulshada", "juqraafi", "taariikh", "tar & juq", "taariikh & juqraafi", "tar/juq", "juqraafiyad", "tarikh"
      ],
    };

    final totalKeywords = [
      "wadar", "wadarta", "total", "sum", "grand total", "natiijo"
    ];

    final nameKeywords = [
      "magaca", "magac", "name", "student", "student name", "arday", "ardayda", "full name", "magaca ardayga"
    ];

    final ignoreColKeywords = [
      "fasal", "class", "grade", "sno", "s/no", "no", "no.", "tirsiga", "tirsi", "#", "id", "student id", "code"
    ];

    final titleKeywords = [
      "dugsiga", "degmada", "gobolka", "jamhuuriyadda", "republic", "somaliland",
      "bile primary", "primary", "secondary", "school"
    ];

    // Auto-detect exam type from document if present
    for (final table in _extractedTables) {
      for (final row in table.take(3)) {
        final rowText = row.join(' ').toLowerCase();
        if (rowText.contains('monthly')) {
          currentExamType = "Monthly Exam";
          break;
        } else if (rowText.contains('term 1') || rowText.contains('term1')) {
          currentExamType = "Term 1";
          break;
        } else if (rowText.contains('pre-final') || rowText.contains('pre final')) {
          currentExamType = "Pre-Final";
          break;
        } else if (rowText.contains('final')) {
          currentExamType = "Final Exam";
          break;
        }
      }
    }

    // 2. Identify header row across tables (strictly ignoring title rows)
    List<String>? detectedHeaderRow;
    int? headerTableIdx;
    int? headerRowIdx;
    int bestHeaderScore = -1;

    for (int tIdx = 0; tIdx < _extractedTables.length; tIdx++) {
      final table = _extractedTables[tIdx];
      for (int r = 0; r < table.length && r < 10; r++) {
        final row = table[r];
        final rowText = row.join(' ').toLowerCase();

        // Must NOT be a title row
        if (titleKeywords.any((k) => rowText.contains(k))) continue;

        int score = 0;
        bool hasName = false;
        int subjectMatches = 0;

        for (final cell in row) {
          final lower = cell.toLowerCase().trim();
          final clean = lower.replaceAll(RegExp(r'[^a-z0-9\s/]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          if (clean.isEmpty) continue;

          if (nameKeywords.any((k) => clean == k || clean.contains(k))) {
            hasName = true;
            score += 5;
          }
          if (totalKeywords.any((k) => clean == k || clean == 'total')) {
            score += 2;
          }
          for (final entry in subjectKeywords.entries) {
            if (entry.value.any((k) => clean == k || lower == k || clean.split(' ').contains(k))) {
              subjectMatches++;
              score += 3;
              break;
            }
          }
        }

        if (hasName && subjectMatches >= 2 && score > bestHeaderScore) {
          bestHeaderScore = score;
          detectedHeaderRow = row;
          headerTableIdx = tIdx;
          headerRowIdx = r;
        }
      }
    }

    // Fallback if strict header not found
    if (detectedHeaderRow == null) {
      for (int tIdx = 0; tIdx < _extractedTables.length; tIdx++) {
        final table = _extractedTables[tIdx];
        for (int r = 0; r < table.length && r < 5; r++) {
          final row = table[r];
          int score = 0;
          for (final cell in row) {
            final lower = cell.toLowerCase().trim();
            for (final entry in subjectKeywords.entries) {
              if (entry.value.any((k) => lower == k || lower.contains(k))) score += 2;
            }
          }
          if (score > bestHeaderScore) {
            bestHeaderScore = score;
            detectedHeaderRow = row;
            headerTableIdx = tIdx;
            headerRowIdx = r;
          }
        }
      }
    }

    if (detectedHeaderRow == null) return;

    // 3. Map columns from detected header row
    int? nameColIdx;
    int? idColIdx;
    int? totalColIdx;
    Map<String, int> subjectColMap = {};

    for (int col = 0; col < detectedHeaderRow.length; col++) {
      final raw = detectedHeaderRow[col].trim();
      final lower = raw.toLowerCase();
      final clean = lower.replaceAll(RegExp(r'[^a-z0-9\s/]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

      if (clean.isEmpty) continue;

      // Check Wadarta / Total first so it is never confused with a subject
      if (totalKeywords.any((k) => clean == k || lower == k)) {
        totalColIdx = col;
        continue;
      }

      // Check Name
      if (nameColIdx == null && nameKeywords.any((k) => clean == k || lower == k || clean.contains(k))) {
        nameColIdx = col;
        continue;
      }

      // Check ID / Sno / Fasal to ignore as subjects
      if (ignoreColKeywords.any((k) => clean == k || lower == k)) {
        if (idColIdx == null && (clean == 'id' || clean.contains('student id'))) {
          idColIdx = col;
        }
        continue;
      }

      // Check Subjects
      for (final subj in ["Social", "Islamic", "Math", "English", "Somali", "Arabic", "Science"]) {
        if (!subjectColMap.containsKey(subj) && !subjectColMap.values.contains(col)) {
          final keywords = subjectKeywords[subj]!;
          bool isMatch = false;

          if (subj == "Science") {
            if (clean.contains("social") || clean.contains("c/b") || clean.contains("cb") || clean.contains("bulsho")) {
              continue;
            }
          }

          isMatch = keywords.any((k) => lower == k || clean == k || clean.split(' ').contains(k));
          if (isMatch) {
            subjectColMap[subj] = col;
            break;
          }
        }
      }
    }

    if (nameColIdx == null) {
      for (int c = 0; c < detectedHeaderRow.length; c++) {
        if (c != idColIdx && c != totalColIdx && !subjectColMap.values.contains(c)) {
          nameColIdx = c;
          break;
        }
      }
    }
    nameColIdx ??= 0;

    debugPrint('[BulkUpload] Mapped Header: Name=$nameColIdx, ID=$idColIdx, Total=$totalColIdx, Subjects=$subjectColMap');

    // 4. Extract data rows across all tables/pages
    final classStudents = currentClassStudents;
    for (var r in _parsedRows) {
      r.dispose();
    }
    _parsedRows.clear();

    for (int tIdx = 0; tIdx < _extractedTables.length; tIdx++) {
      final table = _extractedTables[tIdx];
      int startR = (tIdx == headerTableIdx) ? (headerRowIdx! + 1) : 0;

      for (int r = startR; r < table.length; r++) {
        final row = table[r];
        if (row.isEmpty || !row.any((c) => c.trim().isNotEmpty)) continue;

        String docName = (nameColIdx < row.length) ? row[nameColIdx].trim() : '';
        String docId = (idColIdx != null && idColIdx < row.length) ? row[idColIdx].trim() : '';
        String docTotalRaw = (totalColIdx != null && totalColIdx < row.length) ? row[totalColIdx].trim() : '';

        final normName = docName.toLowerCase().trim();
        if (normName.isEmpty) continue;

        // Skip headers or repeated headers across multi-page tables
        if (nameKeywords.any((k) => normName == k || normName.contains(k))) continue;
        if (ignoreColKeywords.any((k) => normName == k)) continue;
        if (titleKeywords.any((k) => normName.contains(k))) continue;
        if (totalKeywords.any((k) => normName == k || normName.startsWith(k))) continue;
        if (normName.contains('tirada ardayda') || normName.contains('signature') ||
            normName.contains('saxeex') || normName.contains('macallin') || normName.contains('teacher')) {
          continue;
        }

        // Extract scores for each subject
        Map<String, num?> scores = {};
        bool hasAtLeastOneNumericScore = false;
        for (final subj in widget.subjects) {
          if (subjectColMap.containsKey(subj)) {
            int colIdx = subjectColMap[subj]!;
            if (colIdx < row.length) {
              final parsed = _parseScore(row[colIdx]);
              scores[subj] = parsed;
              if (parsed != null) hasAtLeastOneNumericScore = true;
            } else {
              scores[subj] = null;
            }
          } else {
            scores[subj] = null;
          }
        }

        num? docTotal = _parseScore(docTotalRaw);

        // Filter out stray banner or non-student rows that lack scores
        if (!hasAtLeastOneNumericScore && docTotal == null) {
          if (normName.length < 3 || titleKeywords.any((k) => normName.contains(k))) continue;
        }

        StudentModel? matched = _findBestStudentMatch(docName, docId, classStudents);

        final extractedRow = _ExtractedRow(
          docId: docId,
          docName: docName,
          docTotal: docTotal,
          matchedStudent: matched,
          scores: scores,
        );
        extractedRow.initControllers(widget.subjects);
        _parsedRows.add(extractedRow);
      }
    }

    _checkDuplicates();
  }

  Future<void> _confirmAndSave() async {
    if (_parsedRows.isEmpty) {
      _showSnack("Fadlan marka hore soo geli faylka Word-ka ah (.docx)", isError: true);
      return;
    }

    final exceedingRows = _parsedRows.where((r) => r.hasExceedingScore(maxAllowed, widget.subjects)).toList();
    if (exceedingRows.isNotEmpty) {
      _showSnack("Digniin: ${exceedingRows.length} arday dhibcahoodu waxay ka badan yihiin xadka $maxAllowed! Fadlan sax intaadan kaydin.", isError: true);
      return;
    }

    final duplicateRows = _parsedRows.where((r) => r.isDuplicate).toList();
    if (duplicateRows.isNotEmpty) {
      _showSnack("Digniin: Waxaa jira arday laba jeer ku celis ah. Fadlan sax ardayda isku beegantay.", isError: true);
      return;
    }

    final validRows = _parsedRows.where((r) => r.matchedStudent != null).toList();
    if (validRows.isEmpty) {
      _showSnack("Ma jiro hal arday oo ku beegmay fasalka $currentClass. Fadlan gacanta ku beeg ardayda.", isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.security, color: Color(0xFF1E3A8A)),
            SizedBox(width: 10),
            Text("Xaqiijinta Kaydinta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ma hubtaa inaad rabto inaad kaydiso natiijooyinka ${validRows.length} arday?"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Fasalka: $currentClass\nImtixaanka: $currentExamType (Xadka ugu sarreeya: $maxAllowed)\nHaddii ardaygu hore natiijo u lahaa waa la cusboonaysiin doonaa (Overwrite).",
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Ka noqo", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Haa, Kaydi"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isSaving = true;
      saveProgress = 0.0;
      saveProgressText = "Bilaabaya kaydinta...";
    });

    int successCount = 0;
    int failedCount = 0;

    for (int i = 0; i < validRows.length; i++) {
      final row = validRows[i];
      setState(() {
        saveProgress = (i + 1) / validRows.length;
        saveProgressText = "Waxaa la kaydinayaa (${i + 1}/${validRows.length}): ${row.matchedStudent!.name}...";
      });

      // Import only marks that actually exist for that student!
      // If a subject was blank/missing, do not force 0 or save it.
      final List<Map<String, dynamic>> grades = [];
      for (final subj in widget.subjects) {
        final score = row.scores[subj];
        if (score != null) {
          grades.add({
            "subject": subj,
            "score": score,
            "exam_type": currentExamType,
          });
        }
      }

      if (grades.isEmpty) {
        continue;
      }

      int studentId = row.matchedStudent!.id ?? int.tryParse(row.matchedStudent!.idString) ?? 0;
      bool ok = await ApiService.saveExamination(
        studentId,
        row.matchedStudent!.name,
        grades,
      );

      if (ok) {
        successCount++;
      } else {
        failedCount++;
      }
    }

    setState(() {
      isSaving = false;
    });

    int? firstSavedStudentId = validRows.isNotEmpty
        ? (validRows.first.matchedStudent!.id ?? int.tryParse(validRows.first.matchedStudent!.idString))
        : null;

    await widget.onImportCompleted(currentClass, currentExamType, firstSavedStudentId);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Guul: $successCount arday natiijadooda imtixaanka ($currentExamType) si toos ah ayaa loo kaydiyey!${failedCount > 0 ? ' ($failedCount lama kaydin karin)' : ''}",
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final totalCount = _parsedRows.length;
    final matchedCount = _parsedRows.where((r) => r.matchedStudent != null).length;
    final unmatchedCount = _parsedRows.where((r) => r.matchedStudent == null).length;
    final exceedingCount = _parsedRows.where((r) => r.hasExceedingScore(maxAllowed, widget.subjects)).length;
    final duplicateCount = _parsedRows.where((r) => r.isDuplicate).length;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 30, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 750),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description, color: Color(0xFF1E3A8A), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Bulk Exam Results Upload",
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  ".DOCX",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Soo geli shaxda natiijooyinka ardayda oo dhan adigoo isticmaalaya faylka Word-ka",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 2. CONTROLS BAR (Class, Exam Type, File Picker)
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Class Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: currentClass,
                      underline: const SizedBox(),
                      hint: const Text("Dooro Fasalka"),
                      items: widget.availableClasses.map((c) => DropdownMenuItem(value: c, child: Text("Fasalka: $c"))).toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              setState(() {
                                currentClass = val;
                                _processExtractedData();
                              });
                            },
                    ),
                  ),

                  // Exam Type Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: currentExamType,
                      underline: const SizedBox(),
                      items: widget.examTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text("$t (Max: ${widget.examMaxMarks[t] ?? 100})")))
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              setState(() {
                                currentExamType = val!;
                              });
                            },
                    ),
                  ),

                  // File Picker Button
                  ElevatedButton.icon(
                    onPressed: isSaving || isProcessingFile ? null : _pickAndParseWordDoc,
                    icon: isProcessingFile
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      uploadedFileName == null ? "Dooro Faylka Word (.docx)" : "Beddel Faylka",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  if (uploadedFileName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              uploadedFileName!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMessage!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              // 3. STATS SUMMARY BADGES
              if (totalCount > 0) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildSummaryBadge("Ardayda Word-ka: $totalCount", Colors.blueGrey, Icons.people_outline),
                    _buildSummaryBadge("Isku Beegmay: $matchedCount", Colors.green, Icons.check_circle_outline),
                    if (unmatchedCount > 0)
                      _buildSummaryBadge("Lama Helin: $unmatchedCount", Colors.orange, Icons.warning_amber_rounded),
                    if (exceedingCount > 0)
                      _buildSummaryBadge("Dhibco Dheer: $exceedingCount (Max: $maxAllowed)", Colors.red, Icons.error_outline),
                    if (duplicateCount > 0)
                      _buildSummaryBadge("Ku-celis: $duplicateCount", Colors.red, Icons.content_copy),
                  ],
                ),
              ],

              // 4. PREVIEW TABLE OR EMPTY STATE
              const SizedBox(height: 12),
              Expanded(
                child: totalCount == 0
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.drive_folder_upload, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              "Fadlan dooro faylka Word-ka (.docx) ee natiijooyinka fasalka",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Dokumentigu waa inuu leeyahay shax ay ku jiraan magacyada iyo dhibcaha maadooyinka.",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: isMobile ? 850 : 1000),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 14,
                                  headingRowHeight: 42,
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 52,
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                                  columns: [
                                    const DataColumn(label: Text("#", style: TextStyle(fontWeight: FontWeight.bold))),
                                    const DataColumn(label: Text("Magaca (Word Doc)", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("Ardayga Database-ka ($currentClass)", style: const TextStyle(fontWeight: FontWeight.bold))),
                                    ...widget.subjects.map((s) => DataColumn(
                                      label: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    )),
                                    const DataColumn(label: Text("Wadar (Word)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
                                     const DataColumn(label: Text("Tirtir", style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _parsedRows.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final row = entry.value;
                                    final isMatched = row.matchedStudent != null;
                                    final hasExceeding = row.hasExceedingScore(maxAllowed, widget.subjects);

                                    return DataRow(
                                      color: WidgetStateProperty.all(
                                        row.isDuplicate
                                            ? Colors.red.shade50
                                            : hasExceeding
                                                ? Colors.amber.shade50
                                                : (!isMatched ? Colors.orange.shade50.withOpacity(0.4) : Colors.white),
                                      ),
                                      cells: [
                                        DataCell(Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold))),
                                        // Doc Name & ID
                                        DataCell(
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(row.docName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              if (row.docId.isNotEmpty)
                                                Text("ID: ${row.docId}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                            ],
                                          ),
                                        ),
                                        // Matched Database Student Cell (Interactive Selector)
                                        DataCell(
                                          isMatched
                                              ? Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: Colors.green.shade400, width: 1),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        row.matchedStudent!.name,
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade800),
                                                      ),
                                                      PopupMenuButton<StudentModel>(
                                                        icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.green),
                                                        tooltip: "Beddel ardayga",
                                                        onSelected: (selected) {
                                                          setState(() {
                                                            row.matchedStudent = selected;
                                                            _checkDuplicates();
                                                          });
                                                        },
                                                        itemBuilder: (ctx) => currentClassStudents.map((s) => PopupMenuItem(
                                                          value: s,
                                                          child: Text(s.name, style: const TextStyle(fontSize: 13)),
                                                        )).toList(),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: Colors.orange.shade400, width: 1),
                                                  ),
                                                  child: DropdownButton<StudentModel>(
                                                    isDense: true,
                                                    underline: const SizedBox(),
                                                    hint: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                                                        SizedBox(width: 4),
                                                        Text("Dooro Ardayga", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                                                      ],
                                                    ),
                                                    items: currentClassStudents.map((s) => DropdownMenuItem(
                                                      value: s,
                                                      child: Text(s.name, style: const TextStyle(fontSize: 12)),
                                                    )).toList(),
                                                    onChanged: (selected) {
                                                      setState(() {
                                                        row.matchedStudent = selected;
                                                        _checkDuplicates();
                                                      });
                                                    },
                                                  ),
                                                ),
                                        ),
                                        // Subject Score Cells (Editable & Validated)
                                        ...widget.subjects.map((subj) {
                                          num? score = row.scores[subj];
                                          bool isOver = score != null && (score < 0 || score > maxAllowed);

                                          return DataCell(
                                            SizedBox(
                                              width: 52,
                                              height: 34,
                                              child: TextFormField(
                                                controller: row.scoreControllers[subj],
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isOver ? Colors.red : Colors.black87,
                                                ),
                                                decoration: InputDecoration(
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                                  filled: true,
                                                  fillColor: isOver
                                                      ? Colors.red.shade50
                                                      : (score == null ? Colors.amber.shade50.withOpacity(0.3) : Colors.grey.shade100),
                                                  hintText: "-",
                                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                    borderSide: BorderSide(
                                                      color: isOver ? Colors.red : Colors.grey.shade300,
                                                      width: isOver ? 1.5 : 1,
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                    borderSide: BorderSide(
                                                      color: isOver ? Colors.red : const Color(0xFF1E3A8A),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                onChanged: (val) {
                                                  setState(() {
                                                    row.scores[subj] = _parseScore(val);
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        }),
                                        // Wadar (Word Total) Cell
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2)),
                                            ),
                                            child: Text(
                                              row.docTotal != null
                                                  ? ((row.docTotal! % 1 == 0) ? row.docTotal!.toInt().toString() : row.docTotal!.toString())
                                                  : '-',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Delete / Exclude row
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            tooltip: "Ka saar liiska",
                                            onPressed: () {
                                              setState(() {
                                                row.dispose();
                                                _parsedRows.removeAt(index);
                                                _checkDuplicates();
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),

              // 5. FOOTER & SAVE ACTION
              const SizedBox(height: 12),
              if (isSaving) ...[
                LinearProgressIndicator(value: saveProgress, color: const Color(0xFF1E3A8A)),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    saveProgressText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: const Text("Ka noqo (Cancel)", style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton.icon(
                    onPressed: (isSaving || matchedCount == 0 || exceedingCount > 0 || duplicateCount > 0)
                        ? null
                        : _confirmAndSave,
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_alt_rounded, size: 18),
                    label: Text(
                      isSaving
                          ? "Waxaa la kaydinayaa..."
                          : "Xaqiiji & Kaydi ($matchedCount Arday)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
