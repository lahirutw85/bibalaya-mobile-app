import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/bible_verse.dart';
import '../models/bible_book.dart';

class BibleService {
  // Book order mapping for Bolls.life API index
  static const List<String> _bollsBookOrder = [
    "Gen", "Exod", "Lev", "Num", "Deut", "Josh", "Judg", "Ruth",
    "1Sam", "2Sam", "1Kgs", "2Kgs", "1Chr", "2Chr", "Ezra", "Neh", "Esth", "Job",
    "Ps", "Prov", "Eccl", "Song", "Isa", "Jer", "Lam", "Ezek", "Dan", "Hos",
    "Joel", "Amos", "Obad", "Jonah", "Mic", "Nah", "Hab", "Zeph", "Hag", "Zech",
    "Mal", "Matt", "Mark", "Luke", "John", "Acts", "Rom", "1Cor", "2Cor", "Gal",
    "Eph", "Phil", "Col", "1Thess", "2Thess", "1Tim", "2Tim", "Titus", "Phlm",
    "Heb", "Jas", "1Pet", "2Pet", "1John", "2John", "3John", "Jude", "Rev"
  ];

  static final Map<String, String> _localToHelloAoMap = {
    "Gen": "GEN", "Exod": "EXO", "Lev": "LEV", "Num": "NUM", "Deut": "DEU",
    "Josh": "JOS", "Judg": "JDG", "Ruth": "RUT", "1Sam": "1SA", "2Sam": "2SA",
    "1Kgs": "1KI", "2Kgs": "2KI", "1Chr": "1CH", "2Chr": "2CH", "Ezra": "EZR",
    "Neh": "NEH", "Esth": "EST", "Job": "JOB", "Ps": "PSA", "Prov": "PRO",
    "Eccl": "ECC", "Song": "SNG", "Isa": "ISA", "Jer": "JER", "Lam": "LAM",
    "Ezek": "EZK", "Dan": "DAN", "Hos": "HOS", "Joel": "JOL", "Amos": "AMO",
    "Obad": "OBA", "Jonah": "JON", "Mic": "MIC", "Nah": "NAM", "Hab": "HAB",
    "Zeph": "ZEP", "Hag": "HAG", "Zech": "ZEC", "Mal": "MAL", "Matt": "MAT",
    "Mark": "MRK", "Luke": "LUK", "John": "JHN", "Acts": "ACT", "Rom": "ROM",
    "1Cor": "1CO", "2Cor": "2CO", "Gal": "GAL", "Eph": "EPH", "Phil": "PHP",
    "Col": "COL", "1Thess": "1TH", "2Thess": "2TH", "1Tim": "1TI", "2Tim": "2TI",
    "Titus": "TIT", "Phlm": "PHM", "Heb": "HEB", "Jas": "JAS", "1Pet": "1PE",
    "2Pet": "2PE", "1John": "1JN", "2John": "2JN", "3John": "3JN", "Jude": "JUD",
    "Rev": "REV"
  };

  // Static/in-memory caches to prevent redundant work
  static final Map<String, List<BibleVerse>> _localBiblesCache = {};
  static final Map<String, List<BibleVerse>> _apiChaptersCache = {};
  static final Map<String, List<BibleBook>> _booksCache = {};

  int _getBollsBookIndex(String bookCode) {
    final idx = _bollsBookOrder.indexOf(bookCode);
    return idx != -1 ? idx + 1 : 1;
  }

  String getHelloAoBookCode(String localCode) {
    return _localToHelloAoMap[localCode] ?? localCode;
  }

  bool isApiVersion(String version) {
    return ["KJV", "ASV", "BBE", "BSB"].contains(version);
  }

  bool isBollsVersion(String version) {
    return ["NIV", "NKJV", "AMP"].contains(version);
  }

