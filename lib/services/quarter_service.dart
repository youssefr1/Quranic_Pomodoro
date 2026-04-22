import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/quran_data_model.dart';
import 'quran_repository.dart';

/// Represents a quarter (ربع حزب) of the Quran
class QuranQuarter {
  final int rubNumber; // 1–240
  final int hizbNumber;
  final int juzNumber;
  final List<QuranVerse> verses;

  QuranQuarter({
    required this.rubNumber,
    required this.hizbNumber,
    required this.juzNumber,
    required this.verses,
  });

  /// First verse info
  String get startVerseKey => verses.isNotEmpty ? verses.first.verseKey : '';
  int get startChapterId => verses.isNotEmpty ? verses.first.chapterId : 1;
  int get startVerseNumber => verses.isNotEmpty ? verses.first.verseNumber : 1;

  /// Last verse info
  String get endVerseKey => verses.isNotEmpty ? verses.last.verseKey : '';
  int get endChapterId => verses.isNotEmpty ? verses.last.chapterId : 1;
  int get endVerseNumber => verses.isNotEmpty ? verses.last.verseNumber : 1;

  /// Get all unique surah names in this quarter
  List<int> get chapterIds =>
      verses.map((v) => v.chapterId).toSet().toList()..sort();
}

/// Service that manages random quarter selection with auto-refresh
class QuarterService extends ChangeNotifier {
  final QuranRepository _repo;
  final Random _random = Random();

  QuranQuarter? _currentQuarter;
  int? _lastRubNumber;
  Timer? _autoRefreshTimer;
  bool _isLoading = false;

  // Auto-refresh interval (25 minutes)
  static const int autoRefreshMinutes = 25;

  QuarterService(this._repo);

  QuranQuarter? get currentQuarter => _currentQuarter;
  bool get isLoading => _isLoading;

  /// All quarters indexed by rub_el_hizb_number (1–240)
  Map<int, List<QuranVerse>>? _quartersCache;

  /// Build the quarters cache from all pages
  void _buildCache() {
    if (_quartersCache != null) return;
    _quartersCache = {};

    for (int p = 1; p <= _repo.pageCount; p++) {
      final page = _repo.getPage(p);
      if (page == null) continue;
      for (final verse in page.verses) {
        final rub = verse.rubElHizbNumber;
        if (rub > 0) {
          _quartersCache!.putIfAbsent(rub, () => []);
          _quartersCache![rub]!.add(verse);
        }
      }
    }
  }

  /// Get a random quarter, avoiding the last one shown
  QuranQuarter _pickRandomQuarter() {
    _buildCache();
    final keys = _quartersCache!.keys.toList();
    if (keys.isEmpty) {
      throw Exception('No quarters found in data');
    }

    int rubNumber;
    do {
      rubNumber = keys[_random.nextInt(keys.length)];
    } while (rubNumber == _lastRubNumber && keys.length > 1);

    _lastRubNumber = rubNumber;
    final verses = _quartersCache![rubNumber]!;

    return QuranQuarter(
      rubNumber: rubNumber,
      hizbNumber: verses.isNotEmpty ? verses.first.hizbNumber : 1,
      juzNumber: verses.isNotEmpty ? verses.first.juzNumber : 1,
      verses: verses,
    );
  }

  /// Load the initial random quarter and start auto-refresh
  void initialize() {
    if (_currentQuarter != null) return;
    
    _isLoading = true;
    notifyListeners();

    _currentQuarter = _pickRandomQuarter();
    _isLoading = false;
    _startAutoRefresh();
    notifyListeners();
  }

  /// Manually fetch a new random quarter
  void fetchNewQuarter() {
    _isLoading = true;
    notifyListeners();

    _currentQuarter = _pickRandomQuarter();
    _isLoading = false;

    // Restart the auto-refresh timer
    _startAutoRefresh();
    notifyListeners();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer(
      const Duration(minutes: autoRefreshMinutes),
      () {
        fetchNewQuarter();
      },
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
