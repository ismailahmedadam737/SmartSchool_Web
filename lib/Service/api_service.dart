import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; 
import '../models/student_model.dart';
import '../models/bus_model.dart';

class ApiService {
  static const String baseUrl = "https://smartschool-web.onrender.com/api/students";
  static const String teacherUrl = "https://smartschool-web.onrender.com/api/teachers";
  static const String attendanceUrl = "https://smartschool-web.onrender.com/api/attendance";
  static const String busUrl = "https://smartschool-web.onrender.com/api/buses";
  static const String examUrl = "https://smartschool-web.onrender.com/api/exam";
  static const String expenseUrl = "https://smartschool-web.onrender.com/api/expenses";
  static const String incomeUrl = "https://smartschool-web.onrender.com/api/incomes";
  static const String userUrl = "https://smartschool-web.onrender.com/api/users";
  static const String aiUrl = "https://smartschool-web.onrender.com/api/query";

  static const Map<String, String> _headers = {
    "Content-Type": "application/json",
    "Cache-Control": "no-cache",
  };

  static Future<String> askAI(String question) async {
    try {
      final response = await http.post(Uri.parse(aiUrl), headers: _headers, body: jsonEncode({"question": question}));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      }
      return "Khalad: Server-ku wuxuu soo celiyay ${response.statusCode}";
    } catch (e) {
      log("❌ AI Query Error: $e");
      return "Waan ka xumahay, awood uma lihi inaan jawaab soo saaro hadda.";
    }
  }

  // PAGINATION READY - Waxa kaliya ee aan ku daray waa page iyo limit
  static Future<List<StudentModel>> getAllStudents({int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/all?page=$page&limit=$limit"), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => StudentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> registerStudent(StudentModel student) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/register"), headers: {"Content-Type": "application/json"}, body: jsonEncode(student.toJson()));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      log("❌ Register Student Error: $e");
      return false;
    }
  }

  static Future<List<String>> getAllClasses() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/classes/all"), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((c) => c['class_name'].toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getStudentsByClass(String className) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/class/$className"), headers: _headers);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteStudent(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/delete/$id"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> submitAttendance(List<Map<String, dynamic>> students, String className, String month, String date) async {
    try {
      final response = await http.post(Uri.parse("$attendanceUrl/submit"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"students": students, "class_name": className, "month": month, "date": date}));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getDailyReport(String className, String date) async {
    try {
      final response = await http.get(Uri.parse("$attendanceUrl/report/daily?class_name=$className&date=$date"), headers: _headers);
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> registerTeacher(Map<String, String> teacher) async {
    try {
      final response = await http.post(Uri.parse("$teacherUrl/register"), headers: {"Content-Type": "application/json"}, body: jsonEncode(teacher));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, String>>> getAllTeachers() async {
    try {
      final response = await http.get(Uri.parse("$teacherUrl/all"), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => {"id": json['id'].toString(), "name": json['name'].toString(), "district": json['district'].toString(), "phone": json['phone'].toString(), "exp": json['experience']?.toString() ?? json['exp']?.toString() ?? "", "level": json['level'].toString()}).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateTeacher(String id, Map<String, String> teacher) async {
    try {
      final response = await http.put(Uri.parse("$teacherUrl/update/$id"), headers: {"Content-Type": "application/json"}, body: jsonEncode(teacher));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteTeacher(String id) async {
    try {
      final response = await http.delete(Uri.parse("$teacherUrl/delete/$id"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> registerBus(Bus bus) async {
    try {
      final response = await http.post(Uri.parse("$busUrl/register"), headers: {"Content-Type": "application/json"}, body: jsonEncode(bus.toJson()));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Bus>> getAllBuses() async {
    try {
      final response = await http.get(Uri.parse("$busUrl/all"), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Bus.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateBus(int id, Bus bus) async {
    try {
      final response = await http.put(Uri.parse("$busUrl/update/$id"), headers: {"Content-Type": "application/json"}, body: jsonEncode(bus.toJson()));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteBus(int id) async {
    try {
      final response = await http.delete(Uri.parse("$busUrl/delete/$id"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> saveExamination(int studentId, String studentName, List<Map<String, dynamic>> grades) async {
    try {
      final response = await http.post(Uri.parse("$examUrl/save"), headers: _headers, body: jsonEncode({"student_id": studentId, "student_name": studentName, "grades": grades}));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentResults(int studentId) async {
    try {
      final response = await http.get(Uri.parse("$examUrl/student/$studentId"), headers: _headers);
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteAllExamRecords() async {
    try {
      final response = await http.delete(Uri.parse("$examUrl/reset"), headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse(userUrl), headers: _headers);
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> createUser(Map<String, dynamic> user) async {
    try {
      final response = await http.post(Uri.parse(userUrl), headers: _headers, body: jsonEncode(user));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateUser(String id, Map<String, dynamic> user) async {
    try {
      final response = await http.put(Uri.parse("$userUrl/$id"), headers: _headers, body: jsonEncode(user));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(Uri.parse("$userUrl/$id"), headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllExpenses() async {
    try {
      final response = await http.get(Uri.parse(expenseUrl), headers: _headers);
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addExpense(Map<String, dynamic> expense) async {
    try {
      final response = await http.post(Uri.parse(expenseUrl), headers: _headers, body: jsonEncode(expense));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateExpenseStatus(int id, bool isPaid) async {
    try {
      final response = await http.put(Uri.parse("$expenseUrl/$id"), headers: _headers, body: jsonEncode({"is_paid": isPaid}));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<int>> getPaidStudentIds(String month) async {
    try {
      final response = await http.get(Uri.parse("$incomeUrl/paid-ids?month=$month"), headers: _headers);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((id) => int.parse(id.toString())).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addIncome(Map<String, dynamic> income) async {
    try {
      final response = await http.post(Uri.parse(incomeUrl), headers: _headers, body: jsonEncode(income));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllIncomes() async {
    try {
      final response = await http.get(Uri.parse(incomeUrl), headers: _headers);
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final results = await Future.wait([getAllStudents(), getAllTeachers(), getAllClasses(), getAllIncomes()]);
      final studentsList = results[0] as List;
      final teachersList = results[1] as List;
      final classesList = results[2] as List;
      final incomesList = results[3] as List<Map<String, dynamic>>;
      double totalRevenue = 0.0;
      for (var income in incomesList) {
        totalRevenue += double.tryParse(income['amount']?.toString() ?? '0') ?? 0.0;
      }
      return {"totalStudents": studentsList.length, "totalTeachers": teachersList.length, "totalClasses": classesList.length, "totalRevenue": totalRevenue};
    } catch (e) {
      return {"totalStudents": 0, "totalTeachers": 0, "totalClasses": 0, "totalRevenue": 0.0};
    }
  }
}