import 'dart:math' as math;
import 'package:flutter/material.dart';

class AiLessonPlanPage extends StatefulWidget {
  final String userRole;
  const AiLessonPlanPage({super.key, this.userRole = ''});

  @override
  State<AiLessonPlanPage> createState() => _AiLessonPlanPageState();
}

class _AiLessonPlanPageState extends State<AiLessonPlanPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late AnimationController _scrollRevealController;
  late ScrollController _scrollController;

  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _revealAnim;

  double _scrollOffset = 0;

  final List<_FeatureItem> _features = [
    _FeatureItem(
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF38BDF8),
      title: "AI Lesson Plan Generator",
      desc: "Automatically generate detailed lesson plans using AI with rich content",
    ),
    _FeatureItem(
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFF8B5CF6),
      title: "Timetable Generator",
      desc: "Create a full class schedule by telling AI the subjects and teachers — done in minutes",
    ),
    _FeatureItem(
      icon: Icons.quiz_rounded,
      color: const Color(0xFF10B981),
      title: "Exam & Quiz Creator",
      desc: "Automatically generate exams and quizzes at any difficulty level",
    ),
    _FeatureItem(
      icon: Icons.chat_bubble_rounded,
      color: const Color(0xFFF59E0B),
      title: "AI Chat Assistant",
      desc: "Ask the AI anything about education — available 24/7",
    ),
    _FeatureItem(
      icon: Icons.library_books_rounded,
      color: const Color(0xFFEC4899),
      title: "Lesson Library",
      desc: "Save your lesson plans and retrieve them instantly whenever you need",
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _scrollRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _scrollController = ScrollController()
      ..addListener(() {
        setState(() => _scrollOffset = _scrollController.offset);
      });

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotateAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    _floatAnim = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _revealAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scrollRevealController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _scrollRevealController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 6,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeroSection(),
              _buildScrollRevealSection(
                delay: 0,
                child: _buildFeaturesSection(),
              ),
              _buildScrollRevealSection(
                delay: 100,
                child: _buildComingSoonBanner(),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  /// Wraps a widget with a scroll-triggered fade+slide-up animation
  Widget _buildScrollRevealSection({required Widget child, int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 700 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildComingSoonBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnim.value,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                "Coming Soon!! 🚀",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -2,
                  height: 1.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0F1E), Color(0xFF0D1B3E), Color(0xFF0A0F1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Animated orbit rings + center icon
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnim, _rotateAnim, _floatAnim]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer orbit ring
                      Transform.rotate(
                        angle: _rotateAnim.value,
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 0),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Middle orbit ring
                      Transform.rotate(
                        angle: -_rotateAnim.value * 0.6,
                        child: Container(
                          width: 155,
                          height: 155,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Center pulse glow
                      Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFF38BDF8),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                blurRadius: 50,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 36),

          // SmartMind AI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "SmartMind AI • In Development",
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Title with shimmer
          AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: const [
                      Color(0xFF38BDF8),
                      Colors.white,
                      Color(0xFF8B5CF6),
                      Colors.white,
                      Color(0xFF38BDF8),
                    ],
                    stops: [
                      (_shimmerAnim.value - 1).clamp(0.0, 1.0),
                      (_shimmerAnim.value - 0.4).clamp(0.0, 1.0),
                      _shimmerAnim.value.clamp(0.0, 1.0),
                      (_shimmerAnim.value + 0.4).clamp(0.0, 1.0),
                      (_shimmerAnim.value + 1).clamp(0.0, 1.0),
                    ],
                  ).createShader(bounds);
                },
                child: const Text(
                  "AI Lesson Plan",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          const Text(
            "The future of AI-powered teaching tools",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 30),

          // Coming soon description
          Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Text(
              "Qeybtan waxaa lagu diyaarinayaa fechar cusub oo AI la shaqeeya. "
              "Marka la dhamaystiro, macalimiin kasta waxay si fudud uga samayn "
              "karaan lesson plan-no, imtixaannada, iyo jadwalka. Sug - waa dhaw tahay! 🚀",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14.5,
                height: 1.7,
              ),
            ),
          ),

          const SizedBox(height: 36),

          // Animated progress bar
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Development Progress",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, _) {
                  final pct = (65 + (_shimmerController.value * 5)).toInt();
                  return Text(
                    "$pct%",
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              final progress = 0.65 + (_shimmerController.value * 0.05);
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            "Upcoming Features",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "These features will be ready once development is complete",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 700;
              if (isWide) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _features
                      .map((f) => SizedBox(
                            width: (constraints.maxWidth - 32) / 2,
                            child: _buildFeatureCard(f),
                          ))
                      .toList(),
                );
              }
              return Column(
                children: _features
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildFeatureCard(f),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: feature.color.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: feature.color.withValues(alpha: 0.06),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: feature.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(feature.icon, color: feature.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.desc,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Text(
                  "Soon",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}
