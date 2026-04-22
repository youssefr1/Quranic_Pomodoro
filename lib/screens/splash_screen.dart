import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quran_repository.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
    _handleInitialization();
  }

  Future<void> _handleInitialization() async {
    // Start data loading and animation concurrently
    final loadingFuture = QuranRepository().loadQuranData();

    // Ensure splash stays for at least 3 seconds for the experience
    await Future.wait([
      loadingFuture,
      Future.delayed(const Duration(seconds: 3)),
    ]);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AppShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen,
              Color(0xFF0A2E10), // Deep Dark Green
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background patterns or glows could go here
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 150.w,
                            height: 150.w,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(28.r),
                              border: Border.all(
                                color: AppTheme.accentGold.withValues(
                                  alpha: 0.15,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: Image.asset(
                                'assets/images/logo.webp',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.mosque_rounded,
                                    size: 80.w,
                                    color: AppTheme.accentGold,
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 32.h),
                          // App Title
                          Text(
                            'القرآن الكريم',
                            style: GoogleFonts.amiri(
                              fontSize: 38.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentGold,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: AppTheme.accentGold.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'Quranic',
                            style: GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Premium Loading indicator at bottom
            Positioned(
              bottom: 80.h,
              child: Column(
                children: [
                  Container(
                    width: 200.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Container(
                              width: 200.w * (_controller.value),
                              height: 4.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.accentGold,
                                    AppTheme.lightGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentGold.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 1.h),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'جاري التهيئة...',
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
