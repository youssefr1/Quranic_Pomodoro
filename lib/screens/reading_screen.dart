import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/quran_data_model.dart';
import '../services/quarter_service.dart';
import '../services/quran_repository.dart';
import '../theme/app_theme.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final service = context.read<QuarterService>();
          service.initialize();
          _fadeController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onNewQuarter() async {
    final service = context.read<QuarterService>();
    // Fade out
    await _fadeController.reverse();
    service.fetchNewQuarter();
    // Fade in
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuarterService>(
      builder: (context, service, child) {
        if (service.isLoading || service.currentQuarter == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        final quarter = service.currentQuarter!;
        final repo = QuranRepository();

        return Column(
          children: [
            // Header with quarter info
            _buildHeader(quarter, repo),
            // Quarter content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _QuarterContent(quarter: quarter, repo: repo),
              ),
            ),
            // Bottom bar with shuffle button
            _buildBottomBar(quarter),
          ],
        );
      },
    );
  }

  Widget _buildHeader(QuranQuarter quarter, QuranRepository repo) {
    final surahNames = quarter.chapterIds
        .map((id) => 'سورة ${repo.getSurahName(id)}')
        .join(' - ');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.mushafBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    surahNames,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'الجزء ${quarter.juzNumber}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                // Ayah range
                Icon(Icons.bookmark_outline,
                    size: 14.sp,
                    color: AppTheme.accentGold.withValues(alpha: 0.8)),
                SizedBox(width: 4.w),
                Text(
                  'من ${quarter.startVerseKey} إلى ${quarter.endVerseKey}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Hizb & Rub info
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'الحزب ${quarter.hizbNumber} • الربع ${((quarter.rubNumber - 1) % 4) + 1}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentGold.withValues(alpha: 0.9),
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

  Widget _buildBottomBar(QuranQuarter quarter) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.mushafBackground,
        border: Border(
          top: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // Verse count
            Text(
              '${quarter.verses.length} آية',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            // Random Quarter button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onNewQuarter,
                borderRadius: BorderRadius.circular(24.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shuffle_rounded, size: 18.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'ربع عشوائي',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuarterContent extends StatelessWidget {
  final QuranQuarter quarter;
  final QuranRepository repo;

  const _QuarterContent({required this.quarter, required this.repo});

  @override
  Widget build(BuildContext context) {
    // Group verses by page number
    final Map<int, List<QuranVerse>> pages = {};
    for (final verse in quarter.verses) {
      pages.putIfAbsent(verse.pageNumber, () => []).add(verse);
    }

    final sortedPageNumbers = pages.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      itemCount: sortedPageNumbers.length,
      itemBuilder: (context, index) {
        final pageNumber = sortedPageNumbers[index];
        final verses = pages[pageNumber]!;
        
        return _MushafPageCard(
          pageNumber: pageNumber,
          verses: verses,
          repo: repo,
          // Only show surah header if it's the start of a surah
          isStartOfQuarter: index == 0,
        );
      },
    );
  }
}

class _MushafPageCard extends StatelessWidget {
  final int pageNumber;
  final List<QuranVerse> verses;
  final QuranRepository repo;
  final bool isStartOfQuarter;

  const _MushafPageCard({
    required this.pageNumber,
    required this.verses,
    required this.repo,
    required this.isStartOfQuarter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.mushafBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.35),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: Stack(
          children: [
            // Corner ornaments
            Positioned(top: 0, left: 0, child: _cornerOrnament()),
            Positioned(
              top: 0,
              right: 0,
              child: Transform.flip(flipX: true, child: _cornerOrnament()),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Transform.flip(flipY: true, child: _cornerOrnament()),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Transform.flip(
                flipX: true,
                flipY: true,
                child: _cornerOrnament(),
              ),
            ),
            // Inner border
            Positioned.fill(
              child: Container(
                margin: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    width: 1.w,
                  ),
                ),
              ),
            ),
            // Page Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: _buildContent(context),
                  ),
                  SizedBox(height: 12.h),
                  // Page number at the bottom of each "mushaf page"
                  Text(
                    'صفحة $pageNumber',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.accentGold.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
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

  Widget _cornerOrnament() {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.4),
            width: 2.w,
          ),
          right: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.4),
            width: 2.w,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final List<InlineSpan> spans = [];
    int? lastChapterId;

    // To decide whether to show header, we check if it's the start of a surah OR
    // if the chapter changes within the page
    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];

      // Surah header when chapter changes OR if it's the very first verse of the quarter and is verse 1
      bool needsHeader = false;
      if (verse.chapterId != lastChapterId) {
        if (verse.verseNumber == 1) {
          needsHeader = true;
        } else if (isStartOfQuarter && i == 0) {
          // If we start midway in a surah, show header anyway to give context
          needsHeader = true;
        }
      }

      if (needsHeader) {
        if (spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n\n'));
        }
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              margin: EdgeInsets.only(
                bottom: 10.h,
                top: lastChapterId != null ? 4.h : 0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGold.withValues(alpha: 0.0),
                    AppTheme.accentGold.withValues(alpha: 0.15),
                    AppTheme.accentGold.withValues(alpha: 0.0),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.accentGold.withValues(alpha: 0.4),
                    width: 1.w,
                  ),
                  bottom: BorderSide(
                    color: AppTheme.accentGold.withValues(alpha: 0.4),
                    width: 1.w,
                  ),
                ),
              ),
              child: Text(
                'سورة ${repo.getSurahName(verse.chapterId)}',
                textAlign: TextAlign.center,
                style: AppTheme.mushafTextStyle.copyWith(
                  fontSize: 18.sp,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
        
        // Bismillah (except for Surah At-Tawbah)
        if (verse.chapterId != 9 && verse.verseNumber == 1) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  textAlign: TextAlign.center,
                  style: AppTheme.mushafTextStyle.copyWith(
                    fontSize: 18.sp,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          );
        }
        lastChapterId = verse.chapterId;
      }

      // Verse text
      spans.add(
        TextSpan(
          text: verse.textUthmani,
          style: AppTheme.mushafTextStyle.copyWith(fontSize: 22.sp),
        ),
      );

      // Ayah end marker
      spans.add(
        TextSpan(
          text: ' \u06DD${_toArabicNumber(verse.verseNumber)} ',
          style: AppTheme.ayahEndStyle.copyWith(
            fontSize: 20.sp,
            color: AppTheme.accentGold,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = [
      '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'
    ];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}
