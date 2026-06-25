import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/background_resolver.dart';
import '../../core/shared/style/image_manager.dart';
import '../../core/shared/widgets/fluid_container.dart';
import '../Alphabets/bloc/alphabet_bloc.dart';
import '../Profile/profile_cubit.dart';
import '../Profile/profile_setup_screen.dart';
import '../Profile/profile_state.dart';
import '../home/UI/character.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            if (state.currentProfile == null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (context) => AlphabetBloc(),
                    child: const CharacterSelectionScreen(),
                  ),
                ),
              );
            }
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            image: DecorationImage(
              image: AssetImage(BackgroundResolver(context, BackgroundType.splash).resolveBackground()!),
              fit: BoxFit.cover,
            ),
          ),
          child: FluidContainer(
            maxWidth: 600,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  ImageManager.logo,
                  width: 150,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.pets,
                    size: 150,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  AppLocalizations.of(context).splashTitle,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context).splashSubtitle,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
