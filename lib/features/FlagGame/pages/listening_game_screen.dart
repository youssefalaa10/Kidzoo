import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kidzo/core/helpers/media_query.dart';
import 'package:kidzo/core/helpers/tts_helper.dart';
import 'package:kidzo/core/helpers/tts_service.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/mixins/background_music_mixin.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';

import '../data/flag_data_manager.dart';
import '../models/country_model.dart';

class ListeningGameScreen extends StatefulWidget {
  const ListeningGameScreen({super.key});

  @override
  State<ListeningGameScreen> createState() => _ListeningGameScreenState();
}

class _ListeningGameScreenState extends State<ListeningGameScreen>
    with TTSMusicMixin {
  late TtsHelper _ttsHelper;
  late ConfettiController _confettiController;

  Country? _targetCountry;
  List<Country> _options = [];
  bool? _isCorrect;
  String? _selectedCountryCode;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final lang = Localizations.localeOf(context).languageCode;
        if (lang == 'ar') {
          TtsService.checkAndRequestArabicVoice(context);
        }
        _generateQuestion();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    _ttsHelper = TtsHelper(
      musicCubit: context.read<MusicCubit>(),
      languageCode: languageCode,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    setState(() {
      _isCorrect = null;
      _selectedCountryCode = null;
      final countries = FlagDataManager.getRandomCountries(4);
      if (countries.isEmpty) {
        // If still loading or empty, try again in a bit
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _generateQuestion();
        });
        return;
      }
      _options = countries;
      _targetCountry = countries[Random().nextInt(countries.length)];
    });
    _playPrompt();
  }

  void _playPrompt() {
    if (_targetCountry == null) return;
    _ttsHelper.speak(AppLocalizations.of(context)
        .findTheFlagOf(_targetCountry!.localizedName(context)));
  }

  void _checkAnswer(Country selected) {
    if (_isCorrect != null) return;

    setState(() {
      _selectedCountryCode = selected.code;
    });

    if (selected.code == _targetCountry!.code) {
      setState(() {
        _isCorrect = true;
        _score += 10;
      });
      _confettiController.play();
      _ttsHelper.speak(AppLocalizations.of(context)
          .correctYouFound(_targetCountry!.localizedName(context)));

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _generateQuestion();
      });
    } else {
      setState(() {
        _isCorrect = false;
      });
      _ttsHelper.speak(AppLocalizations.of(context).thatsNotItListenAgain);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isCorrect = null;
            _selectedCountryCode = null;
          });
          _playPrompt();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = CustomMQ(context);
    final l10n = AppLocalizations.of(context);

    if (_targetCountry == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        title: Text(l10n.listeningGame),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${l10n.score}: $_score',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple),
                ),
                SizedBox(height: mq.height(5)),
                GestureDetector(
                  onTap: _playPrompt,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(Icons.volume_up,
                        size: 80, color: Colors.purple),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 1000.ms,
                        curve: Curves.easeInOut)
                    .then()
                    .scale(
                        begin: const Offset(1.1, 1.1),
                        end: const Offset(1, 1),
                        duration: 1000.ms,
                        curve: Curves.easeInOut),
                SizedBox(height: mq.height(3)),
                Text(
                  l10n.tapSpeakerToHearAgain,
                  style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey),
                ),
                SizedBox(height: mq.height(5)),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final country = _options[index];
                    return GestureDetector(
                      onTap: () => _checkAnswer(country),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: _selectedCountryCode == country.code
                                ? (_isCorrect == true
                                    ? Colors.green
                                    : Colors.red)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SvgPicture.asset(
                            country.flagAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ).animate().scale(delay: (index * 100).ms),
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}
