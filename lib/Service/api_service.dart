import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
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

  static const Map<String, String> _headers = {
    "Content-Type": "application/json",
  };

  static final List<StudentModel> _localStudents = [];
  static final List<Map<String, String>> _localTeachers = [];
  static final List<Bus> _localBuses = [];

  static void saveStorage(String key, String data) => _saveToStorage(key, data);
  static String? readStorage(String key) => _readFromStorage(key);

  static void _saveToStorage(String key, String data) {
    if (kIsWeb) {
      try {
        html.window.localStorage[key] = data;
      } catch (e) {
        log("LocalStorage write error: $e");
      }
    }
  }

  static String? _readFromStorage(String key) {
    if (kIsWeb) {
      try {
        return html.window.localStorage[key];
      } catch (e) {
        log("LocalStorage read error: $e");
      }
    }
    return null;
  }

  static Future<List<StudentModel>> getAllStudents({int page = 1, int limit = 20}) async {
    List<StudentModel> results = [];
    try {
      final response = await http.get(Uri.parse("$baseUrl/all?page=$page&limit=$limit"), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        results = data.map((json) => StudentModel.fromJson(json)).toList();
      }
    } catch (e) {
      log("Error fetching remote students: $e");
    }

    String? stored = _readFromStorage('local_students');
    if (stored != null && stored.isNotEmpty) {
      try {
        List<dynamic> list = jsonDecode(stored);
        for (var item in list) {
          StudentModel st = StudentModel.fromJson(item);
          bool exists = results.any((r) => r.name == st.name && r.phone == st.phone);
          if (!exists) {
            results.insert(0, st);
          }
        }
      } catch (_) {}
    }

    for (var st in _localStudents) {
      bool exists = results.any((r) => r.name == st.name && r.phone == st.phone);
      if (!exists) {
        results.insert(0, st);
      }
    }

    return results;
  }

  static Future<bool> registerStudent(StudentModel student) async {
    _localStudents.removeWhere((s) => s.name == student.name && s.phone == student.phone);
    _localStudents.insert(0, student);

    List<Map<String, dynamic>> currentStored = [];
    String? stored = _readFromStorage('local_students');
    if (stored != null && stored.isNotEmpty) {
      try {
        currentStored = List<Map<String, dynamic>>.from(jsonDecode(stored));
      } catch (_) {}
    }
    currentStored.removeWhere((s) => s['name'] == student.name && s['phone'] == student.phone);
    currentStored.insert(0, student.toJson());
    _saveToStorage('local_students', jsonEncode(currentStored));

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"), 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode(student.toJson())
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      log("❌ Register Student Error: $e");
      return true;
    }
  }

  static Future<bool> updateStudent(String id, StudentModel student) async {
    int idx = _localStudents.indexWhere((s) => s.idString == id || s.name == student.name);
    if (idx != -1) {
      _localStudents[idx] = student;
    } else {
      _localStudents.insert(0, student);
    }
    
    List<Map<String, dynamic>> currentStored = [];
    String? stored = _readFromStorage('local_students');
    if (stored != null && stored.isNotEmpty) {
      try {
        currentStored = List<Map<String, dynamic>>.from(jsonDecode(stored));
      } catch (_) {}
    }
    int storedIdx = currentStored.indexWhere((s) => s['name'] == student.name || s['id']?.toString() == id);
    if (storedIdx != -1) {
      currentStored[storedIdx] = student.toJson();
    } else {
      currentStored.insert(0, student.toJson());
    }
    _saveToStorage('local_students', jsonEncode(currentStored));

    try {
      final headers = {"Content-Type": "application/json"};
      final body = jsonEncode(student.toJson());

      var response = await http.put(Uri.parse("$baseUrl/update/$id"), headers: headers, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) return true;

      response = await http.put(Uri.parse("$baseUrl/$id"), headers: headers, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) return true;

      response = await http.post(Uri.parse("$baseUrl/update/$id"), headers: headers, body: body);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return true;
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
    _localStudents.removeWhere((s) => s.idString == id);
    String? stored = _readFromStorage('local_students');
    if (stored != null && stored.isNotEmpty) {
      try {
        List<dynamic> list = jsonDecode(stored);
        list.removeWhere((item) => item['id']?.toString() == id || item['_id']?.toString() == id);
        _saveToStorage('local_students', jsonEncode(list));
      } catch (_) {}
    }
    try {
      final response = await http.delete(Uri.parse("$baseUrl/delete/$id"));
      return response.statusCode == 200;
    } catch (e) {
      return true;
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
    _localTeachers.removeWhere((t) => t['name'] == teacher['name'] && t['phone'] == teacher['phone']);
    _localTeachers.insert(0, teacher);

    List<Map<String, String>> currentStored = [];
    String? stored = _readFromStorage('local_teachers');
    if (stored != null && stored.isNotEmpty) {
      try {
        List<dynamic> raw = jsonDecode(stored);
        currentStored = raw.map((item) => Map<String, String>.from(item)).toList();
      } catch (_) {}
    }
    currentStored.removeWhere((t) => t['name'] == teacher['name'] && t['phone'] == teacher['phone']);
    currentStored.insert(0, teacher);
    _saveToStorage('local_teachers', jsonEncode(currentStored));

    try {
      final response = await http.post(Uri.parse("$teacherUrl/register"), headers: {"Content-Type": "application/json"}, body: jsonEncode(teacher));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return true;
    }
  }

  static Future<List<Map<String, String>>> getAllTeachers() async {
    List<Map<String, String>> results = [];
    try {
      final response = await http.get(Uri.parse("$teacherUrl/all"), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        results = data.map((json) => {
          "id": json['id']?.toString() ?? "", 
          "name": json['name']?.toString() ?? "", 
          "district": json['district']?.toString() ?? "", 
          "phone": json['phone']?.toString() ?? "", 
          "exp": json['experience']?.toString() ?? json['exp']?.toString() ?? "", 
          "level": json['level']?.toString() ?? ""
        }).toList();
      }
    } catch (e) {
      log("❌ getAllTeachers Error: $e");
    }

    String? stored = _readFromStorage('local_teachers');
    if (stored != null && stored.isNotEmpty) {
      try {
        List<dynamic> list = jsonDecode(stored);
        for (var item in list) {
          Map<String, String> map = Map<String, String>.from(item);
          bool exists = results.any((r) => r['name'] == map['name'] && r['phone'] == map['phone']);
          if (!exists) {
            results.insert(0, map);
          }
        }
      } catch (_) {}
    }

    for (var t in _localTeachers) {
      bool exists = results.any((r) => r['name'] == t['name'] && r['phone'] == t['phone']);
      if (!exists) {
        results.insert(0, t);
      }
    }

    return results;
  }

  static Future<bool> updateTeacher(String id, Map<String, String> teacher) async {
    int idx = _localTeachers.indexWhere((t) => t['id'] == id || t['name'] == teacher['name']);
    if (idx != -1) {
      _localTeachers[idx] = teacher;
    } else {
      _localTeachers.insert(0, teacher);
    }
    
    List<Map<String, String>> currentStored = [];
    String? stored = _readFromStorage('local_teachers');
    if (stored != null && stored.isNotEmpty) {
      try {
        List<dynamic> raw = jsonDecode(stored);
        currentStored = raw.map((item) => Map<String, String>.from(item)).toList();
      } catch (_) {}
    }
    int storedIdx = currentStored.indexWhere((t) => t['name'] == teacher['name'] || t['id'] == id);
    if (storedIdx != -1) {
      currentStored[storedIdx] = teacher;
    } else {
      currentStored.insert(0, teacher);
    }
    _saveToStorage('local_teachers', jsonEncode(currentStored));

    try {
      final response = await http.put(Uri.parse("$teacherUrl/update/$id"), headers: {"Content-Type": "application/json"}, body: jsonEncode(teacher));
      return response.statusCode == 200;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> deleteTeacher(String id) async {
    _localTeachers.removeWhere((t) => t['id'] == id);
    String? stored = _readFromStorage('local_teachers');
    if (stored != null && stored.isNotEmpty) {
      try {
        List<dynamic> list = jsonDecode(stored);
        list.removeWhere((item) => item['id']?.toString() == id);
        _saveToStorage('local_teachers', jsonEncode(list));
      } catch (_) {}
    }
    try {
      final response = await http.delete(Uri.parse("$teacherUrl/delete/$id"));
      return response.statusCode == 200;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> registerBus(Bus bus) async {
    _localBuses.removeWhere((b) => b.name == bus.name && b.plate == bus.plate);
    _localBuses.insert(0, bus);

    List<Map<String, dynamic>> currentStored = [];
    String? stored = _readFromStorage('local_buses');
    if (stored != null && stored.isNotEmpty) {
      try {
        currentStored = List<Map<String, dynamic>>.from(jsonDecode(stored));
      } catch (_) {}
    }
    currentStored.removeWhere((b) => b['name'] == bus.name && b['plate'] == bus.plate);
    currentStored.insert(0, bus.toJson());
    _saveToStorage('local_buses', jsonEncode(currentStored));

    try {
      final response = await http.post(Uri.parse("$busUrl/register"), headers: {"Content-Type": "application/json"}, body: jsonEncode(bus.toJson()));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return true;
    }
  }

  static Future<List<Bus>> getAllBuses() async {
    List<Bus> results = [];
    try {
      final response = await http.get(Uri.parse("$busUrl/all"), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        results = data.map((json) => Bus.fromJson(json)).toList();
      }
    } catch (e) {
      log("Error fetching remote buses: $e");
    }

    String? stored = _readFromStorage('local_buses');
    if (stored != null && stored.isNotEmpty) {
      try {
        List<dynamic> list = jsonDecode(stored);
        for (var item in list) {
          Bus b = Bus.fromJson(item);
          bool exists = results.any((r) => r.name == b.name && r.plate == b.plate);
          if (!exists) {
            results.insert(0, b);
          }
        }
      } catch (_) {}
    }

    for (var b in _localBuses) {
      bool exists = results.any((r) => r.name == b.name && r.plate == b.plate);
      if (!exists) {
        results.insert(0, b);
      }
    }

    return results;
  }

  static Future<bool> updateBus(int id, Bus bus) async {
    int idx = _localBuses.indexWhere((b) => b.id == id || b.name == bus.name);
    if (idx != -1) {
      _localBuses[idx] = bus;
    } else {
      _localBuses.insert(0, bus);
    }
    
    List<Map<String, dynamic>> currentStored = [];
    String? stored = _readFromStorage('local_buses');
    if (stored != null && stored.isNotEmpty) {
      try {
        currentStored = List<Map<String, dynamic>>.from(jsonDecode(stored));
      } catch (_) {}
    }
    int storedIdx = currentStored.indexWhere((b) => b['name'] == bus.name || b['id'] == id);
    if (storedIdx != -1) {
      currentStored[storedIdx] = bus.toJson();
    } else {
      currentStored.insert(0, bus.toJson());
    }
    _saveToStorage('local_buses', jsonEncode(currentStored));

    try {
      final response = await http.put(Uri.parse("$busUrl/update/$id"), headers: {"Content-Type": "application/json"}, body: jsonEncode(bus.toJson()));
      return response.statusCode == 200;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> deleteBus(int id) async {
    _localBuses.removeWhere((b) => b.id == id);
    String? stored = _readFromStorage('local_buses');
    if (stored != null && stored.isNotEmpty) {
      try {
        List<dynamic> list = jsonDecode(stored);
        list.removeWhere((item) => item['id'] == id);
        _saveToStorage('local_buses', jsonEncode(list));
      } catch (_) {}
    }
    try {
      final response = await http.delete(Uri.parse("$busUrl/delete/$id"));
      return response.statusCode == 200;
    } catch (e) {
      return true;
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