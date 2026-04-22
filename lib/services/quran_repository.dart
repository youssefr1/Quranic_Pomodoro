import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quran_data_model.dart';

/// Surah metadata
class SurahInfo {
  final int number;
  final String nameArabic;
  final int startPage;

  const SurahInfo({
    required this.number,
    required this.nameArabic,
    required this.startPage,
  });
}

class QuranRepository {
  static final QuranRepository _instance = QuranRepository._internal();
  factory QuranRepository() => _instance;
  QuranRepository._internal();

  final Map<int, QuranPage> _pages = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  int get pageCount => 604;

  /// All 114 surah names in Arabic
  static const List<String> surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام',
    'الأعراف', 'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف',
    'الرعد', 'إبراهيم', 'الحجر', 'النحل', 'الإسراء', 'الكهف',
    'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون', 'النور',
    'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
    'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر', 'يس',
    'الصافات', 'ص', 'الزمر', 'غافر', 'فصلت', 'الشورى',
    'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد', 'الفتح',
    'الحجرات', 'ق', 'الذاريات', 'الطور', 'النجم', 'القمر',
    'الرحمن', 'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
    'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق', 'التحريم',
    'الملك', 'القلم', 'الحاقة', 'المعارج', 'نوح', 'الجن',
    'المزمل', 'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ',
    'النازعات', 'عبس', 'التكوير', 'الإنفطار', 'المطففين', 'الإنشقاق',
    'البروج', 'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
    'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين', 'العلق',
    'القدر', 'البينة', 'الزلزلة', 'العاديات', 'القارعة', 'التكاثر',
    'العصر', 'الهمزة', 'الفيل', 'قريش', 'الماعون', 'الكوثر',
    'الكافرون', 'النصر', 'المسد', 'الإخلاص', 'الفلق', 'الناس',
  ];

  Future<void> loadQuranData() async {
    if (_isLoaded) return;

    final jsonString = await rootBundle.loadString('quran_offline.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final Map<String, dynamic> pagesJson = data['pages'];

    for (final entry in pagesJson.entries) {
      final int pageNum = int.parse(entry.key);
      final List<dynamic> versesJson = entry.value;
      final verses = versesJson
          .map((v) => QuranVerse.fromJson(v as Map<String, dynamic>))
          .toList();
      _pages[pageNum] = QuranPage(pageNumber: pageNum, verses: verses);
    }

    _isLoaded = true;
  }

  QuranPage? getPage(int pageNumber) {
    return _pages[pageNumber];
  }

  String getSurahName(int chapterId) {
    if (chapterId < 1 || chapterId > 114) return '';
    return surahNames[chapterId - 1];
  }

  /// Get the surah header text for a page
  String getPageSurahHeader(int pageNumber) {
    final page = _pages[pageNumber];
    if (page == null) return '';
    final chapterIds = page.chapterIds;
    return chapterIds.map((id) => 'سورة ${getSurahName(id)}').join(' - ');
  }

  /// Get juz number for a page
  int getJuzNumber(int pageNumber) {
    final page = _pages[pageNumber];
    return page?.juzNumber ?? 1;
  }
}
