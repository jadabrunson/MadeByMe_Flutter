import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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

  // ScrollController to control the scroll behavior in comments section
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  // Function to load all reels and comments
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
              // Format the comments properly
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
            });
          }
        });
        isLoading = false;
      });
    }
  }

  // Function to like an image
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

  // Function to report an image
  Future<void> _reportImage(String uid, String imageId, String imageUrl) async {
    await _reportedRef.child(imageId).set({
      "reportedBy": currentUser!.uid,
      "imageUrl": imageUrl,
      "reportedAt": DateTime.now().toIso8601String(),
    });
    await _databaseRef.child(uid).child("images").child(imageId).remove();
    _loadReels(); // Reload after reporting
  }

  // Function to add a comment to an image
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
          "user": currentUser!.email?.split('@')[0] ?? 'Anonymous', // Store the username (or UID)
          "text": commentText,
        });

        // Update the comment section locally without needing to reload the whole data
        setState(() {
          // Find the corresponding reel and add the new comment to it
          for (var reel in reelsData) {
            if (reel["uid"] == uid && reel["imageId"] == imageId) {
              reel["comments"].insert(0, {
                "user": currentUser!.email?.split('@')[0] ?? 'Anonymous',
                "text": commentText,
              });
            }
          }
        });

        // Scroll to the top after adding a new comment
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
                                      controller: _scrollController,  // Attach the controller
                                      reverse: true, // This ensures the newest comment comes at the top
                                      itemCount: reel["comments"] != null ? reel["comments"].length : 0,
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
