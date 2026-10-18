import 'package:flutter/material.dart';
import 'package:kidzo/core/catalog/default_game_catalog.dart';
import 'package:kidzo/core/catalog/game_catalog.dart';
import 'package:kidzo/core/catalog/game_descriptor.dart';
import 'package:kidzo/core/catalog/game_surface.dart';
import 'package:kidzo/core/helpers/media_query.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/shared/style/image_manager.dart';

// Define app categories
enum AppCategory {
  games,
  education,
}

// Reusable options grid, driven by the injected catalog.
class OptionsGrid extends StatelessWidget {
  OptionsGrid({
    required this.mq,
    required this.category,
    GameCatalog? catalog,
    super.key,
  }) : catalog = catalog ?? buildDefaultGameCatalog();

  final CustomMQ mq;
  final AppCategory category;

  /// Injected so tests and Adventure Mode can supply their own without any
  /// global state. Defaults to the catalog the app ships with.
  final GameCatalog catalog;

  GameSurface get _surface {
    switch (category) {
      case AppCategory.games:
        return GameSurface.games;
      case AppCategory.education:
        return GameSurface.education;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<GameDescriptor> descriptors = catalog.forSurface(_surface);
    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: mq.width(4),
        vertical: mq.height(2),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: mq.width(4),
        mainAxisSpacing: mq.height(2),
        childAspectRatio: 3 / 2.5,
      ),
      itemCount: descriptors.length,
      itemBuilder: (context, index) {
        final GameDescriptor descriptor = descriptors[index];
        return OptionCard(
          icon: descriptor.iconAsset,
          title: l10n.resolve(descriptor.titleLocalizationKey),
          screenBuilder: descriptor.screenBuilder,
          flipImage: descriptor.flipImageAsset,
          backIcon: descriptor.backIcon,
          frontIcon: descriptor.frontIcon,
          mq: mq,
        );
      },
    );
  }
}

class OptionCard extends StatefulWidget {
  const OptionCard({
    required this.icon,
    required this.title,
    required this.flipImage,
    required this.screenBuilder,
    required this.mq,
    this.backIcon,
    this.frontIcon,
    super.key,
  });
  final String icon;
  final String title;
  final String flipImage;
  final Widget Function() screenBuilder;
  final CustomMQ mq;
  final IconData? backIcon;
  final IconData? frontIcon;

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_controller.value == 1) {
          _controller.reverse();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => widget.screenBuilder(),
                ),
              );
            }
          });
        } else {
          _controller.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159;
          final isFront = angle < 3.14159 / 2;

          return Transform(
            transform: Matrix4.rotationY(angle),
            alignment: Alignment.center,
            child: isFront
                ? _buildFrontSide()
                : Transform(
                    transform: Matrix4.rotationY(3.14159),
                    alignment: Alignment.center,
                    child: _buildBackSide(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide() {
    final isSpecialIcon = widget.icon == ImageManager.simle ||
        widget.icon == ImageManager.pen ||
        widget.icon == ImageManager.xo ||
        widget.frontIcon != null;

    final iconSize = isSpecialIcon ? widget.mq.width(16) : widget.mq.width(12);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.mq.width(4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(widget.mq.width(2)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.frontIcon != null)
            Flexible(
              child: Icon(
                widget.frontIcon,
                size: iconSize,
                color: const Color(0xFFe2c9b5),
              ),
            )
          else
            Flexible(
              child: Image.asset(
                widget.icon,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
            ),
          SizedBox(height: widget.mq.height(1)),
          Flexible(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: widget.mq.width(3.5),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    final iconSize = widget.mq.width(12);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.mq.width(4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: widget.backIcon != null
          ? Icon(
              widget.backIcon,
              size: iconSize,
              color: const Color(0xFF776E65),
            )
          : Image.asset(
              widget.flipImage,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
    );
  }
}
