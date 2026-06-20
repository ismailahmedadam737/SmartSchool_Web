import 'dart:convert';
import 'package:http/http.dart' as http;

class CommunicationService {
  // Waxaan beddelay localhost una beddelay URL-kaaga Render ee rasmiga ah
  static const String baseUrl = "https://smartschool-web.onrender.com/api/communications";

  static Future<bool> sendFormMessage(Map<String, String> messageData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(messageData),
      );

      // Waxaan aqbalnay 200 iyo 201 maadaama server-kaagu uu 201 soo celin karo marka la kaydiyo
      if (response.statusCode == 200 || response.statusCode == 201) {
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