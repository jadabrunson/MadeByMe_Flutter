//reel ad edit
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // For Banner Ads

class ReelsPage extends StatefulWidget {
  @override
  _ReelsPageState createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef =
  FirebaseDatabase.instance.ref().child("users");

  User? currentUser;
  List<Map<String, dynamic>> reelsData = [];
  bool isLoading = true;
  ScrollController _scrollController = ScrollController();
  Set<String> reportedImageIds = {};

  // Firebase Analytics
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Banner Ad
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;

  final Map<int, String> _routes = {
    0: '/main',
    1: '/leaderboard',
    2: '/gallery',
    3: '/reels',
    4: '/powerzone',
  };

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadBannerAd(); // Load Banner Ad
  }

  Future<void> _initializeUser() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _loadReportedImages();
      await _loadReels();
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadReportedImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      reportedImageIds =
          prefs.getStringList('reportedImages_${currentUser?.uid}')?.toSet() ??
              {};
    });
  }

  Future<void> _loadReels() async {
    try {
      final usersSnapshot = await _databaseRef.get();
      if (usersSnapshot.exists) {
        Map<String, dynamic> allUsersData =
        Map<String, dynamic>.from(usersSnapshot.value as Map);
        List<Map<String, dynamic>> fetchedReels = [];

        allUsersData.forEach((uid, userData) {
          if (userData['images'] != null) {
            Map<String, dynamic> userImages =
            Map<String, dynamic>.from(userData['images']);
            userImages.forEach((imageId, imageData) {
              if (!reportedImageIds.contains(imageId)) {
                List<Map<String, String>> formattedComments = [];
                if (imageData["comments"] != null) {
                  Map<String, dynamic> commentsData =
                  Map<String, dynamic>.from(imageData["comments"]);
                  commentsData.forEach((key, commentData) {
                    formattedComments.insert(0, {
                      "user": commentData["user"] ?? "Anonymous",
                      "text": commentData["text"] ?? "",
                    });
                  });
                }
                fetchedReels.add({
                  "uid": uid,
                  "imageId": imageId,
                  "url": imageData["url"],
                  "likes": Map<String, dynamic>.from(
                      imageData["likes"] ?? {}), // Ensure it's a Map
                  "comments": formattedComments,
                });
              }
            });
          }
        });

        setState(() {
          reelsData = fetchedReels;
          isLoading = false;
        });
      } else {
        setState(() {
          reelsData = [];
          isLoading = false;
        });
      }
    } catch (error) {
      print("Failed to fetch reels data: $error");
      setState(() {
        reelsData = [];
        isLoading = false;
      });
    }
  }



  // Load Banner Ad
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
          print("Banner Ad Loaded");
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print("Banner Ad Failed to Load: $error");
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  Widget _buildBannerAdWidget() {
    if (!_isBannerAdLoaded) return SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd),
      width: _bannerAd.size.width.toDouble(),
      height: _bannerAd.size.height.toDouble(),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                _logoutEnhanced();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logoutEnhanced() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged out successfully."),
          backgroundColor: Colors.green,
        ),
      );
      await _logEvent('user_sign_out', null);
    } catch (e) {
      print("Error during sign out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error signing out. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Color(0xFFF6E6CC),
      selectedItemColor: Color(0xFFE17055),
      unselectedItemColor: Color(0xFF8D6E63),
      currentIndex: 3,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard), label: "Leaderboard"),
        BottomNavigationBarItem(icon: Icon(Icons.photo_album), label: "Gallery"),
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Reels"),
        BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: "PowerZone"),
      ],
      onTap: (index) {
        if (_routes[index] == '/reels') return;

        Navigator.pushReplacementNamed(context, _routes[index]!);
        _logEvent('navigation', {'destination': _routes[index]!});
      },
    );
  }

  Widget _buildReelCard(Map<String, dynamic> reel) {
    final isLiked = reel["likes"][currentUser!.uid] ?? false;

    return Card(
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Image.network(
            reel["url"],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.broken_image,
                    size: 50, color: Colors.grey[700]),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE17055),
                  ),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () => _likeImage(reel["uid"], reel["imageId"]),
              ),
              IconButton(
                icon: Icon(Icons.comment, color: Color(0xFF8D6E63)),
                onPressed: () => _showCommentsModal(
                    reel["uid"], reel["imageId"], reel["comments"]),
              ),
              if (reel["uid"] != currentUser!.uid)
                IconButton(
                  icon: Icon(Icons.flag, color: Color(0xFFE17055)),
                  onPressed: () => _showReportOptions(
                      reel["uid"], reel["imageId"]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCommentsModal(
      String uid, String imageId, List<Map<String, String>> comments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        TextEditingController commentController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(8.0),
            height: MediaQuery.of(context).size.height * 0.5, // 50% height
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) {
                          String trimmedValue = value.trim();
                          if (trimmedValue.isNotEmpty) {
                            _addComment(uid, imageId, trimmedValue);
                            commentController.clear();
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8.0),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Color(0xFFE17055),
                      ),
                      onPressed: () {
                        String comment = commentController.text.trim();
                        if (comment.isNotEmpty) {
                          _addComment(uid, imageId, comment);
                          commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: comments.isEmpty
                      ? Center(
                    child: Text(
                      "No comments yet.",
                      style: TextStyle(
                          color: Color(0xFF8D6E63), fontSize: 14),
                    ),
                  )
                      : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, commentIndex) {
                      final comment = comments[commentIndex];
                      return ListTile(
                        leading: Icon(Icons.person,
                            color: Color(0xFFE17055)),
                        title: Text(comment["user"] ?? "Anonymous"),
                        subtitle: Text(comment["text"] ?? ""),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addComment(
      String uid, String imageId, String commentText) async {
    if (currentUser == null) return;

    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Comment cannot be empty.")),
      );
      return;
    }

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
              "user": currentUser!.email?.split('@')[0] ?? "Anonymous",
              "text": commentText,
            });
          }
        }
      });

      await _logEvent('comment_added', {
        'uid': uid,
        'imageId': imageId,
        'comment': commentText,
      });
    } catch (e) {
      print("Error adding comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add comment. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _likeImage(String uid, String imageId) async {
    if (currentUser == null) return;

    DatabaseReference likesRef =
    _databaseRef.child(uid).child("images").child(imageId).child("likes");

    bool isLiked = reelsData.any((element) =>
    element['uid'] == uid &&
        element['imageId'] == imageId &&
        (element['likes'][currentUser!.uid] ?? false));

    try {
      if (isLiked) {
        await likesRef.child(currentUser!.uid).remove(); // Unlike the image
      } else {
        await likesRef.child(currentUser!.uid).set(true); // Like the image
      }
      setState(() {
        int reelIndex = reelsData.indexWhere((reel) =>
        reel['uid'] == uid && reel['imageId'] == imageId);
        if (reelIndex != -1) {
          if (isLiked) {
            reelsData[reelIndex]['likes'].remove(currentUser!.uid);
          } else {
            reelsData[reelIndex]['likes'][currentUser!.uid] = true;
          }
        }
      });

      await _logEvent(
        isLiked ? 'image_unliked' : 'image_liked',
        {'uid': uid, 'imageId': imageId},
      );
    } catch (e) {
      print("Error liking/unliking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update like. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportOptions(String uid, String imageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.fastfood, color: Color(0xFFE17055)),
                title: Text("Not homecooked food"),
                onTap: () {
                  _reportImage(uid, imageId);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.report, color: Color(0xFFE17055)),
                title: Text("Inappropriate image"),
                onTap: () {
                  _reportImage(uid, imageId);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reportImage(String uid, String imageId) async {
    if (currentUser == null) return;

    setState(() {
      reelsData.removeWhere(
              (reel) => reel["uid"] == uid && reel["imageId"] == imageId);
      reportedImageIds.add(imageId); // Track reported image
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'reportedImages_${currentUser?.uid}', reportedImageIds.toList());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Image reported successfully.")),
    );

    await _logEvent('image_reported', {'uid': uid, 'imageId': imageId});
  }

  Future<void> _logEvent(String eventName, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
    } catch (e) {
      print("Error logging event: $e");
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
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      backgroundColor: Color(0xFFFFF8E7),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(color: Color(0xFFE17055)),
      )
          : reelsData.isEmpty
          ? Center(
        child: Text(
          "No reels to display.",
          style: TextStyle(color: Color(0xFF8D6E63), fontSize: 16),
        ),
      )
          : ListView.builder(
        controller: _scrollController,
        itemCount: reelsData.length + (reelsData.length ~/ 5),
        itemBuilder: (context, index) {
          if (index > 0 && index % 5 == 0) {
            return BannerAdWidget(); // Replace with banner ad widget
          }

          final reelIndex = index - (index ~/ 5);
          final reel = reelsData[reelIndex];

          return _buildReelCard(reel);
        },
      ),
    );
  }

  Widget BannerAdWidget() {
    // Replace the native ad implementation with a fixed banner ad
    final bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test banner ad ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print("Banner Ad Loaded");
        },
        onAdFailedToLoad: (ad, error) {
          print("Banner Ad Failed to Load: $error");
          ad.dispose();
        },
      ),
    );

    bannerAd.load();

    return Container(
      alignment: Alignment.center,
      child: AdWidget(ad: bannerAd),
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
    );
  }
}
