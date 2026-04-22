class QuranWord {
  final int position;
  final String verseKey;
  final String charTypeName;
  final String textUthmani;
  final String codeV2;
  final int pageNumber;
  final int lineNumber;

  const QuranWord({
    required this.position,
    required this.verseKey,
    required this.charTypeName,
    required this.textUthmani,
    required this.codeV2,
    required this.pageNumber,
    required this.lineNumber,
  });

  factory QuranWord.fromJson(Map<String, dynamic> json) {
    return QuranWord(
      position: json['position'] as int,
      verseKey: json['verse_key'] as String,
      charTypeName: json['char_type_name'] as String,
      textUthmani: json['text_uthmani'] as String? ?? '',
      codeV2: json['code_v2'] as String? ?? '',
      pageNumber: json['page_number'] as int,
      lineNumber: json['line_number'] as int? ?? json['line_v2'] as int? ?? 1,
    );
  }
}

class QuranVerse {
  final int id;
  final int verseNumber;
  final String verseKey;
  final int hizbNumber;
  final int rubElHizbNumber;
  final String textUthmani;
  final int pageNumber;
  final int juzNumber;
  final int chapterId;
  final List<QuranWord> words;

  const QuranVerse({
    required this.id,
    required this.verseNumber,
    required this.verseKey,
    required this.hizbNumber,
    required this.rubElHizbNumber,
    required this.textUthmani,
    required this.pageNumber,
    required this.juzNumber,
    required this.chapterId,
    required this.words,
  });

  factory QuranVerse.fromJson(Map<String, dynamic> json) {
    return QuranVerse(
      id: json['id'] as int,
      verseNumber: json['verse_number'] as int,
      verseKey: json['verse_key'] as String,
      hizbNumber: json['hizb_number'] as int? ?? 0,
      rubElHizbNumber: json['rub_el_hizb_number'] as int? ?? 0,
      textUthmani: json['text_uthmani'] as String? ?? '',
      pageNumber: json['page_number'] as int,
      juzNumber: json['juz_number'] as int,
      chapterId: json['chapter_id'] as int,
      words: (json['words'] as List<dynamic>?)
              ?.map((w) => QuranWord.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class QuranPage {
  final int pageNumber;
  final List<QuranVerse> verses;

  const QuranPage({
    required this.pageNumber,
    required this.verses,
  });

  int get juzNumber => verses.isNotEmpty ? verses.first.juzNumber : 1;
  int get hizbNumber => verses.isNotEmpty ? verses.first.hizbNumber : 1;

  /// Get all unique chapter IDs on this page
  List<int> get chapterIds =>
      verses.map((v) => v.chapterId).toSet().toList()..sort();
}
