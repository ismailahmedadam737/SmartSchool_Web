import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ExpenseService {
  static const String expenseUrl = "https://smartschool-web.onrender.com/api/expenses";
  static const Map<String, String> _headers = {"Content-Type": "application/json"};

  static Future<List<Map<String, dynamic>>> getAllExpenses() async {
    try {
      final response = await http.get(Uri.parse(expenseUrl), headers: _headers);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded['expenses'] is List) {
          return List<Map<String, dynamic>>.from(decoded['expenses']);
        } else if (decoded is Map && decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addExpense(Map<String, dynamic> expense) async {
    try {
      final response = await http.post(Uri.parse(expenseUrl), headers: _headers, body: jsonEncode(expense));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> deleteExpense(dynamic id) async {
    if (id == null || id.toString().isEmpty) {
      debugPrint("❌ deleteExpense: ID is null or empty");
      return false;
    }
    try {
      final String idStr = id.toString().trim();
      debugPrint("🔄 Deleting expense with ID: $idStr");

      // 1. Standard REST DELETE: /api/expenses/:id
      var response = await http.delete(Uri.parse("$expenseUrl/$idStr"), headers: _headers);
      debugPrint("DELETE $expenseUrl/$idStr -> ${response.statusCode}: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 201) {
        return true;
      }

      // 2. Custom route DELETE: /api/expenses/delete/:id (used in students/teachers)
      response = await http.delete(Uri.parse("$expenseUrl/delete/$idStr"), headers: _headers);
      debugPrint("DELETE $expenseUrl/delete/$idStr -> ${response.statusCode}: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 201) {
        return true;
      }

      // 3. POST route: /api/expenses/delete/:id
      response = await http.post(Uri.parse("$expenseUrl/delete/$idStr"), headers: _headers);
      debugPrint("POST $expenseUrl/delete/$idStr -> ${response.statusCode}: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 201) {
        return true;
      }

      // 4. POST body route: /api/expenses/delete
      response = await http.post(
        Uri.parse("$expenseUrl/delete"),
        headers: _headers,
        body: jsonEncode({"id": idStr, "_id": idStr}),
      );
      debugPrint("POST $expenseUrl/delete (body) -> ${response.statusCode}: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("❌ Error in deleteExpense: $e");
      return false;
    }
  }
}