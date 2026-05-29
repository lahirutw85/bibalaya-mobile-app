import 'package:flutter/material.dart';
import '../services/lexicon_service.dart';
import '../models/lexicon.dart';

class LexiconDialog extends StatefulWidget {
  final String word;
  final String book;
  final int chapter;
  final int verse;
  final LexiconService lexiconService;
  final String helloAoBookCode;

  const LexiconDialog({
    super.key,
    required this.word,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.lexiconService,
    required this.helloAoBookCode,
  });

  @override
  State<LexiconDialog> createState() => _LexiconDialogState();
}

class _LexiconDialogState extends State<LexiconDialog> {
  bool _loading = true;
  String? _error;
  StrongsDefinition? _strongsData;
  List<InterlinearWord> _verseStrongs = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails(widget.word);
  }

  Future<void> _fetchDetails(String targetWord) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Fetch interlinear mapping for the verse if we don't have it
      if (_verseStrongs.isEmpty) {
        _verseStrongs = await widget.lexiconService.fetchStrongsMapping(
          widget.helloAoBookCode,
          widget.chapter,
          widget.verse,
        );
      }

      // 2. Find best matching word
      final match = widget.lexiconService.findBestMatch(_verseStrongs, targetWord);
      if (match != null && match.strongs.isNotEmpty) {
        final strongsNumber = match.strongs.first;
        final def = await widget.lexiconService.fetchStrongsDefinition(strongsNumber);
        
        setState(() {
          _strongsData = def.copyWith(matchedWord: match.word);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Could not match "$targetWord". Select a word below to view root definition.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load lexicon info: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _fetchDirectStrongs(String strongsCode, String englishWord) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final def = await widget.lexiconService.fetchStrongsDefinition(strongsCode);
      setState(() {
        _strongsData = def.copyWith(matchedWord: englishWord);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load definition: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "📖 Word Lexicon Study",
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildWordsSelector(),
            ] else if (_strongsData != null) ...[
              // Statistics fields
              _buildInfoRow("English Word:", _strongsData!.matchedWord, isBoldVal: true),
              _buildInfoRow("Root Word:", _strongsData!.rootWord),
              _buildInfoRow("Transliteration:", _strongsData!.transliteration),
              if (_strongsData!.pronunciation.isNotEmpty)
                _buildInfoRow("Pronunciation:", _strongsData!.pronunciation),
              _buildInfoRow("Strong's ID:", _strongsData!.number, isCode: true),
              const SizedBox(height: 12),
              
              Text(
                "Strong's Definition:",
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // Render HTML-like tags or clean entries
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark 
                      ? Colors.grey.shade900 
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _cleanHtmlTags(_strongsData!.entry),
                    style: textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildWordsSelector(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBoldVal = false, bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              _cleanHtmlTags(value),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBoldVal ? FontWeight.bold : FontWeight.normal,
                fontFamily: isCode ? 'Courier' : null,
                color: isCode ? Colors.blueAccent : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordsSelector() {
    if (_verseStrongs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Verse Words (Select to lookup):",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6.0,
          runSpacing: 4.0,
          children: _verseStrongs.map((w) {
            final isCurrent = _strongsData?.number != null && 
                w.strongs.isNotEmpty && 
                _strongsData!.number == w.strongs.first;

            return FilterChip(
              label: Text(
                "${w.word} ${w.strongs.isNotEmpty ? '(${w.strongs.first})' : ''}",
                style: const TextStyle(fontSize: 11),
              ),
              selected: isCurrent,
              onSelected: w.strongs.isEmpty 
                  ? null 
                  : (selected) {
                      _fetchDirectStrongs(w.strongs.first, w.word);
                    },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _cleanHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  }
}
