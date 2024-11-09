import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'VisionHelper.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child("users");
  User? currentUser;
  File? _imageFile;
  int streakCount = 0;
  int maxStreak = 0;
  DateTime? lastUploadDate;
  bool isUploading = false;
  bool verificationFailed = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      currentUser = _auth.currentUser;
      if (currentUser != null) {
        final event = await _databaseRef.child(currentUser!.uid).once();
        final snapshot = event.snapshot;
        if (snapshot.value != null) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            streakCount = userData["streaks"]?["currentStreak"] ?? 0;
            maxStreak = userData["streaks"]?["maxStreak"] ?? 0;
            lastUploadDate = DateTime.tryParse(userData["streaks"]?["lastUploadDate"] ?? '');
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _updateStreak() async {
    try {
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

      if (streakCount > maxStreak) {
        maxStreak = streakCount;
      }

      await _databaseRef.child(currentUser!.uid).set({
        "email": currentUser!.email,
        "streaks": {
          "currentStreak": streakCount,
          "maxStreak": maxStreak,
          "lastUploadDate": DateFormat('yyyy-MM-dd').format(today),
        }
      });

      setState(() {});
    } catch (e) {
      print("Error updating streak: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        verificationFailed = false; // Reset verification fail message
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

    setState(() {
      isUploading = true;
    });

    try {
      bool isVerified = await VisionHelper.verifyImage(_imageFile!);
      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verified as home-cooked food. Streak updated!")),
        );

        await _updateStreak();
        setState(() {
          _imageFile = null;
          isUploading = false;
          verificationFailed = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image not verified as home-cooked food.")),
        );
        setState(() {
          _imageFile = null;
          isUploading = false;
          verificationFailed = true;
        });
      }
    } catch (e) {
      print("Error during verification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to verify image. Please try again.")),
      );
      setState(() {
        isUploading = false;
        verificationFailed = false;
      });
    }
  }

  void _navigateTo(String route) {
    Navigator.pushNamed(context, route);
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text('Main Screen'),
        backgroundColor: Color(0xFFE17055),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome, ${currentUser?.email?.split('@')[0] ?? 'User'}",
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                "Current Streak: $streakCount days",
                style: TextStyle(
                  color: Color(0xFF8D6E63),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Max Streak: $maxStreak days",
                style: TextStyle(
                  color: Color(0xFF8D6E63),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 20),
              _imageFile != null
                  ? Flexible(
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.35,
                ),
              )
                  : Center(
                child: Text(
                  verificationFailed
                      ? "Please upload a home-cooked meal"
                      : "No image selected.",
                  style: TextStyle(
                    color: Color(0xFF8D6E63),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 25),
              if (isUploading)
                CircularProgressIndicator(color: Color(0xFFE17055))
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.photo_camera, size: 40, color: Color(0xFFE17055)),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        Text(
                          "Take Photo",
                          style: TextStyle(color: Color(0xFF8D6E63), fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.photo_library, size: 40, color: Color(0xFFE17055)),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                        Text(
                          "Upload from Gallery",
                          style: TextStyle(color: Color(0xFF8D6E63), fontSize: 14),
                        ),
                      ],
                    ),
                    if (_imageFile != null)
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.check_circle, size: 40, color: Color(0xFFE17055)),
                            onPressed: _verifyAndUploadImage,
                          ),
                          Text(
                            "Verify",
                            style: TextStyle(color: Color(0xFF8D6E63), fontSize: 14),
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFFF6E6CC),
        selectedItemColor: Color(0xFFE17055),
        unselectedItemColor: Color(0xFF8D6E63),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: "Leaderboard",
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            _navigateTo('/leaderboard');
          }
        },
      ),
    );
  }
}
