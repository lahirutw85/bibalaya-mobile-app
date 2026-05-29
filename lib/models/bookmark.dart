class Bookmark {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String version;
  final String color; // hex representation of highlight color
  final DateTime createdAt;

  Bookmark({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.version,
    required this.color,
    required this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      book: json['book'] ?? '',
      chapter: json['chapter'] ?? 0,
      verse: json['verse'] ?? 0,
      text: json['text'] ?? '',
      version: json['version'] ?? '',
      color: json['color'] ?? '#FFEB3B', // default yellow highlight
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'version': version,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
