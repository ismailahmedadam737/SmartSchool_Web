import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Si loo isticmaalo debugPrint

class CommunicationService {
  static const String baseUrl = "https://smartschool-web.onrender.com/api/communications";

  static Future<bool> sendFormMessage(Map<String, String> messageData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json", // Waxaa fiican in lagu daro
        },
        body: json.encode(messageData),
      );

      // Hubi haddii statusCode uu yahay 200 ama 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Guul: Fariinta waa la diray");
        return true;
      } else {
        // Waxaan ku darnay inaan aragno waxa server-ku soo celiyay haddii ay cillad jirto
        debugPrint("Cillad Server: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      // Isticmaal debugPrint halkii aad isticmaali lahayd print
      debugPrint("Cillad xiriirka: $e");
      return false;
    }
  }
}