import 'dart:convert';
import 'package:http/http.dart' as http;

class FinanceModel {
  final String baseUrl = "http://localhost:5000/api/finance";

  // GET finance by class
  Future<List<dynamic>> getFinanceByClass(String className) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$className"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception("Failed to load finance data");
    }
  }

  // ADD finance record
  Future<bool> addFinance({
    required String studentName,
    required String className,
    required double paidAmount,
    required double totalAmount,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "student_name": studentName,
        "class_name": className,
        "paid_amount": paidAmount,
        "total_amount": totalAmount,
      }),
    );

    return response.statusCode == 200;
  }

  // UPDATE payment
  Future<bool> updatePayment(int id, double paidAmount) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "paid_amount": paidAmount,
      }),
    );

    return response.statusCode == 200;
  }
}