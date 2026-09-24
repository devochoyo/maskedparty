import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: isSmallScreen
            ? const TextScaler.linear(0.92)
            : MediaQuery.of(context).textScaler,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          visualDensity: isSmallScreen
              ? VisualDensity.compact
              : Theme.of(context).visualDensity,
        ),
        child: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/masked_party.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Wipe stack so back never returns to Splash/Welcome
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/clientHome',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
  }
}
