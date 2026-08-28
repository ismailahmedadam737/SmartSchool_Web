import 'package:flutter/material.dart';
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
  Map<String, int> scoresMap = {};

  @override
  void initState() {
    super.initState();
    if (isUserRole) {
      isTeacherView = false;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final students = await ApiService.getAllStudents();
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
            scoresMap[res['subject']] = res['score'] ?? 0;
          }
        }
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  int _calculateCurrentExamTotal() {
    int total = 0;
    var filtered = currentStudentResults.where((res) => res['exam_type'] == selectedExamType);
    for (var res in filtered) {
      total += (res['score'] as int? ?? 0);
    }
    return total;
  }

  int _calculateGrandTotal() {
    int total = 0;
    for (var res in currentStudentResults) {
      total += (res['score'] as int? ?? 0);
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
    int currentTotal = _calculateCurrentExamTotal();

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
                      "IFTIINSHE",
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
                          pw.Text( "IFTIINSHE EXAMINATION CENTER",
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
                            int score = res['score'] ?? 0;
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
                                      "$score", 
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
                            "TOTAL SCORE:   $currentTotal / $examTotalMax",
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
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : _buildMainFlow()),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFlow() {
    if (selectedClass == null) return _buildClassGrid();
    if (selectedStudent == null) return _buildStudentList();
    return (isTeacherView && !isUserRole) ? _buildGradeEntryForm() : _buildStudentView();
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Exam Management", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.red)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isUserRole) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.blueAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Student Results (Read-Only)",
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  if (isTeacherView) 
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.grey), 
                      onPressed: _showSettings
                    ),
                  const SizedBox(width: 10),
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
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Teacher")),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Student"))
                    ],
                  ),
                ],
              ),
            ],
            if (!isTeacherView && selectedStudent != null && selectedExamType == "Final Exam")
               Container(
                 margin: const EdgeInsets.only(top: 10),
                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                 decoration: BoxDecoration(
                   color: Colors.green.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(10),
                   border: Border.all(color: Colors.green)
                 ),
                 child: Text(
                   " Total: ${_calculateGrandTotal()} / 700",
                   style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                 ),
               ),
          ],
        ),
      ],
    );
  }

  Widget _buildClassGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 6;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 4;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: constraints.maxWidth < 600 ? 1.4 : 1.0,
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
                  fontSize: constraints.maxWidth < 600 ? 18 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentList() {
    return Column(
      children: [
        Row(children: [
          IconButton(onPressed: () => setState(() => selectedClass = null), icon: const Icon(Icons.arrow_back_ios)),
          Text("Students $selectedClass", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Spacer(),
          if(isTeacherView) _buildExamTypeDropdown(),
        ]),
        Expanded(
          child: ListView.builder(
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(filteredStudents[index].name),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                int studentId = filteredStudents[index].id ?? int.tryParse(filteredStudents[index].idString) ?? 0;
                if (isTeacherView) {
                  await _fetchResults(studentId);
                  setState(() => selectedStudent = filteredStudents[index]);
                } else {
                  _studentLoginAccess(filteredStudents[index]);
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
                      initialValue: (scoresMap[subject] ?? 0).toString(),
                      keyboardType: TextInputType.number,
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
                        int value = int.tryParse(val) ?? 0;
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
    int currentTotalKept = _calculateCurrentExamTotal();

    List<Map<String, dynamic>> displaySubjectList = subjects.map((subj) {
      final match = currentStudentResults.firstWhere(
        (res) => res['exam_type'] == selectedExamType && res['subject'].toString().toLowerCase() == subj.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      bool hasRecord = match.isNotEmpty && match.containsKey('score') && match['score'] != null;
      int score = hasRecord ? (match['score'] as int? ?? 0) : 0;
      return {
        'subject': subj,
        'score': score,
        'hasRecord': hasRecord,
      };
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet = constraints.maxWidth < 900;
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
                  int score = res['score'] as int;
                  
                  Color statusColor;
                  String statusText;

                  if (!hasRecord) {
                    statusColor = Colors.blueGrey;
                    statusText = "Ma galin";
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
                                Text(hasRecord ? "$score" : "-", style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: statusColor)),
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
      },
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
    int currentTotal = _calculateCurrentExamTotal();
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
                              "$currentTotal / $examTotalMax",
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
          title: const Text("Enter Code"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Exam Type:"),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedExamType,
                items: examTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setDialogState(() => selectedExamType = val!),
              ),
              const SizedBox(height: 15),
              TextField(
                maxLength: 4, 
                obscureText: true, 
                keyboardType: TextInputType.number,
                autofillHints: const [], 
                autocorrect: false, 
                enableSuggestions: false, 
                enableInteractiveSelection: false, 
                onChanged: (val) => inputId = val,
                decoration: const InputDecoration(
                  hintText: "****",
                  counterText: "", 
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
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
              child: const Text("Enter password"),
            )
          ],
        ),
      ),
    );
  }
}