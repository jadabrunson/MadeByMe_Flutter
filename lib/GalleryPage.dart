import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'FullScreenImagePage.dart';

class GalleryPage extends StatefulWidget {
  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child("users");

  List<String> imageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final imagesSnapshot = await _databaseRef.child(currentUser.uid).child("images").get();
      if (imagesSnapshot.exists) {
        Map<String, dynamic> imagesData = Map<String, dynamic>.from(imagesSnapshot.value as Map);
        setState(() {
          imageUrls = imagesData.values.map((e) => e['url'] as String).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Gallery"),
        backgroundColor: Color(0xFFE17055),
      ),
      backgroundColor: Color(0xFFFFF8E7),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE17055)))
          : imageUrls.isEmpty
          ? Center(
        child: Text(
          "No images to display.",
          style: TextStyle(color: Color(0xFF8D6E63), fontSize: 16),
        ),
      )
          : GridView.builder(
        padding: EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Number of images per row
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImagePage(imageUrl: imageUrls[index]),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: NetworkImage(imageUrls[index]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFFF6E6CC), // Light Almond
        selectedItemColor: Color(0xFFE17055), // Burnt Orange
        unselectedItemColor: Color(0xFF8D6E63), // Soft Brown
        currentIndex: 2, // Set current index to 2 for the gallery page
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
            icon: Icon(Icons.bolt), // Icon for PowerZone
            label: "PowerZone",
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/main'); // Navigate to Home page
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/leaderboard'); // Navigate to Leaderboard page
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/reels'); // Navigate to Reels page
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/powerzone'); // Navigate to PowerZone page
          }
        },
      ),
    );
  }
}
