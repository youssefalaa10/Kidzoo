import 'package:flutter/material.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  int _selectedIndex = 1; // Default selected card (middle one)

  // Define our character categories
  final List<CharacterCategory> _categories = [
    CharacterCategory(
      name: "Games",
      characterName: "Games",
      characterDesc: "Wise mentor teaching valuable lessons across disciplines",
      color: Colors.blue.shade100,
      coins: 980,
    ),
    CharacterCategory(
      name: "Education",
      characterName: "Education",
      characterDesc:
          "Enigmatic explorer guiding metaverse adventures through endless digital dimensions",
      color: Colors.orange.shade300,
      coins: 1240,
    ),
    CharacterCategory(
      name: "Challenge",
      characterName: "Challenge",
      characterDesc:
          "Mysterious problem-solver who creates mind-bending challenges",
      color: Colors.purple.shade100,
      coins: 1500,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff1646cc),
      body: SafeArea(
        child: Stack(
          children: [
            // Top header section
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(),
            ),

            // Title in blue area
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Improve Your Skills',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Curved white container with clip path
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(top: 35),
                  child: Column(
                    children: [
                      // Explore and View More section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Explore',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'View More',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Carousel section
                      Expanded(
                        child: OverlappedCarousel(
                          items: _categories,
                          selectedIndex: _selectedIndex,
                          onItemChanged: (index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/home/abc-block.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[300],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: Colors.yellow, size: 20),
                const SizedBox(width: 5),
                Text(
                  '3,100',
                  style: TextStyle(
                    color: Colors.yellow[300],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom ClipPath to create the wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    // Start at top-left
    path.lineTo(0, 40);

    // Create the wave curve
    var firstControlPoint = Offset(size.width / 4, 0);
    var firstEndPoint = Offset(size.width / 2, 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 3 / 4, 40);
    var secondEndPoint = Offset(size.width, 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Complete the clip path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class CharacterCategory {
  final String name;
  final String characterName;
  final String characterDesc;
  final Color color;
  final int coins;

  CharacterCategory({
    required this.name,
    required this.characterName,
    required this.characterDesc,
    required this.color,
    required this.coins,
  });
}

class OverlappedCarousel extends StatefulWidget {
  final List<CharacterCategory> items;
  final int selectedIndex;
  final Function(int) onItemChanged;

  const OverlappedCarousel({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemChanged,
  });

  @override
  State<OverlappedCarousel> createState() => _OverlappedCarouselState();
}

class _OverlappedCarouselState extends State<OverlappedCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.65,
      initialPage: widget.selectedIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.items.length,
      onPageChanged: widget.onItemChanged,
      itemBuilder: (context, index) {
        final isSelected = index == widget.selectedIndex;
        final double scale = isSelected ? 1.0 : 0.8;
        final double opacity = isSelected ? 1.0 : 0.8;

        return TweenAnimationBuilder(
          tween: Tween<double>(begin: scale, end: scale),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: opacity,
                child: CharacterCard(
                  category: widget.items[index],
                  isSelected: isSelected,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CharacterCard extends StatelessWidget {
  final CharacterCategory category;
  final bool isSelected;

  const CharacterCard({
    super.key,
    required this.category,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character image container with rounded corners
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: isSelected
                  ? Image.asset(
                      'assets/images/home/abc-block.png',
                      height: 180,
                      width: 180,
                    )
                  : Container(), // Empty for non-selected cards
            ),
          ),
          const SizedBox(height: 20),

          // Character name
          Text(
            category.characterName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Character description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              category.characterDesc,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Coins indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on,
                    color: Colors.yellow, size: 18),
                const SizedBox(width: 8),
                Text(
                  category.coins.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
