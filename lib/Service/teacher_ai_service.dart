import 'dart:convert';
import 'package:http/http.dart' as http;

class TeacherService {
  // 1. U isticmaal 10.0.2.2 haddii aad isticmaalayso Android Emulator
  // 2. U isticmaal localhost ama IP-ga kombiyuutarkaaga haddii aad isticmaalayso web/browser
  static const String baseUrl = "https://smartschool-web.onrender.com/api";

  // CILLAD-SAXID: Method-kan hadda wuxuu si toos ah u wacayaa nidaamka mushaharka (salary list)
  // si uu u soo celiyo macalimiinta iyo status-kooda saxda ah (Paid ama Pending)
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

  // Method-kan ayaa bixinaya mushaharka (POST Request)
  static Future<void> paySalary(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/salary/pay/$id'),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
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