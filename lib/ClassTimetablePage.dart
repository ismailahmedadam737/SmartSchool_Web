import 'dart:convert';
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

  // Multi-image Timetable Map per Class
  // Key: Class Name e.g. "General", "Class 2A", "Class 3A"...
  // Value: List of image URLs / base64 Data URLs
  Map<String, List<String>> classTimetableImagesMap = {};

  // Timetable Data Grid for the active school
  Map<String, List<List<String>>> timetableData = {};

  // Custom Period Times per school
  List<Map<String, String>>? customPeriodTimes;

  bool showImageView = true;

  List<Map<String, String>> get effectivePeriodTimes {
    if (customPeriodTimes != null && customPeriodTimes!.isNotEmpty) {
      return customPeriodTimes!;
    }
    return periodTimes;
  }

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

  bool get canManageTimetable {
    final role = widget.userRole.trim().toLowerCase();
    if (role == 'student' || role == 'parent' || role == 'user' || role == 'ardey' || role.contains('student') || role.contains('parent')) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: defaultClasses.length, vsync: this);
    _loadPersistedTimetableData();
  }

  void _loadPersistedTimetableData() {
    // 1. Grid Data
    final String? gridJson = ApiService.readStorage('timetable_grid_data');
    if (gridJson != null && gridJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(gridJson);
        Map<String, List<List<String>>> loadedGrid = {};
        decoded.forEach((key, val) {
          if (val is List) {
            List<List<String>> rows = [];
            for (var row in val) {
              if (row is List) {
                rows.add(row.map((item) => item.toString()).toList());
              }
            }
            loadedGrid[key] = rows;
          }
        });
        if (loadedGrid.isNotEmpty) {
          timetableData = loadedGrid;
        }
      } catch (e) {
        debugPrint("Error loading timetable grid data: $e");
      }
    }

    // 2. Class Timetable Images
    final String? imagesJson = ApiService.readStorage('timetable_class_images');
    if (imagesJson != null && imagesJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(imagesJson);
        Map<String, List<String>> loadedImages = {};
        decoded.forEach((key, val) {
          if (val is List) {
            loadedImages[key] = val.map((e) => e.toString()).toList();
          }
        });
        classTimetableImagesMap = loadedImages;
      } catch (e) {
        debugPrint("Error loading class timetable images: $e");
      }
    } else {
      // Legacy single image compatibility
      final String? oldSingle = ApiService.readStorage('timetable_single_image');
      if (oldSingle != null && oldSingle.isNotEmpty) {
        classTimetableImagesMap["General"] = [oldSingle];
      }
    }

    // 3. Period Times
    final String? timesJson = ApiService.readStorage('timetable_period_times');
    if (timesJson != null && timesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(timesJson);
        List<Map<String, String>> loadedTimes = [];
        for (var item in decoded) {
          if (item is Map) {
            loadedTimes.add({
              "period": item["period"]?.toString() ?? "",
              "time": item["time"]?.toString() ?? "",
            });
          }
        }
        if (loadedTimes.isNotEmpty) {
          customPeriodTimes = loadedTimes;
        }
      } catch (e) {
        debugPrint("Error loading period times: $e");
      }
    }

    if (timetableData.isEmpty) {
      _loadSampleScheduleQuietly();
    }
  }

  void _saveTimetableData() {
    try {
      ApiService.savePersistentSetting('timetable_grid_data', timetableData);
      ApiService.savePersistentSetting('timetable_class_images', classTimetableImagesMap);
      if (customPeriodTimes != null) {
        ApiService.savePersistentSetting('timetable_period_times', customPeriodTimes);
      }
    } catch (e) {
      debugPrint("Error saving timetable data: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> get availableClasses {
    final set = <String>{"All"};
    for (var c in defaultClasses) {
      if (c != "All") set.add(c);
    }
    set.addAll(timetableData.keys);
    for (var k in classTimetableImagesMap.keys) {
      if (k != "General" && k != "All") set.add(k);
    }
    return set.toList();
  }

  bool get hasTimetableImages {
    for (var list in classTimetableImagesMap.values) {
      if (list.isNotEmpty) return true;
    }
    return false;
  }

  List<Map<String, dynamic>> get activeTimetableImages {
    List<Map<String, dynamic>> list = [];
    if (selectedClassFilter == "All") {
      classTimetableImagesMap.forEach((clsKey, imgList) {
        for (int i = 0; i < imgList.length; i++) {
          list.add({"class": clsKey, "url": imgList[i], "index": i});
        }
      });
    } else {
      if (classTimetableImagesMap.containsKey(selectedClassFilter)) {
        final imgList = classTimetableImagesMap[selectedClassFilter]!;
        for (int i = 0; i < imgList.length; i++) {
          list.add({"class": selectedClassFilter, "url": imgList[i], "index": i});
        }
      }
      if (classTimetableImagesMap.containsKey("General")) {
        final imgList = classTimetableImagesMap["General"]!;
        for (int i = 0; i < imgList.length; i++) {
          list.add({"class": "General", "url": imgList[i], "index": i});
        }
      }
    }
    return list;
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
      selectedClassFilter = "All";
      _saveTimetableData();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Jadwalka muunada ah (Sample Schedule) si guul leh ayaa loo kaysiyay! ✨"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _loadSampleScheduleQuietly() {
    timetableData = {
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
  }

  void _showUploadTimetableImageDialog(BuildContext context) {
    String targetClass = selectedClassFilter == "All" ? "General" : selectedClassFilter;
    final TextEditingController urlController = TextEditingController();
    final TextEditingController customClassController = TextEditingController();
    bool isCustomClass = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final List<String> classOptions = [
              "General",
              "Class 2A", "Class 3A", "Class 4A", "Class 5A", "Class 6A", "Class 7A", "Class 8A",
              "Fasal Cusub / Custom Class"
            ];

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF6366F1)),
                  SizedBox(width: 10),
                  Text("Soo Gali Sawirka Jadwalka", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dooro Fasal-ka ama Xiisada sawirka jadwalka uu u gaarka yahay:",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: classOptions.contains(targetClass) ? targetClass : (isCustomClass ? "Fasal Cusub / Custom Class" : "General"),
                      decoration: InputDecoration(
                        labelText: "Dooro Fasal (Target Class)",
                        prefixIcon: const Icon(Icons.school_rounded, color: Color(0xFF6366F1)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: classOptions.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c == "General" ? "Dhammaan Fasallada (General)" : c),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            if (val == "Fasal Cusub / Custom Class") {
                              isCustomClass = true;
                              targetClass = "";
                            } else {
                              isCustomClass = false;
                              targetClass = val;
                            }
                          });
                        }
                      },
                    ),
                    if (isCustomClass) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customClassController,
                        decoration: InputDecoration(
                          labelText: "Magaca Fasalka Cusub (e.g. Form 1B)",
                          prefixIcon: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) {
                          targetClass = val.trim();
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      "Waxaad ka soo xuli kartaa sawirka Computer-ka ama waxaad gelin kartaa Link-ka (URL):",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final selectedCls = isCustomClass ? customClassController.text.trim() : targetClass;
                          final finalClass = selectedCls.isEmpty ? "General" : selectedCls;
                          Navigator.pop(ctx);
                          _pickTimetableImageFromComputer(finalClass);
                        },
                        icon: const Icon(Icons.folder_open_rounded, size: 20),
                        label: const Text(
                          "📁 Ka Xul Computer-ka (Documents/Pictures)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text("AMA / OR", style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: "URL Link Sawirka Jadwalka",
                        hintText: "https://example.com/timetable.jpg",
                        prefixIcon: const Icon(Icons.link, color: Color(0xFF6366F1)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Baaq / Cancel"),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5257),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text("Gali Link-ka"),
                  onPressed: () {
                    final text = urlController.text.trim();
                    final selectedCls = isCustomClass ? customClassController.text.trim() : targetClass;
                    final finalClass = selectedCls.isEmpty ? "General" : selectedCls;
                    if (text.isNotEmpty) {
                      _addTimetableImage(finalClass, text);
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _pickTimetableImageFromComputer(String targetClass) {
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
              _addTimetableImage(targetClass, result);
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Error picking timetable image: $e");
    }
  }

  void _addTimetableImage(String targetClass, String imageStr) {
    setState(() {
      if (!classTimetableImagesMap.containsKey(targetClass)) {
        classTimetableImagesMap[targetClass] = [];
      }
      classTimetableImagesMap[targetClass]!.insert(0, imageStr);
      showImageView = true;
      _saveTimetableData();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sawirka jadwalka ($targetClass) si guul leh ayaa loo kaysiyay (Permanently Saved)! ✨"),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteSingleTimetableImage(String targetClass, int index) {
    setState(() {
      if (classTimetableImagesMap.containsKey(targetClass)) {
        classTimetableImagesMap[targetClass]!.removeAt(index);
        if (classTimetableImagesMap[targetClass]!.isEmpty) {
          classTimetableImagesMap.remove(targetClass);
        }
        _saveTimetableData();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Sawirka jadwalka si guul leh ayaa loo tirtiray!"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _triggerPrint() {
    try {
      final List<String> activeClasses = selectedClassFilter == "All"
          ? (timetableData.isNotEmpty ? timetableData.keys.toList() : ["Class 2A"])
          : [selectedClassFilter];

      String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <title>Timetable - $effectiveSchoolName</title>
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; color: #1e293b; background: #ffffff; }
    .header { text-align: center; margin-bottom: 24px; border-bottom: 3px solid #0f5257; padding-bottom: 12px; }
    .school-name { font-size: 26px; font-weight: 900; color: #0f5257; text-transform: uppercase; margin: 0; letter-spacing: 1px; }
    .subtitle { font-size: 13px; color: #475569; margin-top: 4px; font-weight: 700; letter-spacing: 0.5px; }
    .class-section { margin-bottom: 30px; page-break-inside: avoid; }
    .class-title { font-size: 16px; font-weight: 900; background: #0f5257; color: white; padding: 10px 16px; border-radius: 8px 8px 0 0; text-transform: uppercase; }
    table { width: 100%; border-collapse: collapse; margin-top: 0; }
    th, td { border: 1px solid #cbd5e1; padding: 10px; text-align: center; font-size: 13px; }
    th { background-color: #f1f5f9; font-weight: bold; color: #0f5257; }
    tr:nth-child(even) { background-color: #f8fafc; }
    .footer { margin-top: 24px; font-size: 12px; color: #475569; border-top: 1.5px solid #e2e8f0; padding-top: 14px; }
    .period-title { font-weight: bold; color: #0f5257; font-size: 13px; margin-bottom: 8px; }
    .period-times { display: flex; flex-wrap: wrap; gap: 10px; }
    .period-box { background: #f1f5f9; padding: 8px 14px; border-radius: 8px; border: 1px solid #cbd5e1; }
    .period-box strong { color: #0f5257; display: block; font-size: 11px; margin-bottom: 2px; }
    @media print {
      body { margin: 0; }
      @page { margin: 1cm; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1 class="school-name">$effectiveSchoolName</h1>
    <div class="subtitle">STUDENT CLASS TIMETABLE • JADWALKA XIISADAHA ARDAYDA (2026 - 2027)</div>
  </div>
''';

      for (var cls in activeClasses) {
        final schedule = timetableData[cls] ?? [];
        htmlContent += '''
  <div class="class-section">
    <div class="class-title">${cls.toUpperCase()}</div>
    <table>
      <thead>
        <tr>
          <th>P</th>
          ${days.map((d) => '<th>$d</th>').join('')}
        </tr>
      </thead>
      <tbody>
''';
        for (int pIndex = 0; pIndex < 6; pIndex++) {
          final periodNum = pIndex + 1;
          htmlContent += '<tr><td><strong>P$periodNum</strong></td>';
          for (int dIndex = 0; dIndex < 5; dIndex++) {
            final subjectName = (schedule.length > pIndex && schedule[pIndex].length > dIndex)
                ? schedule[pIndex][dIndex]
                : "Free";
            htmlContent += '<td>$subjectName</td>';
          }
          htmlContent += '</tr>';
        }
        htmlContent += '''
      </tbody>
    </table>
  </div>
''';
      }

      htmlContent += '''
  <div class="footer">
    <div class="period-title">PERIOD TIMES / WAKHTIYADA XIISADAHA IYO NASASHADA:</div>
    <div class="period-times">
''';
      for (var pt in effectivePeriodTimes) {
        htmlContent += '''
      <div class="period-box">
        <strong>${pt["period"]}</strong>
        <span>${pt["time"]}</span>
      </div>
''';
      }
      htmlContent += '''
    </div>
  </div>
  <script>
    window.onload = function() {
      window.print();
    };
  </script>
</body>
</html>
''';

      final blob = html.Blob([htmlContent], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
    } catch (e) {
      debugPrint("Error creating print window: $e");
      html.window.print();
    }
  }

  void _showEditPeriodTimesDialog() {
    final List<Map<String, String>> currentTimes = effectivePeriodTimes;
    final List<TextEditingController> controllers = currentTimes.map((pt) {
      return TextEditingController(text: pt["time"]);
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.settings_rounded, color: Color(0xFF0F5257)),
              SizedBox(width: 10),
              Text("Habee Wakhtiyada Xiisadaha"),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Beddel ama habee saacadaha xiisadaha Iskuulka (Start - End):",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(currentTimes.length, (index) {
                    final pt = currentTimes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextField(
                        controller: controllers[index],
                        decoration: InputDecoration(
                          labelText: pt["period"],
                          prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Baaq / Cancel"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5257),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text("Kaysi / Save"),
              onPressed: () {
                final List<Map<String, String>> updated = [];
                for (int i = 0; i < currentTimes.length; i++) {
                  updated.add({
                    "period": currentTimes[i]["period"]!,
                    "time": controllers[i].text.trim(),
                  });
                }
                setState(() {
                  customPeriodTimes = updated;
                  _saveTimetableData();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Wakhtiyada xiisadaha dugsiga si guul leh ayaa loo kaysiyay! ✨"),
                    backgroundColor: Color(0xFF0F5257),
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final List<Map<String, dynamic>> imagesList = activeTimetableImages;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBanner(isDark, isMobile),
                const SizedBox(height: 16),
                _buildControlsRow(isDark, textColor, cardColor),
                // Timetable Grid or Empty State
                timetableData.isEmpty
                    ? _buildEmptyState(isDark, cardColor, textColor)
                    : _buildTimetableContent(isDark, cardColor, textColor),

                const SizedBox(height: 20),
                _buildPeriodTimesFooter(isDark, cardColor, textColor),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBanner(bool isDark, bool isMobile) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: isMobile ? 14 : 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F5257), Color(0xFF0B6623), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F5257).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
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
                size: isMobile ? 90 : 140,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: Icon(Icons.school_rounded, color: Colors.amberAccent, size: isMobile ? 24 : 30),
                    ),
                    SizedBox(width: isMobile ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF00D2FF), Color(0xFF928DFF), Color(0xFF00E676)],
                            ).createShader(bounds),
                            child: Text(
                              effectiveSchoolName,
                              style: TextStyle(
                                fontSize: isMobile ? 17 : 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "WELCOME TO CLASS TIMETABLE 👋 • JADWALKA XIISADAHA",
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.cyanAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 10 : 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        "KNOWLEDGE IS POWER • AQOONTU WAA AWOOD",
                        style: TextStyle(color: Colors.white, fontSize: isMobile ? 9 : 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
            // Actions (Upload Sawir, Print & Delete)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canManageTimetable)
                  ElevatedButton.icon(
                    onPressed: () => _showUploadTimetableImageDialog(context),
                    icon: const Icon(Icons.image_rounded, size: 18),
                    label: Text(selectedClassFilter == "All" ? "Upload Sawirka Jadwalka" : "Upload Sawir ($selectedClassFilter)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
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
                if (canManageTimetable && (timetableData.isNotEmpty || hasTimetableImages))
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dooro waxa aad rabto inaad tirtirto (${selectedClassFilter == "All" ? "Dhammaan Iskuulka" : selectedClassFilter}):",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (hasTimetableImages)
                ListTile(
                  leading: const Icon(Icons.image_not_supported_rounded, color: Colors.orangeAccent),
                  title: Text("Tirtir Sawirada Jadwalka ($selectedClassFilter)"),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      if (selectedClassFilter == "All") {
                        classTimetableImagesMap.clear();
                      } else {
                        classTimetableImagesMap.remove(selectedClassFilter);
                      }
                      _saveTimetableData();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Sawirada jadwalka ($selectedClassFilter) si guul leh ayaa loo tirtiray!"),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              if (timetableData.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.table_rows_rounded, color: Colors.redAccent),
                  title: Text("Tirtir Shaxda Xiisadaha ($selectedClassFilter)"),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      if (selectedClassFilter == "All") {
                        timetableData.clear();
                      } else {
                        timetableData.remove(selectedClassFilter);
                      }
                      _saveTimetableData();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Shaxda xiisadaha ($selectedClassFilter) si guul leh ayaa loo tirtiray!"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: const Text("Tirtir Dhamaan (Everything)"),
                subtitle: const Text("Wuxuu tirtirayaa sawirada iyo shaxdaba", style: TextStyle(fontSize: 11)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    timetableData.clear();
                    classTimetableImagesMap.clear();
                    selectedClassFilter = "All";
                    _saveTimetableData();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Dhammaan jadwalka xiisadaha dugsiga si buuxda ayaa loo tirtiray!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Baaq / Cancel", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageViewerGallery(bool isDark, Color cardColor, Color textColor, List<Map<String, dynamic>> imagesList) {
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
                    "SAWIRADA JADWALKA XIISADAHA (${imagesList.length} SAWIR)",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (canManageTimetable)
                ElevatedButton.icon(
                  onPressed: () => _showUploadTimetableImageDialog(context),
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                  label: const Text("Soo Gali Sawir Kale"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Display list of timetable images
          ...imagesList.map((item) {
            final String clsName = item["class"] as String;
            final String imgUrl = item["url"] as String;
            final int imgIndex = item["index"] as int;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badge for class image
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F5257).withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bookmark_rounded, color: Color(0xFF0F5257), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              clsName == "General" ? "JADWALKA ALBAABKA / GENERAL TIMETABLE" : "JADWALKA: ${clsName.toUpperCase()}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F5257),
                              ),
                            ),
                          ],
                        ),
                        if (canManageTimetable)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            tooltip: "Tirtir sawirkan jadwalka",
                            onPressed: () => _deleteSingleTimetableImage(clsName, imgIndex),
                          ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxHeight: 550),
                          width: double.infinity,
                          color: isDark ? Colors.black38 : Colors.grey.shade100,
                          child: Image.network(
                            imgUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Center(child: Text("Cilad ayaa ka dhacday soo bandhigida sawirka")),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: FloatingActionButton.small(
                            heroTag: "zoom_timetable_${clsName}_$imgIndex",
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            tooltip: "Eeg Mugged Buuxa (Full Screen)",
                            onPressed: () => _showFullScreenImage(context, imgUrl),
                            child: const Icon(Icons.zoom_in_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
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
            "Ma doonaysaa  inaad jadwalka $className ka tirtirto nidaamka?",
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
                  _saveTimetableData();
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
            "Jadwalka Xiisadaha Dugsiga wali lama soo gelin",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canManageTimetable
                ? "Dugsi walba wuxuu leeyahay jadwalkiisa u gaarka ah. Fadlan ka soo upload-gareey sawirka jadwalka ama soo dhig jadwalka xiisadaha iskuulkaaga:"
                : "Fadlan kala xidhiidh maamulka dugsiga  si jadwalka xiisadaha loo soo geliyo.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          if (canManageTimetable) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showUploadTimetableImageDialog(context),
                  icon: const Icon(Icons.image_rounded, size: 20),
                  label: const Text("Soo Gali Sawirka Jadwalka"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _loadSampleSchedule,
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 20),
                  label: const Text("Jadwal muunad ah (Sample)"),
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
        ],
      ),
    );
  }

  Widget _buildTimetableContent(bool isDark, Color cardColor, Color textColor) {
    List<String> activeClasses = selectedClassFilter == "All"
        ? timetableData.keys.toList()
        : [selectedClassFilter];

    if (activeClasses.isEmpty) return const SizedBox.shrink();

    return Column(
      children: activeClasses.map((cls) {
        final List<List<String>> schedule = timetableData[cls] ?? [];
        if (schedule.isEmpty) return const SizedBox.shrink();

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
                        if (canManageTimetable) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                            tooltip: "Tirtir $cls",
                            onPressed: () => _deleteClassSchedule(cls),
                          ),
                        ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, color: Color(0xFF0F5257)),
                  SizedBox(width: 8),
                  Text(
                    "PERIOD TIMES • (WAKHTIYADA XIISADAHA IYO NASASHADA)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF0F5257),
                    ),
                  ),
                ],
              ),
              if (canManageTimetable)
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Color(0xFF0F5257)),
                  tooltip: "Habee Wakhtiyada Xiisadaha (Edit Period Times)",
                  onPressed: _showEditPeriodTimesDialog,
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: effectivePeriodTimes.map((pt) {
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
