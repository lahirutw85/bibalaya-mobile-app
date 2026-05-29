import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_verse.dart';
import '../models/bible_book.dart';
import '../models/bookmark.dart';
import '../models/lexicon.dart';
import '../services/bible_service.dart';
import '../services/bookmark_service.dart';
import '../services/lexicon_service.dart';
import '../services/audio_service.dart';
import '../services/reference_service.dart';

class PanelCoordinate {
  final String book;
  final int chapter;
  final int verse;
  final String version;

  PanelCoordinate({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.version,
  });
}

class BibleProvider with ChangeNotifier {
  final BibleService _bibleService = BibleService();
  final BookmarkService _bookmarkService = BookmarkService();
  final LexiconService _lexiconService = LexiconService();
  final AudioService _audioService = AudioService();
  final ReferenceService _referenceService = ReferenceService();

  // Selected Bible values
  String _version = "SINBIBLE";
  String _selectedBook = "Gen";
  int _selectedChapter = 1;
  double _fontSize = 16.0;
  bool _isDarkTheme = false;

  // Compare mode
  bool _compareMode = false;
  String _compareVersion = "KJV";
  bool _threeWayCompare = false;
  String _compareVersion3 = "NIV";

  // References state
  bool _showReferences = true;
  final List<PanelCoordinate> _referencePanels = [];

  // Content loading
  List<BibleBook> _books = [];
  List<BibleVerse> _verses = [];
  List<BibleVerse> _compareVerses = [];
  List<BibleVerse> _compareVerses3 = [];
  Map<String, List<BibleReference>> _referencesMap = {};

  bool _loading = false;
  bool _compareLoading = false;
  bool _compareLoading3 = false;
  bool _searchActive = false;
  String _searchTerm = "";
  List<BibleVerse> _searchResults = [];
  bool _searchLoading = false;

  // Getters
  String get version => _version;
  String get selectedBook => _selectedBook;
  int get selectedChapter => _selectedChapter;
  double get fontSize => _fontSize;
  bool get isDarkTheme => _isDarkTheme;

  bool get compareMode => _compareMode;
  String get compareVersion => _compareVersion;
  bool get threeWayCompare => _threeWayCompare;
  String get compareVersion3 => _compareVersion3;

  bool get showReferences => _showReferences;
  List<PanelCoordinate> get referencePanels => _referencePanels;

  List<BibleBook> get books => _books;
  List<BibleVerse> get verses => _verses;
  List<BibleVerse> get compareVerses => _compareVerses;
  List<BibleVerse> get compareVerses3 => _compareVerses3;
  Map<String, List<BibleReference>> get referencesMap => _referencesMap;

  bool get loading => _loading;
  bool get compareLoading => _compareLoading;
  bool get compareLoading3 => _compareLoading3;
  bool get searchActive => _searchActive;
  String get searchTerm => _searchTerm;
  List<BibleVerse> get searchResults => _searchResults;
  bool get searchLoading => _searchLoading;

  List<Bookmark> get bookmarks => _bookmarkService.bookmarks;
  String? get playingAudioId => _audioService.playingId;

  // Services
  BibleService get bibleService => _bibleService;
  LexiconService get lexiconService => _lexiconService;
  AudioService get audioService => _audioService;

  BibleProvider() {
    _initSettings();
  }

  Future<void> _initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _version = prefs.getString("bible-version") ?? "SINBIBLE";
    _selectedBook = prefs.getString("bible-book") ?? "Gen";
    _selectedChapter = prefs.getInt("bible-chapter") ?? 1;
    _fontSize = prefs.getDouble("bible-font-size") ?? 16.0;
    _isDarkTheme = prefs.getBool("bible-theme-dark") ?? false;
    _showReferences = prefs.getBool("bible-show-references") ?? true;
    
