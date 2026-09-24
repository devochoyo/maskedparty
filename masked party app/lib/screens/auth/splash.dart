// FILE LOCATION: lib/screens/auth/splash.dart
import 'package:flutter/material.dart';

import '/services/session_manager.dart';
import '/services/auth_service.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _darkPink = Color(0xFFC2185B);

  @override
  void initState() {
    super.initState();
    // Delay navigation to ensure splash renders first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveStartDestination();
    });
  }

  Future<void> _resolveStartDestination() async {
    // Ensure minimum splash display time
    final minSplash = Future.delayed(const Duration(seconds: 3));
    
    // Check authentication status
    final isLoggedIn = await SessionManager.isLoggedIn();
    final role = await SessionManager.getRole();
    final token = await SessionManager.getToken();

    // Wait for minimum splash duration
    await minSplash;
    if (!mounted) return;

    // Handle logged-in users
    if (isLoggedIn && token != null) {
      if ((role ?? '').toLowerCase() == 'influencer') {
        // Check if influencer profile is complete
        try {
          final authService = AuthService();
          final result = await authService.checkProfileCompletion(token);
          
          if (!mounted) return;
          
          if (result['success'] == true && result['profile_completed'] == false) {
            Navigator.pushReplacementNamed(context, '/completeProfile');
            return;
          }
        } catch (e) {
          debugPrint('Profile check failed: $e');
        }
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/influencerHome');
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/clientHome');
        }
      }
      return;
    }

    // Not logged in - show welcome screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

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
      backgroundColor: _primaryPink,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _primaryPink,
              _softPink,
              _lightPink.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _darkPink.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.masks_rounded,
                    color: _primaryPink,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                const Text(
                  'MaskedParty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'With or Without the Vail',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Loading Indicator
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
      ),
    );
  }
}