import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/vocab_item.dart';

class VocabRepository {
  const VocabRepository();

  Future<VocabSeed> loadSeed() async {
    final raw = await rootBundle.loadString('assets/data/vocab_seed.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return VocabSeed.fromJson(json);
  }
}
