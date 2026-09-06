import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/api_service.dart';

class AnnouncementsPage extends StatefulWidget {
  final String userRole;

  const AnnouncementsPage({super.key, this.userRole = ''});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  String selectedFilter = "Dhammaan";
  String searchQuery = "";
  List<Map<String, dynamic>> _announcements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => isLoading = true);
    try {
      final String? stored = await ApiService.getPersistentSetting('school_announcements');
      if (stored != null && stored.isNotEmpty) {
        final List<dynamic> list = jsonDecode(stored);
        final List<Map<String, dynamic>> loaded = list.map((e) => Map<String, dynamic>.from(e)).toList();
        if (mounted) {
          setState(() {
            _announcements = loaded;
            isLoading = false;
          });
        }
      } else {
        _loadDefaultSampleAnnouncements();
      }
    } catch (e) {
      debugPrint("Error loading announcements page: $e");
      _loadDefaultSampleAnnouncements();
    }
  }

  void _loadDefaultSampleAnnouncements() {
    final now = DateTime.now();
    final sampleAnnouncements = [
      {
        "id": "1",
        "title": "Fasaxa Dhexe ee Imtixaanka Mid-Term",
        "description": "Iskuulku wuxuu galayaa fasaxa dhexe ee imtixaanka. Dhammaan maamulka iyo ardayda waxaa lagu ogeysiinayaa in fasaxu bilaabmi doono.",
        "category": "Fasax",
        "targetRole": "All",
        "eventDate": now.add(const Duration(days: 5)).toIso8601String().split('T')[0],
        "createdAt": now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        "id": "2",
        "title": "DIGNIIN: Fasax Kadis ah (Roobka & Dabaylaha)",
        "description": "Roobab waaweyn oo ka da'aya magaalada awgeed, maanta waxaa jira fasax kadis ah si daryeelka ardayda loo ilaaliyo.",
        "category": "Fasax Kadis ah",
        "targetRole": "All",
        "eventDate": now.toIso8601String().split('T')[0],
        "createdAt": now.subtract(const Duration(minutes: 30)).toIso8601String(),
      },
      {
        "id": "3",
        "title": "Imtixaanka Final-ka ee Sanad Dugsileedka",
        "description": "Jadwalka rasmi ah ee imtixaanka Final-ka waa la soo saaray. Fadlan arday walba iyo macallin walba ha u diyaargaroobo imtixaanka.",
        "category": "Imtixaan",
        "targetRole": "All",
        "eventDate": now.add(const Duration(days: 12)).toIso8601String().split('T')[0],
        "createdAt": now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        "id": "4",
        "title": "Maalinta Safka ee Subaxda (Morning Assembly)",
        "description": "Dhammaan ardayda iyo macallimiinta waxaa lagu ogeysiinayaa in safka subaxda uu bilaabmi doono 7:00 AM sakad ahaan.",
        "category": "Safka Dugsiga",
        "targetRole": "All",
        "eventDate": now.add(const Duration(days: 2)).toIso8601String().split('T')[0],
        "createdAt": now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        "id": "5",
        "title": "Shirka Wadajirka ah ee Macallimiinta",
        "description": "Waxaa jira shir muhiim ah oo dhammaan macallimiinta iskuulka loogu yeedhay saacadu markay tahay 1:00 PM maanta.",
        "category": "Shirka Macallimiinta",
        "targetRole": "Teachers",
        "eventDate": now.add(const Duration(days: 1)).toIso8601String().split('T')[0],
        "createdAt": now.subtract(const Duration(hours: 5)).toIso8601String(),
      },
    ];

    if (mounted) {
      setState(() {
        _announcements = sampleAnnouncements;
        isLoading = false;
      });
      _saveAnnouncements();
    }
  }

  void _saveAnnouncements() {
    try {
      ApiService.savePersistentSetting('school_announcements', _announcements);
    } catch (e) {
      debugPrint("Error saving announcements: $e");
    }
  }

  String _getCountdownText(String? eventDateStr) {
    if (eventDateStr == null || eventDateStr.isEmpty) return "";
    final DateTime? eventDate = DateTime.tryParse(eventDateStr);
    if (eventDate == null) return "";

    final DateTime today = DateTime.now();
    final DateTime dateOnlyEvent = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final DateTime dateOnlyToday = DateTime(today.year, today.month, today.day);

    final int diffDays = dateOnlyEvent.difference(dateOnlyToday).inDays;

    if (diffDays > 0) {
      return "⏳ Waxaa ka dhiman $diffDays Maalmood";
    } else if (diffDays == 0) {
      return "🚨 Maanta Waa Maalinta Dhacdada!";
    } else {
      return "✅ Maalintii Way Soo Dhaaftay";
    }
  }

  Map<String, dynamic> _getAnnouncementCategoryStyle(String category) {
    switch (category.trim()) {
      case "Fasax Kadis ah":
        return {
          "color": const Color(0xFFFF2A4B),
          "bgColor": const Color(0xFFFF2A4B).withValues(alpha: 0.12),
          "borderColor": Colors.redAccent,
          "icon": Icons.warning_rounded,
          "badge": "DIGNIIN KADIS AH",
        };
      case "Fasax":
        return {
          "color": const Color(0xFFFF9800),
          "bgColor": const Color(0xFFFF9800).withValues(alpha: 0.12),
          "borderColor": Colors.orangeAccent,
          "icon": Icons.beach_access_rounded,
          "badge": "FASAXA DUGSIGA",
        };
      case "Imtixaan":
        return {
          "color": const Color(0xFF9C27B0),
          "bgColor": const Color(0xFF9C27B0).withValues(alpha: 0.12),
          "borderColor": Colors.purpleAccent,
          "icon": Icons.assignment_rounded,
          "badge": "OGEYSIISKA IMTIXAANKA",
        };
      case "Safka Dugsiga":
        return {
          "color": const Color(0xFF00E676),
          "bgColor": const Color(0xFF00E676).withValues(alpha: 0.12),
          "borderColor": Colors.greenAccent,
          "icon": Icons.groups_rounded,
          "badge": "SAFKA ARDAYDA",
        };
      case "Shirka Macallimiinta":
        return {
          "color": const Color(0xFF00D2FF),
          "bgColor": const Color(0xFF00D2FF).withValues(alpha: 0.12),
          "borderColor": Colors.cyanAccent,
          "icon": Icons.record_voice_over_rounded,
          "badge": "SHIRKA MACALLIMIINTA",
        };
      case "Tababarka Macallimiinta":
        return {
          "color": const Color(0xFF6C63FF),
          "bgColor": const Color(0xFF6C63FF).withValues(alpha: 0.12),
          "borderColor": const Color(0xFF6C63FF),
          "icon": Icons.model_training_rounded,
          "badge": "TABABARKA MACALLIMIINTA",
        };
      default:
        return {
          "color": const Color(0xFF6C63FF),
          "bgColor": const Color(0xFF6C63FF).withValues(alpha: 0.12),
          "borderColor": const Color(0xFF6C63FF),
          "icon": Icons.notifications_active_rounded,
          "badge": "OGEYSIIS GUUD",
        };
    }
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = "Fasax";
    String targetRole = "All";
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
        final txtColor = isDark ? Colors.white : Colors.black87;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Color(0xFF6C63FF), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Add Ogeysiis Cusub",
                    style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Category-ga Ogeysiiska", style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: category,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          style: TextStyle(color: txtColor, fontSize: 14),
                          items: [
                            "Fasax",
                            "Fasax Kadis ah",
                            "Imtixaan",
                            "Safka Dugsiga",
                            "Shirka Macallimiinta",
                            "Tababarka Macallimiinta",
                          ].map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => category = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text("Cinwaanka Ogeysiiska (Title)", style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: txtColor),
                      decoration: InputDecoration(
                        hintText: "Tusaale: Fasaxa Imtixaanka Mid-Term...",
                        hintStyle: TextStyle(color: txtColor.withValues(alpha: 0.5), fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text("Faahfaahinta Ogeysiiska (Description)", style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      style: TextStyle(color: txtColor),
                      decoration: InputDecoration(
                        hintText: "Qeer faahfaahin buuxda oo ku saabsan ogeysiiska...",
                        hintStyle: TextStyle(color: txtColor.withValues(alpha: 0.5), fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text("Taariikhda Dhacdada / Fasaxa", style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text("${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}"),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text("Sida Loo Ugaarsanayo (Target Audience)", style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          selected: targetRole == "All",
                          label: const Text("Dhammaan (All)"),
                          selectedColor: const Color(0xFF6C63FF),
                          labelStyle: TextStyle(color: targetRole == "All" ? Colors.white : txtColor),
                          onSelected: (val) {
                            if (val) setDialogState(() => targetRole = "All");
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          selected: targetRole == "Teachers",
                          label: const Text("Macallimiinta"),
                          selectedColor: const Color(0xFF00D2FF),
                          labelStyle: TextStyle(color: targetRole == "Teachers" ? Colors.white : txtColor),
                          onSelected: (val) {
                            if (val) setDialogState(() => targetRole = "Teachers");
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Baqsho", style: TextStyle(color: txtColor.withValues(alpha: 0.7))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fadlan geli cinwaanka ogeysiiska!")),
                      );
                      return;
                    }

                    final newAnnouncement = {
                      "id": DateTime.now().millisecondsSinceEpoch.toString(),
                      "title": title,
                      "description": desc,
                      "category": category,
                      "targetRole": targetRole,
                      "eventDate": "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                      "createdAt": DateTime.now().toIso8601String(),
                    };

                    setState(() {
                      // Insert at the beginning so newer messages are always on top
                      _announcements.insert(0, newAnnouncement);
                      _saveAnnouncements();
                    });

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ogeysiiska si guul leh ayaa loo soo dhigay! ✨"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text("Kaydi & Baahi"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161B26) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    String role = widget.userRole.toLowerCase();
    bool isStudent = role == 'user' || role.contains('student') || role.contains('ardey') || role.contains('waalid') || role.contains('parent');

    // Sort announcements so NEWEST CREATED IS ALWAYS AT THE TOP
    List<Map<String, dynamic>> sortedList = List.from(_announcements);
    sortedList.sort((a, b) {
      final String aCreated = (a["createdAt"] ?? "").toString();
      final String bCreated = (b["createdAt"] ?? "").toString();
      return bCreated.compareTo(aCreated);
    });

    // Apply Filter & Search
    List<Map<String, dynamic>> filteredList = sortedList.where((item) {
      final String tr = (item["targetRole"] ?? "All").toString();
      final cat = (item["category"] ?? "").toString().trim();
      
      if (isStudent && (tr == 'Teachers' || cat == "Shirka Macallimiinta" || cat == "Tababarka Macallimiinta")) return false;

      final title = (item["title"] ?? "").toString().toLowerCase();
      final desc = (item["description"] ?? "").toString().toLowerCase();

      bool matchesFilter = true;
      if (selectedFilter == "Fasaxyada") {
        matchesFilter = (cat == "Fasax" || cat == "Fasax Kadis ah");
      } else if (selectedFilter == "Imtixaanaadka") {
        matchesFilter = (cat == "Imtixaan");
      } else if (selectedFilter == "Safka Dugsiga") {
        matchesFilter = (cat == "Safka Dugsiga");
      } else if (selectedFilter == "Shirarka & Tababarada") {
        matchesFilter = (cat == "Shirka Macallimiinta" || cat == "Tababarka Macallimiinta");
      }

      bool matchesSearch = searchQuery.isEmpty ||
          title.contains(searchQuery.toLowerCase()) ||
          desc.contains(searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Card
            LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 650;
                
                Widget iconWidget = Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF007F), Color(0xFF7928CA), Color(0xFF00D2FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF007F).withValues(alpha: 0.4),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 32),
                );

                Widget textWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        const Text(
                          "Ogeysiisyada & Dhacdooyinka Iskuulka",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            "${_announcements.length} WARTA CUSUB",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Halkan ka eeg dhammaan fasaxyada, imtixaanaadka, safka subaxda iyo shirarka macallimiinta.",
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                );

                Widget buttonWidget = ElevatedButton.icon(
                  onPressed: _showAddAnnouncementDialog,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text("Ogeysiis Cusub"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 18 : 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1E2C), Color(0xFF2A2A40)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                iconWidget,
                                const SizedBox(width: 14),
                                Expanded(child: textWidget),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(width: double.infinity, child: buttonWidget),
                          ],
                        )
                      : Row(
                          children: [
                            iconWidget,
                            const SizedBox(width: 16),
                            Expanded(child: textWidget),
                            const SizedBox(width: 12),
                            buttonWidget,
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Search Bar & Filter Chips Row
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setState(() => searchQuery = val),
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: "Raadi ogeysiis gaar ah...",
                              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, color: textColor.withValues(alpha: 0.6)),
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filters List
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          "Dhammaan",
                          "Fasaxyada",
                          "Imtixaanaadka",
                          "Safka Dugsiga",
                          if (!isStudent) "Shirarka & Tababarada",
                        ].map((flt) {
                          final bool isSel = selectedFilter == flt;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              selected: isSel,
                              label: Text(flt),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : textColor,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              selectedColor: const Color(0xFF6C63FF),
                              backgroundColor: cardColor,
                              elevation: isSel ? 3 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isSel ? const Color(0xFF6C63FF) : (isDark ? Colors.white12 : Colors.black12),
                                ),
                              ),
                              onSelected: (val) {
                                setState(() => selectedFilter = flt);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Announcements Grid / List
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.notifications_off_rounded, size: 50, color: textColor.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      "Ma jiraan ogeysiisyo laga helay qaybtaan.",
                      style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  _buildFeaturedAnnouncementCard(filteredList.first, isDark, cardColor, textColor),
                  const SizedBox(height: 20),
                  if (filteredList.length > 1)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final listRest = filteredList.sublist(1);
                        final int crossAxisCount = constraints.maxWidth >= 1100
                            ? 3
                            : (constraints.maxWidth >= 700 ? 2 : 1);

                        if (crossAxisCount == 1) {
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: listRest.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                            itemBuilder: (ctx, index) {
                              return _buildAnnouncementCard(listRest[index], isDark, cardColor, textColor);
                            },
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 240,
                          ),
                          itemCount: listRest.length,
                          itemBuilder: (ctx, index) {
                            return _buildAnnouncementCard(listRest[index], isDark, cardColor, textColor);
                          },
                        );
                      },
                    ),
                ],
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedAnnouncementCard(Map<String, dynamic> item, bool isDark, Color cardColor, Color textColor) {
    final String cat = (item["category"] ?? "General").toString();
    final style = _getAnnouncementCategoryStyle(cat);
    final String countdownText = _getCountdownText(item["eventDate"]?.toString());

    final Color cardAccent = style["color"] as Color;
    final IconData cardIcon = style["icon"] as IconData;
    final String badgeLabel = style["badge"] as String;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardAccent.withValues(alpha: 0.15),
            cardAccent.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardAccent.withValues(alpha: 0.5), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: cardAccent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardAccent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: cardAccent.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(cardIcon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "WARKA UGU DAMBEEYA",
                          style: TextStyle(
                            color: cardAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withValues(alpha: 0.7), size: 24),
                tooltip: "Tirtir Ogeysiiska",
                onPressed: () {
                  setState(() {
                    _announcements.removeWhere((a) => a["id"] == item["id"]);
                    _saveAnnouncements();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ogeysiiska waa la tirtiray")),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item["title"]?.toString() ?? "",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item["description"]?.toString() ?? "",
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: textColor.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_rounded, color: cardAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      countdownText.isNotEmpty ? countdownText : "📅 ${item["eventDate"] ?? ""}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cardAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> item, bool isDark, Color cardColor, Color textColor) {
    final String cat = (item["category"] ?? "General").toString();
    final style = _getAnnouncementCategoryStyle(cat);
    final String countdownText = _getCountdownText(item["eventDate"]?.toString());

    final Color cardAccent = style["color"] as Color;
    final IconData cardIcon = style["icon"] as IconData;
    final String badgeLabel = style["badge"] as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardAccent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardAccent.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cardIcon, color: cardAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardAccent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        color: cardAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withValues(alpha: 0.7), size: 20),
                tooltip: "Tirtir Ogeysiiska",
                onPressed: () {
                  setState(() {
                    _announcements.removeWhere((a) => a["id"] == item["id"]);
                    _saveAnnouncements();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ogeysiiska waa la tirtiray")),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            item["title"]?.toString() ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            item["description"]?.toString() ?? "",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: textColor.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),

      // Countdown & Date Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black38 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      countdownText.isNotEmpty ? countdownText : "📅 ${item["eventDate"] ?? ""}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cardAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
