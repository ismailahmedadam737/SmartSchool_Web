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

      // 1. Isku day DELETE REST standard
      try {
        final deleteResponse = await http.delete(
          Uri.parse("$expenseUrl/$idStr"),
          headers: _headers,
        );
        debugPrint("DELETE $expenseUrl/$idStr -> ${deleteResponse.statusCode}: ${deleteResponse.body}");
        if (deleteResponse.statusCode == 200 || deleteResponse.statusCode == 204) {
          return true;
        }
      } catch (_) {
        debugPrint("⚠️ DELETE failed (CORS), trying POST fallback...");
      }

      // 2. Fallback: POST /delete/:id (Flutter Web browser CORS workaround)
      final postResponse = await http.post(
        Uri.parse("$expenseUrl/delete/$idStr"),
        headers: _headers,
      );
      debugPrint("POST $expenseUrl/delete/$idStr -> ${postResponse.statusCode}: ${postResponse.body}");
      return postResponse.statusCode == 200 || postResponse.statusCode == 204;

    } catch (e) {
      debugPrint("❌ Error in deleteExpense: $e");
      return false;
    }
  }
}