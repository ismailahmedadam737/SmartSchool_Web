import 'package:flutter/material.dart';
import 'package:iftiinshe/AdminMessagesPage.dart';
import 'package:iftiinshe/Service/communication_service.dart'; // Hubi in koodhkan uu import yahay

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
      
      // Xogta laga soo ururiyey Form-ka ee loo dirayo Database-ka
      final Map<String, String> messageData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "subject": _subjectController.text.trim(),
        "message": _messageController.text.trim(),
      };

      // Toos ugu dir database-ka iyadoo la isticmaalayo Service-ka
      bool isSuccess = await CommunicationService.sendFormMessage(messageData);
      
      setState(() => _isSending = false);

      if (isSuccess) {
        // Haddii uu database-ka guul ku galo, nuqul maxali ah ku dar liiska AdminMessagesPage
        final Map<String, String> localMessage = {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          ...messageData,
          "date": "Hadda",
        };
        AdminMessagesPage.globalMessages.insert(0, localMessage);

        // Nadiifi Form-ka mar fariinta la diro ka dib
        _nameController.clear();
        _phoneController.clear();
        _subjectController.clear();
        _messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Fariintaada si guul leh ayaa loo diray database-ka!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Cillad ayaa ku dhacday dirista fariinta! Hubi server-ka."),
            backgroundColor: Colors.red,
          ),
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
            // BIDIX: Xogta xiriirka Dugsiga Iftiinshe
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "La Xidhiidh Maamulka",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Iftiinshe Primary and KG Schools. Haddii aad qabto wax su'aal, cabasho ama faallo ah, fadlan fariin toos ah noogu soo reeb.",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                    ),
                    const SizedBox(height: 30),
                    
                    _buildContactCard(
                      icon: Icons.phone_in_talk_rounded,
                      title: "Taleefanka",
                      subtitle: "+252 63 4868156",
                      gradientColors: [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
                    ),
                    const SizedBox(height: 15),
                    _buildContactCard(
                      icon: Icons.location_on_outlined,
                      title: "Goobta / Cinwaanka",
                      subtitle: "Hargeisa, Somaliland",
                      gradientColors: [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
                    ),
                    
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: Color(0xFF1A237E), size: 30),
                          SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Xilliyada Shaqada", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text("Sabti - Khamiis: 7:00 AM - 12:30 PM", style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            // MIDIG: Form-ka rasmiga ah ee Fariinta lagu soo dirayo
            Expanded(
              flex: 6,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6A11CB).withOpacity(0.06),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Noo Soo Dir Fariin",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildFormTextField(
                          label: "Magacaaga Buuxa",
                          icon: Icons.person_outline_rounded,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 18),
                        _buildFormTextField(
                          label: "Taleefankaaga",
                          icon: Icons.phone_android_outlined,
                          controller: _phoneController,
                        ),
                        const SizedBox(height: 18),
                        _buildFormTextField(
                          label: "Ujeedada Fariinta",
                          icon: Icons.subject_rounded,
                          controller: _subjectController,
                        ),
                        const SizedBox(height: 18),
                        _buildFormTextField(
                          label: "Fariintaada oo Faahfaahsan",
                          icon: Icons.chat_bubble_outline_rounded,
                          controller: _messageController,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 30),
                        
                        _isSending
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _sendMessage,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                  shadowColor: const Color(0xFF6A11CB).withOpacity(0.3),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Container(
                                    height: 55,
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 10),
                                        const Text(
                                          "Dir Fariinta",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFormTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Fadlan buuxi meeshan";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF6A11CB), size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 1.5),
        ),
      ),
    );
  }
}