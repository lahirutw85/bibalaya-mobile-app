class BibleBook {
  final String code;
  final String name;

  BibleBook({
    required this.code,
    required this.name,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }
}
