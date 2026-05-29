import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lexicon.dart';

class LexiconService {
  /// Fetches interlinear word listings for a given verse.
  /// Parses the text and groups words with their corresponding Strong's numbers.
  Future<List<InterlinearWord>> fetchStrongsMapping(String helloAoBookId, int chapter, int verse) async {
    final url = Uri.parse(
      "https://api.biblesupersearch.com/api?bible=kjv_strongs&reference=$helloAoBookId+$chapter:$verse&markup=raw"
    );
    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception("Failed to fetch interlinear data.");
    
    final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    final List<dynamic>? results = data['results'];
    if (results == null || results.isEmpty) {
      throw Exception("No interlinear data found for this verse.");
    }

    final verses = results[0]['verses']?['kjv_strongs'];
    if (verses == null) throw Exception("No interlinear data results.");
    final chapterData = verses[chapter.toString()];
    if (chapterData == null) throw Exception("Chapter data not found.");
    final verseTextObj = chapterData[verse.toString()];
    if (verseTextObj == null) throw Exception("Verse text not found.");
    final String text = verseTextObj['text'] ?? '';

    final List<InterlinearWord> wordsWithStrongs = [];
    final parts = text.split(RegExp(r'\s+'));
    for (var part in parts) {
      final wordMatch = RegExp(r'^([A-Za-z]+(?:\x27[A-Za-z]+)?)', caseSensitive: false).firstMatch(part);
      if (wordMatch != null) {
        final matchedWord = wordMatch.group(1)!;
        final cleanWord = matchedWord.toLowerCase();
        
        final strongsMatches = RegExp(r'\{([GH][0-9]+)\}', caseSensitive: false)
            .allMatches(part)
            .map((m) => m.group(1)!)
            .toList();

        wordsWithStrongs.add(InterlinearWord(
          word: matchedWord,
          cleanWord: cleanWord,
          strongs: strongsMatches,
        ));
      }
    }

    return wordsWithStrongs;
  }

  /// Fetches dictionary definition data for a specific Strong's concordance number.
  Future<StrongsDefinition> fetchStrongsDefinition(String strongsNumber) async {
    final url = Uri.parse("https://api.biblesupersearch.com/api/strongs?strongs=$strongsNumber");
    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception("Failed to fetch Strong's definition.");
    
    final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    final List<dynamic>? results = data['results'];
    if (results == null || results.isEmpty) {
      throw Exception("No definition found for Strong's $strongsNumber");
    }

    final def = results[0];
    return StrongsDefinition(
      number: strongsNumber,
      rootWord: def['root_word'] ?? '',
      transliteration: def['transliteration'] ?? '',
      pronunciation: def['pronunciation'] ?? '',
      entry: def['entry'] ?? '',
    );
  }

  /// Try to align double-clicked English word to the parsed interlinear verse words list
  InterlinearWord? findBestMatch(List<InterlinearWord> wordsWithStrongs, String cleanWord) {
    final searchWord = cleanWord.toLowerCase();
    
    // 1. Exact match
    for (var w in wordsWithStrongs) {
      if (w.cleanWord == searchWord) return w;
    }
    
    // 2. Fuzzy match fallback
    for (var w in wordsWithStrongs) {
      if (w.cleanWord.startsWith(searchWord) || 
          searchWord.startsWith(w.cleanWord) ||
          w.cleanWord.contains(searchWord) ||
          searchWord.contains(w.cleanWord)) {
        return w;
      }
    }
    return null;
  }
}
