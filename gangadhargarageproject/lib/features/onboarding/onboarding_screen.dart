import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Premium Cars",
      "subtitle": "Enjoy The Luxury",
      "description": "Experience top-tier service tailored for high-end luxury vehicles and premium sports cars. Excellence in every detail.",
      "image": "assets/images/car1.png"
    },
    {
      "title": "Precision Care",
      "subtitle": "Unmatched Quality",
      "description": "Our expert mechanics use state-of-the-art diagnostic tools to ensure your vehicle performs flawlessly on the road.",
      "image": "assets/images/car2.png"
    },
    {
      "title": "Drive With Pride",
      "subtitle": "Your Journey Matters",
      "description": "From aesthetic detailing to profound engine tuning, we bring your automotive dreams entirely into reality.",
      "image": "assets/images/car3.png"
    }
  ];

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go('/login');
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
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return _buildPageContent(
                title: _onboardingData[index]["title"]!,
                subtitle: _onboardingData[index]["subtitle"]!,
                description: _onboardingData[index]["description"]!,
                imagePath: _onboardingData[index]["image"]!,
              );
            },
          ),
          
          // Navigation & Indicators
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    _onboardingData.length,
                    (index) => buildDot(index, context),
                  ),
                ),
                
                // Next / Get Started Button
                _currentPage == _onboardingData.length - 1
                    ? ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.white,
                          foregroundColor: AppTheme.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Get Started", style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios, size: 16)
                          ],
                        ),
                      )
                    : InkWell(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward, color: AppTheme.white),
                        ),
                      ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPageContent({
    required String title,
    required String subtitle,
    required String description,
    required String imagePath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              )
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.primaryDark.withOpacity(0.5),
                    AppTheme.primaryDark,
                  ],
                  stops: const [0.6, 0.85, 1.0],
                )
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: _currentPage == index ? 24 : 10,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _currentPage == index ? AppTheme.primaryRed : Colors.grey.shade600,
      ),
    );
  }
}
