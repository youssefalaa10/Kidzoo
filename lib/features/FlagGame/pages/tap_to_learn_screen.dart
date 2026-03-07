import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/core/helpers/tts_helper.dart';
import 'package:kidzoo/core/mixins/background_music_mixin.dart';
import 'package:kidzoo/core/services/cubit/music_cubit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/flag_data_manager.dart';
import '../models/country_model.dart';

class TapToLearnScreen extends StatefulWidget {
  const TapToLearnScreen({super.key});

  @override
  State<TapToLearnScreen> createState() => _TapToLearnScreenState();
}

class _TapToLearnScreenState extends State<TapToLearnScreen>
    with TTSMusicMixin {
  late TtsHelper _ttsHelper;
  List<Country> countries = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _ttsHelper = TtsHelper(musicCubit: context.read<MusicCubit>());
    countries = FlagDataManager.countries;
  }

  void _showCountryDialog(Country country) {
    _ttsHelper.speak(country.name);

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                country.flagAsset,
                width: 200,
                placeholderBuilder: (context) =>
                    const CircularProgressIndicator(),
              ).animate().shake(),
              const SizedBox(height: 20),
              Text(
                country.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Continent: ${country.continent}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text(
                'Capital: ${country.capital}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child:
                    const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCountries = countries
        .where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap to Learn Flags'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search countries...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: filteredCountries.length,
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                return GestureDetector(
                  onTap: () => _showCountryDialog(country),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SvgPicture.asset(
                              country.flagAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            country.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (index % 20).ms * 50).scale(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
