import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReelsPage extends StatefulWidget {
  @override
  _ReelsPageState createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child("users");

  User? currentUser;
  List<Map<String, dynamic>> reelsData = [];
  bool isLoading = true;
  ScrollController _scrollController = ScrollController();
  Set<String> reportedImageIds = {};

  @override
  void initState() {
    super.initState();
    _loadReportedImages();
    _loadReels();
  }

  Future<void> _loadReportedImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      reportedImageIds = prefs.getStringList('reportedImages_${currentUser?.uid}')?.toSet() ?? {};
    });
  }

  Future<void> _loadReels() async {
    currentUser = _auth.currentUser;
    final usersSnapshot = await _databaseRef.get();
    if (usersSnapshot.exists) {
      Map<String, dynamic> allUsersData = Map<String, dynamic>.from(usersSnapshot.value as Map);
      setState(() {
        reelsData = [];
        allUsersData.forEach((uid, userData) {
          if (userData['images'] != null) {
            Map<String, dynamic> userImages = Map<String, dynamic>.from(userData['images']);
            userImages.forEach((imageId, imageData) {
              // Only add the image if it's not reported by the current user
              if (!reportedImageIds.contains(imageId)) {
                List<Map<String, String>> formattedComments = [];
                if (imageData["comments"] != null) {
                  Map<String, dynamic> commentsData = Map<String, dynamic>.from(imageData["comments"]);
                  commentsData.forEach((key, commentData) {
                    formattedComments.add({
                      "user": commentData["user"] ?? "Anonymous",
                      "text": commentData["text"] ?? "",
                    });
                  });
                }
                reelsData.add({
                  "uid": uid,
                  "imageId": imageId,
                  "url": imageData["url"],
                  "likes": imageData["likes"] ?? {},
                  "comments": formattedComments,
                });
              }
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
    _loadReels();
  }

  Future<void> _reportImage(String uid, String imageId) async {
    setState(() {
      reelsData.removeWhere((reel) => reel["uid"] == uid && reel["imageId"] == imageId);
      reportedImageIds.add(imageId); // Track reported image
    });

    // Save reported images locally for this specific user
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('reportedImages_${currentUser?.uid}', reportedImageIds.toList());
  }

  void _showReportOptions(String uid, String imageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Not homecooked food"),
              onTap: () {
                _reportImage(uid, imageId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Inappropriate image"),
              onTap: () {
                _reportImage(uid, imageId);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _addComment(String uid, String imageId, String commentText) async {
    currentUser = _auth.currentUser;
    if (currentUser != null && commentText.isNotEmpty) {
      try {
        DatabaseReference commentsRef = _databaseRef
            .child(uid)
            .child("images")
            .child(imageId)
            .child("comments")
            .push();

        await commentsRef.set({
          "user": currentUser!.email?.split('@')[0] ?? 'Anonymous',
          "text": commentText,
        });

        setState(() {
          for (var reel in reelsData) {
            if (reel["uid"] == uid && reel["imageId"] == imageId) {
              reel["comments"].insert(0, {
                "user": currentUser!.email?.split('@')[0] ?? 'Anonymous',
                "text": commentText,
              });
            }
          }
        });

        _scrollController.jumpTo(0);
      } catch (e) {
        print("Error adding comment: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reels"),
        backgroundColor: Color(0xFFE17055),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFFF6E6CC),
        selectedItemColor: Color(0xFFE17055),
        unselectedItemColor: Color(0xFF8D6E63),
        currentIndex: 3,
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
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/main');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/leaderboard');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/gallery');
          }
        },
      ),
      backgroundColor: Color(0xFFFFF8E7),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE17055)))
          : reelsData.isEmpty
          ? Center(
        child: Text(
          "No reels to display.",
          style: TextStyle(color: Color(0xFF8D6E63), fontSize: 16),
        ),
      )
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
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            TextEditingController commentController = TextEditingController();
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: commentController,
                                    decoration: InputDecoration(hintText: "Add a comment..."),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.send, color: Color(0xFFE17055)),
                                    onPressed: () {
                                      _addComment(reel["uid"], reel["imageId"], commentController.text);
                                      commentController.clear();
                                    },
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      reverse: true,
                                      itemCount: reel["comments"].length,
                                      itemBuilder: (context, commentIndex) {
                                        final comment = reel["comments"][commentIndex];
                                        return ListTile(
                                          leading: Icon(Icons.person, color: Color(0xFFE17055)),
                                          title: Text(comment["user"]),
                                          subtitle: Text(comment["text"]),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (reel["uid"] != currentUser!.uid)
                      IconButton(
                        icon: Icon(Icons.flag, color: Color(0xFFE17055)),
                        onPressed: () => _showReportOptions(reel["uid"], reel["imageId"]),
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
