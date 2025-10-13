import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/crossword_models.dart';

class CrosswordLoader {
  static Future<List<CrosswordPuzzle>> loadAllPuzzles() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/crossword_puzzles.json');
      final List<dynamic> jsonList = jsonDecode(jsonString) as List;

      return jsonList
          .map((json) => CrosswordPuzzle.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load puzzles: $e');
    }
  }

  static Future<CrosswordPuzzle?> loadPuzzleById(String id) async {
    final puzzles = await loadAllPuzzles();
    try {
      return puzzles.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<CrosswordPuzzle>> loadPuzzlesByDifficulty(
      Difficulty difficulty) async {
    final puzzles = await loadAllPuzzles();
    return puzzles.where((p) => p.difficulty == difficulty).toList();
  }
}
