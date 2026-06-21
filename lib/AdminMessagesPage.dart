import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  // Tani waxay ogolaanaysaa in bogagga kale ay ku daraan fariimo cusub
  static List<Map<String, dynamic>> globalMessages = [];
  static ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  bool isLoading = true;
  final String baseUrl = "https://smartschool-web.onrender.com/api/communications";

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  // 1. Ka soo jiid fariimaha Server-ka
  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/all'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          AdminMessagesPage.globalMessages = List<Map<String, dynamic>>.from(data);
          AdminMessagesPage.unreadCountNotifier.value = 
              AdminMessagesPage.globalMessages.where((m) => m['is_read'] == false).length;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    }
  }

  // 2. Calaamadee in la aqriyay
  Future<void> _markAllAsRead() async {
    final response = await http.put(Uri.parse('$baseUrl/mark-all-as-read'));
    if (response.statusCode == 200) {
      setState(() {
        for (var msg in AdminMessagesPage.globalMessages) {
          msg['is_read'] = true;
        }
        AdminMessagesPage.unreadCountNotifier.value = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fariimaha Waalidiinta"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: "Dhammaan calaamadee in la aqriyay",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: AdminMessagesPage.unreadCountNotifier,
              builder: (context, count, child) {
                return ListView.builder(
                  itemCount: AdminMessagesPage.globalMessages.length,
                  itemBuilder: (context, index) {
                    final msg = AdminMessagesPage.globalMessages[index];
                    return Card(
                      color: (msg['is_read'] == false) ? Colors.blue.shade50 : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(child: Text(msg['name'][0])),
                        title: Text(msg['subject'] ?? 'No Subject'),
                        subtitle: Text(msg['message']),
                        trailing: (msg['is_read'] == false)
                            ? const Icon(Icons.circle, color: Colors.red, size: 12)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}