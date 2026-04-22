import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/pomodoro_service.dart';
import '../theme/app_theme.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroService>(
      builder: (context, pomodoro, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                // Main content area
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 16.h),
                          // Duration Selector (only when idle)
                          if (pomodoro.state == PomodoroState.idle)
                            _DurationSelector(pomodoro: pomodoro),
                          if (pomodoro.state == PomodoroState.idle)
                            const SizedBox(height: 32),
                          // Timer Circle
                          _TimerCircle(pomodoro: pomodoro),
                          const SizedBox(height: 32),
                          // Control buttons
                          _ControlButtons(pomodoro: pomodoro),
                          const SizedBox(height: 32),
                          // Motivational text
                          Text(
                            'بين ضغط اليوم وسكينته... قرآن',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'غير منسوب',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                // Sidebar with stats (desktop only)
                if (constraints.maxWidth > 600)
                  Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    child: _StatsSidebar(pomodoro: pomodoro),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Stop and Restart buttons shown when timer is active
class _ControlButtons extends StatelessWidget {
  final PomodoroService pomodoro;

  const _ControlButtons({required this.pomodoro});

  @override
  Widget build(BuildContext context) {
    // If idle, show Start button
    if (pomodoro.state == PomodoroState.idle) {
      return _PremiumButton(
        onTap: pomodoro.startFocus,
        icon: Icons.play_arrow_rounded,
        label: 'ابدأ التركيز',
        isPrimary: true,
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
        ),
        shadowColor: AppTheme.primaryGreen,
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop / Reset button
              _PremiumButton(
                onTap: pomodoro.reset,
                icon: Icons.stop_rounded,
                label: 'إيقاف',
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade400],
                ),
                shadowColor: Colors.red.shade300,
              ),
              const SizedBox(width: 20),
              // Restart / Repeat button
              _PremiumButton(
                onTap: () {
                  pomodoro.reset();
                  pomodoro.startFocus();
                },
                icon: Icons.replay_rounded,
                label: 'إعادة',
                gradient: const LinearGradient(
                  colors: [AppTheme.accentGold, Color(0xFFF5D76E)],
                ),
                shadowColor: AppTheme.accentGold,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Time extending button
          _PremiumButton(
            onTap: () => pomodoro.addTime(5),
            icon: Icons.add_rounded,
            label: 'إضافة 5 دقائق',
            isPrimary: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.8),
                AppTheme.primaryGreen,
              ],
            ),
            shadowColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final PomodoroService pomodoro;
  final List<int> durations = const [10, 20, 30, 45];

  const _DurationSelector({super.key, required this.pomodoro});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'اختر مدة التركيز',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...durations.map((d) {
              final isSelected = pomodoro.focusDurationMinutes == d;
              return _DurationChip(
                label: '$d د',
                isSelected: isSelected,
                onTap: () => pomodoro.setFocusDuration(d),
              );
            }),
            // Custom Duration Button
            _DurationChip(
              icon: Icons.edit_rounded,
              isSelected: !durations.contains(pomodoro.focusDurationMinutes),
              onTap: () => _showCustomDurationDialog(context, pomodoro),
            ),
          ],
        ),
      ],
    );
  }

  void _showCustomDurationDialog(
    BuildContext context,
    PomodoroService pomodoro,
  ) {
    // Default to 5 minutes if not already custom
    int minutes = durations.contains(pomodoro.focusDurationMinutes)
        ? 5
        : pomodoro.focusDurationMinutes;
    showDialog(
      context: context,
      builder: (context) => _CustomTimeDialog(
        initialValue: minutes,
        onSave: (val) => pomodoro.setFocusDuration(val),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.dividerColor,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: icon != null
            ? Icon(
                icon,
                size: 16.sp,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              )
            : Text(
                label!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
      ),
    );
  }
}

class _CustomTimeDialog extends StatefulWidget {
  final int initialValue;
  final Function(int) onSave;

  const _CustomTimeDialog({required this.initialValue, required this.onSave});

  @override
  State<_CustomTimeDialog> createState() => _CustomTimeDialogState();
}

class _CustomTimeDialogState extends State<_CustomTimeDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF0D3310)],
          ),
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مدة التركيز مخصصة',
              style: GoogleFonts.amiri(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconButton(
                  icon: Icons.remove_rounded,
                  onTap: () => setState(() => _value = math.max(1, _value - 1)),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      Text(
                        '$_value',
                        style: GoogleFonts.cairo(
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'دقيقة',
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _IconButton(
                  icon: Icons.add_rounded,
                  onTap: () =>
                      setState(() => _value = math.min(120, _value + 1)),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'إلغاء',
                      style: GoogleFonts.cairo(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.onSave(_value);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accentGold, Color(0xFFF5D76E)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          'حفظ',
                          style: GoogleFonts.cairo(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: AppTheme.accentGold, size: 24.sp),
      ),
    );
  }
}

/// A single premium glassmorphism-style action button
class _PremiumButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final Color shadowColor;
  final bool isPrimary;

  const _PremiumButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.shadowColor,
    this.isPrimary = false,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: widget.isPrimary ? 220 : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerCircle extends StatelessWidget {
  final PomodoroService pomodoro;

  const _TimerCircle({required this.pomodoro});

  @override
  Widget build(BuildContext context) {
    final size = 260.0;

    return GestureDetector(
      onTap: pomodoro.toggleStartPause,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background ring
            CustomPaint(
              size: Size(size, size),
              painter: _TimerRingPainter(
                progress: pomodoro.progress,
                backgroundColor: AppTheme.dividerColor,
                progressColor: pomodoro.state == PomodoroState.focusing
                    ? AppTheme.primaryGreen
                    : AppTheme.accentGold,
                strokeWidth: 5.0,
              ),
            ),
            // Center content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (pomodoro.state != PomodoroState.idle) ...[
                  Text(
                    pomodoro.stateLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontSize: 13,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pomodoro.timeDisplay,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w300,
                      fontSize: 48,
                    ),
                  ),
                  if (pomodoro.isPaused) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'اضغط للاستئناف',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      'اضغط للإيقاف المؤقت',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ] else ...[
                  Text(
                    'وقت التركيز',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontSize: 13,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 48,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _TimerRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StatsSidebar extends StatelessWidget {
  final PomodoroService pomodoro;

  const _StatsSidebar({required this.pomodoro});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatItem(
            icon: Icons.access_time_filled,
            label:
                '${(pomodoro.totalFocusSeconds / 3600).toStringAsFixed(0)} ساعة',
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 16),
          _StatItem(
            icon: Icons.timer_outlined,
            label: 'مذاكرة ${pomodoro.focusDurationMinutes}د',
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          _StatItem(
            icon: Icons.auto_stories_outlined,
            label: 'قراءة 6ص',
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          _StatItem(
            icon: Icons.grid_view_rounded,
            label: 'ربع',
            color: AppTheme.textSecondary,
          ),
          const Spacer(),
          _StatItem(
            icon: Icons.bar_chart_rounded,
            label: 'الإحصائيات',
            color: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
