import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._localizedValues);
  final Locale locale;
  final Map<String, String> _localizedValues;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('ar', ''),
  ];

  // DrawLab translations
  String get drawLab => _localizedValues['drawLab']!;
  String get navigationNotAllowed => _localizedValues['navigationNotAllowed']!;
  String get gamesOnlyThroughLevelMap =>
      _localizedValues['gamesOnlyThroughLevelMap']!;
  String get goBack => _localizedValues['goBack']!;
  String get toolSettings => _localizedValues['toolSettings']!;
  String get failedToShare => _localizedValues['failedToShare']!;
  String get brushSettings => _localizedValues['brushSettings']!;
  String get brushType => _localizedValues['brushType']!;
  String get brushShape => _localizedValues['brushShape']!;
  String get strokeWidth => _localizedValues['strokeWidth']!;
  String get opacity => _localizedValues['opacity']!;
  String get colorPicker => _localizedValues['colorPicker']!;
  String get currentColor => _localizedValues['currentColor']!;
  String get customColor => _localizedValues['customColor']!;
  String get pickColor => _localizedValues['pickColor']!;
  String get tools => _localizedValues['tools']!;
  String get gallery => _localizedValues['gallery']!;
  String get drawingTools => _localizedValues['drawingTools']!;
  String get shapes => _localizedValues['shapes']!;
  String get grid => _localizedValues['grid']!;
  String get showGrid => _localizedValues['showGrid']!;
  String get snapToGrid => _localizedValues['snapToGrid']!;
  String get undo => _localizedValues['undo']!;
  String get redo => _localizedValues['redo']!;
  String get clearCanvas => _localizedValues['clearCanvas']!;
  String get saveDrawing => _localizedValues['saveDrawing']!;
  String get exportImage => _localizedValues['exportImage']!;
  String get saveToGallery => _localizedValues['saveToGallery']!;
  String get openGallery => _localizedValues['openGallery']!;
  String get enterDrawingName => _localizedValues['enterDrawingName']!;
  String get cancel => _localizedValues['cancel']!;
  String get save => _localizedValues['save']!;
  String get clear => _localizedValues['clear']!;
  String get clearCanvasConfirm => _localizedValues['clearCanvasConfirm']!;
  String get drawingSaved => _localizedValues['drawingSaved']!;
  String get drawingExported => _localizedValues['drawingExported']!;
  String get failedToSave => _localizedValues['failedToSave']!;
  String get failedToExport => _localizedValues['failedToExport']!;
  String get myDrawings => _localizedValues['myDrawings']!;
  String get noDrawingsYet => _localizedValues['noDrawingsYet']!;
  String get startCreating => _localizedValues['startCreating']!;
  String get startDrawing => _localizedValues['startDrawing']!;
  String get renameDrawing => _localizedValues['renameDrawing']!;
  String get enterNewName => _localizedValues['enterNewName']!;
  String get rename => _localizedValues['rename']!;
  String get share => _localizedValues['share']!;
  String get delete => _localizedValues['delete']!;
  String get deleteDrawing => _localizedValues['deleteDrawing']!;
  String get deleteConfirm => _localizedValues['deleteConfirm']!;
  String get drawingDeleted => _localizedValues['drawingDeleted']!;
  String get drawingRenamed => _localizedValues['drawingRenamed']!;
  String get failedToDelete => _localizedValues['failedToDelete']!;
  String get failedToRename => _localizedValues['failedToRename']!;
  String get addText => _localizedValues['addText']!;
  String get enterText => _localizedValues['enterText']!;
  String get ticTacToe => _localizedValues['ticTacToe']!;
  String get dotsAndBoxes => _localizedValues['dotsAndBoxes']!;
  String get add => _localizedValues['add']!;
  String get today => _localizedValues['today']!;
  String get yesterday => _localizedValues['yesterday']!;
  String get daysAgo => _localizedValues['daysAgo']!;
  String get hideGrid => _localizedValues['hideGrid']!;
  String get showGridTooltip => _localizedValues['showGridTooltip']!;
  String get undoTooltip => _localizedValues['undoTooltip']!;
  String get redoTooltip => _localizedValues['redoTooltip']!;
  String get clearCanvasTooltip => _localizedValues['clearCanvasTooltip']!;
  String get renameTooltip => _localizedValues['renameTooltip']!;
  String get shareTooltip => _localizedValues['shareTooltip']!;
  String get deleteTooltip => _localizedValues['deleteTooltip']!;

  // Brush types
  String get pen => _localizedValues['pen']!;
  String get marker => _localizedValues['marker']!;
  String get pencil => _localizedValues['pencil']!;
  String get eraser => _localizedValues['eraser']!;
  String get highlighter => _localizedValues['highlighter']!;

  // Brush shapes
  String get round => _localizedValues['round']!;
  String get square => _localizedValues['square']!;
  String get calligraphy => _localizedValues['calligraphy']!;

  // Shape types
  String get line => _localizedValues['line']!;
  String get rectangle => _localizedValues['rectangle']!;
  String get circle => _localizedValues['circle']!;
  String get triangle => _localizedValues['triangle']!;
  String get arrow => _localizedValues['arrow']!;

  // Color picker
  String get defaultColors => _localizedValues['defaultColors']!;
  String get pastelColors => _localizedValues['pastelColors']!;
  String get vibrantColors => _localizedValues['vibrantColors']!;
  String get pickAColor => _localizedValues['pickAColor']!;
  String get select => _localizedValues['select']!;
  String get hue => _localizedValues['hue']!;
  String get saturation => _localizedValues['saturation']!;
  String get value => _localizedValues['value']!;
  String get alpha => _localizedValues['alpha']!;
  String get hex => _localizedValues['hex']!;

  // Language settings
  String get languageSettings => _localizedValues['languageSettings']!;
  String get switchToArabic => _localizedValues['switchToArabic']!;
  String get switchToEnglish => _localizedValues['switchToEnglish']!;
  String get english => _localizedValues['english']!;
  String get arabic => _localizedValues['arabic']!;

  // Alphabet examples
  String get axe => _localizedValues['axe']!;
  String get ball => _localizedValues['ball']!;
  String get cold => _localizedValues['cold']!;
  String get dice => _localizedValues['dice']!;
  String get egg => _localizedValues['egg']!;
  String get fish => _localizedValues['fish']!;
  String get glasses => _localizedValues['glasses']!;
  String get hat => _localizedValues['hat']!;
  String get iceCream => _localizedValues['iceCream']!;
  String get juice => _localizedValues['juice']!;
  String get knife => _localizedValues['knife']!;
  String get lightExample => _localizedValues['lightExample']!;
  String get musicExample => _localizedValues['musicExample']!;
  String get nut => _localizedValues['nut']!;
  String get owl => _localizedValues['owl']!;
  String get queen => _localizedValues['queen']!;
  String get ruler => _localizedValues['ruler']!;
  String get tree => _localizedValues['tree']!;
  String get umbrella => _localizedValues['umbrella']!;
  String get van => _localizedValues['van']!;
  String get watch => _localizedValues['watch']!;
  String get xRay => _localizedValues['xRay']!;
  String get zoom => _localizedValues['zoom']!;

  // Numbers
  String get one => _localizedValues['one']!;
  String get two => _localizedValues['two']!;
  String get three => _localizedValues['three']!;
  String get four => _localizedValues['four']!;
  String get five => _localizedValues['five']!;
  String get six => _localizedValues['six']!;
  String get seven => _localizedValues['seven']!;
  String get eight => _localizedValues['eight']!;
  String get nine => _localizedValues['nine']!;
  String get ten => _localizedValues['ten']!;

  // Home Screen
  String get improveYourSkills => _localizedValues['improveYourSkills']!;
  String get games => _localizedValues['games']!;
  String get education => _localizedValues['education']!;
  String get challenge => _localizedValues['challenge']!;
  String get enjoyAndHaveFun => _localizedValues['enjoyAndHaveFun']!;
  String get learnNewThings => _localizedValues['learnNewThings']!;
  String get challengeYourself => _localizedValues['challengeYourself']!;
  String get play => _localizedValues['play']!;
  String get learn => _localizedValues['learn']!;
  String get compete => _localizedValues['compete']!;

  // Color Memory Game
  String get colorMemory => _localizedValues['colorMemory']!;
  String get getReady => _localizedValues['getReady']!;
  String get watchCarefully => _localizedValues['watchCarefully']!;
  String get yourTurn => _localizedValues['yourTurn']!;
  String get checking => _localizedValues['checking']!;
  String get perfect => _localizedValues['perfect']!;
  String get gameOver => _localizedValues['gameOver']!;
  String get levelComplete => _localizedValues['levelComplete']!;
  String get tapped => _localizedValues['tapped']!;
  String get left => _localizedValues['left']!;
  String get time => _localizedValues['time']!;
  String get showing => _localizedValues['showing']!;
  String get score => _localizedValues['score']!;
  String get sequence => _localizedValues['sequence']!;
  String get newBestScore => _localizedValues['newBestScore']!;
  String get youCompletedRound => _localizedValues['youCompletedRound']!;
  String get youReachedRound => _localizedValues['youReachedRound']!;
  String get memoryGame => _localizedValues['memoryGame']!;
  String get pairs => _localizedValues['pairs']!;
  String get bestScore => _localizedValues['bestScore']!;
  String get roundText => _localizedValues['round']!;
  String get longestSequence => _localizedValues['longestSequence']!;
  String get restart => _localizedValues['restart']!;
  String get continueText => _localizedValues['continueButton']!;
  String get exit => _localizedValues['exit']!;

  // Math Game
  String get mathMagic => _localizedValues['mathMagic']!;
  String get superDuper => _localizedValues['superDuper']!;
  String get mathWizard => _localizedValues['mathWizard']!;
  String get youEarned => _localizedValues['youEarned']!;
  String get stars => _localizedValues['stars']!;
  String get playAgain => _localizedValues['playAgain']!;
  String get continueToNextLevel => _localizedValues['continueToNextLevel']!;
  String get oopsieTryAgain => _localizedValues['oopsieTryAgain']!;

  // Tic Tac Toe
  String get epicTicTacToe => _localizedValues['epicTicTacToe']!;
  String get playerXTurn => _localizedValues['playerXTurn']!;
  String get playerOTurn => _localizedValues['playerOTurn']!;
  String get yourTurnTicTacToe => _localizedValues['yourTurn']!;
  String get aiThinking => _localizedValues['aiThinking']!;
  String get youWin => _localizedValues['youWin']!;
  String get aiWins => _localizedValues['aiWins']!;
  String get playerXWins => _localizedValues['playerXWins']!;
  String get playerOWins => _localizedValues['playerOWins']!;
  String get itsADraw => _localizedValues['itsADraw']!;
  String get newGame => _localizedValues['newGame']!;
  String get vsPlayer => _localizedValues['vsPlayer']!;
  String get vsAI => _localizedValues['vsAI']!;
  String get playerX => _localizedValues['playerX']!;
  String get playerO => _localizedValues['playerO']!;
  String get you => _localizedValues['you']!;
  String get ai => _localizedValues['ai']!;
  String get draws => _localizedValues['draws']!;

  // Dots & Boxes
  String get chooseGameMode => _localizedValues['chooseGameMode']!;
  String get whoWouldYouLikeToPlayAgainst =>
      _localizedValues['whoWouldYouLikeToPlayAgainst']!;
  String get playVsAI => _localizedValues['playVsAI']!;
  String get challengeTheComputer => _localizedValues['challengeTheComputer']!;
  String get playVsFriend => _localizedValues['playVsFriend']!;
  String get playWithAFriend => _localizedValues['playWithAFriend']!;
  String get selectAIDifficulty => _localizedValues['selectAIDifficulty']!;
  String get easy => _localizedValues['easy']!;

  String get hard => _localizedValues['hard']!;
  String get gridSize => _localizedValues['gridSize']!;
  String get gameMode => _localizedValues['gameMode']!;
  String get aiDifficulty => _localizedValues['aiDifficulty']!;
  String get howToPlay => _localizedValues['howToPlay']!;
  String get turn => _localizedValues['turn']!;
  String get combo => _localizedValues['combo']!;
  String get moves => _localizedValues['moves']!;
  String get best => _localizedValues['best']!;
  String get startNewGame => _localizedValues['startNewGame']!;
  String get currentGameProgressWillBeLost =>
      _localizedValues['currentGameProgressWillBeLost']!;
  String get selectGridSize => _localizedValues['selectGridSize']!;
  String get selectGameMode => _localizedValues['selectGameMode']!;
  String get gotIt => _localizedValues['gotIt']!;
  String get playersTakeTurns => _localizedValues['playersTakeTurns']!;
  String get whenYouComplete => _localizedValues['whenYouComplete']!;
  String get gameEndsWhen => _localizedValues['gameEndsWhen']!;
  String get playerWithMostBoxes => _localizedValues['playerWithMostBoxes']!;
  String get tipAvoidGiving => _localizedValues['tipAvoidGiving']!;
  String get easyDescription => _localizedValues['easyDescription']!;
  String get mediumDescription => _localizedValues['mediumDescription']!;
  String get hardDescription => _localizedValues['hardDescription']!;

  // Settings Screen
  String get settings => _localizedValues['settings']!;
  String get funSettings => _localizedValues['funSettings']!;
  String get language => _localizedValues['language']!;
  String get sound => _localizedValues['sound']!;
  String get music => _localizedValues['music']!;
  String get notifications => _localizedValues['notifications']!;
  String get theme => _localizedValues['theme']!;
  String get brightness => _localizedValues['brightness']!;
  String get volume => _localizedValues['volume']!;
  String get on => _localizedValues['on']!;
  String get off => _localizedValues['off']!;
  String get auto => _localizedValues['auto']!;
  String get light => _localizedValues['light']!;
  String get dark => _localizedValues['dark']!;
  String get system => _localizedValues['system']!;
  String get high => _localizedValues['high']!;
  String get low => _localizedValues['low']!;
  String get medium => _localizedValues['medium']!;
  String get enableSound => _localizedValues['enableSound']!;
  String get enableMusic => _localizedValues['enableMusic']!;
  String get enableNotifications => _localizedValues['enableNotifications']!;
  String get selectTheme => _localizedValues['selectTheme']!;
  String get selectBrightness => _localizedValues['selectBrightness']!;
  String get adjustVolume => _localizedValues['adjustVolume']!;
  String get languageDescription => _localizedValues['languageDescription']!;
  String get soundDescription => _localizedValues['soundDescription']!;
  String get musicDescription => _localizedValues['musicDescription']!;
  String get notificationsDescription =>
      _localizedValues['notificationsDescription']!;
  String get themeDescription => _localizedValues['themeDescription']!;
  String get brightnessDescription =>
      _localizedValues['brightnessDescription']!;
  String get volumeDescription => _localizedValues['volumeDescription']!;
  String get backToHome => _localizedValues['backToHome']!;
  String get saveSettings => _localizedValues['saveSettings']!;
  String get resetSettings => _localizedValues['resetSettings']!;
  String get settingsSaved => _localizedValues['settingsSaved']!;
  String get settingsReset => _localizedValues['settingsReset']!;

  // Missing Letter Game translations
  String get missingLetter => _localizedValues['missingLetter']!;
  String get learnTheAlphabet => _localizedValues['learnTheAlphabet']!;
  String get yourProgress => _localizedValues['yourProgress']!;
  String get completed => _localizedValues['completed']!;
  String get currentScore => _localizedValues['currentScore']!;
  String get yourScore => _localizedValues['yourScore']!;
  String get continueGame => _localizedValues['continueGame']!;
  String get correct => _localizedValues['correct']!;
  String get tryAgain => _localizedValues['tryAgain']!;
  String get nextWord => _localizedValues['nextWord']!;
  String get complete => _localizedValues['complete']!;
  String get congratulations => _localizedValues['congratulations']!;
  String get youCompletedAllWords => _localizedValues['youCompletedAllWords']!;
  String get finalScore => _localizedValues['finalScore']!;
  String get done => _localizedValues['done']!;
  String get pauseGame => _localizedValues['pauseGame']!;
  String get doYouWantToExit => _localizedValues['doYouWantToExit']!;
  String get progress => _localizedValues['progress']!;
  String get yourProgressWillBeSaved =>
      _localizedValues['yourProgressWillBeSaved']!;
  String get resume => _localizedValues['resume']!;
  String get exitAndSave => _localizedValues['exitAndSave']!;
  String get changeLanguage => _localizedValues['changeLanguage']!;
  String get translateToArabic => _localizedValues['translateToArabic']!;
  String get translateToEnglish => _localizedValues['translateToEnglish']!;
  String get yes => _localizedValues['yes']!;
  String get no => _localizedValues['no']!;

  // ColorLearn Game translations
  String get colorLearn => _localizedValues['colorLearn']!;
  String get colorSwitch => _localizedValues['colorSwitch']!;

  // Animal Name Game translations
  String get animalNameGame => _localizedValues['animalNameGame']!;
  String get flagGame => _localizedValues['flagGame']!;

  // Level Map and Games translations
  String get readyToPlay => _localizedValues['readyToPlay']!;
  String get funGames => _localizedValues['funGames']!;
  String get flappyBird => _localizedValues['flappyBird']!;
  String get game2048 => _localizedValues['game2048']!;

  String currentLevelLabel(int level) => _localizedValues['currentLevelLabel']!
      .replaceAll('{level}', level.toString());
  String levelLabel(int level) =>
      _localizedValues['levelLabel']!.replaceAll('{level}', level.toString());
  String difficultyLevel(int level) => _localizedValues['difficultyLevel']!
      .replaceAll('{level}', level.toString());
  String get gameTypesLabel => _localizedValues['gameTypesLabel']!;
  String get memoryGameCongrats => _localizedValues['memoryGameCongrats']!;
  String get memoryGameTimeResult => _localizedValues['memoryGameTimeResult']!;
  String totalMovesLabel(int moves) => _localizedValues['totalMovesLabel']!
      .replaceAll('{moves}', moves.toString());
  String pairsLabel(int current, int total) => _localizedValues['pairsLabel']!
      .replaceAll('{current}', current.toString())
      .replaceAll('{total}', total.toString());
  String lockedLevelMessage(int level) =>
      _localizedValues['lockedLevelMessage']!
          .replaceAll('{level}', level.toString());

  // Learning Activities translations
  String get numbers => _localizedValues['numbers']!;
  String get alphabet => _localizedValues['alphabet']!;
  String get learningActivities => _localizedValues['learningActivities']!;

  // Maze Game translations
  String get mazeGame => _localizedValues['mazeGame']!;
  String get startPlaying => _localizedValues['startPlaying']!;
  String get difficulty => _localizedValues['difficulty']!;
  String get reason => _localizedValues['reason']!;
  String get touchedWall => _localizedValues['touchedWall']!;
  String get timeUp => _localizedValues['timeUp']!;
  String get mazeInstruction1 => _localizedValues['mazeInstruction1']!;
  String get mazeInstruction2 => _localizedValues['mazeInstruction2']!;
  String get mazeInstruction3 => _localizedValues['mazeInstruction3']!;
  String mazeInstruction4(int count) => _localizedValues['mazeInstruction4']!
      .replaceAll('{count}', count.toString());
  String get mazeInstruction5 => _localizedValues['mazeInstruction5']!;
  String get mazeGameOver => _localizedValues['mazeGameOver']!;
  String get mazeCongratulations => _localizedValues['mazeCongratulations']!;
  String get mazeYouWon => _localizedValues['mazeYouWon']!;
  String get mazeTryAgain => _localizedValues['mazeTryAgain']!;

  // Paddle Bounce Game translations
  String get paddleBounce => _localizedValues['paddleBounce']!;
  String get player1 => _localizedValues['player1']!;
  String get player2 => _localizedValues['player2']!;
  String get player1Wins => _localizedValues['player1Wins']!;
  String get player2Wins => _localizedValues['player2Wins']!;
  String get pause => _localizedValues['pause']!;
  String get mainMenu => _localizedValues['mainMenu']!;
  String get tapToStart => _localizedValues['tapToStart']!;
  String get selectALetter => _localizedValues['selectALetter']!;
  String get selectANumber => _localizedValues['selectANumber']!;
  String get guessTheFlag => _localizedValues['guessTheFlag']!;
  String get tapToLearnFlags => _localizedValues['tapToLearnFlags']!;
  String get listeningGame => _localizedValues['listeningGame']!;
  String get learnCountryFlags => _localizedValues['learnCountryFlags']!;
  String get matchFlagSubtitle => _localizedValues['matchFlagSubtitle']!;
  String get exploreFlagsSubtitle => _localizedValues['exploreFlagsSubtitle']!;
  String get listeningGameSubtitle =>
      _localizedValues['listeningGameSubtitle']!;
  String whichFlagIs(String country) =>
      _localizedValues['whichFlagIs']!.replaceAll('{country}', country);
  String greatJobThats(String country) =>
      _localizedValues['greatJobThats']!.replaceAll('{country}', country);
  String findTheFlagOf(String country) =>
      _localizedValues['findTheFlagOf']!.replaceAll('{country}', country);
  String correctYouFound(String country) =>
      _localizedValues['correctYouFound']!.replaceAll('{country}', country);
  String get thatsNotItListenAgain =>
      _localizedValues['thatsNotItListenAgain']!;
  String get tapSpeakerToHearAgain =>
      _localizedValues['tapSpeakerToHearAgain']!;
  String get searchCountries => _localizedValues['searchCountries']!;
  String get continent => _localizedValues['continent']!;
  String get capital => _localizedValues['capital']!;
  String get close => _localizedValues['close']!;
  String get newMaze => _localizedValues['newMaze']!;
  String get exitGame => _localizedValues['exitGame']!;
  String get exitGameConfirm => _localizedValues['exitGameConfirm']!;
  String get reachedEnd => _localizedValues['reachedEnd']!;
  String get keepDragging => _localizedValues['keepDragging']!;
  String get statistics => _localizedValues['statistics']!;
  String get gamesPlayedLabel => _localizedValues['gamesPlayedLabel']!;
  String get totalPlayTime => _localizedValues['totalPlayTime']!;
  String get viewHistory => _localizedValues['viewHistory']!;
  String get history => _localizedValues['history']!;
  String get noHistory => _localizedValues['noHistory']!;
  String get enableSoundToggle => _localizedValues['enableSoundToggle']!;
  String get enableMusicToggle => _localizedValues['enableMusicToggle']!;
  String get soundSettings => _localizedValues['soundSettings']!;
  String get wins => _localizedValues['wins']!;

  // Added getters
  String get hello => _localizedValues['hello']!;
  String get animalNames => _localizedValues['animalNames']!;
  String get cat => _localizedValues['cat']!;
  String get dog => _localizedValues['dog']!;
  String get cow => _localizedValues['cow']!;
  String get hen => _localizedValues['hen']!;
  String get bird => _localizedValues['bird']!;
  String get lion => _localizedValues['lion']!;
  String get sheep => _localizedValues['sheep']!;
  String get horse => _localizedValues['horse']!;
  String get elephant => _localizedValues['elephant']!;
  String get giraffe => _localizedValues['giraffe']!;
  String get panda => _localizedValues['panda']!;
  String welcomeToAnimalQuiz(int level) =>
      _localizedValues['welcomeToAnimalQuiz']!
          .replaceAll('{level}', level.toString());
  String get excellent => _localizedValues['excellent']!;
  String get greatJob => _localizedValues['greatJob']!;
  String get youMatchedAllAnimals => _localizedValues['youMatchedAllAnimals']!;
  String get tapToPlayKeepTapping => _localizedValues['tapToPlayKeepTapping']!;
  String yourFinalScore(int score) => _localizedValues['yourFinalScore']!
      .replaceAll('{score}', score.toString());
  String get selectAnImage => _localizedValues['selectAnImage']!;
  String get puzzleFrame => _localizedValues['puzzleFrame']!;
  String get noImageAvailable => _localizedValues['noImageAvailable']!;
  String get scoreLabel => _localizedValues['scoreLabel']!;
  String get bestLabel => _localizedValues['bestLabel']!;
  String get maxTile => _localizedValues['maxTile']!;
  String get continuePlaying => _localizedValues['continuePlaying']!;
  String youWinReached(int maxTile) => _localizedValues['youWinReached']!
      .replaceAll('{maxTile}', maxTile.toString());
  String get noMoreMoves => _localizedValues['noMoreMoves']!;
  String get red => _localizedValues['red']!;
  String get green => _localizedValues['green']!;
  String get blue => _localizedValues['blue']!;
  String get yellow => _localizedValues['yellow']!;
  String get cyan => _localizedValues['cyan']!;
  String get purple => _localizedValues['purple']!;
  String get orange => _localizedValues['orange']!;
  String get pink => _localizedValues['pink']!;
  String get goal2048 => _localizedValues['goal2048']!;
  String levelText(int level) =>
      _localizedValues['levelText']!.replaceAll('{level}', level.toString());
  String get oopsTryAgain => _localizedValues['oopsTryAgain']!;
  String get tryAgainToGetBetterScore =>
      _localizedValues['tryAgainToGetBetterScore']!;
  String get pentagon => _localizedValues['pentagon']!;
  String get heart => _localizedValues['heart']!;
  String get diamond => _localizedValues['diamond']!;
  String get star => _localizedValues['star']!;
  String get hexagon => _localizedValues['hexagon']!;
  String get cylinder => _localizedValues['cylinder']!;
  String get straightLineModeEnabled =>
      _localizedValues['straightLineModeEnabled']!;
  String get freehandModeEnabled => _localizedValues['freehandModeEnabled']!;
  String get gameComplete => _localizedValues['gameComplete']!;
  String get saveDrawingConfirm => _localizedValues['saveDrawingConfirm']!;
  String get exitWithoutSaving => _localizedValues['exitWithoutSaving']!;
  String get saveAndExit => _localizedValues['saveAndExit']!;
  String get quickActions => _localizedValues['quickActions']!;
  String get brush => _localizedValues['brush']!;
  String get chooseColor => _localizedValues['chooseColor']!;
  String get selectTool => _localizedValues['selectTool']!;
  String get selectShape => _localizedValues['selectShape']!;
  String get size => _localizedValues['size']!;
  String get filled => _localizedValues['filled']!;
  String get ok => _localizedValues['ok']!;
  String get penOptions => _localizedValues['penOptions']!;
  String get straightLineMode => _localizedValues['straightLineMode']!;
  String get straightLineModeDesc => _localizedValues['straightLineModeDesc']!;
  String get enterYourText => _localizedValues['enterYourText']!;
  String get textAdded => _localizedValues['textAdded']!;
  String get editText => _localizedValues['editText']!;
  String get shape => _localizedValues['shape']!;
  String get text => _localizedValues['text']!;
  String get galleryAccessDenied => _localizedValues['galleryAccessDenied']!;
  
  // Vehicles Game
  String get whichVehicleFliesInSky => _localizedValues['which_vehicle_flies_in_sky']!;
  String get whichVehicleTravelsOnRailway => _localizedValues['which_vehicle_travels_on_railway']!;
  String get whichVehicleDrivesOnRoad => _localizedValues['which_vehicle_drives_on_road']!;
  String get whichVehicleTravelsOnWater => _localizedValues['which_vehicle_travels_on_water']!;
  String get airplane => _localizedValues['airplane']!;
  String get car => _localizedValues['car']!;
  String get train => _localizedValues['train']!;
  String get boat => _localizedValues['boat']!;
  String get helicopter => _localizedValues['helicopter']!;
  String get motorcycle => _localizedValues['motorcycle']!;
  String get truck => _localizedValues['truck']!;
  String get bus => _localizedValues['bus']!;
  String get bicycle => _localizedValues['bicycle']!;
  String get submarine => _localizedValues['submarine']!;
  String get ship => _localizedValues['ship']!;

  String get vehicles => _localizedValues['vehicles']!;
  String get fruits => _localizedValues['fruits']!;
  String get vegetables => _localizedValues['vegetables']!;
  String get splashTitle => _localizedValues['splashTitle']!;
  String get splashSubtitle => _localizedValues['splashSubtitle']!;
  String get backgroundMusicTitle => _localizedValues['backgroundMusicTitle']!;
  String get backgroundMusicDesc => _localizedValues['backgroundMusicDesc']!;
  String get track1 => _localizedValues['track1']!;
  String get track2 => _localizedValues['track2']!;

  // Feed The Animal
  String get apple => _localizedValues['apple']!;
  String get banana => _localizedValues['banana']!;
  String get orangeFruit => _localizedValues['orange_fruit']!; // 'orange' is already used for color
  String get grapes => _localizedValues['grapes']!;
  String get watermelon => _localizedValues['watermelon']!;
  String get mango => _localizedValues['mango']!;
  String get pineapple => _localizedValues['pineapple']!;
  String get cherries => _localizedValues['cherries']!;
  String get monkey => _localizedValues['monkey']!;
  String get rabbit => _localizedValues['rabbit']!;
  
  String promptGiveMeFruit(String fruit) => _localizedValues['prompt_give_me_fruit']!.replaceAll('{fruit}', fruit);
  String promptFindColorFruit(String color) => _localizedValues['prompt_find_color_fruit']!.replaceAll('{color}', color);
  String promptWhichIsCalled(String fruit) => _localizedValues['prompt_which_is_called']!.replaceAll('{fruit}', fruit);
  String yummyFruit(String fruit) => _localizedValues['yummy_fruit']!.replaceAll('{fruit}', fruit);
  String successPhrase1(String fruit) => _localizedValues['success_phrase_1']!.replaceAll('{fruit}', fruit);
  String successPhrase2(String fruit) => _localizedValues['success_phrase_2']!.replaceAll('{fruit}', fruit);
  String successPhrase3(String fruit) => _localizedValues['success_phrase_3']!.replaceAll('{fruit}', fruit);
  String get tryAgainPrompt => _localizedValues['try_again_prompt']!;
  String get feedAnimalTitle => _localizedValues['feed_animal_title']!;

  // Fruit & Vegetable Sorter
  String get fruitVegSorterTitle => _localizedValues['fruitVegSorterTitle']!;
  String get cabbage => _localizedValues['cabbage']!;
  String get carrot => _localizedValues['carrot']!;
  String get cucumber => _localizedValues['cucumber']!;
  String get eggplant => _localizedValues['eggplant']!;
  String get onion => _localizedValues['onion']!;
  String get potato => _localizedValues['potato']!;
  String get redPepper => _localizedValues['redPepper']!;
  String get tomato => _localizedValues['tomato']!;
  String get fruitsBasket => _localizedValues['fruitsBasket']!;
  String get vegetablesBasket => _localizedValues['vegetablesBasket']!;
  String putItemInBasket(String item, String basket) => _localizedValues['putItemInBasket']!.replaceAll('{item}', item).replaceAll('{basket}', basket);
  String get sorterGreatJob => _localizedValues['sorterGreatJob']!;
  String get sorterExcellent => _localizedValues['sorterExcellent']!;
  String get sorterFantastic => _localizedValues['sorterFantastic']!;
  String get sorterTryAgain => _localizedValues['sorterTryAgain']!;

  String get bamboo => _localizedValues['bamboo']!;
  String get corn => _localizedValues['corn']!;
  String get grass => _localizedValues['grass']!;
  String get meat => _localizedValues['meat']!;
  String get fantastic => _localizedValues['fantastic']!;
  String get wellDone => _localizedValues['wellDone']!;
  String promptFeedAnimal(String animal) => _localizedValues['promptFeedAnimal']!.replaceAll('{animal}', animal);
  String promptWhatDoesAnimalEat(String animal) => _localizedValues['promptWhatDoesAnimalEat']!.replaceAll('{animal}', animal);

  String getCountryName(String code) {
    return _localizedValues[code.toLowerCase()] ?? code;
  }

  String getVegetableName(String key) {
    // try direct key, then lowerCamelCase if there are underscores
    final camelKey = key.replaceAllMapped(RegExp(r'_([a-z])'), (m) => m[1]!.toUpperCase());
    return _localizedValues[camelKey] ?? _localizedValues[key] ?? key;
  }

  String getFruitName(String key) {
    if (key == 'orange') return _localizedValues['orange_fruit'] ?? key;
    final camelKey = key.replaceAllMapped(RegExp(r'_([a-z])'), (m) => m[1]!.toUpperCase());
    return _localizedValues[camelKey] ?? _localizedValues[key] ?? key;
  }

  // Vegetables Drag Game
  String get chiliPepper => _localizedValues['chiliPepper']!;
  String get lemon => _localizedValues['lemon']!;
  String get whatIsThisVegetable => _localizedValues['whatIsThisVegetable']!;

  String get vegetablesGameComplete => _localizedValues['vegetablesGameComplete']!;
  String get backToCategories => _localizedValues['backToCategories']!;

  String get fruitsGameComplete => _localizedValues['fruitsGameComplete']!;

  // Universal Educational Prompts
  List<String> getEducationalPrompts(String itemName) {
    return [
      _localizedValues['vocab_tap_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_touch_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_find_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_can_you_find_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_catch_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_where_is_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_point_to_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_show_me_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_choose_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_lets_find_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_can_you_tap_the']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_touch_picture_of']!.replaceAll('{item}', itemName),
      _localizedValues['vocab_which_one_is_the']!.replaceAll('{item}', itemName),
    ];
  }

  /// Clever, environment-based prompts for the Vehicles game, e.g.
  /// "Which vehicle can fly in the sky?" instead of "Where is the {item}?".
  /// [environment] must be one of: sky, sea, road, railway.
  List<String> getVehicleEnvironmentPrompts(String environment) {
    switch (environment) {
      case 'sky':
        return [
          _localizedValues['vehicle_q_sky_1']!,
          _localizedValues['vehicle_q_sky_2']!,
          _localizedValues['vehicle_q_sky_3']!,
        ];
      case 'sea':
        return [
          _localizedValues['vehicle_q_sea_1']!,
          _localizedValues['vehicle_q_sea_2']!,
          _localizedValues['vehicle_q_sea_3']!,
        ];
      case 'road':
        return [
          _localizedValues['vehicle_q_road_1']!,
          _localizedValues['vehicle_q_road_2']!,
          _localizedValues['vehicle_q_road_3']!,
        ];
      case 'railway':
        return [
          _localizedValues['vehicle_q_railway_1']!,
          _localizedValues['vehicle_q_railway_2']!,
          _localizedValues['vehicle_q_railway_3']!,
        ];
      default:
        return [_localizedValues['vocab_where_is_the']!];
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final String languageCode = locale.languageCode;
    final String assetPath = 'assets/lang/$languageCode.json';

    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final Map<String, String> localizedValues = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      return AppLocalizations(locale, localizedValues);
    } catch (e) {
      // Fallback to English if the language file is not found
      if (languageCode != 'en') {
        return load(const Locale('en', ''));
      }
      rethrow;
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
