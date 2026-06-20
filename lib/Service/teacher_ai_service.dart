import 'dart:convert';
import 'package:http/http.dart' as http;

class TeacherService {
  // Waxaan u beddelay URL-ka rasmiga ah ee Render
  static const String baseUrl = "https://smartschool-web.onrender.com/api";

  // 1. Soo helidda macalimiinta iyo status-ka mushaharkooda
  static Future<List<dynamic>> getAllTeachers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/salary/list'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server-ka ayaa soo celiyay qalad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Cillad xiriirka server-ka: $e');
    }
  }

  // 2. Bixinta mushaharka (POST Request)
  static Future<void> paySalary(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/salary/pay/$id'),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Bixintu way guulaysatay
        print("Mushaharka si guul leh ayaa loo kaydiyay");
      } else {
        // Halkan waxaan soo bandhigaynaa jawaabta server-ka si aan u ogaano sababta
        throw Exception('Cillad bixinta mushaharka: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Cillad xiriirka bixinta: $e');
    }
  }
}