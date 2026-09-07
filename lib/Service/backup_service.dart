// lib/Service/backup_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'api_service.dart';
import '../models/student_model.dart';
import '../models/bus_model.dart';

class BackupService {
  /// Fetches all tenant-scoped data and packages it into an isolated JSON backup payload
  static Future<Map<String, dynamic>> fetchSchoolBackupData(int tenantId, String tenantName) async {
    final int? previousTenantId = ApiService.currentTenantId;
    final String? previousTenantName = ApiService.currentTenantName;

    try {
      // Temporarily set active tenant ID for scoped requests
      ApiService.currentTenantId = tenantId;
      ApiService.currentTenantName = tenantName;

      final results = await Future.wait([
        ApiService.getAllStudents(),
        ApiService.getAllTeachers(),
        ApiService.getAllBuses(),
        ApiService.getAllExpenses(),
        ApiService.getAllIncomes(),
        ApiService.getAllUsers(),
      ]);

      final studentsList = (results[0] as List<StudentModel>).map((s) => s.toJson()).toList();
      final teachersList = results[1] as List<Map<String, String>>;
      final busesList = (results[2] as List<Bus>).map((b) => b.toJson()).toList();
      final expensesList = results[3] as List<Map<String, dynamic>>;
      final incomesList = results[4] as List<Map<String, dynamic>>;
      final usersList = results[5] as List<Map<String, dynamic>>;

      final Map<String, dynamic> backupPayload = {
        "system": "SmartSchool Multi-Tenant Backup System",
        "version": "1.0.0",
        "exported_at": DateTime.now().toIso8601String(),
        "tenant_id": tenantId,
        "tenant_name": tenantName,
        "summary": {
          "total_students": studentsList.length,
          "total_teachers": teachersList.length,
          "total_buses": busesList.length,
          "total_expenses": expensesList.length,
          "total_incomes": incomesList.length,
          "total_users": usersList.length,
        },
        "data": {
          "students": studentsList,
          "teachers": teachersList,
          "buses": busesList,
          "expenses": expensesList,
          "incomes": incomesList,
          "users": usersList,
        }
      };

      return backupPayload;
    } catch (e) {
      log("Error fetching school backup data for tenant $tenantId: $e");
      rethrow;
    } finally {
      // Always restore original tenant context
      ApiService.currentTenantId = previousTenantId;
      ApiService.currentTenantName = previousTenantName;
    }
  }

  /// Triggers browser file download of the backup payload
  static void downloadBackupFile(Map<String, dynamic> backupData, String tenantName) {
    final String jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
    final String sanitizedName = tenantName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final String dateStr = DateTime.now().toIso8601String().split('T').first;
    final String fileName = "SmartSchool_Backup_${sanitizedName}_$dateStr.json";

    if (kIsWeb) {
      try {
        final bytes = utf8.encode(jsonStr);
        final blob = html.Blob([bytes], 'application/json');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } catch (e) {
        log("Error triggering web download for backup file: $e");
      }
    }
  }

  /// Restores data from JSON payload into the specified school's tenant space
  static Future<bool> restoreSchoolBackup(int tenantId, String tenantName, Map<String, dynamic> backupData) async {
    final int? previousTenantId = ApiService.currentTenantId;
    final String? previousTenantName = ApiService.currentTenantName;

    try {
      ApiService.currentTenantId = tenantId;
      ApiService.currentTenantName = tenantName;

      final dataMap = backupData['data'] as Map<String, dynamic>?;
      if (dataMap == null) return false;

      // Restore Students
      if (dataMap['students'] is List) {
        final students = dataMap['students'] as List;
        for (var s in students) {
          try {
            await ApiService.registerStudent(StudentModel.fromJson(Map<String, dynamic>.from(s)));
          } catch (_) {}
        }
      }

      // Restore Teachers
      if (dataMap['teachers'] is List) {
        final teachers = dataMap['teachers'] as List;
        for (var t in teachers) {
          try {
            await ApiService.registerTeacher(Map<String, String>.from(t));
          } catch (_) {}
        }
      }

      // Restore Buses
      if (dataMap['buses'] is List) {
        final buses = dataMap['buses'] as List;
        for (var b in buses) {
          try {
            await ApiService.registerBus(Bus.fromJson(Map<String, dynamic>.from(b)));
          } catch (_) {}
        }
      }

      // Restore Expenses
      if (dataMap['expenses'] is List) {
        final expenses = dataMap['expenses'] as List;
        for (var e in expenses) {
          try {
            await ApiService.addExpense(Map<String, dynamic>.from(e));
          } catch (_) {}
        }
      }

      // Restore Incomes
      if (dataMap['incomes'] is List) {
        final incomes = dataMap['incomes'] as List;
        for (var inc in incomes) {
          try {
            await ApiService.addIncome(Map<String, dynamic>.from(inc));
          } catch (_) {}
        }
      }

      // Restore Users
      if (dataMap['users'] is List) {
        final users = dataMap['users'] as List;
        for (var u in users) {
          try {
            await ApiService.createUser(Map<String, dynamic>.from(u));
          } catch (_) {}
        }
      }

      return true;
    } catch (e) {
      log("Error restoring school backup: $e");
      return false;
    } finally {
      ApiService.currentTenantId = previousTenantId;
      ApiService.currentTenantName = previousTenantName;
    }
  }
}
