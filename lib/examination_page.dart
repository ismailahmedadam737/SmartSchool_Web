import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/api_service.dart';
import '../models/student_model.dart';

// Packages-ka daabacaadda iyo PDF-ka
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExaminationPage extends StatefulWidget {
  const ExaminationPage({super.key});

  @override
  State<ExaminationPage> createState() => _ExaminationPageState();
}

class _ExaminationPageState extends State<ExaminationPage> {
  bool isTeacherView = true;
  String? selectedClass;
  StudentModel? selectedStudent;
  
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Shahaado_${selectedStudent!.name}_$selectedExamType',
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
    return isTeacherView ? _buildGradeEntryForm() : _buildStudentView();
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
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 15, mainAxisSpacing: 15),
      itemCount: dynamicClasses.length,
      itemBuilder: (context, index) => InkWell(
        onTap: () => _filterStudentsByClass(dynamicClasses[index]),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF1B5E20)]),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(dynamicClasses[index], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ),
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
                if (isTeacherView) {
                  await _fetchResults(filteredStudents[index].id!);
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

                  bool success = await ApiService.saveExamination(
                    selectedStudent!.id!,
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
    var filteredResults = currentStudentResults.where((res) => res['exam_type'] == selectedExamType).toList();
    int maxPerSubject = examMaxMarks[selectedExamType] ?? 10;
    int examTotalMax = maxPerSubject * 7; 
    int currentTotalKept = _calculateCurrentExamTotal();

    if (filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Wax imtixaan ah lama soo galin", style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => setState(() => selectedStudent = null), child: const Text("Back"))
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(onPressed: () => setState(() => selectedStudent = null), icon: const Icon(Icons.arrow_back_ios)),
          Column(
            children: [
              Text(selectedStudent!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(selectedExamType, style: const TextStyle(fontSize: 16, color: Colors.indigo)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.indigo, size: 28),
            onPressed: _printStudentResult, 
          ),
        ]),
        
        const SizedBox(height: 10),
        
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15)),
          child: Text(
            "Wadarta: $currentTotalKept / $examTotalMax",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 15),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,          
              crossAxisSpacing: 10,       
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,     
            ),
            itemCount: filteredResults.length,
            itemBuilder: (context, index) {
              final res = filteredResults[index];
              int score = res['score'] ?? 0;
              
              Color statusColor;
              double percentage = (score / maxPerSubject);

              if (percentage >= 0.8) {
                statusColor = Colors.green; 
              } else if (percentage >= 0.5) {
                statusColor = Colors.orange; 
              } else {
                statusColor = Colors.red; 
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15), 
                  border: Border(top: BorderSide(color: statusColor, width: 5)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getSubjectIcon(res['subject']), color: statusColor.withOpacity(0.7), size: 20),
                    const SizedBox(height: 4),
                    Text(
                      res['subject'], 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                      overflow: TextOverflow.ellipsis, 
                    ),
                    const SizedBox(height: 2),
                    Text("$score", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor)), 
                  ],
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
                  await _fetchResults(student.id!);
                  setState(() => selectedStudent = student);
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