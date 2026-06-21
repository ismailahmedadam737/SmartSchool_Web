import 'dart:async'; // Lagu daray Timer
import 'package:flutter/material.dart';

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  // Liisku ha ahaado mid madhan marka hore
  static List<Map<String, dynamic>> globalMessages = [];

  static ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  final bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Nadiifinta fariimaha 24-kii saac mar
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      setState(() {
        AdminMessagesPage.globalMessages.removeWhere((msg) {
          final DateTime messageTime = msg['timestamp'];
          return now.difference(messageTime).inHours >= 24;
        });
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminMessagesPage.unreadCountNotifier.value = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Jooji timer-ka markii bogga laga baxo
    super.dispose();
  }

  // Tusaale shaqaynaya oo lagu darayo fariin:
  // void addMessage(Map<String, dynamic> msg) {
  //   msg['timestamp'] = DateTime.now(); // Wakhtiga hadda
  //   AdminMessagesPage.globalMessages.add(msg);
  // }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E2E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDarkMode ? Colors.white60 : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: const DecorationImage(
                    image: NetworkImage("https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=600&auto=format&fit=crop"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [const Color(0xFF1A237E).withOpacity(0.95), const Color(0xFF3949AB).withOpacity(0.6)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(30)),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                                SizedBox(width: 8),
                                Text("Live Messages", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                              onPressed: () => setState(() {}),
                            ),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(" Fariimaha tooska ah", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                          const SizedBox(height: 10),
                          Text("Halkan ka eeg fariimaha tooska ah ee ay soo qoreen waalidiinta.", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.4)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20, right: 20),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AdminMessagesPage.globalMessages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mail_outline_rounded, size: 70, color: subTextColor.withOpacity(0.4)),
                                const SizedBox(height: 15),
                                Text("Wax fariimo ah weli ma soo dhacin.", style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: AdminMessagesPage.globalMessages.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final msg = AdminMessagesPage.globalMessages[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.03), blurRadius: 15, offset: const Offset(0, 6))],
                                  border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              height: 48, width: 48,
                                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]), borderRadius: BorderRadius.circular(14)),
                                              alignment: Alignment.center,
                                              child: Text(msg['name']![0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                            ),
                                            const SizedBox(width: 16),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(msg['name']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.phone_outlined, size: 14, color: subTextColor),
                                                    const SizedBox(width: 4),
                                                    Text(msg['phone']!, style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(30)),
                                          child: Text(msg['date']!, style: TextStyle(color: isDarkMode ? Colors.cyanAccent : const Color(0xFF1A237E), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 30, thickness: 0.8),
                                    Row(
                                      children: [
                                        Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF6A11CB), borderRadius: BorderRadius.circular(10))),
                                        const SizedBox(width: 10),
                                        Text(msg['subject']!, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(msg['message']!, style: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF334155), fontSize: 14, height: 1.5)),
                                    const SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.08), padding: const EdgeInsets.all(10)),
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                          onPressed: () => setState(() => AdminMessagesPage.globalMessages.removeAt(index)),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}