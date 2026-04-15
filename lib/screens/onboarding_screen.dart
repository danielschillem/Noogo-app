import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Brand colours
const _kOrange = Color(0xFFF97316);
const _kOrangeLight = Color(0xFFFFF7ED);
const _kOrangeDeep = Color(0xFFEA580C);

class _OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });
}

const _pages = [
  _OnboardingData(
    title: 'Bienvenue sur Noogo',
    subtitle:
        'Commandez vos repas facilement depuis votre table, sans attendre.',
    icon: Icons.restaurant_menu_rounded,
    accentColor: _kOrange,
    bgColor: _kOrangeLight,
  ),
  _OnboardingData(
    title: 'Scannez le QR Code',
    subtitle:
        'Pointez votre camÃ©ra vers le QR code affichÃ© sur votre table pour accÃ©der au menu.',
    icon: Icons.qr_code_scanner_rounded,
    accentColor: Color(0xFF7C3AED),
    bgColor: Color(0xFFFAF5FF),
  ),
  _OnboardingData(
    title: 'Choisissez vos plats',
    subtitle:
        'Parcourez le menu, ajoutez vos plats prÃ©fÃ©rÃ©s et passez commande en un clic.',
    icon: Icons.lunch_dining_rounded,
    accentColor: Color(0xFF0891B2),
    bgColor: Color(0xFFECFEFF),
  ),
  _OnboardingData(
    title: 'Suivez en temps rÃ©el',
    subtitle:
        'Recevez des notifications Ã  chaque Ã©tape : confirmation, prÃ©paration, service.',
    icon: Icons.notifications_active_rounded,
    accentColor: Color(0xFF16A34A),
    bgColor: Color(0xFFF0FDF4),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _iconScale =
        CurvedAnimation(parent: _iconController, curve: Curves.elasticOut);
    _iconController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) Navigator.of(context).pushReplacementNamed('/welcome');
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _iconController.reset();
    _iconController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Skip button â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.grey[400]),
                  child: const Text('Passer',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ),

            // â”€â”€ PageView â”€â”€
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildSlide(_pages[index]),
              ),
            ),

            // â”€â”€ Bottom controls â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? page.accentColor : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Next / Start button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: page.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        shadowColor: page.accentColor.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'C\'est parti !'
                            : 'Suivant',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon in a circle
          ScaleTransition(
            scale: _iconScale,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: page.bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(page.icon, size: 90, color: page.accentColor),
              ),
            ),
          ),
          const SizedBox(height: 52),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            page.subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
