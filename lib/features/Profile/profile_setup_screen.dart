import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/image_manager.dart';

import '../Alphabets/bloc/alphabet_bloc.dart';
import '../home/UI/character.dart';
import 'profile_cubit.dart';
import 'profile_state.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  int _selectedAvatarIndex = 0;

  final List<String> _avatars = ImageManager.kidAvatars;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      context.read<ProfileCubit>().createProfile(name, _selectedAvatarIndex);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pleaseEnterNameError)),
      );
    }
  }

  void _nextAvatar() {
    setState(() {
      _selectedAvatarIndex = (_selectedAvatarIndex + 1) % _avatars.length;
    });
  }

  void _prevAvatar() {
    setState(() {
      _selectedAvatarIndex = (_selectedAvatarIndex - 1 + _avatars.length) % _avatars.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E2), // Warm cream background
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && state.currentProfile != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider(
                  create: (context) => AlphabetBloc(),
                  child: const CharacterSelectionScreen(),
                ),
              ),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // Pinkish-Red curved background
              Positioned.fill(
                child: CustomPaint(
                  painter: CurvePainter(),
                ),
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Everything below scales against the available height so the
                    // layout survives short phones, big text and the keyboard.
                    final availableHeight = constraints.maxHeight;
                    final scale = (availableHeight / 780).clamp(0.65, 1.15);

                    final nameFontSize = (48 * scale).clamp(28.0, 52.0);
                    final subtitleFontSize = (18 * scale).clamp(12.0, 20.0);
                    final captionFontSize = (20 * scale).clamp(14.0, 22.0);
                    final buttonFontSize = (24 * scale).clamp(16.0, 26.0);
                    final buttonHeight = (60 * scale).clamp(46.0, 64.0);
                    final arrowPadding = (12 * scale).clamp(8.0, 14.0);
                    final arrowIconSize = (22 * scale).clamp(16.0, 24.0);
                    final horizontalPadding =
                        (constraints.maxWidth * 0.09).clamp(20.0, 48.0);
                    final avatarHeight =
                        (availableHeight * 0.42).clamp(150.0, 420.0);
                    final topGap = (50 * scale).clamp(16.0, 56.0);

                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: availableHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              SizedBox(height: topGap),

                              // Name TextField
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding),
                                child: TextField(
                                  controller: _nameController,
                                  textAlign: TextAlign.center,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _saveProfile(),
                                  style: TextStyle(
                                    fontSize: nameFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    shadows: const [
                                      Shadow(
                                        offset: Offset(2, 2),
                                        blurRadius: 4.0,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                  decoration: InputDecoration(
                                    hintText: l10n.nameFieldHint,
                                    hintStyle: TextStyle(
                                      color: Colors.white54,
                                      fontSize: nameFontSize,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding),
                                child: Text(
                                  l10n.theSmartKid,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Avatar Carousel
                              SizedBox(
                                height: avatarHeight,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Previous
                                    _CarouselArrow(
                                      icon: Icons.arrow_back_ios_new_rounded,
                                      onTap: _prevAvatar,
                                      padding: arrowPadding,
                                      iconSize: arrowIconSize,
                                    ),

                                    // Avatar Image
                                    Expanded(
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        transitionBuilder: (Widget child,
                                            Animation<double> animation) {
                                          return ScaleTransition(
                                            scale: Tween<double>(
                                                    begin: 0.8, end: 1.0)
                                                .animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOutBack,
                                              ),
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: Image.asset(
                                          _avatars[_selectedAvatarIndex],
                                          key: ValueKey<int>(
                                              _selectedAvatarIndex),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),

                                    // Next
                                    _CarouselArrow(
                                      icon: Icons.arrow_forward_ios_rounded,
                                      onTap: _nextAvatar,
                                      padding: arrowPadding,
                                      iconSize: arrowIconSize,
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding),
                                child: Text(
                                  l10n.chooseYourAvatarCaps,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: captionFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF5A4C78),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),

                              SizedBox(height: 16 * scale),

                              // Save Button
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  0,
                                  horizontalPadding,
                                  16 * scale,
                                ),
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF4AC49A), // Kid-friendly green
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    minimumSize:
                                        Size(double.infinity, buttonHeight),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      l10n.letsPlay,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.icon,
    required this.onTap,
    required this.padding,
    required this.iconSize,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Icon(icon, color: Colors.black87, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEE4964) // Match screenshot red/pink
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.5);
    path.quadraticBezierTo(
        size.width / 2, size.height * 0.75, size.width, size.height * 0.5);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
