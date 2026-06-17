import 'dart:convert';
import 'package:http/http.dart' as http;

class CommunicationService {
  static const String baseUrl = "http://localhost:5000/api/communications";

  static Future<bool> sendFormMessage(Map<String, String> messageData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(messageData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Cillad xiriirka: $e");
      return false;
    }
  }
}