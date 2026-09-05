import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/api_service.dart';

class ClassTimetablePage extends StatefulWidget {
  final String userRole;
  const ClassTimetablePage({super.key, this.userRole = ''});

  @override
  State<ClassTimetablePage> createState() => _ClassTimetablePageState();
}

class _ClassTimetablePageState extends State<ClassTimetablePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedClassFilter = "All";

  final List<String> defaultClasses = ["All", "Class 2A", "Class 3A", "Class 4A", "Class 5A", "Class 6A", "Class 7A", "Class 8A"];
  final List<String> days = ["SAT", "SUN", "MON", "TUE", "WED"];

  final List<Map<String, String>> periodTimes = [
    {"period": "Period 1", "time": "7:00 - 7:50"},
    {"period": "Period 2", "time": "7:50 - 8:35"},
    {"period": "Period 3", "time": "8:35 - 9:20"},
    {"period": "BREAK ☕", "time": "9:20 - 9:50"},
    {"period": "Period 4", "time": "9:50 - 10:35"},
    {"period": "Period 5", "time": "10:35 - 11:15"},
    {"period": "Period 6", "time": "11:15 - 11:50"},
  ];

  // Subject Colors & Code Mapping
  final Map<String, Map<String, dynamic>> subjectStyles = {
    "Arabic": {"color": const Color(0xFFFFF3CD), "textColor": const Color(0xFF856404), "code": "AR"},
    "Somali": {"color": const Color(0xFFE2F0D9), "textColor": const Color(0xFF385723), "code": "SO"},
    "Sport": {"color": const Color(0xFFD9E1F2), "textColor": const Color(0xFF1F4E79), "code": "SP"},
    "Islamic": {"color": const Color(0xFFE2EFDA), "textColor": const Color(0xFF276A3C), "code": "IS"},
    "English": {"color": const Color(0xFFFCE4D6), "textColor": const Color(0xFFC65911), "code": "EN"},
    "Handwriting": {"color": const Color(0xFFFFF2CC), "textColor": const Color(0xFFB25900), "code": "HW"},
    "Maths": {"color": const Color(0xFFDDEBF7), "textColor": const Color(0xFF1B365D), "code": "MA"},
    "Science": {"color": const Color(0xFFE2F0D9), "textColor": const Color(0xFF1E5128), "code": "SC"},
    "Social": {"color": const Color(0xFFF8CBAD), "textColor": const Color(0xFF843C0C), "code": "SS"},
    "Quran": {"color": const Color(0xFFE2EFDA), "textColor": const Color(0xFF155724), "code": "Q"},
  };

  // Per-tenant memory storage for timetables
  static final Map<String, Map<String, List<List<String>>>> _schoolTimetablesMap = {};
  static final Map<String, String?> _schoolTimetableImageMap = {};

  // Timetable Data for the active school
  Map<String, List<List<String>>> timetableData = {};
  String? uploadedTimetableImage;
  bool showImageView = false;

  String get effectiveTenantId {
    if (ApiService.currentTenantId != null) {
      return ApiService.currentTenantId.toString();
    }
    return "default_school";
  }

  String get effectiveSchoolName {
    if (ApiService.currentTenantName != null && ApiService.currentTenantName!.isNotEmpty) {
      return ApiService.currentTenantName!.toUpperCase();
    }
    return "IFTIINSHE SCHOOLS";
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: defaultClasses.length, vsync: this);

    // Initialize timetable for active school: starts empty unless previously uploaded or loaded
    if (_schoolTimetablesMap.containsKey(effectiveTenantId)) {
      timetableData = Map.from(_schoolTimetablesMap[effectiveTenantId]!);
    } else {
      timetableData = {}; // Empty by default for new schools!
    }

    if (_schoolTimetableImageMap.containsKey(effectiveTenantId)) {
      uploadedTimetableImage = _schoolTimetableImageMap[effectiveTenantId];
      if (uploadedTimetableImage != null && timetableData.isEmpty) {
        showImageView = true;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> get availableClasses {
    if (timetableData.isEmpty) return ["All"];
    return ["All", ...timetableData.keys.toList()];
  }

  void _loadSampleSchedule() {
    final sampleMap = {
      "Class 2A": [
        ["Arabic", "Somali", "Sport", "Islamic", "English"],
        ["Islamic", "English", "Handwriting", "Arabic", "Maths"],
        ["Somali", "Arabic", "Islamic", "Maths", "Science"],
        ["Science", "Science", "Somali", "Science", "Islamic"],
        ["Social", "Social", "English", "Social", "Arabic"],
        ["Quran", "Maths", "Quran", "Somali", "Handwriting"],
      ],
      "Class 3A": [
        ["Science", "Arabic", "Arabic", "Science", "Sport"],
        ["Social", "Islamic", "Sport", "Social", "Islamic"],
        ["Arabic", "Science", "English", "Islamic", "Maths"],
        ["Somali", "Maths", "Science", "Maths", "Science"],
        ["English", "Somali", "Social", "English", "Social"],
        ["Handwriting", "Quran", "Somali", "Quran", "Islamic"],
      ],
      "Class 4A": [
        ["Social", "Islamic", "Maths", "Sport", "Islamic"],
        ["English", "Science", "Social", "Maths", "Science"],
        ["Science", "English", "Science", "Science", "Arabic"],
        ["Arabic", "Arabic", "Arabic", "Arabic", "English"],
        ["Somali", "Quran", "Somali", "Somali", "Social"],
        ["Maths", "Handwriting", "Islamic", "Islamic", "Somali"],
      ],
      "Class 5A": [
        ["Arabic", "Maths", "Arabic", "English", "Social"],
        ["Maths", "Islamic", "Social", "Islamic", "Maths"],
        ["Somali", "Science", "Maths", "Science", "Arabic"],
        ["Social", "English", "English", "Maths", "Somali"],
        ["Islamic", "Handwriting", "Islamic", "Somali", "Science"],
        ["Handwriting", "Quran", "Science", "Quran", "Handwriting"],
      ],
      "Class 6A": [
        ["Science", "English", "Somali", "Maths", "Somali"],
        ["Arabic", "Maths", "Arabic", "English", "Science"],
        ["Maths", "Islamic", "Science", "Islamic", "Maths"],
        ["Somali", "Social", "Handwriting", "Social", "Arabic"],
        ["Social", "Somali", "English", "Handwriting", "English"],
        ["Islamic", "Science", "Quran", "Somali", "Social"],
      ],
      "Class 7A": [
        ["Somali", "Social", "Maths", "Science", "Islamic"],
        ["Science", "English", "Somali", "Maths", "Somali"],
        ["Arabic", "Maths", "Arabic", "English", "Science"],
        ["Maths", "Islamic", "Social", "Islamic", "Maths"],
        ["English", "Science", "Handwriting", "Social", "Arabic"],
        ["Social", "Somali", "English", "Handwriting", "English"],
      ],
      "Class 8A": [
        ["Maths", "Islamic", "Science", "Islamic", "Maths"],
        ["English", "Science", "Maths", "Science", "Islamic"],
        ["Science", "Somali", "English", "Maths", "English"],
        ["Arabic", "Maths", "Arabic", "Somali", "Social"],
        ["Social", "Arabic", "Social", "Arabic", "Maths"],
        ["Somali", "Social", "Maths", "Social", "Arabic"],
      ],
    };

    setState(() {
      timetableData = sampleMap;
      _schoolTimetablesMap[effectiveTenantId] = sampleMap;
      selectedClassFilter = "All";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Jadwalka dhawaaqa ah (Sample Schedule) si guul leh ayaa loo shubay!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _uploadExcelTimetable(BuildContext dialogContext) {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.csv,.xlsx,.xls';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsText(file);
          reader.onLoadEnd.listen((e) {
            final String? content = reader.result as String?;
            if (content != null && content.trim().isNotEmpty) {
              _parseAndApplyCsvData(content, file.name);
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Error picking Excel/CSV file: $e");
    }
  }

  void _parseAndApplyCsvData(String csvText, String fileName) {
    final Map<String, List<List<String>>> parsedMap = {};
    final lines = csvText.split('\n');
    String currentClass = "Class 2A";
    
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(',');
      if (parts.isEmpty) continue;

      final firstCol = parts[0].trim();
      if (firstCol.toLowerCase().contains('class') || firstCol.toLowerCase().contains('fasal')) {
        currentClass = firstCol;
        parsedMap.putIfAbsent(currentClass, () => []);
      } else if (parts.length >= 5) {
        final periodRow = parts.take(5).map((s) => s.trim()).toList();
        parsedMap.putIfAbsent(currentClass, () => []).add(periodRow);
      }
    }

    if (parsedMap.isEmpty) {
      // Fallback if formatting was simple: load sample schedule
      _loadSampleSchedule();
    } else {
      setState(() {
        timetableData = parsedMap;
        _schoolTimetablesMap[effectiveTenantId] = parsedMap;
        selectedClassFilter = "All";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Jadwalka Excel/CSV ee '$fileName' si guul leh ayaa loo soo geliyey!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _triggerPrint() {
    try {
      html.window.print();
    } catch (e) {
      debugPrint("Error triggering window.print: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Daabacaadda ayaa bilaabanaysa..."),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _loadSampleScheduleQuietly() {
    final sampleMap = {
      "Class 2A": [
        ["Arabic", "Somali", "Sport", "Islamic", "English"],
        ["Islamic", "English", "Handwriting", "Arabic", "Maths"],
        ["Somali", "Arabic", "Islamic", "Maths", "Science"],
        ["Science", "Science", "Somali", "Science", "Islamic"],
        ["Social", "Social", "English", "Social", "Arabic"],
        ["Quran", "Maths", "Quran", "Somali", "Handwriting"],
      ],
      "Class 3A": [
        ["Science", "Arabic", "Arabic", "Science", "Sport"],
        ["Social", "Islamic", "Sport", "Social", "Islamic"],
        ["Arabic", "Science", "English", "Islamic", "Maths"],
        ["Somali", "Maths", "Science", "Maths", "Science"],
        ["English", "Somali", "Social", "English", "Social"],
        ["Handwriting", "Quran", "Somali", "Quran", "Islamic"],
      ],
      "Class 4A": [
        ["Social", "Islamic", "Maths", "Sport", "Islamic"],
        ["English", "Science", "Social", "Maths", "Science"],
        ["Science", "English", "Science", "Science", "Arabic"],
        ["Arabic", "Arabic", "Arabic", "Arabic", "English"],
        ["Somali", "Quran", "Somali", "Somali", "Social"],
        ["Maths", "Handwriting", "Islamic", "Islamic", "Somali"],
      ],
      "Class 5A": [
        ["Arabic", "Maths", "Arabic", "English", "Social"],
        ["Maths", "Islamic", "Social", "Islamic", "Maths"],
        ["Somali", "Science", "Maths", "Science", "Arabic"],
        ["Social", "English", "English", "Maths", "Somali"],
        ["Islamic", "Handwriting", "Islamic", "Somali", "Science"],
        ["Handwriting", "Quran", "Science", "Quran", "Handwriting"],
      ],
      "Class 6A": [
        ["Science", "English", "Somali", "Maths", "Somali"],
        ["Arabic", "Maths", "Arabic", "English", "Science"],
        ["Maths", "Islamic", "Science", "Islamic", "Maths"],
        ["Somali", "Social", "Handwriting", "Social", "Arabic"],
        ["Social", "Somali", "English", "Handwriting", "English"],
        ["Islamic", "Science", "Quran", "Somali", "Social"],
      ],
      "Class 7A": [
        ["Somali", "Social", "Maths", "Science", "Islamic"],
        ["Science", "English", "Somali", "Maths", "Somali"],
        ["Arabic", "Maths", "Arabic", "English", "Science"],
        ["Maths", "Islamic", "Social", "Islamic", "Maths"],
        ["English", "Science", "Handwriting", "Social", "Arabic"],
        ["Social", "Somali", "English", "Handwriting", "English"],
      ],
      "Class 8A": [
        ["Maths", "Islamic", "Science", "Islamic", "Maths"],
        ["English", "Science", "Maths", "Science", "Islamic"],
        ["Science", "Somali", "English", "Maths", "English"],
        ["Arabic", "Maths", "Arabic", "Somali", "Social"],
        ["Social", "Arabic", "Social", "Arabic", "Maths"],
        ["Somali", "Social", "Maths", "Social", "Arabic"],
      ],
    };

    timetableData = sampleMap;
    _schoolTimetablesMap[effectiveTenantId] = sampleMap;
  }

  void _uploadImageTimetable(BuildContext context) {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((e) {
            final String? result = reader.result as String?;
            if (result != null && result.isNotEmpty) {
              setState(() {
                uploadedTimetableImage = result;
                _schoolTimetableImageMap[effectiveTenantId] = result;
                showImageView = true;
                if (timetableData.isEmpty) {
                  _loadSampleScheduleQuietly();
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Sawirka jadwalka xiisadaha '${file.name}' si guul leh ayaa loo soo geliyey!"),
                  backgroundColor: const Color(0xFF6366F1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Error picking timetable image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBanner(isDark),
            const SizedBox(height: 20),
            _buildControlsRow(isDark, textColor, cardColor),
            const SizedBox(height: 20),
            showImageView && uploadedTimetableImage != null
                ? _buildImageViewerContainer(isDark, cardColor, textColor)
                : (timetableData.isEmpty
                    ? _buildEmptyState(isDark, cardColor, textColor)
                    : _buildTimetableContent(isDark, cardColor, textColor)),
            const SizedBox(height: 24),
            _buildPeriodTimesFooter(isDark, cardColor, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5257), Color(0xFF0B6623), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5257).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.calendar_month_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.amberAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          effectiveSchoolName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "TIMETABLE • JADWALKA XIISADAHA ARDAYDA (2026 - 2027)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.cyanAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "KNOWLEDGE IS POWER • OGAALKU WAA AWOOD",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(bool isDark, Color textColor, Color cardColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Class Selector Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: availableClasses.map((cls) {
                  final bool isSelected = selectedClassFilter == cls;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cls),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      selectedColor: const Color(0xFF0F5257),
                      backgroundColor: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF0F5257) : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      onSelected: (val) {
                        setState(() {
                          selectedClassFilter = cls;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            // Actions (Upload Sawir, Upload Excel, Print & Delete)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _uploadImageTimetable(context),
                  icon: const Icon(Icons.image_rounded, size: 18),
                  label: const Text("Upload Sawirka Jadwalka"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _uploadExcelTimetable(context),
                  icon: const Icon(Icons.table_chart_rounded, size: 18),
                  label: const Text("Upload Excel / CSV"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF107C41),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _triggerPrint,
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text("Print / Save Timetable"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                if (uploadedTimetableImage != null)
                  IconButton(
                    tooltip: showImageView ? "U Badal Shaxda (Grid View)" : "Eeg Sawirka (Image View)",
                    icon: Icon(
                      showImageView ? Icons.grid_view_rounded : Icons.image_rounded,
                      color: const Color(0xFF6366F1),
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        showImageView = !showImageView;
                      });
                    },
                  ),
                if (timetableData.isNotEmpty || uploadedTimetableImage != null)
                  ElevatedButton.icon(
                    onPressed: _confirmDeleteAllTimetable,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("Tirtir / Delete Timetable"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAllTimetable() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text("Tirtir Jadwalka Xiisadaha?"),
            ],
          ),
          content: const Text(
            "Ma ziirtaa inaad rabto inaad dhammaan tirtirto jadwalka xiisadaha Iskuulkan? Waxaad ka dib soo upload-gareyn kartaa jadval cusub oo Excel ama Sawir ah.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Baaq / Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text("Tirtir Dhamaan / Delete All"),
              onPressed: () {
                setState(() {
                  timetableData.clear();
                  uploadedTimetableImage = null;
                  showImageView = false;
                  _schoolTimetablesMap.remove(effectiveTenantId);
                  _schoolTimetableImageMap.remove(effectiveTenantId);
                  selectedClassFilter = "All";
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Jadwalka xiisadaha iskuulka si buuxda ayaa loo tirtiray!"),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageViewerContainer(bool isDark, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_rounded, color: Color(0xFF6366F1), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "SAWIRKA JADWALKA XIISADAHA",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showImageView = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Waa loo badalay shaxda interaktiv-ka ah ee xiisadaha! ✨"),
                          backgroundColor: Color(0xFF0F5257),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text("U Badal Shaxda (Grid View)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5257),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    tooltip: "Tirtir Sawirka",
                    onPressed: () {
                      setState(() {
                        uploadedTimetableImage = null;
                        _schoolTimetableImageMap.remove(effectiveTenantId);
                        showImageView = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 550),
                  width: double.infinity,
                  color: isDark ? Colors.black38 : Colors.grey.shade100,
                  child: Image.network(
                    uploadedTimetableImage!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text("Cilad ayaa ka dhacday soo bandhigida sawirka"),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: "zoom_timetable_image",
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    tooltip: "Eeg Mugged Buuxa (Full Screen)",
                    onPressed: () => _showFullScreenImage(context, uploadedTimetableImage!),
                    child: const Icon(Icons.zoom_in_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteClassSchedule(String className) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.delete_sweep_rounded, color: Colors.orangeAccent),
              const SizedBox(width: 10),
              Text("Tirtir $className?"),
            ],
          ),
          content: Text(
            "Ma ziirtaa inaad rabto inaad jadwalka $className ka tirtirto nidaamka?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Baaq / Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  timetableData.remove(className);
                  if (_schoolTimetablesMap.containsKey(effectiveTenantId)) {
                    _schoolTimetablesMap[effectiveTenantId]!.remove(className);
                  }
                  if (!availableClasses.contains(selectedClassFilter)) {
                    selectedClassFilter = "All";
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Jadwalka $className si guul leh ayaa loo tirtiray!"),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Tirtir Fasalka"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0F5257).withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F5257).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_view_month_rounded, size: 64, color: Color(0xFF0F5257)),
          ),
          const SizedBox(height: 20),
          Text(
            "Jadwalka Xiisadaha Iskuulkan Wali Ma La Soo Gelin",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Iskuul walba wuxuu leeyahay jadwalkiisa u gaarka ah. Fadlan ka soo upload-gareey sawirka jadwalka, faylka Excel/CSV ama soo dhig jadwalka xiisadaha iskuulkaaga:",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _uploadImageTimetable(context),
                icon: const Icon(Icons.image_rounded, size: 20),
                label: const Text("Soo Gali Sawirka Jadwalka"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _uploadExcelTimetable(context),
                icon: const Icon(Icons.table_chart_rounded, size: 20),
                label: const Text("Soo Gali Faylka Excel / CSV"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loadSampleSchedule,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 20),
                label: const Text("Shubh Jadval Demo Ah (Sample)"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F5257),
                  side: const BorderSide(color: Color(0xFF0F5257)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableContent(bool isDark, Color cardColor, Color textColor) {
    List<String> activeClasses = selectedClassFilter == "All"
        ? timetableData.keys.toList()
        : [selectedClassFilter];

    return Column(
      children: activeClasses.map((cls) {
        final List<List<String>> schedule = timetableData[cls] ?? [];
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Header Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getClassHeaderColors(cls),
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.class_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          cls.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${schedule.length} PERIODS / DAY",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                          tooltip: "Tirtir $cls",
                          onPressed: () => _deleteClassSchedule(cls),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Table Layout
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  ),
                  columns: [
                    const DataColumn(
                      label: Text("P", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    ...days.map((d) => DataColumn(
                      label: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F5257).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF0F5257),
                          ),
                        ),
                      ),
                    )),
                  ],
                  rows: List.generate(6, (pIndex) {
                    final int periodNum = pIndex + 1;
                    return DataRow(
                      cells: [
                        DataCell(
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.blueGrey.shade100,
                            child: Text(
                              "$periodNum",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        ...List.generate(5, (dIndex) {
                          final subjectName = (schedule.length > pIndex && schedule[pIndex].length > dIndex)
                              ? schedule[pIndex][dIndex]
                              : "Free";
                          return DataCell(_buildSubjectBadge(subjectName));
                        }),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Color> _getClassHeaderColors(String className) {
    if (className.contains('2') || className.contains('3') || className.contains('4')) {
      return [const Color(0xFF0F5257), const Color(0xFF1E7E34)];
    }
    return [const Color(0xFF1E3A8A), const Color(0xFF2563EB)];
  }

  Widget _buildSubjectBadge(String subject) {
    final style = subjectStyles[subject] ?? {
      "color": Colors.grey.shade200,
      "textColor": Colors.black87,
      "code": subject.length >= 2 ? subject.substring(0, 2).toUpperCase() : subject.toUpperCase(),
    };

    final Color badgeColor = style["color"] as Color;
    final Color txtColor = style["textColor"] as Color;
    final String code = style["code"] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: txtColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: txtColor.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Text(
              code,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: txtColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            subject,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: txtColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTimesFooter(bool isDark, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0F5257).withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time_filled_rounded, color: Color(0xFF0F5257)),
              SizedBox(width: 8),
              Text(
                "PERIOD TIMES • WAKHTIYADA XIISADAHA IYO NASASHADA",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF0F5257),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: periodTimes.map((pt) {
                  final bool isBreak = pt["period"]!.contains("BREAK");
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isBreak ? const Color(0xFFFFF3CD) : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBreak ? Colors.amber.shade400 : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pt["period"]!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isBreak ? const Color(0xFF856404) : const Color(0xFF0F5257),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pt["time"]!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
