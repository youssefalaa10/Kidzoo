import 'dart:math';

import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';

class FruitItem {

  FruitItem(this.assetPath) : keyName = assetPath.split('/').last.split('.').first;
  final String assetPath;
  final String keyName;

  String getLocalizedName(AppLocalizations l10n) {
    return l10n.getFruitName(keyName);
  }
}

class FruitsGameEngine {
  final _random = Random();
  List<FruitItem> _allFruits = [];
  List<FruitItem> _unusedFruits = [];
  
  FruitItem? currentTarget;
  List<FruitItem> currentOptions = [];
  String currentPrompt = '';

  Random get random => _random;

  Future<void> initialize() async {
    final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> assets = assetManifest.listAssets();
    
    final fruitPaths = assets
        .where((String key) => key.startsWith('assets/gen/images/fruits/'))
        .where((String key) => key.endsWith('.png'))
        .toList();
        
    _allFruits = fruitPaths.map((path) => FruitItem(path)).toList();
    _unusedFruits = List.from(_allFruits)..shuffle(_random);
  }

  bool get isComplete => _unusedFruits.isEmpty;
  
  int get totalQuestions => _allFruits.length;
  int get currentProgress => _allFruits.length - _unusedFruits.length;

  bool nextQuestion() {
    if (isComplete) return false;
    
    currentTarget = _unusedFruits.removeLast();
    
    // Choose 3 to 5 distractors to have 4 to 6 fruits on the belt
    final distractorCount = _random.nextInt(3) + 3; // 3, 4, 5 distractors -> 4, 5, 6 total fruits
    final availableDistractors = _allFruits.where((v) => v.assetPath != currentTarget!.assetPath).toList()..shuffle(_random);
    
    currentOptions = [currentTarget!];
    for (int i = 0; i < distractorCount && i < availableDistractors.length; i++) {
      currentOptions.add(availableDistractors[i]);
    }
    
    currentOptions.shuffle(_random);
    
    return true;
  }

  void generatePrompt(AppLocalizations l10n) {
    if (currentTarget == null) return;
    final name = currentTarget!.getLocalizedName(l10n);
    final templates = l10n.getEducationalPrompts(name);
    templates.shuffle(_random);
    currentPrompt = templates.first;
  }

  void reset() {
    _unusedFruits = List.from(_allFruits)..shuffle(_random);
    currentTarget = null;
    currentOptions = [];
    currentPrompt = '';
  }
}
