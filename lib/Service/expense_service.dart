import 'dart:convert';
import 'package:http/http.dart' as http;

class ExpenseService {
  static const String expenseUrl = "ttps://smartschool-web.onrender.com/api/api/expenses";
  static const Map<String, String> _headers = {"Content-Type": "application/json"};

  static Future<List<Map<String, dynamic>>> getAllExpenses() async {
    try {
      final response = await http.get(Uri.parse(expenseUrl), headers: _headers);
      return response.statusCode == 200 ? List<Map<String, dynamic>>.from(jsonDecode(response.body)) : [];
    } catch (e) { return []; }
  }

  static Future<bool> addExpense(Map<String, dynamic> expense) async {
    try {
      final response = await http.post(Uri.parse(expenseUrl), headers: _headers, body: jsonEncode(expense));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> deleteExpense(int id) async {
    try {
      final response = await http.delete(Uri.parse("$expenseUrl/$id"), headers: _headers);
      return response.statusCode == 200;
    } catch (e) { return false; }
  }
}