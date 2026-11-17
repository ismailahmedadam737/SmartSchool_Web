import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Si loo isticmaalo debugPrint

class PaymentApiService {
  static const String baseUrl = 'https://smartschool-web.onrender.com/api'; 

  // Global In-Memory Caches for super-fast instant rendering (0ms delay)
  static Map<int, double> cachedPaidByStudentId = {};
  static Map<int, double> cachedDebtByStudentId = {};
  static Map<String, double> cachedPaidByName = {};
  static Map<String, double> cachedDebtByName = {};
  static DateTime? _lastFetchTime;

  // Single unified method to fetch all payments and update caches in 1 fast call
  static Future<void> syncAllPayments({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inSeconds < 45 &&
        cachedPaidByStudentId.isNotEmpty) {
      return;
    }

    try {
      final list = await getAllPayments();
      if (list.isEmpty) return;
      final Map<int, double> pMap = {};
      final Map<int, double> dMap = {};
      final Map<String, double> pNameMap = {};
      final Map<String, double> dNameMap = {};

      for (var p in list) {
        int sId = int.tryParse(p['student_id']?.toString() ?? '0') ?? 0;
        String sName = (p['student_name'] ?? '').toString().trim();
        double amt = double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
        double dbt = double.tryParse(p['debt']?.toString() ?? '0') ?? 0.0;

        if (sId != 0) {
          pMap[sId] = (pMap[sId] ?? 0.0) + amt;
          dMap[sId] = (dMap[sId] ?? 0.0) + dbt;
        }
        if (sName.isNotEmpty) {
          pNameMap[sName] = (pNameMap[sName] ?? 0.0) + amt;
          dNameMap[sName] = (dNameMap[sName] ?? 0.0) + dbt;
        }
      }

      cachedPaidByStudentId = pMap;
      cachedDebtByStudentId = dMap;
      cachedPaidByName = pNameMap;
      cachedDebtByName = dNameMap;
      _lastFetchTime = DateTime.now();
    } catch (e) {
      debugPrint("syncAllPayments note: $e");
    }
  }

  static Future<Map<String, dynamic>> addPayment({
    required int studentId,
    required double amount,
    required double debt,
    required String month,
    required String transport,
  }) async {
    // Update local cache immediately so UI reflects payment instantly (0ms delay)
    cachedPaidByStudentId[studentId] = (cachedPaidByStudentId[studentId] ?? 0.0) + amount;
    cachedDebtByStudentId[studentId] = debt;

    final response = await http.post(
      Uri.parse('$baseUrl/payments/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "student_id": studentId, 
        "amount": amount,
        "debt": debt,
        "month": month,
        "transport": transport,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint("Server Error Body: ${response.body}");
      throw Exception('Failed to add payment: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> getPaymentsByStudent(int studentId) async {
    final response = await http.get(Uri.parse('$baseUrl/payments/history/$studentId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load payments');
    }
  }

  static Future<double> getTotalIncome() async {
    final response = await http.get(Uri.parse('$baseUrl/payments/total-income'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return double.tryParse(data['total_income'].toString()) ?? 0.0;
    } else {
      throw Exception('Failed to load total income');
    }
  }

  static Future<double> getTotalExpenses() async {
    final response = await http.get(Uri.parse('$baseUrl/expenses/total-expenses'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return double.tryParse(data['total_expenses'].toString()) ?? 0.0;
    } else {
      throw Exception('Failed to load total expenses');
    }
  }

  // Method-kan ayaa soo celinaya dhammaan lacag bixinta ardayda oo dhan halmar
  static Future<List<dynamic>> getAllPayments() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/payments/all'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
    } catch (_) {}
    return [];
  }

  // Method-kan ayaa tirtiraya dhammaan lacagaha server-ka marka Reset All la riixo
  static Future<void> resetAllPayments() async {
    // Clear in-memory caches instantly
    cachedPaidByStudentId.clear();
    cachedDebtByStudentId.clear();
    cachedPaidByName.clear();
    cachedDebtByName.clear();
    _lastFetchTime = null;

    final response = await http.delete(
      Uri.parse('$baseUrl/payments/reset-all'), 
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      debugPrint("Server Error Body: ${response.body}");
      throw Exception('Failed to reset payments: ${response.statusCode}');
    }
  }
}