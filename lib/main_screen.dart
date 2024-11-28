import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'VisionHelper.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child("users");
  final DatabaseReference _featureFlagRef = FirebaseDatabase.instance.ref().child("featureFlags");
  final DatabaseReference _challengeRef = FirebaseDatabase.instance.ref().child("weeklyChallenge");
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  User? currentUser;
  File? _imageFile;
  int streakCount = 0;
  int maxStreak = 0;
  DateTime? lastUploadDate;
  bool isUploading = false;
  bool verificationFailed = false;

  // Feature flags
  bool isTakePhotoEnabled = true;
  bool isUploadFromGalleryEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeFeatureFlags();
    _logScreenView();
  }

  Future<void> _initializeFeatureFlags() async {
    try {
      final takePhotoFlag = await _featureFlagRef.child("takePhoto").get();
      final uploadFromGalleryFlag = await _featureFlagRef.child("uploadFromGallery").get();

      setState(() {
        if (takePhotoFlag.exists) {
          isTakePhotoEnabled = takePhotoFlag.value == 1;
        } else {
          _featureFlagRef.child("takePhoto").set(1); // Default to 'on'
          isTakePhotoEnabled = true;
        }

        if (uploadFromGalleryFlag.exists) {
          isUploadFromGalleryEnabled = uploadFromGalleryFlag.value == 1;
        } else {
          _featureFlagRef.child("uploadFromGallery").set(1); // Default to 'on'
          isUploadFromGalleryEnabled = true;
        }
      });
    } catch (e) {
      print("Error initializing feature flags: $e");
    }
  }

  Future<void> _logScreenView() async {
    await _analytics.logEvent(name: 'screen_view', parameters: {
      'screen_name': 'MainScreen',
      'screen_class': 'MainScreen'
    });
  }

  Future<void> _logEvent(String eventName, Map<String, Object>? parameters) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
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

  Future<void> _updateStreak(String? imageUrl) async {
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

      String imageKey = _databaseRef.child(currentUser!.uid).child("images").push().key!;

      await _databaseRef.child(currentUser!.uid).update({
        "email": currentUser!.email,
        "streaks": {
          "currentStreak": streakCount,
          "maxStreak": maxStreak,
          "lastUploadDate": DateFormat('yyyy-MM-dd').format(today),
        }
      });

      if (imageUrl != null) {
        await _databaseRef.child(currentUser!.uid).child("images").child(imageKey).set({
          "url": imageUrl,
          "uploadedAt": DateFormat('yyyy-MM-dd HH:mm:ss').format(today),
        });
      }

      // Log streak update event
      await _logEvent('streak_updated', {
        'current_streak': streakCount,
        'max_streak': maxStreak,
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
        verificationFailed = false;
      });
      // Log image pick event
      await _logEvent('image_picked', {
        'source': source == ImageSource.camera ? 'camera' : 'gallery',
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
      final result = await VisionHelper.verifyImage(_imageFile!);
      bool isVerified = result["isVerified"] ?? false;
      bool matchesChallenge = result["matchesChallenge"] ?? false;

      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verified as home-cooked food. Streak updated!")),
        );

        String imageUrl = await _uploadImageToFirebase(_imageFile!);

        if (imageUrl.isNotEmpty) {
          await _updateStreak(imageUrl);

          if (matchesChallenge) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Image meets the challenge theme! Contribution added.")),
            );
            await _contributeToChallenge();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Image does not meet the challenge theme.")),
            );
          }
        } else {
          throw Exception("Image URL is empty after upload.");
        }

        setState(() {
          _imageFile = null;
          isUploading = false;
          verificationFailed = false;
        });

        await _logEvent('image_verified', {'status': 'success'});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image not verified as home-cooked food.")),
        );
        setState(() {
          _imageFile = null;
          isUploading = false;
          verificationFailed = true;
        });

        await _logEvent('image_verified', {'status': 'failed'});
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

  Future<String> _uploadImageToFirebase(File image) async {
    try {
      String filePath = 'images/${currentUser!.uid}/${DateTime.now().toIso8601String()}.jpg';
      final ref = _storage.ref().child(filePath);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return "";
    }
  }

  Future<void> _contributeToChallenge() async {
    try {
      final challengeSnapshot = await _challengeRef.child("contributions").get();
      if (!challengeSnapshot.exists) {
        await _challengeRef.child("contributions").set({
          currentUser!.uid: {
            "userContribution": 1,
            "lastContributed": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          },
        });
      } else {
        await _challengeRef.child("contributions").child(currentUser!.uid).update({
          "userContribution": ServerValue.increment(1),
          "lastContributed": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        });
      }

      await _challengeRef.child("groupProgress").set(ServerValue.increment(1));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Challenge contribution added! Group progress updated.")),
      );
      await _logEvent('challenge_contributed', {'user_id': currentUser!.uid});
    } catch (e) {
      print("Error contributing to challenge: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to contribute to challenge. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateTo(String route) {
    Navigator.pushNamed(context, route);
    _logEvent('navigation', {'destination': route});
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    await _logEvent('user_sign_out', null);
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
                    if (isTakePhotoEnabled)
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
                    if (isUploadFromGalleryEnabled)
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
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: "Leaderboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: "Gallery",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: "Reels",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on), // Icon for PowerZone
            label: "PowerZone",
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              _navigateTo('/main');
              break;
            case 1:
              _navigateTo('/leaderboard');
              break;
            case 2:
              _navigateTo('/gallery');
              break;
            case 3:
              _navigateTo('/reels');
              break;
            case 4:
              _navigateTo('/powerzone');
              break;
            default:
              break;
          }
        },
      ),
    );
  }
}
