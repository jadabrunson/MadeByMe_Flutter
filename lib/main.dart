import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'LoginActivity.dart';
import 'main_screen.dart';
import 'LeaderboardActivity.dart';
import 'GalleryPage.dart';
import 'ReelsPage.dart';
import 'PowerZone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  MobileAds.instance.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MadeByMe',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Color(0xFFFFF8E7),
        appBarTheme: AppBarTheme(
          color: Color(0xFFE17055),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF5D4037)),
          bodyMedium: TextStyle(color: Color(0xFF8D6E63)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginActivity(),
        '/login': (context) => LoginActivity(),
        '/main': (context) => MainScreen(),
        '/leaderboard': (context) => LeaderboardActivity(),
        '/gallery': (context) => GalleryPage(),
        '/reels': (context) => ReelsPage(),
        '/powerzone': (context) => PowerZone(),
        '/payment' : (context) => PowerZone(),
      },
    );
  }
}