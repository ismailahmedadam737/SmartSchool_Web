import 'package:flutter/material.dart';
import 'package:iftiinshe/MessageBubble.dart';
import 'package:iftiinshe/Service/api_service.dart';

class ChatDialog extends StatefulWidget {
  const ChatDialog({super.key});

  @override
  State<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"message": "Hello! Sidee baan kuu caawiyaa maanta?", "isUser": false}
  ];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userText = _controller.text;
    setState(() {
      _messages.add({"message": userText, "isUser": true});
      _isLoading = true;
    });
    _controller.clear();

    String result = await ApiService.askAI(userText);

    setState(() {
      _messages.add({"message": result, "isUser": false});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.smart_toy, color: Colors.white),
                  SizedBox(width: 10),
                  Center(child: Text("Iftiinshe AI Assistant", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) => MessageBubble(
                  message: _messages[index]["message"],
                  isUser: _messages[index]["isUser"],
                ),
              ),
            ),
            if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Weydii wax kasta...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor:  Colors.green,
                    child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}