import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentApiService {
  static const String baseUrl = 'http://localhost:5000/api'; 

  // 1. Habka loo diro lacagta
  static Future<Map<String, dynamic>> addPayment({
    required int studentId,
    required double amount,
    required double debt,
    required String month,
    required String transport,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "studentId": studentId,
        "amount": amount,
        "debt": debt,
        "month": month,
        "transport": transport,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add payment: ${response.statusCode}');
    }
  }

  // 2. Habka loo soo akhrinayo lacagaha ardayga
  static Future<List<dynamic>> getPaymentsByStudent(int studentId) async {
    final response = await http.get(Uri.parse('$baseUrl/payments/history/$studentId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load payments');
    }
  }

  // 3. Habka loo soo celinayo wadarta guud ee Income
  static Future<double> getTotalIncome() async {
    final response = await http.get(Uri.parse('$baseUrl/payments/total-income'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Waxaan isticmaalnay 'total_income' si waafaqsan server-kaaga
      return double.tryParse(data['total_income'].toString()) ?? 0.0;
    } else {
      throw Exception('Failed to load total income');
    }
  }

  // 4. Habka loo soo celinayo wadarta guud ee Expenses
  static Future<double> getTotalExpenses() async {
    final response = await http.get(Uri.parse('$baseUrl/expenses/total-expenses'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Waxaan isticmaalnay 'total_expenses' si waafaqsan server-kaaga
      return double.tryParse(data['total_expenses'].toString()) ?? 0.0;
    } else {
      throw Exception('Failed to load total expenses');
    }
  }
}