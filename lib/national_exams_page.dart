import 'package:flutter/material.dart';
import 'national_exams_years_page.dart';

class SubjectItem {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;

  SubjectItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
  });
}

class NationalExamsPage extends StatefulWidget {
  final String userRole;
  const NationalExamsPage({super.key, this.userRole = ''});

  @override
  State<NationalExamsPage> createState() => _NationalExamsPageState();
}

class _NationalExamsPageState extends State<NationalExamsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<SubjectItem> _subjects = [
    SubjectItem(
      key: 'Science',
      title: 'Saynis (Science)',
      subtitle: 'Imtixaanadii Sayniska Fasaalka 8aad',
      icon: Icons.science_rounded,
      gradientColors: [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
      accentColor: const Color(0xFF5EEAD4),
    ),
    SubjectItem(
      key: 'Arabic',
      title: 'Carabi (Arabic)',
      subtitle: 'Imtixaanadii Af-Carabiga Fasaalka 8aad',
      icon: Icons.menu_book_rounded,
      gradientColors: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
      accentColor: const Color(0xFFFDE68A),
    ),
    SubjectItem(
      key: 'Tarbia',
      title: 'Tarbiyada (Tarbia)',
      subtitle: 'Imtixaanadii Tarbiyada Islaamka Fasaalka 8aad',
      icon: Icons.auto_stories_rounded,
      gradientColors: [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
      accentColor: const Color(0xFFC7D2FE),
    ),
    SubjectItem(
      key: 'English',
      title: 'Ingiriisi (English)',
      subtitle: 'Imtixaanadii Af-Ingiriisiga Fasaalka 8aad',
      icon: Icons.translate_rounded,
      gradientColors: [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
      accentColor: const Color(0xFFBAE6FD),
    ),
    SubjectItem(
      key: 'Somali',
      title: 'Af-Soomaali (Somali)',
      subtitle: 'Imtixaanadii Af-Soomaaliga Fasaalka 8aad',
      icon: Icons.history_edu_rounded,
      gradientColors: [const Color(0xFFDC2626), const Color(0xFFEF4444)],
      accentColor: const Color(0xFFFCA5A5),
    ),
    SubjectItem(
      key: 'Maths',
      title: 'Xisaab (Maths)',
      subtitle: 'Imtixaanadii Xisaabta Fasaalka 8aad',
      icon: Icons.calculate_rounded,
      gradientColors: [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
      accentColor: const Color(0xFFBFDBFE),
    ),
    SubjectItem(
      key: 'Social',
      title: 'Bulshada (Social)',
      subtitle: 'Imtixaanadii Cilmiga Bulshada Fasaalka 8aad',
      icon: Icons.public_rounded,
      gradientColors: [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
      accentColor: const Color(0xFFDDD6FE),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredSubjects = _subjects.where((subject) {
      return subject.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          subject.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF38BDF8), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Imtixaanada Qaranka (Grade 8)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Banner & Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Somaliland National Examinations',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '2018 - 2026',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dooro Maaddada Aad Rabto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ka hel dhammaan imtixaanadii hore ee fasalka 8aad eeg ama la soo deg PDF-yada rasmiga ah.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Raadi maaddo (e.g. Xisaab, Saynis, Ingiriisi)...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subjects Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900
                    ? 3
                    : MediaQuery.of(context).size.width > 600
                        ? 2
                        : 1,
                childAspectRatio: MediaQuery.of(context).size.width > 900
                    ? 2.2
                    : MediaQuery.of(context).size.width > 600
                        ? 2.0
                        : 1.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final subject = filteredSubjects[index];
                  return _buildSubjectCard(context, subject);
                },
                childCount: filteredSubjects.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectItem subject) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NationalExamsYearsPage(
                subjectKey: subject.key,
                subjectTitle: subject.title,
                accentColor: subject.accentColor,
                userRole: widget.userRole,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: subject.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: subject.gradientColors.first.withValues(alpha: 0.35),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Stack(
            children: [
              // Background Watermark Icon
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  subject.icon,
                  size: 110,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(subject.icon, color: Colors.white, size: 24),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '7 Papers',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            subject.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subject.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
