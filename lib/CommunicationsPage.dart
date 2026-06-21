import 'package:flutter/material.dart';
import 'package:iftiinshe/AdminMessagesPage.dart';
import 'package:iftiinshe/Service/communication_service.dart';

class SchoolCommunicationsPage extends StatefulWidget {
  const SchoolCommunicationsPage({super.key});

  @override
  State<SchoolCommunicationsPage> createState() => _SchoolCommunicationsPageState();
}

class _SchoolCommunicationsPageState extends State<SchoolCommunicationsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  bool _isSending = false;

  void _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSending = true);
      
      final Map<String, String> messageData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "subject": _subjectController.text.trim(),
        "message": _messageController.text.trim(),
      };

      bool isSuccess = await CommunicationService.sendFormMessage(messageData);
      
      setState(() => _isSending = false);

      if (isSuccess) {
        // Kordhi badge-ka gaduudan
        AdminMessagesPage.unreadCountNotifier.value += 1;

        // Xallinta cilada: Hubi in keys-ku ay yihiin String iyo values-ku ay yihiin dynamic
        final Map<String, dynamic> localMessage = {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "name": messageData['name'],
          "phone": messageData['phone'],
          "subject": messageData['subject'],
          "message": messageData['message'],
          "date": "Hadda",
          "is_read": false,
        };
        
        AdminMessagesPage.globalMessages.insert(0, localMessage);

        _nameController.clear();
        _phoneController.clear();
        _subjectController.clear();
        _messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Fariintaada waa la diray!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Cillad ayaa dhacday!"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Row(
          children: [
            // [UI-gaaga Bidix halkan geli...]
            Expanded(flex: 5, child: Container()), 
            
            // UI-ga Midig (Form-ka)
            Expanded(
              flex: 6,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFormTextField(label: "Magacaaga", icon: Icons.person, controller: _nameController),
                      _buildFormTextField(label: "Taleefanka", icon: Icons.phone, controller: _phoneController),
                      _buildFormTextField(label: "Ujeedada", icon: Icons.subject, controller: _subjectController),
                      _buildFormTextField(label: "Fariinta", icon: Icons.chat, controller: _messageController, maxLines: 5),
                      const SizedBox(height: 20),
                      _isSending 
                        ? const CircularProgressIndicator() 
                        : ElevatedButton(onPressed: _sendMessage, child: const Text("Dir Fariinta")),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Waa inaad haysataa function-kan _buildFormTextField
  Widget _buildFormTextField({required String label, required IconData icon, required TextEditingController controller, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (value) => (value == null || value.isEmpty) ? "Waa inaan la faaruqin" : null,
    );
  }
}