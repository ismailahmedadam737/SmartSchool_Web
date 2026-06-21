import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  // Badge-ka gaduudan oo loo isticmaalo sidebar-ka
  static ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  List<dynamic> messages = [];
  bool isLoading = true;
  final String baseUrl = "http://localhost:5000/api"; // Beddel adigoo isticmaalaya IP-gaaga server-ka

  @override
  void initState() {
    super.initState();
    _fetchAllMessages();
  }

  // 1. Soo qaado dhammaan fariimaha
  Future<void> _fetchAllMessages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/communications/all'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          messages = data;
          isLoading = false;
          // Tirinta fariimaha aan la aqrin (is_read == false)
          AdminMessagesPage.unreadCountNotifier.value = 
              data.where((m) => m['is_read'] == false).length;
        });
      }
    } catch (e) {
      debugPrint("Error loading messages: $e");
    }
  }

  // 2. Calaamadee dhammaan fariimaha in la aqriyay
  Future<void> _markAllAsRead() async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/communications/mark-all-as-read'));
      if (response.statusCode == 200) {
        AdminMessagesPage.unreadCountNotifier.value = 0;
        _fetchAllMessages(); // Dib u cusboonaysii liiska
      }
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Messages"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _markAllAsRead,
            tooltip: "Calaamadee dhammaan in la aqriyay",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllMessages,
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return Card(
                color: msg['is_read'] == false ? Colors.blue.shade50 : Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(msg['subject'] ?? 'No Subject'),
                  subtitle: Text("${msg['name']} - ${msg['message']}"),
                  trailing: msg['is_read'] == false 
                      ? const Icon(Icons.circle, color: Colors.red, size: 12) 
                      : null,
                ),
              );
            },
          ),
    );
  }
}