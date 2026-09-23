import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'Service/api_service.dart';

class NationalExamsYearsPage extends StatefulWidget {
  final String subjectKey;
  final String subjectTitle;
  final Color accentColor;
  final String userRole;

  const NationalExamsYearsPage({
    super.key,
    required this.subjectKey,
    required this.subjectTitle,
    required this.accentColor,
    this.userRole = '',
  });

  @override
  State<NationalExamsYearsPage> createState() => _NationalExamsYearsPageState();
}

class _NationalExamsYearsPageState extends State<NationalExamsYearsPage> {
  final List<int> _years = [2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018];
  Map<int, Map<String, dynamic>> _uploadedExams = {};
  bool _isLoading = true;

  bool get canManageExams {
    final r = widget.userRole.trim().toLowerCase();
    if (r == 'user' || r.contains('student') || r.contains('ardey') || r.contains('parent') || r.contains('waalid')) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    final examsList = await ApiService.getNationalExams(subject: widget.subjectKey);
    final Map<int, Map<String, dynamic>> map = {};
    for (var exam in examsList) {
      final y = int.tryParse(exam['year'].toString());
      if (y != null) {
        map[y] = exam;
      }
    }
    setState(() {
      _uploadedExams = map;
      _isLoading = false;
    });
  }

  String _getEmbeddedViewerUrl(String rawUrl) {
    String url = rawUrl.trim();
    if (url.startsWith('data:application/pdf') || url.startsWith('data:')) {
      try {
        final parts = url.split(',');
        if (parts.length > 1) {
          final bytes = base64Decode(parts[1]);
          final blob = html.Blob([bytes], 'application/pdf');
          return html.Url.createObjectUrlFromBlob(blob);
        }
      } catch (e) {
        debugPrint("Error creating blob URL: $e");
      }
      return url;
    }
    if (url.contains('drive.google.com/file/d/')) {
      if (url.contains('/view')) {
        url = url.replaceAll(RegExp(r'/view.*'), '/preview');
      } else if (!url.endsWith('/preview')) {
        url = '$url/preview';
      }
      return url;
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (url.toLowerCase().contains('.pdf')) {
        return 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(url)}';
      }
    }
    return url;
  }

  void _showUploadDialog({int? preselectedYear, Map<String, dynamic>? existingExam}) {
    if (!canManageExams) return;

    final titleController = TextEditingController(
      text: existingExam != null ? existingExam['title'] : 'Somaliland Grade 8 Exam ${preselectedYear ?? 2026} - ${widget.subjectKey}',
    );
    final yearController = TextEditingController(
      text: (preselectedYear ?? (existingExam != null ? existingExam['year'] : 2026)).toString(),
    );
    final urlController = TextEditingController(
      text: existingExam != null ? existingExam['pdf_url'] : '',
    );

    String? selectedFileName;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void pickPdfFile() {
              try {
                final uploadInput = html.FileUploadInputElement();
                uploadInput.accept = 'application/pdf,.pdf';
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
                        setModalState(() {
                          urlController.text = result;
                          selectedFileName = file.name;
                        });
                      }
                    });
                  }
                });
              } catch (e) {
                debugPrint("Error picking PDF: $e");
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.cloud_upload_rounded, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 10),
                  Text(
                    existingExam != null ? 'Wax ka baddal Imtixaanka' : 'Geli Imtixaan Cusub (PDF)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ciwaanka Imtixaanka (Title)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Sanadka (2018 - 2026)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Dooro Habka Gelinta PDF-ka (Sideedaba 17 Bogag A4 ah):',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: pickPdfFile,
                        icon: Icon(
                          selectedFileName != null ? Icons.check_circle_rounded : Icons.folder_open_rounded,
                          color: Colors.black,
                        ),
                        label: Text(
                          selectedFileName != null ? '✅ $selectedFileName' : '📁 Ka Xul Computer-ka (Upload PDF)',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedFileName != null ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'AMA / OR (Google Drive / Online Link)',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Direct PDF URL (Google Drive / Online Link)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'https://drive.google.com/... ama https://site.com/exam.pdf',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Talo: Haddii imtixaanku yahay bogag badan (e.g. 17 A4 pages), geli Link-ga Google Drive si mobilada dhan toos ugu furmo!',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kansal', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final textVal = urlController.text.trim();
                          if (textVal.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fadlan xul fayl PDF ah ama geli link-ga PDF-ka')),
                            );
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          final ok = await ApiService.uploadNationalExam({
                            'title': titleController.text.trim(),
                            'subject': widget.subjectKey,
                            'year': int.tryParse(yearController.text.trim()) ?? 2026,
                            'pdf_url': textVal,
                            'tenant_id': ApiService.currentTenantId,
                            'school_name': ApiService.currentTenantName,
                          });
                          setModalState(() => isSubmitting = false);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _fetchExams();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Imtixaanka si guul leh ayaa loo kaysiyay server-ka oo mobilada dhan waa laga arki karaa! ✨'
                                    : 'Imtixaanka si guul leh ayaa loo kaysiyay local-ka.'),
                                backgroundColor: ok ? Colors.green : Colors.orange,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Kaydi Imtixaanka', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openPdfViewer(Map<String, dynamic> exam) {
    final String rawPdfUrl = exam['pdf_url'] ?? '';
    final String title = exam['title'] ?? 'National Exam PDF';
    final String displayUrl = _getEmbeddedViewerUrl(rawPdfUrl);

    if (kIsWeb) {
      try {
        html.window.open(displayUrl, '_blank');
      } catch (e) {
        debugPrint("Error opening PDF in window: $e");
      }
      _registerIframeView(displayUrl);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Somaliland Grade 8 Past Paper',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (kIsWeb) {
                      if (rawPdfUrl.startsWith('data:')) {
                        final anchor = html.AnchorElement(href: rawPdfUrl)
                          ..target = '_blank'
                          ..download = '$title.pdf';
                        anchor.click();
                      } else {
                        html.window.open(rawPdfUrl, '_blank');
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                  label: const Text('Soo Dajiso PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1E293B),
            child: kIsWeb
                ? HtmlElementView(
                    viewType: 'pdf_iframe_${displayUrl.hashCode}',
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, size: 80, color: Color(0xFFEF4444)),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          onPressed: () {
                            if (kIsWeb) {
                              if (rawPdfUrl.startsWith('data:')) {
                                final anchor = html.AnchorElement(href: rawPdfUrl)
                                  ..target = '_blank'
                                  ..download = '$title.pdf';
                                anchor.click();
                              } else {
                                html.window.open(rawPdfUrl, '_blank');
                              }
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded, color: Colors.black),
                          label: const Text('Fura Imtixaanka (Open PDF)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _registerIframeView(String url) {
    if (kIsWeb) {
      final String viewId = 'pdf_iframe_${url.hashCode}';
      ui_web.platformViewRegistry.registerViewFactory(
        viewId,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = url
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allow = 'autoplay; encrypted-media; fullscreen';
          return iframe;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'Xulashada Sannadka (2018 - 2026)',
              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchExams,
            tooltip: 'Cusboonaysii',
          ),
          if (canManageExams)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showUploadDialog(),
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                label: const Text('Geli PDF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.picture_as_pdf_rounded, color: widget.accentColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.subjectTitle} - Past Papers',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Guji sanadka uu imtixaanku "Diyaar" yahay si aad u akhriso ama ugu soo dajiso PDF.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 900
                          ? 3
                          : MediaQuery.of(context).size.width > 600
                              ? 2
                              : 1,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final year = _years[index];
                        final hasExam = _uploadedExams.containsKey(year);
                        final examData = _uploadedExams[year];

                        return _buildYearCard(context, year, hasExam, examData);
                      },
                      childCount: _years.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildYearCard(BuildContext context, int year, bool isAvailable, Map<String, dynamic>? examData) {
    return Container(
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFF1E293B) : const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable ? const Color(0xFF10B981).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
          width: isAvailable ? 1.5 : 1,
        ),
        boxShadow: isAvailable
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable
              ? () => _openPdfViewer(examData!)
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Imtixaanka $year weli ma uusan saarin maamulku.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isAvailable ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isAvailable ? const Color(0xFF10B981) : Colors.white24,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$year',
                      style: TextStyle(
                        color: isAvailable ? const Color(0xFF10B981) : Colors.white54,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAvailable ? (examData?['title'] ?? 'Imtixaanka $year') : 'Imtixaanka $year',
                        style: TextStyle(
                          color: isAvailable ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAvailable ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvailable ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
                                  size: 13,
                                  color: isAvailable ? const Color(0xFF10B981) : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAvailable ? 'AVAILABLE (Diyaar)' : 'NOT AVAILABLE',
                                  style: TextStyle(
                                    color: isAvailable ? const Color(0xFF10B981) : Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canManageExams) ...[
                  if (isAvailable) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 20),
                      tooltip: 'Wax ka baddal',
                      onPressed: () => _showUploadDialog(preselectedYear: year, existingExam: examData),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      tooltip: 'Tirtir',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1E293B),
                            title: const Text('Ma meel marisaa tirtirista?', style: TextStyle(color: Colors.white)),
                            content: Text('Imtixaanka $year waa la saarayaa database-ka.', style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Maya')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Haa, Tirtir', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && examData != null && examData['id'] != null) {
                          final ok = await ApiService.deleteNationalExam(int.parse(examData['id'].toString()));
                          if (ok) {
                            _fetchExams();
                          }
                        }
                      },
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF38BDF8)),
                      tooltip: 'Geli Imtixaankan',
                      onPressed: () => _showUploadDialog(preselectedYear: year),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
