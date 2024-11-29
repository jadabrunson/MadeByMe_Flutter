import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'LoginActivity.dart';
import 'main_screen.dart';
import 'LeaderboardActivity.dart';
import 'GalleryPage.dart';
import 'ReelsPage.dart';
import 'PowerZone.dart';
import 'keys.dart';
import 'package:flutter_stripe/flutter_stripe.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Google Mobile Ads SDK
  MobileAds.instance.initialize();

  Stripe.publishableKey = PublishableKey;
  await Stripe.instance.applySettings();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MadeByMe',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Color(0xFFFFF8E7), // Warm ivory background
        appBarTheme: AppBarTheme(
          color: Color(0xFFE17055), // Burnt orange app bar
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF5D4037)), // Deep brown for primary text
          bodyMedium: TextStyle(color: Color(0xFF8D6E63)), // Soft brown for secondary text
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginActivity(),
        '/login': (context) => LoginActivity(), // Added '/login' route
        '/main': (context) => MainScreen(),
        '/leaderboard': (context) => LeaderboardActivity(),
        '/gallery': (context) => GalleryPage(),
        '/reels': (context) => ReelsPage(),
        '/powerzone': (context) => PowerZone(), // Route for the PowerZone page
        '/payment' : (context) => PowerZone(),
      },
    );
  }
}