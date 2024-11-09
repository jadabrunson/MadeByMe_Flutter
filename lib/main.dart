import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'LoginActivity.dart';
import 'main_screen.dart';
import 'LeaderboardActivity.dart';
import 'GalleryPage.dart'; // Import the gallery page
import 'ReelsPage.dart'; // Import the reels page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/main': (context) => MainScreen(),
        '/leaderboard': (context) => LeaderboardActivity(),
        '/gallery': (context) => GalleryPage(), // Route for the gallery page
        '/reels': (context) => ReelsPage(), // Route for the reels page
      },
    );
  }
}
