import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class BibleReference {
  final String book;
  final int chapter;
  final int verse;

  BibleReference({
    required this.book,
    required this.chapter,
    required this.verse,
  });

  factory BibleReference.fromJson(Map<String, dynamic> json) {
    return BibleReference(
      book: json['book'] ?? '',
      chapter: json['chapter'] ?? 0,
      verse: json['verse'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
    };
  }
}

class ReferenceService {
  static const List<String> _standardOrder = [
    "Gen", "Exod", "Lev", "Num", "Deut", "Josh", "Judg", "Ruth",
    "1Sam", "2Sam", "1Kgs", "2Kgs", "1Chr", "2Chr", "Ezra", "Neh", "Esth", "Job",
    "Ps", "Prov", "Eccl", "Song", "Isa", "Jer", "Lam", "Ezek", "Dan", "Hos",
    "Joel", "Amos", "Obad", "Jonah", "Mic", "Nah", "Hab", "Zeph", "Hag", "Zech",
    "Mal", "Matt", "Mark", "Luke", "John", "Acts", "Rom", "1Cor", "2Cor", "Gal",
    "Eph", "Phil", "Col", "1Thess", "2Thess", "1Tim", "2Tim", "Titus", "Phlm",
    "Heb", "Jas", "1Pet", "2Pet", "1John", "2John", "3John", "Jude", "Rev"
  ];

  static const Map<String, String> _helloAoToLocalMap = {
    "GEN": "Gen", "EXO": "Exod", "LEV": "Lev", "NUM": "Num", "DEU": "Deut",
    "JOS": "Josh", "JDG": "Judg", "RUT": "Ruth", "1SA": "1Sam", "2SA": "2Sam",
    "1KI": "1Kgs", "2KI": "2Kgs", "1CH": "1Chr", "2CH": "2Chr", "EZR": "Ezra",
    "NEH": "Neh", "EST": "Esth", "JOB": "Job", "PSA": "Ps", "PRO": "Prov",
    "ECC": "Eccl", "SNG": "Song", "ISA": "Isa", "JER": "Jer", "LAM": "Lam",
    "EZK": "Ezek", "DAN": "Dan", "HOS": "Hos", "JOL": "Joel", "AMO": "Amos",
    "OBA": "Obad", "JON": "Jonah", "MIC": "Mic", "NAM": "Nah", "HAB": "Hab",
    "ZEP": "Zeph", "HAG": "Hag", "ZEC": "Zech", "MAL": "Mal", "MAT": "Matt",
    "MRK": "Mark", "LUK": "Luke", "JHN": "John", "ACT": "Acts", "ROM": "Rom",
    "1CO": "1Cor", "2CO": "2Cor", "GAL": "Gal", "EPH": "Eph", "PHP": "Phil",
    "COL": "Col", "1TH": "1Thess", "2TH": "2Thess", "1TI": "1Tim", "2TI": "2Tim",
    "TIT": "Titus", "PHM": "Phlm", "HEB": "Heb", "JAS": "Jas", "1PE": "1Pet",
    "2PE": "2Pet", "1JN": "1John", "2JN": "2John", "3JN": "3John", "JUD": "Jude",
    "REV": "Rev"
  };

  static final Map<int, Map<String, dynamic>> _sharedFileCache = {};
  Map<String, dynamic>? _verseCounts;

  Future<void> init() async {
    if (_verseCounts != null) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/verse_counts.json');
      _verseCounts = jsonDecode(jsonStr);
    } catch (e) {
      print("Error loading verse counts: $e");
    }
  }

  int getAbsoluteVerseId(String book, int chapter, int verse) {
    if (_verseCounts == null) return -1;
    final bookIdx = _standardOrder.indexOf(book);
    if (bookIdx == -1) return -1; // Apocrypha or unsupported book

    int absoluteId = 0;
    // Sum preceding books
    for (int i = 0; i < bookIdx; i++) {
      final prevBook = _standardOrder[i];
      final List<dynamic>? chapters = _verseCounts![prevBook];
      if (chapters != null) {
        for (var count in chapters) {
          absoluteId += count as int;
        }
      }
    }

    // Sum preceding chapters of this book
    final List<dynamic>? chapters = _verseCounts![book];
    if (chapters != null) {
      for (int c = 0; c < chapter - 1; c++) {
        if (c < chapters.length) {
          absoluteId += chapters[c] as int;
        }
      }
    }

    absoluteId += verse;
    return absoluteId;
  }

  int getFileIndex(int absoluteId) {
    return ((absoluteId - 1) / 1000).floor() + 1;
  }

  Future<Map<String, List<BibleReference>>> fetchReferencesForChapter(
      List<dynamic> versesList) async {
    final Map<String, List<BibleReference>> refsMap = {};
    await init();
    if (_verseCounts == null || versesList.isEmpty) return refsMap;

    for (var v in versesList) {
      // Expecting dynamic objects with book, chapter, verse properties
      final String book = v.book;
      final int chapter = v.chapter;
      final int verse = v.verse;

      final absoluteId = getAbsoluteVerseId(book, chapter, verse);
      if (absoluteId == -1 || absoluteId > 31102) continue;

      final fileIdx = getFileIndex(absoluteId);
      Map<String, dynamic>? fileData = _sharedFileCache[fileIdx];

      if (fileData == null) {
        try {
          final url = Uri.parse(
              "https://raw.githubusercontent.com/josephilipraja/bible-cross-reference-json/master/$fileIdx.json");
          final res = await http.get(url);
          if (res.statusCode == 200) {
            fileData = jsonDecode(res.body);
            _sharedFileCache[fileIdx] = fileData!;
          }
        } catch (e) {
          print("Error fetching cross reference file $fileIdx: $e");
        }
      }

      if (fileData != null) {
        final verseData = fileData[absoluteId.toString()];
        if (verseData != null && verseData['r'] != null) {
          final List<dynamic> refsList = verseData['r'] is List 
              ? verseData['r'] 
              : (verseData['r'] as Map).values.toList();
              
          final parsedRefs = refsList.map((refStr) {
            final parts = (refStr as String).split(' ');
            final helloAoBook = parts[0];
            final ch = int.parse(parts[1]);
            final ver = int.parse(parts[2]);

            final localBook = _helloAoToLocalMap[helloAoBook] ?? helloAoBook;
            return BibleReference(
              book: localBook,
              chapter: ch,
              verse: ver,
            );
          }).toList();

          refsMap["${book}_${chapter}_$verse"] = parsedRefs;
        }
      }
    }

    return refsMap;
  }
}
