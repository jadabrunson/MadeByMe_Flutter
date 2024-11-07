//first edition

/**
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'VisionHelper.dart'; // Ensure this exists and is correctly implemented for Google Vision API

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child("users");
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? currentUser;
  File? _imageFile;
  int streakCount = 0;
  DateTime? lastUploadDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _databaseRef.child(currentUser!.uid).child("streaks").once().then((
          DatabaseEvent event) {
        final snapshot = event.snapshot;
        if (snapshot.value != null) {
          // Ensure type-safety when converting snapshot data to Map
          Map<String, dynamic> streakData = Map<String, dynamic>.from(
              snapshot.value as Map);
          setState(() {
            streakCount = streakData["streakCount"] ?? 0;
            lastUploadDate =
                DateTime.tryParse(streakData["lastUploadDate"] ?? '');
          });
        }
      });
    }
  }

  Future<void> _updateStreak() async {
    DateTime today = DateTime.now();
    if (lastUploadDate != null) {
      int difference = today.difference(lastUploadDate!).inDays;
      if (difference == 1) {
        streakCount++;
      } else if (difference > 1) {
        streakCount = 1;
      }
    } else {
      streakCount = 1;
    }

    lastUploadDate = today;

    await _databaseRef.child(currentUser!.uid).child("streaks").set({
      "streakCount": streakCount,
      "lastUploadDate": DateFormat('yyyy-MM-dd').format(today),
    });

    setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _verifyAndUploadImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No image selected!")),
      );
      return;
    }

    // Verify with Vision API (mockup)
    bool isVerified = await VisionHelper.verifyImage(_imageFile!);
    if (isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verified as home-cooked food. Uploading...")),
      );

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child("images/$fileName");

      await storageRef.putFile(_imageFile!);
      String downloadUrl = await storageRef.getDownloadURL();
      _databaseRef.child(currentUser!.uid).child("uploaded_images").push().set(downloadUrl);

      await _updateStreak();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload successful! Streak updated.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image not verified as home-cooked food.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Main Screen"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${currentUser?.email ?? 'User'}"),
            SizedBox(height: 10),
            Text("Current Streak: $streakCount days"),
            SizedBox(height: 20),
            _imageFile != null
                ? Image.file(_imageFile!)
                : Text("No image selected."),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: Text("Take Photo"),
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: Text("Upload from Gallery"),
            ),
            ElevatedButton(
              onPressed: _verifyAndUploadImage,
              child: Text("Verify and Upload"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/leaderboard');
              },
              child: Text("Leaderboard"),
            ),
          ],
        ),
      ),
    );
  }
}

 */

/**
//slightly better ui, but not the best
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  File? _imageFile;
  int streakCount = 0;

  @override
  void initState() {
    super.initState();
    _checkUserAuthentication();
  }

  void _checkUserAuthentication() {
    currentUser = _auth.currentUser;
    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF222831),
      appBar: AppBar(
        title: Text(
          "Main Screen",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF393E46),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Welcome, ${currentUser?.email ?? 'User'}",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              "Current Streak: $streakCount days",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 16),
            _imageFile != null
                ? Image.file(
              _imageFile!,
              height: 200,
              fit: BoxFit.cover,
            )
                : Text(
              "No image selected.",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF673AB7),
              ),
              child: Text("Take Photo"),
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF673AB7),
              ),
              child: Text("Upload from Gallery"),
            ),
            ElevatedButton(
              onPressed: () {
                // Add your verification and upload logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF673AB7),
              ),
              child: Text("Verify and Upload"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF393E46),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt, color: Colors.white),
            label: "Camera",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard, color: Colors.white),
            label: "Leaderboard",
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Camera page logic
          } else if (index == 1) {
            // Navigate to Leaderboard page
            Navigator.pushNamed(context, '/leaderboard');
          }
        },
      ),
    );
  }
}

*/

//trying to fix buttons not working
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'VisionHelper.dart'; // Make sure this file handles Google Vision API verification

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child("users");
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? currentUser;
  File? _imageFile;
  int streakCount = 0;
  DateTime? lastUploadDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _databaseRef.child(currentUser!.uid).child("streaks").once().then((DatabaseEvent event) {
        final snapshot = event.snapshot;
        if (snapshot.value != null) {
          Map<String, dynamic> streakData = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            streakCount = streakData["streakCount"] ?? 0;
            lastUploadDate = DateTime.tryParse(streakData["lastUploadDate"] ?? '');
          });
        }
      });
    }
  }

  Future<void> _updateStreak() async {
    DateTime today = DateTime.now();
    if (lastUploadDate != null) {
      int difference = today.difference(lastUploadDate!).inDays;
      if (difference == 1) {
        streakCount++;
      } else if (difference > 1) {
        streakCount = 1;
      }
    } else {
      streakCount = 1;
    }

    lastUploadDate = today;
    await _databaseRef.child(currentUser!.uid).child("streaks").set({
      "streakCount": streakCount,
      "lastUploadDate": DateFormat('yyyy-MM-dd').format(today),
    });

    setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _verifyAndUploadImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No image selected!")),
      );
      return;
    }

    // Verify with Vision API
    bool isVerified = await VisionHelper.verifyImage(_imageFile!);
    if (isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verified as home-cooked food. Uploading...")),
      );

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child("images/$fileName");

      await storageRef.putFile(_imageFile!);
      String downloadUrl = await storageRef.getDownloadURL();
      _databaseRef.child(currentUser!.uid).child("uploaded_images").push().set(downloadUrl);

      await _updateStreak();
      setState(() {
        _imageFile = null; // Remove image after successful upload
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload successful! Streak updated.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image not verified as home-cooked food.")),
      );
      setState(() {
        _imageFile = null; // Remove image if verification fails
      });
    }
  }

  void _navigateTo(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF222831),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome, ${currentUser?.email ?? 'User'}",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "Current Streak: $streakCount days",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 20),
            _imageFile != null
                ? Image.file(_imageFile!)
                : Text("No image selected.", style: TextStyle(color: Colors.white70)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: Text("Take Photo"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: Text("Upload from Gallery"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
            ),
            ElevatedButton(
              onPressed: _verifyAndUploadImage,
              child: Text("Verify and Upload"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF393E46),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Camera",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: "Leaderboard",
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            _navigateTo('/camera'); // Ensure you have a route defined for '/camera'
          } else if (index == 1) {
            _navigateTo('/leaderboard'); // Ensure you have a route defined for '/leaderboard'
          }
        },
      ),
    );
  }
}
