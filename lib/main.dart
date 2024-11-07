
/**
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core package
import 'LoginActivity.dart'; // Ensure this import is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MadeByMe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginActivity(), // Ensure this matches the actual name of your login screen class
    );
  }
}

*/


import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'LoginActivity.dart'; // Ensure this import is correct
import 'main_screen.dart'; // Import your main screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MadeByMe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginActivity(), // Home route for login
        '/main': (context) => MainScreen(), // Main screen route
      },
    );
  }
}
