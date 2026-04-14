import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Scannez le QR Code',
      description:
          'Scannez, commandez et profitez de votre repas en toute simplicité',
      imagePath: 'assets/icons/04.png',
      icon: Icons.restaurant_menu,
      color: const Color.fromARGB(255, 220, 220, 220),
    ),
    OnboardingPage(
      title: 'Commandez vos plats',
      description: 'Parcourez le menu et ajoutez vos plats préférés en un clic',
      imagePath: 'assets/icons/02.png',
      icon: Icons.shopping_cart,
      color: const Color.fromARGB(255, 220, 220, 220),
    ),
    OnboardingPage(
      title: 'Payez en ligne',
      description: 'Réglez votre addition directement depuis l\'application',
      imagePath: 'assets/icons/05.png',
      icon: Icons.payment,
      color: const Color.fromARGB(255, 220, 220, 220),
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _pages[_currentPage].color.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Bouton Skip en haut à droite
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF61C370),
                    ),
                    child: const Text(
                      'Passer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView pour les slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Indicateurs et boutons en bas
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Dots indicateurs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? _pages[_currentPage].color
                                : const Color(0xFF61C370),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bouton Suivant/Commencer
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].color,
                          foregroundColor: const Color(0xFFFFFFFF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Commencer'
                              : 'Suivant',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image ou Icon avec animation
          Hero(
            tag: 'onboarding_${page.title}',
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                color: page.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  page.imagePath,
                  height: 300,
                  width: 300,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback avec icône si l'image n'existe pas
                    return Icon(
                      page.icon,
                      size: 120,
                      color: page.color,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),

          // Titre
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.color,
  });
}