  /// Load book metadata list based on selected translation version
  Future<List<BibleBook>> loadBooks(String version) async {
    String fileKey = 'books';
    if (["KJV", "ASV", "BBE", "BSB", "NIV", "NKJV", "AMP"].contains(version)) {
      fileKey = 'books_en';
    } else if (version == 'TAMOVR') {
      fileKey = 'books_ta';
    }

    if (_booksCache.containsKey(fileKey)) {
      return _booksCache[fileKey]!;
    }

    try {
      final jsonStr = await rootBundle.loadString('assets/data/$fileKey.json');
      final List<dynamic> data = jsonDecode(jsonStr);
      final list = data.map((x) => BibleBook.fromJson(x)).toList();
      _booksCache[fileKey] = list;
      return list;
    } catch (e) {
      print("Error loading books metadata: $e");
      return [];
    }
  }

  /// Load chapter content
  Future<List<BibleVerse>> fetchChapter(String book, int chapter, String version) async {
    final cacheKey = "${version}_${book}_$chapter";
    if (_apiChaptersCache.containsKey(cacheKey)) {
      return _apiChaptersCache[cacheKey]!;
    }

    // 1. Check Bolls.life API versions
    if (isBollsVersion(version)) {
      final bookIndex = _getBollsBookIndex(book);
      final url = Uri.parse("https://bolls.life/get-chapter/$version/$bookIndex/$chapter/");
      
      final res = await http.get(url);
      if (res.statusCode != 200) throw Exception("Failed to fetch chapter from Bolls.life");
      
      final List<dynamic> data = jsonDecode(res.body);
      final List<BibleVerse> flat = data.map((item) {
        String rawText = item['text'] ?? '';
        // Strip html tags
        rawText = rawText
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        return BibleVerse(
          book: book,
          chapter: chapter,
          verse: item['verse'] ?? 0,
          text: rawText,
        );
      }).toList();

      _apiChaptersCache[cacheKey] = flat;
      return flat;
    }

    // 2. Check HelloAO API versions
    if (isApiVersion(version)) {
      final apiVersions = { "KJV": "eng_kjv", "ASV": "eng_asv", "BBE": "eng_bbe", "BSB": "BSB" };
      final helloAoId = apiVersions[version];
      final helloAoBookId = getHelloAoBookCode(book);
      final url = Uri.parse("https://bible.helloao.org/api/$helloAoId/$helloAoBookId/$chapter.json");

      final res = await http.get(url);
      if (res.statusCode != 200) throw Exception("Failed to fetch chapter from HelloAO");
      
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      final List<BibleVerse> flat = [];
      final chapterData = data['chapter'];
      if (chapterData != null && chapterData['content'] is List) {
        for (var item in chapterData['content']) {
          if (item['type'] == 'verse') {
            final verseNum = item['number'] ?? item['verse'];
            final List<dynamic> contentParts = item['content'] ?? [];
            final text = contentParts
                .map((part) {
                  if (part is String) return part;
                  if (part is Map && part['text'] is String) return part['text'];
                  return '';
                })
                .where((t) => t.trim().isNotEmpty)
                .join(' ');

            flat.add(BibleVerse(
              book: book,
              chapter: chapter,
              verse: verseNum is String ? int.parse(verseNum) : (verseNum as int),
              text: text,
            ));
          }
        }
      }

      _apiChaptersCache[cacheKey] = flat;
      return flat;
    }

    // 3. Check Local versions (Sinhala & Tamil) loaded from assets
    if (_localBiblesCache.containsKey(version)) {
      return _localBiblesCache[version]!
          .where((v) => v.book == book && v.chapter == chapter)
          .toList();
    }

    // Read full local json on first request for that translation
    String assetName;
    if (version == '2018') {
      assetName = 'sinnrv2018.json';
    } else if (version == 'TAMOVR') {
      assetName = 'ta_movr.json';
    } else if (version == 'SINBIBLE') {
      assetName = 'sin_simple.json';
    } else {
      assetName = 'sirov.json';
    }

    final jsonStr = await rootBundle.loadString('assets/data/$assetName');
    final List<dynamic> rawVerses = jsonDecode(jsonStr);
    
    final fullList = rawVerses.map((v) {
      String rawText = v['t'] ?? '';
      rawText = rawText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      return BibleVerse(
        book: v['b'] ?? '',
        chapter: v['c'] ?? 0,
        verse: v['v'] ?? 0,
        text: rawText,
      );
    }).toList();

    _localBiblesCache[version] = fullList;
    return fullList.where((v) => v.book == book && v.chapter == chapter).toList();
  }

