import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'CommentPage.dart'; // Import the new comment page for viewing and adding comments

class ReelsPage extends StatefulWidget {
  @override
  _ReelsPageState createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child("users");
  final DatabaseReference _reportedRef = FirebaseDatabase.instance.ref().child("reported");
  User? currentUser;
  List<Map<String, dynamic>> reelsData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    currentUser = _auth.currentUser;
    // Loading all images from users to display
    final usersSnapshot = await _databaseRef.get();
    if (usersSnapshot.exists) {
      Map<String, dynamic> allUsersData = Map<String, dynamic>.from(usersSnapshot.value as Map);
      setState(() {
        reelsData = [];
        allUsersData.forEach((uid, userData) {
          if (userData['images'] != null) {
            Map<String, dynamic> userImages = Map<String, dynamic>.from(userData['images']);
            userImages.forEach((imageId, imageData) {
              reelsData.add({
                "uid": uid,
                "imageId": imageId,
                "url": imageData["url"],
                "likes": imageData["likes"] ?? {},
                "comments": imageData["comments"] ?? {},
              });
            });
          }
        });
        isLoading = false;
      });
    }
  }

  Future<void> _likeImage(String uid, String imageId) async {
    currentUser = _auth.currentUser;
    DatabaseReference likesRef = _databaseRef.child(uid).child("images").child(imageId).child("likes");
    if (reelsData.any((element) =>
    element['uid'] == uid &&
        element['imageId'] == imageId &&
        (element['likes'][currentUser!.uid] ?? false))) {
      await likesRef.child(currentUser!.uid).remove(); // Unlike the image
    } else {
      await likesRef.child(currentUser!.uid).set(true); // Like the image
    }
    _loadReels(); // Reload after like/unlike
  }

  Future<void> _reportImage(String uid, String imageId, String imageUrl) async {
    await _reportedRef.child(imageId).set({
      "reportedBy": currentUser!.uid,
      "imageUrl": imageUrl,
      "reportedAt": DateTime.now().toIso8601String(),
    });
    await _databaseRef.child(uid).child("images").child(imageId).remove();
    _loadReels(); // Reload after reporting
  }

  void _openComments(String uid, String imageId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommentPage(uid: uid, imageId: imageId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feed"),
        backgroundColor: Color(0xFFE17055),
      ),
      backgroundColor: Color(0xFFFFF8E7),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE17055)))
          : reelsData.isEmpty
          ? Center(child: Text("No images to display.", style: TextStyle(color: Color(0xFF8D6E63), fontSize: 16)))
          : ListView.builder(
        itemCount: reelsData.length,
        itemBuilder: (context, index) {
          final reel = reelsData[index];
          final isLiked = reel["likes"][currentUser!.uid] ?? false;
          return Card(
            margin: EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Image.network(reel["url"], fit: BoxFit.cover),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                      onPressed: () => _likeImage(reel["uid"], reel["imageId"]),
                    ),
                    IconButton(
                      icon: Icon(Icons.comment, color: Color(0xFF8D6E63)),
                      onPressed: () => _openComments(reel["uid"], reel["imageId"]),
                    ),
                    if (reel["uid"] != currentUser!.uid)
                      IconButton(
                        icon: Icon(Icons.flag, color: Color(0xFFE17055)),
                        onPressed: () => _reportImage(reel["uid"], reel["imageId"], reel["url"]),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
