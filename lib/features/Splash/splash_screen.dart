import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Profile/profile_cubit.dart';
import '../Profile/profile_state.dart';
import '../Profile/profile_setup_screen.dart';
import '../home/UI/character.dart';
import '../Alphabets/bloc/alphabet_bloc.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/shared/style/image_manager.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
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
        child: Center(
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
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).splashTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context).splashSubtitle,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
