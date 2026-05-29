import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';
import '../models/bible_verse.dart';

class BookmarkService {
  static const String _key = "bible-bookmarks";
  List<Bookmark> _bookmarks = [];

  List<Bookmark> get bookmarks => _bookmarks;

  /// Load bookmarks from SharedPreferences
  Future<List<Bookmark>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) {
      _bookmarks = [];
      return _bookmarks;
    }
    try {
      final List<dynamic> data = jsonDecode(jsonStr);
      _bookmarks = data.map((x) => Bookmark.fromJson(x)).toList();
    } catch (e) {
      print("Error loading bookmarks: $e");
      _bookmarks = [];
    }
    return _bookmarks;
  }

  /// Add a bookmark/highlight
  Future<List<Bookmark>> addBookmark(BibleVerse verse, String color, String version) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if bookmark already exists at coordinates
    _bookmarks.removeWhere((b) => 
        b.book == verse.book && 
        b.chapter == verse.chapter && 
        b.verse == verse.verse
    );

    final newBookmark = Bookmark(
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
      text: verse.text,
      version: version,
      color: color,
      createdAt: DateTime.now(),
    );

    _bookmarks.add(newBookmark);
    // Sort by created date descending
    _bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await prefs.setString(_key, jsonEncode(_bookmarks.map((x) => x.toJson()).toList()));
    return _bookmarks;
  }

  /// Remove bookmark
  Future<List<Bookmark>> removeBookmark(String book, int chapter, int verse) async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarks.removeWhere((b) => 
        b.book == book && 
        b.chapter == chapter && 
        b.verse == verse
    );
    await prefs.setString(_key, jsonEncode(_bookmarks.map((x) => x.toJson()).toList()));
    return _bookmarks;
  }

  /// Check if a verse is bookmarked and return it
  Bookmark? getBookmarkForVerse(String book, int chapter, int verse) {
    try {
      return _bookmarks.firstWhere((b) => 
          b.book == book && 
          b.chapter == chapter && 
          b.verse == verse
      );
    } catch (_) {
      return null;
    }
  }
}
