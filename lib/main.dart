import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'screens/focus_screen.dart';
import 'screens/reading_screen.dart';
import 'screens/splash_screen.dart';
import 'services/pomodoro_service.dart';
import 'services/quarter_service.dart';
import 'services/quran_repository.dart';
import 'services/background_service_logic.dart';
import 'theme/app_theme.dart';

// Overlay Entry Point
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: FloatingTimerBubble(),
        );
      },
    ),
  );
}

class FloatingTimerBubble extends StatefulWidget {
  const FloatingTimerBubble({super.key});

  @override
  State<FloatingTimerBubble> createState() => _FloatingTimerBubbleState();
}

class _FloatingTimerBubbleState extends State<FloatingTimerBubble> {
  String _time = "00:00";
  String _stateLabel = "التركيز";

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() {
          _time = event['time'] ?? "00:00";
          _stateLabel = event['label'] ?? "التركيز";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 150.w,
          height: 150.w,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber, width: 4.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15.r,
                spreadRadius: 5.r,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 10.h),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _time,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32.sp,
                              ),
                            ),
                            Text(
                              _stateLabel,
                              style: TextStyle(
                                color: const Color(0xFFD4AF37),
                                fontSize: 14.sp,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
              Positioned(
                bottom: 15.h,
                child: GestureDetector(
                  onTap: () async {
                    try {
                      await FlutterOverlayWindow.closeOverlay();
                    } catch (e) {
                      debugPrint("Overlay interaction error: $e");
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 20.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Background Service
  await initializeBackgroundService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PomodoroService()),
        ChangeNotifierProvider(
          create: (_) => QuarterService(QuranRepository()),
        ),
      ],
      child: const QuranicPomodoroApp(),
    ),
  );
}

class QuranicPomodoroApp extends StatelessWidget {
  const QuranicPomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Quranic',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Register session completion listener
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<PomodoroService>().onSessionComplete = _handleSessionComplete;
      
      try {
        if (!await FlutterOverlayWindow.isPermissionGranted()) {
          await FlutterOverlayWindow.requestPermission();
        }
      } catch (e) {
        debugPrint("Overlay permission check failed: $e");
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final pomodoro = context.read<PomodoroService>();
    final isRunning = pomodoro.state != PomodoroState.idle && !pomodoro.isPaused;

    // Show overlay ONLY on paused (actual home screen)
    if (state == AppLifecycleState.paused) {
      if (isRunning) {
        try {
          final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
          if (hasPermission) {
            await FlutterOverlayWindow.showOverlay(
              enableDrag: true,
              overlayTitle: "Quranic",
              overlayContent: "Timer is running",
              width: WindowSize.matchParent,
              height: WindowSize.matchParent,
              flag: OverlayFlag.focusPointer,
              alignment: OverlayAlignment.center,
            );
          }
        } catch (e) {
          debugPrint("Overlay error: $e");
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      try {
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.closeOverlay();
        }
      } catch (e) {
        debugPrint("Overlay close error: $e");
      }
    }
  }

  void _handleSessionComplete(PomodoroState state) {
    if (state == PomodoroState.focusing) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PremiumCompletionDialog(
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 64.h,
      titleSpacing: 20.w,
      title: Row(
        children: [
          // Logo
          Image.asset(
            'assets/images/logo.webp',
            width: 32.w,
            height: 32.h,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.mosque_rounded,
              size: 24.w,
              color: AppTheme.primaryGreen,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Quranic',
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreen,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<PomodoroService>(
          builder: (context, pomodoro, child) {
            final isReading = _selectedTab == 1;
            final isActive = pomodoro.state != PomodoroState.idle;
            
            if (!isReading || !isActive) return const SizedBox.shrink();
            
            return Padding(
              padding: EdgeInsets.only(right: 20.w),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14.sp,
                        color: AppTheme.accentGold,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        pomodoro.timeDisplay,
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1.h,
          color: AppTheme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.timer_outlined,
                activeIcon: Icons.timer_rounded,
                label: 'التركيز',
                isSelected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _NavBarItem(
                icon: Icons.book_rounded,
                activeIcon: Icons.book_rounded,
                label: 'القراءة',
                isSelected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 0:
        return const FocusScreen();
      case 1:
        return const ReadingScreen();
      default:
        return const FocusScreen();
    }
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                size: 24.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCompletionDialog extends StatelessWidget {
  final VoidCallback onDismiss;

  const _PremiumCompletionDialog({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF0D3310),
              ],
            ),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30.r,
                offset: Offset(0, 15.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.accentGold,
                  size: 48.sp,
                ),
              ),
              SizedBox(height: 24.h),
              // Congratulations Text
              Text(
                'مبارك!',
                style: GoogleFonts.amiri(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 8.h),
              Text(
                'تقبل الله طاعتكم',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 16.h),
              Text(
                'لقد أتممت جلسة التركيز بنجاح. حان وقت الاستراحة!',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 32.h),
              // Action Button
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accentGold, Color(0xFFF5D76E)],
                    ),
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withValues(alpha: 0.3),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'بدء الاستراحة',
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'إغلاق',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
