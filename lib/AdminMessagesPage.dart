import 'package:flutter/material.dart';

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  // Liiska caalamiga ah ee fariimaha (Static Global List)
  static List<Map<String, String>> globalMessages = [
    {
      "id": "1",
      "name": "Axmed Cali Cilmi",
      "phone": "0634455667",
      "subject": "Diiwaangelinta Carruurta",
      "message": "Asc maamulka, waxaan rabay inaan ogaado in boos quraac weli ka bannaanyahay fasalka KG2, gabadh baan rabaa inaan iska qoro.",
      "date": "Maanta, 09:15 AM"
    },
    {
      "id": "2",
      "name": "Faadumo Jaamac",
      "phone": "0633211223",
      "subject": "Xog-wareysi Gaadiidka",
      "message": "Haddii uu jiro bas qaada ardayda dhiiri-galinta deggen fadlan nala soo xiriiriya xilliyada shaqada.",
      "date": "Shalay, 04:30 PM"
    }
  ];

  // Kani waa ka caawinaya Sidebar-ka/Drawer-ka inuu ogaado marka gudaha loo galo
  // Waxay ku bilaabmaysaa 2 fariimood oo cusub. Marka bogga la furo wuxuu noqonayaa 0.
  static ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(2);

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // MARKA GUDAHA LOO GALO BOGGAN: Si toos ah u baabi'i calaamaddii Sidebar-ka (Ka dhig 0)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminMessagesPage.unreadCountNotifier.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Habaynta midabada casriga ah
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E2E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDarkMode ? Colors.white60 : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: Colors.transparent, // Waxay dhaxlaysaa dhabarka weyn ee Dashboard-ka
      body: SafeArea(
        child: Row(
          children: [
            // DHINACA LEFT: Sawirka dad fariimo qoraya iyo Header-ka
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: const DecorationImage(
                    // Halkan waxaa lagu beddelay sawir muujinaya qof fariin ka diraya taleefanka
                    image: NetworkImage("https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=600&auto=format&fit=crop"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A237E).withOpacity(0.95),
                        const Color(0xFF3949AB).withOpacity(0.6),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Qaybta sare iyo badhanka Refresh-ka
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                                SizedBox(width: 8),
                                Text("Live Messages", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                              onPressed: () {
                                setState(() {});
                              },
                            ),
                          )
                        ],
                      ),
                      // Qaybta qoraalka hoose ee kaarka
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            " Fariimaha tooska ah",
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Halkan ka eeg fariimaha tooska ah ee ay soo qoreen waalidiinta iyo macaamiishu si aad uga jawaabto.",
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // DHINACA RIGHT: Fariimaha oo u qulqulaya si toos ah
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.03),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    )
                                  ],
                                  border: Border.all(
                                    color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Profile, Name iyo Saacadda
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              height: 48,
                                              width: 48,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                                                ),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                msg['name']!.isNotEmpty ? msg['name']![0].toUpperCase() : "?", 
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                                              ),
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
                                        // Saacadda
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            msg['date']!, 
                                            style: TextStyle(color: isDarkMode ? Colors.cyanAccent : const Color(0xFF1A237E), fontSize: 11, fontWeight: FontWeight.bold)
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 30, thickness: 0.8),
                                    
                                    // Subject
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6A11CB),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          msg['subject']!,
                                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    
                                    // Fariinta oo faahfaahsan
                                    Text(
                                      msg['message']!,
                                      style: TextStyle(color: isDarkMode ? Colors.white70 : const Color(0xFF334155), fontSize: 14, height: 1.5),
                                    ),
                                    const SizedBox(height: 15),
                                    
                                    // Badhamada waxqabadka
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.red.withOpacity(0.08),
                                            padding: const EdgeInsets.all(10),
                                          ),
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                          onPressed: () {
                                            setState(() => AdminMessagesPage.globalMessages.removeAt(index));
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            backgroundColor: const Color(0xFF1A237E).withOpacity(0.08),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () {
                                            // Action-ka ka jawaabista
                                          },
                                          icon: const Icon(Icons.reply_rounded, color: Color(0xFF1A237E), size: 18),
                                          label: const Text(
                                            "Ka Jawaab",
                                            style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
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