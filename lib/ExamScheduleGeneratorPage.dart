import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExamScheduleGeneratorPage extends StatefulWidget {
  const ExamScheduleGeneratorPage({super.key});

  @override
  State<ExamScheduleGeneratorPage> createState() => _ExamScheduleGeneratorPageState();
}

class _ExamScheduleGeneratorPageState extends State<ExamScheduleGeneratorPage> {
  bool _showForm = false;
  String _selectedLevel = 'Lower Primary';
  final _schoolNameController = TextEditingController();
  final List<TextEditingController> _subjectControllers = List.generate(7, (_) => TextEditingController());
  final List<TextEditingController> _dateControllers = List.generate(7, (_) => TextEditingController());
  final List<String> _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  Future<void> _selectDate(BuildContext context, int index) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF004D40))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateControllers[index].text = DateFormat('dd/MM/yyyy').format(picked));
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final PdfColor gold = PdfColor.fromHex("#D4AF37");

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: gold, width: 4)),
          child: pw.Column(children: [
            // Qaybta Magaca Iskuulka iyo Level-ka oo Center ah
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 20),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    _schoolNameController.text.toUpperCase(),
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: pw.BoxDecoration(color: gold, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
                    child: pw.Text(
                      _selectedLevel.toUpperCase(),
                      style: pw.TextStyle(fontSize: 18, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            // Jadwalka
            pw.Table.fromTextArray(
              headers: ["DAY", "SUBJECT", "DATE"],
              data: List.generate(7, (i) => [_days[i], _subjectControllers[i].text, _dateControllers[i].text]),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 14),
              border: pw.TableBorder.all(color: gold, width: 0.5),
            ),
            pw.Spacer(),
            pw.Text("Kani waa jadwalka rasmi ah ee imtixaanka Final-ka.", 
              style: pw.TextStyle(color: PdfColors.grey700, fontStyle: pw.FontStyle.italic))
          ]),
        );
      },
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _showForm ? _buildForm() : _buildWelcomeScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.picture_as_pdf, size: 100, color: Color(0xFF004D40)),
      const Text("Exam Schedule", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), padding: const EdgeInsets.all(20)),
        onPressed: () => setState(() => _showForm = true),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("CREATE NEW SCHEDULE", style: TextStyle(color: Colors.white)),
      ),
    ]);
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(children: [
            Row(children: [
              IconButton(onPressed: () => setState(() => _showForm = false), icon: const Icon(Icons.arrow_back)),
              const Text("Design Schedule", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
            const Divider(),
            TextField(controller: _schoolNameController, decoration: const InputDecoration(labelText: "School Name", prefixIcon: Icon(Icons.school))),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: _selectedLevel,
              items: ['Lower Primary', 'Upper Primary'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _selectedLevel = v!),
              decoration: const InputDecoration(labelText: "Level"),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 7,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(children: [
                  SizedBox(width: 80, child: Text(_days[i], style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: TextField(controller: _subjectControllers[i], decoration: const InputDecoration(hintText: "Subject", border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  SizedBox(width: 130, child: TextField(controller: _dateControllers[i], readOnly: true, onTap: () => _selectDate(context, i), decoration: const InputDecoration(hintText: "Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today, size: 18)))),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)), onPressed: _generatePdf, child: const Text("GENERATE & PRINT PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            )
          ]),
        ),
      ),
    );
  }
}