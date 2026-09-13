enum VocabKind { word, phrase }

class VocabSense {
  const VocabSense({
    required this.meaning,
    this.partOfSpeech = '',
    this.collocations = '',
    this.example = '',
    this.exampleTranslation = '',
  });

  final String meaning;
  final String partOfSpeech;
  final String collocations;
  final String example;
  final String exampleTranslation;

  factory VocabSense.fromJson(Map<String, dynamic> json) {
    return VocabSense(
      meaning: json['meaning'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      collocations: json['collocations'] as String? ?? '',
      example: json['example'] as String? ?? '',
      exampleTranslation: json['exampleTranslation'] as String? ?? '',
    );
  }
}

class VocabItem {
  const VocabItem({
    required this.id,
    required this.kind,
    required this.term,
    required this.meaning,
    required this.example,
    required this.senses,
    this.normalizedTerm = '',
    this.phonetic = '',
    this.partOfSpeech = '',
    this.collocations = '',
    this.category = '',
    this.sourceRows = const [],
    this.exampleTranslation = '',
  });

  final String id;
  final VocabKind kind;
  final String term;
  final String normalizedTerm;
  final String phonetic;
  final String partOfSpeech;
  final String meaning;
  final String collocations;
  final String example;
  final String exampleTranslation;
  final String category;
  final List<VocabSense> senses;
  final List<int> sourceRows;

  String get kindLabel => kind == VocabKind.word ? '高频单词' : '词组搭配';

  factory VocabItem.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] == 'phrase' ? VocabKind.phrase : VocabKind.word;
    final rawSenses = json['senses'] as List<dynamic>? ?? const [];

    return VocabItem(
      id: json['id'] as String? ?? '',
      kind: kind,
      term: json['term'] as String? ?? '',
      normalizedTerm: json['normalizedTerm'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      collocations: json['collocations'] as String? ?? '',
      example: json['example'] as String? ?? '',
      exampleTranslation: json['exampleTranslation'] as String? ?? '',
      category: json['category'] as String? ?? '',
      senses: rawSenses
          .whereType<Map<String, dynamic>>()
          .map(VocabSense.fromJson)
          .toList(growable: false),
      sourceRows: (json['sourceRows'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(growable: false),
    );
  }
}

class VocabSeed {
  const VocabSeed({required this.items, required this.metadata});

  final List<VocabItem> items;
  final Map<String, dynamic> metadata;

  int get wordCount =>
      metadata['wordCardCount'] as int? ??
      items.where((item) => item.kind == VocabKind.word).length;

  int get phraseCount =>
      metadata['phraseCardCount'] as int? ??
      items.where((item) => item.kind == VocabKind.phrase).length;

  String get examDateLabel =>
      metadata['examDateLabel'] as String? ?? '2026年10月24日-25日';

  factory VocabSeed.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return VocabSeed(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(VocabItem.fromJson)
          .toList(growable: false),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
