import 'dart:convert';
import 'package:http/http.dart' as http;

class TeacherService {
  static const String baseUrl = "https://smartschool-web.onrender.com/api";

  // 1. Soo helidda macalimiinta
  static Future<List<dynamic>> getAllTeachers() async {
    try {
      print("📡 Waxaa la soo akhrinayaa xogta: $baseUrl/salary/list");
      final response = await http.get(Uri.parse('$baseUrl/salary/list'));
      
      print("📥 Server Response Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server-ka ayaa soo celiyay qalad: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Cillad getAllTeachers: $e");
      throw Exception('Cillad xiriirka server-ka: $e');
    }
  }

  // 2. Bixinta ama Update-ka mushaharka
  static Future<void> paySalary(int id, Map<String, dynamic> data) async {
    try {
      final url = '$baseUrl/salary/pay/$id';
      print("🚀 Waxaa loo dirayaa codsi POST URL-kan: $url");
      print("📦 Xogta la dirayo (Payload): ${json.encode(data)}");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(data),
      );

      print("📥 Pay Response Status: ${response.statusCode}");
      print("📥 Pay Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Xogta mushaharka si guul leh ayaa loo keydiyay");
      } else {
        throw Exception('Cillad bixinta mushaharka: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ Cillad paySalary: $e");
      throw Exception('Cillad xiriirka bixinta: $e');
    }
  }
}