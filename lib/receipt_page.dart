import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iftiinshe/Service/payment_api_service.dart'; // Isticmaal PaymentApiService
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReceiptPage extends StatefulWidget {
  final int studentId;
  final String name;
  final double paid;
  final double dept;

  const ReceiptPage({
    super.key,
    required this.studentId,
    required this.name,
    required this.paid,
    required this.dept,
  });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final GlobalKey _printKey = GlobalKey();
  String selectedPayment = "Zaad";
  late String receiptNumber;

  @override
  void initState() {
    super.initState();
    receiptNumber = (Random().nextInt(90000) + 10000).toString();
  }

  static const Color receiptBlue = Color(0xFF005477);
  static const Color inkBlue = Color(0xFF0D47A1);

  String _convertAmountToWords(double amount) {
    if (amount == 0) return "Zero Dollars";
    final units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    final tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
    int val = amount.toInt();
    String words = "";
    if (val >= 100) {
      words += "${units[val ~/ 100]} Hundred ";
      val %= 100;
    }
    if (val >= 20) {
      words += "${tens[val ~/ 10]} ";
      if (val % 10 > 0) words += "${units[val % 10]} ";
    } else if (val >= 1) {
      words += "${units[val]} ";
    }
    return "${words.trim()} Dollars ";
  }

  Future<void> _saveToDatabase() async {
    String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    try {
      // Isticmaalka PaymentApiService sida aad codsatay
      await PaymentApiService.addPayment(
        studentId: widget.studentId,
        amount: widget.paid,
        debt: widget.dept,
        month: currentMonth,
        transport: "No Bus", // Waxaad bedeli kartaa haddii loo baahdo
      );
      debugPrint("✅ Receipt saved successfully!");
    } catch (e) {
      debugPrint("❌ Failed to save receipt: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _printReceipt() async {
    try {
      await _saveToDatabase();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _printKey.currentContext == null) return;
      
      final boundary = _printKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30), 
          build: (pw.Context context) => pw.Center(
            child: pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.contain),
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Receipt_${widget.name}.pdf');
    } catch (e) {
      debugPrint("Print Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      floatingActionButton: FloatingActionButton(
        backgroundColor: receiptBlue,
        onPressed: _printReceipt,
        child: const Icon(Icons.print, color: Colors.white),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: RepaintBoundary(
                key: _printKey,
                child: Container(
                  padding: const EdgeInsets.all(25), 
                  width: 650, 
                  height: 550,
                  color: Colors.white, 
                  child: _buildReceiptContent(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: receiptBlue),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptContent() {
    String currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: receiptBlue, width: 2), 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: receiptBlue, width: 1), 
          borderRadius: BorderRadius.circular(10)
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildContactAndDate(currentDate, receiptNumber),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: receiptBlue, width: 2.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildDashedLineInput("Customer Name:", widget.name),
                        const SizedBox(height: 10),
                        _buildAmountRow(),
                        const SizedBox(height: 12),
                        _buildPaymentMethods(),
                        const SizedBox(height: 12),
                        _buildDashedLineInput("In Words:", _convertAmountToWords(widget.paid)),
                        _buildDashedLineInput("Description:", "School Fee Payment"),
                        _buildDashedLineInput("Remaining Dept:", "\$${widget.dept.toStringAsFixed(2)}"),
                        const Spacer(),
                        _buildSignatures(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Qaybaha kale ee UI-ga (Header, Input, iwm) way ku jiraan sidii aad hore u soo dirtay.
  // Code-kan kor ku xusan wuxuu xallinayaa dhibaatadii API-ga.
  
  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: receiptBlue, width: 2.5), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: const [
            Text("IFTIINSHE PRIMARY AND KG SCHOOLS", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: receiptBlue)),
            Text("Tel: 063-7758927 // 063-4869775 Zaad: 510624", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF004677))),
          ],
        ));

  Widget _buildContactAndDate(String date, String no) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLabelValue("Date:", date),
          const Text("LACAG QABASHO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: receiptBlue)),
          _buildLabelValue("No:", no),
        ],
      );

  Widget _buildPaymentMethods() => Row(children: [_buildSelectableBox("By Zaad", "Zaad"), const SizedBox(width: 20), _buildSelectableBox("By e-Dahab", "e-Dahab"), const SizedBox(width: 20), _buildSelectableBox("By Cash", "Cash")]);

  Widget _buildSelectableBox(String label, String value) {
    bool isSelected = selectedPayment == value;
    return GestureDetector(
        onTap: () => setState(() => selectedPayment = value),
        child: Row(children: [Text(label, style: const TextStyle(color: receiptBlue, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 5), Container(width: 38, height: 22, decoration: BoxDecoration(border: Border.all(color: receiptBlue), borderRadius: BorderRadius.circular(4), color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent), child: isSelected ? const Icon(Icons.check, size: 16, color: inkBlue) : null)]));
  }

  Widget _buildDashedLineInput(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(label, style: const TextStyle(color: receiptBlue, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 5), Expanded(child: Stack(children: [const Positioned(bottom: 2, child: Text("........................................................................................................", style: TextStyle(color: Colors.grey, fontSize: 10))), Padding(padding: const EdgeInsets.only(left: 8, bottom: 2), child: Text(value, style: const TextStyle(color: inkBlue, fontSize: 15, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)))]))]));

  Widget _buildAmountRow() => Row(children: [const Text("The Amount Of US", style: TextStyle(color: receiptBlue, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(width: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5), decoration: BoxDecoration(border: Border.all(color: receiptBlue, width: 1.5), borderRadius: BorderRadius.circular(6)), child: Text("\$ ${widget.paid.toStringAsFixed(2)}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: inkBlue)))]);

  Widget _buildSignatures() => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildSignatureLine("Cashier Sign:"), _buildSignatureLine("Received Sign:")]));

  Widget _buildSignatureLine(String label) => Column(children: [const SizedBox(width: 110, child: Divider(color: Colors.black, thickness: 1.2)), Text(label, style: const TextStyle(color: receiptBlue, fontWeight: FontWeight.bold, fontSize: 11))]);

  Widget _buildLabelValue(String label, String value) => Row(children: [Text(label, style: const TextStyle(color: receiptBlue, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(width: 5), Text(value, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15))]);
}