  /// Dynamic single verse lookup (primarily for reference panels)
  Future<String?> fetchSingleVerse(String book, int chapter, int verse, String version) async {
    try {
      final list = await fetchChapter(book, chapter, version);
      final match = list.firstWhere(
        (v) => v.book == book && v.chapter == chapter && v.verse == verse
      );
      return match.text;
    } catch (_) {
      return null;
    }
  }

  /// Pre-loads full Bible data into cache to execute instant in-memory full-text search
  Future<List<BibleVerse>> loadFullBibleForSearch(String version) async {
    if (_localBiblesCache.containsKey(version)) {
      return _localBiblesCache[version]!;
    }

    if (isBollsVersion(version)) {
      final url = Uri.parse("https://bolls.life/static/translations/$version.json");
      final res = await http.get(url);
      if (res.statusCode != 200) throw Exception("Failed to load search db for $version");
      
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      final List<BibleVerse> flat = data.map((item) {
        final bIndex = item['book'] as int;
        final bookCode = (bIndex - 1 < _bollsBookOrder.length) 
            ? _bollsBookOrder[bIndex - 1] 
            : bIndex.toString();
        
        String rawText = item['text'] ?? '';
        rawText = rawText
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        return BibleVerse(
          book: bookCode,
          chapter: item['chapter'] ?? 0,
          verse: item['verse'] ?? 0,
          text: rawText,
        );
      }).toList();
      
      _localBiblesCache[version] = flat;
      return flat;
    }

    if (isApiVersion(version)) {
      final apiVersions = { "KJV": "eng_kjv", "ASV": "eng_asv", "BBE": "eng_bbe", "BSB": "BSB" };
      final apiId = apiVersions[version];
      final url = Uri.parse("https://bible.helloao.org/api/$apiId/complete.json");
      
      final res = await http.get(url);
      if (res.statusCode != 200) throw Exception("Failed to load search db for $version");
      
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      final List<BibleVerse> flat = [];
      
      // Inverse localToHelloAoMap
      final helloAoToLocalMap = <String, String>{};
      _localToHelloAoMap.forEach((localCode, helloAoId) {
        helloAoToLocalMap[helloAoId] = localCode;
      });

      if (data['books'] is List) {
        for (var bObj in data['books']) {
          final bookId = bObj['id'] as String;
          final bookCode = helloAoToLocalMap[bookId] ?? bookId;
          if (bObj['chapters'] is List) {
            for (var chObj in bObj['chapters']) {
              final ch = chObj['chapter'];
              if (ch != null && ch['content'] is List) {
                for (var item in ch['content']) {
                  if (item['type'] == 'verse') {
                    final verseNum = item['number'] ?? item['verse'];
                    final List<dynamic> contentParts = item['content'] ?? [];
                    final text = contentParts
                        .map((part) {
                          if (part is String) return part;
                          if (part is Map && part['text'] is String) return part['text'];
                          return '';
                        })
                        .where((t) => t.trim().isNotEmpty)
                        .join(' ');

                    flat.add(BibleVerse(
                      book: bookCode,
                      chapter: ch['number'] ?? 0,
                      verse: verseNum is String ? int.parse(verseNum) : (verseNum as int),
                      text: text,
                    ));
                  }
                }
              }
            }
          }
        }
      }

      _localBiblesCache[version] = flat;
      return flat;
    }

    // Otherwise, loading local file caches it automatically
    await fetchChapter("Gen", 1, version);
    return _localBiblesCache[version] ?? [];
  }
}
