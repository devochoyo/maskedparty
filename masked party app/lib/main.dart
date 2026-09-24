// FILE LOCATION: lib/main.dart
import 'package:flutter/material.dart';
import 'screens/auth/splash.dart';
import 'screens/auth/login.dart';
import 'screens/client/bottom_navigation.dart';
import 'screens/influencer/bottom_navigation.dart';
import 'screens/influencer/complete_profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No Stripe initialization needed — Paystack checkout uses WebView
  // No Paystack keys needed in the app — backend handles all payment processing
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masked Party',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/clientHome': (context) => const ClientBottomNavigation(),
        '/influencerHome': (context) => const InfluencerBottomNavigation(),
        '/completeProfile': (context) => const CompleteProfileScreen(),
      },
    );
  }
}