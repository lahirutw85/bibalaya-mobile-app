class BibleVerse {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final List<dynamic>? references;

  BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.references,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      book: json['book'] ?? json['b'] ?? '',
      chapter: json['chapter'] ?? json['c'] ?? 0,
      verse: json['verse'] ?? json['v'] ?? 0,
      text: json['text'] ?? json['t'] ?? '',
      references: json['references'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      if (references != null) 'references': references,
    };
  }

  BibleVerse copyWith({
    String? book,
    int? chapter,
    int? verse,
    String? text,
    List<dynamic>? references,
  }) {
    return BibleVerse(
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      text: text ?? this.text,
      references: references ?? this.references,
    );
  }
}
