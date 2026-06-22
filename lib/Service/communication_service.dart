import 'dart:convert';
import 'package:http/http.dart' as http;

class CommunicationService {
  static const String baseUrl = "https://smartschool-web.onrender.com/api/communications";

  // Function-ka dirista fariimaha
  static Future<bool> sendFormMessage(Map<String, String> messageData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(messageData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Cillad xiriirka: $e");
      return false;
    }
  }

  // Function-ka tirtiridda fariimaha (Dhammaystiran)
  static Future<bool> deleteMessage(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return true; // Si guul leh ayaa loo tirtiray
      } else {
        print("Tirtiridda way fashilantay: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Cillad xiriirka (Delete): $e");
      return false;
    }
  }
}