import 'dart:math';

import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';

class VegetableItem {

  VegetableItem(this.assetPath) : keyName = assetPath.split('/').last.split('.').first;
  final String assetPath;
  final String keyName;

  String getLocalizedName(AppLocalizations l10n) {
    return l10n.getVegetableName(keyName);
  }
}

class VegetablesGameEngine {
  final _random = Random();
  List<VegetableItem> _allVegetables = [];
  List<VegetableItem> _unusedVegetables = [];
  
  VegetableItem? currentTarget;
  List<VegetableItem> currentOptions = [];
  String currentPrompt = '';

  Future<void> initialize() async {
    final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> assets = assetManifest.listAssets();
    
    final vegetablePaths = assets
        .where((String key) => key.startsWith('assets/gen/images/vegetables/'))
        .where((String key) => key.endsWith('.png'))
        .toList();
        
    _allVegetables = vegetablePaths.map((path) => VegetableItem(path)).toList();
    _unusedVegetables = List.from(_allVegetables)..shuffle(_random);
  }

  bool get isComplete => _unusedVegetables.isEmpty;
  
  int get totalQuestions => _allVegetables.length;
  int get currentProgress => _allVegetables.length - _unusedVegetables.length;

  bool nextQuestion() {
    if (isComplete) return false;
    
    currentTarget = _unusedVegetables.removeLast();
    
    final distractors = _allVegetables.where((v) => v.assetPath != currentTarget!.assetPath).toList()..shuffle(_random);
    currentOptions = [currentTarget!, distractors[0], distractors[1]]..shuffle(_random);
    
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
    _unusedVegetables = List.from(_allVegetables)..shuffle(_random);
    currentTarget = null;
    currentOptions = [];
    currentPrompt = '';
  }
}
