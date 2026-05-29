class InterlinearWord {
  final String word;
  final String cleanWord;
  final List<String> strongs;

  InterlinearWord({
    required this.word,
    required this.cleanWord,
    required this.strongs,
  });

  factory InterlinearWord.fromMap(Map<String, dynamic> map) {
    return InterlinearWord(
      word: map['word'] ?? '',
      cleanWord: map['cleanWord'] ?? '',
      strongs: List<String>.from(map['strongs'] ?? []),
    );
  }
}

class StrongsDefinition {
  final String number;
  final String rootWord;
  final String transliteration;
  final String pronunciation;
  final String entry;
  final String matchedWord;

  StrongsDefinition({
    required this.number,
    required this.rootWord,
    required this.transliteration,
    required this.pronunciation,
    required this.entry,
    this.matchedWord = '',
  });

  StrongsDefinition copyWith({
    String? number,
    String? rootWord,
    String? transliteration,
    String? pronunciation,
    String? entry,
    String? matchedWord,
  }) {
    return StrongsDefinition(
      number: number ?? this.number,
      rootWord: rootWord ?? this.rootWord,
      transliteration: transliteration ?? this.transliteration,
      pronunciation: pronunciation ?? this.pronunciation,
      entry: entry ?? this.entry,
      matchedWord: matchedWord ?? this.matchedWord,
    );
  }
}
