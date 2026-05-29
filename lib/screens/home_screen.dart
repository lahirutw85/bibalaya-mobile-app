import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/bible_verse.dart';
import '../models/bible_book.dart';
import '../widgets/lexicon_dialog.dart';
import '../widgets/cross_reference_panel.dart';
import 'compare_screen.dart';
import 'search_screen.dart';
import 'bookmarks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BibleProvider>(context);
    final theme = Theme.of(context);
    final isDark = provider.isDarkTheme;

    // Define colors matching premium aesthetics
    final Color primaryColor = isDark ? Colors.teal.shade300 : Colors.teal.shade700;
    final Color scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F7);
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Theme(
      data: isDark 
          ? ThemeData.dark().copyWith(
              primaryColor: primaryColor,
              scaffoldBackgroundColor: scaffoldBg,
              cardColor: cardBg,
              appBarTheme: AppBarTheme(backgroundColor: cardBg, elevation: 0),
            )
          : ThemeData.light().copyWith(
              primaryColor: primaryColor,
              scaffoldBackgroundColor: scaffoldBg,
              cardColor: cardBg,
              appBarTheme: AppBarTheme(backgroundColor: cardBg, elevation: 0),
            ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 32,
                  width: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.book, color: primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bibalaya",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87
                    ),
                  ),
                  const Text(
                    "ශුද්ධ වූ බයිබලය",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Translation Selection Dropdown
            DropdownButton<String>(
              value: provider.version,
              underline: const SizedBox.shrink(),
              dropdownColor: cardBg,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              onChanged: (String? val) {
                if (val != null) provider.setVersion(val);
              },
              items: const [
                DropdownMenuItem(value: "ROV", child: Text("පැරණි සංශෝධිත")),
                DropdownMenuItem(value: "2018", child: Text("2018 නව සංශෝධිත")),
                DropdownMenuItem(value: "SINBIBLE", child: Text("Simple Sinhala")),
                DropdownMenuItem(value: "TAMOVR", child: Text("தமிழ் (Tamil)")),
                DropdownMenuItem(value: "BSB", child: Text("BSB (English)")),
                DropdownMenuItem(value: "KJV", child: Text("KJV (English)")),
                DropdownMenuItem(value: "NIV", child: Text("NIV (English)")),
                DropdownMenuItem(value: "AMP", child: Text("AMP (English)")),
              ],
            ),
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => provider.toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsBottomSheet(context, provider),
            ),
          ],
        ),
        body: Column(
          children: [
            // Book & Chapter Pickers, Audio Play Controls
            _buildNavigationToolbar(context, provider, primaryColor),
            
            // Main Content Area
            Expanded(
              child: provider.loading 
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: provider.verses.length,
                            itemBuilder: (context, index) {
                              final verse = provider.verses[index];
                              return _buildVerseItem(context, provider, verse, primaryColor);
                            },
                          ),
                        ),
                        // Split view horizontal reference panels stack at the bottom
                        if (provider.referencePanels.isNotEmpty)
                          _buildHorizontalReferenceStack(provider),
                      ],
                    ),
            ),
            // Navigation controls (Bottom Bar)
            _buildBottomActionBar(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationToolbar(BuildContext context, BibleProvider provider, Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          // Book picker button
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.menu_book, size: 16),
              label: Text(
                provider.books.firstWhere((b) => b.code == provider.selectedBook, orElse: () => BibleBook(code: provider.selectedBook, name: provider.selectedBook)).name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              onPressed: () => _showBookSelectorDialog(context, provider),
            ),
          ),
          const SizedBox(width: 8),
          // Chapter picker button
          OutlinedButton.icon(
            icon: const Icon(Icons.unfold_more, size: 16),
            label: Text("පරිච්ඡේදය ${provider.selectedChapter}"),
            onPressed: () => _showChapterSelectorDialog(context, provider),
          ),
          const SizedBox(width: 8),
          // Narration Audio Play/Pause Button
          if (provider.isAudioExists) ...[
            IconButton(
              icon: CircleAvatar(
                backgroundColor: provider.playingAudioId != null ? Colors.redAccent : themeColor,
                child: Icon(
                  provider.playingAudioId != null ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () {
                if (provider.playingAudioId != null) {
                  provider.stopAudio();
                } else {
                  provider.playAudio();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseItem(BuildContext context, BibleProvider provider, BibleVerse verse, Color accentColor) {
    final key = "${verse.book}_${verse.chapter}_${verse.verse}";
    final bookmark = provider.getBookmark(verse.book, verse.chapter, verse.verse);
    final isHighlighted = bookmark != null;
    
    Color? highlightColor;
    if (isHighlighted) {
      // Decode hex color from bookmark
      try {
        final hexStr = bookmark.color.replaceAll("#", "");
        highlightColor = Color(int.parse("0xFF$hexStr")).withOpacity(0.35);
      } catch (_) {
        highlightColor = Colors.yellow.withOpacity(0.3);
      }
    }

    final refs = provider.referencesMap[key] ?? [];

    return InkWell(
      onTap: () => _showVerseOptionsBottomSheet(context, provider, verse),
      child: Container(
        color: highlightColor,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${verse.verse}. ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: provider.fontSize - 2,
                    color: accentColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    verse.text,
                    style: TextStyle(
                      fontSize: provider.fontSize,
                      height: 1.5,
                    ),
                  ),
                ),
                if (provider.isVerseAudioExists(verse.book, verse.chapter, verse.verse)) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      provider.playingAudioId == "verse-${verse.book}-${verse.chapter}-${verse.verse}"
                          ? Icons.volume_up
                          : Icons.volume_mute,
                      color: provider.playingAudioId == "verse-${verse.book}-${verse.chapter}-${verse.verse}"
                          ? accentColor
                          : Colors.grey,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (provider.playingAudioId == "verse-${verse.book}-${verse.chapter}-${verse.verse}") {
                        provider.stopAudio();
                      } else {
                        provider.playVerseAudio(verse.book, verse.chapter, verse.verse);
                      }
                    },
                  ),
                ],
              ],
            ),
            // Render Cross References
            if (provider.showReferences && refs.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6.0,
                children: refs.map((ref) => ActionChip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
                  padding: EdgeInsets.zero,
                  label: Text(
                    "${ref.book} ${ref.chapter}:${ref.verse}",
                    style: const TextStyle(fontSize: 10, color: Colors.blueAccent),
                  ),
                  onPressed: () {
                    provider.openReferencePanel(ref.book, ref.chapter, ref.verse);
                  },
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalReferenceStack(BibleProvider provider) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.referencePanels.length,
        itemBuilder: (context, index) {
          final panel = provider.referencePanels[index];
          return CrossReferencePanel(
            panelIndex: index,
            coordinate: panel,
            onClose: () => provider.closeReferencePanel(index),
          );
        },
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, BibleProvider provider) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: "Previous Chapter",
            onPressed: () {
              int currentIdx = provider.books.indexWhere((b) => b.code == provider.selectedBook);
              if (provider.selectedChapter > 1) {
                provider.setSelectedChapter(provider.selectedChapter - 1);
              } else if (currentIdx > 0) {
                final prevBook = provider.books[currentIdx - 1].code;
                provider.setSelectedBook(prevBook);
                // Simple chapter count mapping, default to max fallback if not standard
                provider.setSelectedChapter(1); 
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.compare),
            tooltip: "Parallel View",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search Text",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: "Saved Verses",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: "Next Chapter",
            onPressed: () {
              int currentIdx = provider.books.indexWhere((b) => b.code == provider.selectedBook);
              // Maximum fallback
              if (provider.selectedChapter < 150) { 
                provider.setSelectedChapter(provider.selectedChapter + 1);
              } else if (currentIdx < provider.books.length - 1) {
                provider.setSelectedBook(provider.books[currentIdx + 1].code);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showVerseOptionsBottomSheet(BuildContext context, BibleProvider provider, BibleVerse verse) {
    final isEnglish = provider.bibleService.isApiVersion(provider.version) || 
                      provider.bibleService.isBollsVersion(provider.version);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "${verse.book} ${verse.chapter}:${verse.verse}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Highlighter Colors
              const Text("Highlight color:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _colorPickerBtn(context, provider, verse, Colors.yellow, "#FFEB3B"),
                  _colorPickerBtn(context, provider, verse, Colors.green, "#4CAF50"),
                  _colorPickerBtn(context, provider, verse, Colors.blue, "#2196F3"),
                  _colorPickerBtn(context, provider, verse, Colors.pink, "#E91E63"),
                  if (provider.isBookmarked(verse.book, verse.chapter, verse.verse))
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () {
                        provider.removeBookmark(verse.book, verse.chapter, verse.verse);
                        Navigator.pop(context);
                      },
                    )
                ],
              ),
              const SizedBox(height: 16),

              // Lexicon Interlinear triggers only for English
              if (isEnglish) ...[
                ListTile(
                  leading: const Icon(Icons.g_translate),
                  title: const Text("Interlinear Word Lexicon"),
                  subtitle: const Text("Study Greek & Hebrew definitions"),
                  onTap: () {
                    Navigator.pop(context);
                    _showLexiconBottomSheet(context, provider, verse);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _colorPickerBtn(BuildContext context, BibleProvider provider, BibleVerse verse, Color color, String hexCode) {
    return GestureDetector(
      onTap: () {
        provider.addBookmark(verse, hexCode);
        Navigator.pop(context);
      },
      child: CircleAvatar(
        backgroundColor: color.withOpacity(0.5),
        radius: 18,
        child: CircleAvatar(backgroundColor: color, radius: 10),
      ),
    );
  }

  void _showLexiconBottomSheet(BuildContext context, BibleProvider provider, BibleVerse verse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: LexiconDialog(
                word: verse.text.split(" ").first,
                book: verse.book,
                chapter: verse.chapter,
                verse: verse.verse,
                lexiconService: provider.lexiconService,
                helloAoBookCode: provider.bibleService.getHelloAoBookCode(verse.book),
              ),
            );
          },
        );
      },
    );
  }

  void _showSettingsBottomSheet(BuildContext context, BibleProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Settings / සිටුවම්", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              // Font Size Adjustment
              ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text("Font Size / අකුරු වල විශාලත්වය"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => provider.adjustFontSize('decrease'),
                    ),
                    Text(provider.fontSize.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => provider.adjustFontSize('increase'),
                    ),
                  ],
                ),
              ),
              // Cross Reference Toggle
              SwitchListTile(
                secondary: const Icon(Icons.share),
                title: const Text("Show References / සබැඳි පද පෙන්වන්න"),
                value: provider.showReferences,
                onChanged: (val) {
                  provider.toggleReferences();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBookSelectorDialog(BuildContext context, BibleProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("පොත තෝරන්න / Select Book"),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: provider.books.length,
              itemBuilder: (context, index) {
                final book = provider.books[index];
                final isSelected = book.code == provider.selectedBook;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                  onPressed: () {
                    provider.setSelectedBook(book.code);
                    Navigator.pop(context);
                  },
                  child: Text(
                    book.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showChapterSelectorDialog(BuildContext context, BibleProvider provider) {
    // Dynamic chapter counts fallback. BibleService.js uses bookChaptersMap.
    final Map<String, int> bookChaptersMap = {
      "Gen": 50, "Exod": 40, "Lev": 27, "Num": 36, "Deut": 34, "Josh": 24, "Judg": 21, "Ruth": 4,
      "1Sam": 31, "2Sam": 24, "1Kgs": 22, "2Kgs": 25, "1Chr": 29, "2Chr": 36, "Ezra": 10, "Neh": 13,
      "Esth": 10, "Job": 42, "Ps": 150, "Prov": 31, "Eccl": 12, "Song": 8, "Isa": 66, "Jer": 52,
      "Lam": 5, "Ezek": 48, "Dan": 12, "Hos": 14, "Joel": 3, "Amos": 9, "Obad": 1, "Jonah": 4,
      "Mic": 7, "Nah": 3, "Hab": 3, "Zeph": 3, "Hag": 2, "Zech": 14, "Mal": 4, "Matt": 28,
      "Mark": 16, "Luke": 24, "John": 21, "Acts": 28, "Rom": 16, "1Cor": 16, "2Cor": 13, "Gal": 6,
      "Eph": 6, "Phil": 4, "Col": 4, "1Thess": 5, "2Thess": 3, "1Tim": 6, "2Tim": 4, "Titus": 3,
      "Phlm": 1, "Heb": 13, "Jas": 5, "1Pet": 5, "2Pet": 3, "1John": 5, "2John": 1, "3John": 1,
      "Jude": 1, "Rev": 22, "Tob": 14, "Jdt": 16, "Wis": 19, "Sir": 51, "Bar": 6, "1Macc": 16, "2Macc": 15
    };

    final totalChapters = bookChaptersMap[provider.selectedBook] ?? 50;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("පරිච්ඡේදය තෝරන්න / Select Chapter"),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: totalChapters,
              itemBuilder: (context, index) {
                final chNum = index + 1;
                final isSelected = chNum == provider.selectedChapter;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    provider.setSelectedChapter(chNum);
                    Navigator.pop(context);
                  },
                  child: Text(
                    chNum.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