    await _bookmarkService.loadBookmarks();
    await _audioService.init();
    await loadBooks();
    await loadChapter();
  }

  Future<void> setVersion(String val) async {
    _version = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("bible-version", val);
    stopAudio();
    await loadBooks();
    await loadChapter();
    notifyListeners();
  }

  Future<void> setSelectedBook(String val) async {
    _selectedBook = val;
    _selectedChapter = 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("bible-book", val);
    await prefs.setInt("bible-chapter", 1);
    stopAudio();
    await loadChapter();
    notifyListeners();
  }

  Future<void> setSelectedChapter(int val) async {
    _selectedChapter = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("bible-chapter", val);
    stopAudio();
    await loadChapter();
    notifyListeners();
  }

  Future<void> loadBooks() async {
    _books = await _bibleService.loadBooks(_version);
    notifyListeners();
  }

  Future<void> loadChapter() async {
    _loading = true;
    notifyListeners();
    try {
      final raw = await _bibleService.fetchChapter(_selectedBook, _selectedChapter, _version);
      _verses = raw;
      
      if (_showReferences) {
        _referencesMap = await _referenceService.fetchReferencesForChapter(_verses);
      } else {
        _referencesMap = {};
      }

      if (_compareMode) {
        await loadCompareChapter();
      }
    } catch (e) {
      print("Error loading chapter: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCompareChapter() async {
    _compareLoading = true;
    notifyListeners();
    try {
      _compareVerses = await _bibleService.fetchChapter(_selectedBook, _selectedChapter, _compareVersion);
      if (_threeWayCompare) {
        _compareLoading3 = true;
        _compareVerses3 = await _bibleService.fetchChapter(_selectedBook, _selectedChapter, _compareVersion3);
      }
    } catch (e) {
      print("Error loading compare: $e");
    } finally {
      _compareLoading = false;
      _compareLoading3 = false;
      notifyListeners();
    }
  }

  Future<void> toggleCompareMode(bool val) async {
    _compareMode = val;
    if (_compareMode) {
      await loadCompareChapter();
    }
    notifyListeners();
  }

  Future<void> setCompareVersion(String val) async {
    _compareVersion = val;
    if (_compareMode) {
      await loadCompareChapter();
    }
    notifyListeners();
  }

  Future<void> toggleThreeWayCompare(bool val) async {
    _threeWayCompare = val;
    if (_threeWayCompare && _compareMode) {
      await loadCompareChapter();
    }
    notifyListeners();
  }

  Future<void> setCompareVersion3(String val) async {
    _compareVersion3 = val;
    if (_compareMode && _threeWayCompare) {
      await loadCompareChapter();
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("bible-theme-dark", _isDarkTheme);
    notifyListeners();
  }

  Future<void> toggleReferences() async {
    _showReferences = !_showReferences;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("bible-show-references", _showReferences);
    await loadChapter();
  }

  void adjustFontSize(String action) async {
    if (action == 'increase' && _fontSize < 32.0) {
      _fontSize += 2.0;
    } else if (action == 'decrease' && _fontSize > 12.0) {
      _fontSize -= 2.0;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("bible-font-size", _fontSize);
    notifyListeners();
  }

  // Audio Playback
  bool get isAudioExists => _audioService.chapterAudioExists(_selectedBook, _selectedChapter, _version);
  
  bool isVerseAudioExists(String book, int chapter, int verse) {
    return _audioService.verseAudioExists(book, chapter, verse, _version);
  }

  Future<void> playAudio() async {
    if (isAudioExists) {
      await _audioService.playChapter(_selectedBook, _selectedChapter);
      notifyListeners();
    }
  }

  Future<void> playVerseAudio(String book, int chapter, int verse) async {
    if (isVerseAudioExists(book, chapter, verse)) {
      await _audioService.playVerse(book, chapter, verse);
      notifyListeners();
    }
  }

  Future<void> stopAudio() async {
    await _audioService.stop();
    notifyListeners();
  }

  // Bookmarking / Highlights
  bool isBookmarked(String book, int chapter, int verse) {
    return _bookmarkService.getBookmarkForVerse(book, chapter, verse) != null;
  }

  Bookmark? getBookmark(String book, int chapter, int verse) {
    return _bookmarkService.getBookmarkForVerse(book, chapter, verse);
  }

  Future<void> addBookmark(BibleVerse verse, String color) async {
    await _bookmarkService.addBookmark(verse, color, _version);
    notifyListeners();
  }

  Future<void> removeBookmark(String book, int chapter, int verse) async {
    await _bookmarkService.removeBookmark(book, chapter, verse);
    notifyListeners();
  }

  // Reference Panels
  void openReferencePanel(String book, int chapter, int verse) {
    _referencePanels.add(PanelCoordinate(
      book: book,
      chapter: chapter,
      verse: verse,
      version: _version,
    ));
    notifyListeners();
  }

  void closeReferencePanel(int index) {
    if (index >= 0 && index < _referencePanels.length) {
      _referencePanels.removeRange(index, _referencePanels.length);
    }
    notifyListeners();
  }

  void clearReferencePanels() {
    _referencePanels.clear();
    notifyListeners();
  }

  // Searching
  Future<void> performSearch(String term, String scope) async {
    if (term.trim().isEmpty) {
      _searchActive = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _searchLoading = true;
    _searchTerm = term;
    _searchActive = true;
    notifyListeners();

    try {
      final all = await _bibleService.loadFullBibleForSearch(_version);
      
      final query = term.toLowerCase();
      _searchResults = all.where((v) {
        if (scope == 'thisBook' && v.book != _selectedBook) return false;
        return v.text.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      print("Search failed: $e");
      _searchResults = [];
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchActive = false;
    _searchResults = [];
    notifyListeners();
  }
}
