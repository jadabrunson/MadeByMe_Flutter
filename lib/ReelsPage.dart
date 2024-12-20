import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InlineAd {
  BannerAd bannerAd;
  bool isLoaded;

  InlineAd({required this.bannerAd, this.isLoaded = false});
}

class AdReelCard extends StatelessWidget {
  final InlineAd? inlineAd;

  AdReelCard({required this.inlineAd});

  @override
  Widget build(BuildContext context) {
    if (inlineAd == null || !inlineAd!.isLoaded) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: Color(0xFFE17055)),
      );
    }
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Sponsored',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Container(
            width: inlineAd!.bannerAd.size.width.toDouble(),
            height: inlineAd!.bannerAd.size.height.toDouble(),
            child: AdWidget(ad: inlineAd!.bannerAd),
          ),
        ],
      ),
    );
  }
}

class ReelCard extends StatefulWidget {
  final Map<String, dynamic> reel;
  final User currentUser;
  final Function(String uid, String imageId) onReport;

  ReelCard({
    required this.reel,
    required this.currentUser,
    required this.onReport,
  });

  @override
  _ReelCardState createState() => _ReelCardState();
}

class _ReelCardState extends State<ReelCard> {
  bool isCommentsVisible = false;
  TextEditingController commentController = TextEditingController();

  late Map<String, dynamic> reelData;
  late User currentUser;
  final DatabaseReference databaseRef =
  FirebaseDatabase.instance.ref().child("users");

  @override
  void initState() {
    super.initState();
    reelData = Map<String, dynamic>.from(widget.reel);
    currentUser = widget.currentUser;
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  void toggleComments() {
    setState(() {
      isCommentsVisible = !isCommentsVisible;
    });
  }

  Future<void> _likeImage() async {
    DatabaseReference likesRef = databaseRef
        .child(reelData["uid"])
        .child("images")
        .child(reelData["imageId"])
        .child("likes");

    bool isLiked = reelData["likes"][currentUser.uid] ?? false;

    try {
      if (isLiked) {
        await likesRef.child(currentUser.uid).remove();
      } else {
        await likesRef.child(currentUser.uid).set(true);
      }
      setState(() {
        if (isLiked) {
          reelData["likes"].remove(currentUser.uid);
        } else {
          reelData["likes"][currentUser.uid] = true;
        }
      });

      await FirebaseAnalytics.instance.logEvent(
        name: isLiked ? 'image_unliked' : 'image_liked',
        parameters: _removeNullValues({
          'uid': reelData["uid"],
          'imageId': reelData["imageId"],
        }),
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

  Future<void> _addComment(String commentText) async {
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Comment cannot be empty.")),
      );
      return;
    }

    try {
      DatabaseReference commentsRef = databaseRef
          .child(reelData["uid"])
          .child("images")
          .child(reelData["imageId"])
          .child("comments")
          .push();

      await commentsRef.set({
        "user": currentUser.email?.split('@')[0] ?? 'Anonymous',
        "text": commentText,
      });

      setState(() {
        reelData["comments"].insert(0, {
          "user": currentUser.email?.split('@')[0] ?? "Anonymous",
          "text": commentText,
        });
      });

      await FirebaseAnalytics.instance.logEvent(
        name: 'comment_added',
        parameters: _removeNullValues({
          'uid': reelData["uid"],
          'imageId': reelData["imageId"],
          'comment': commentText,
        }),
      );
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

  Map<String, Object>? _removeNullValues(Map<String, Object?>? original) {
    if (original == null) return null;
    final filtered = <String, Object>{};
    original.forEach((key, value) {
      if (value != null) {
        filtered[key] = value;
      }
    });
    return filtered.isEmpty ? null : filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = reelData["likes"][currentUser.uid] ?? false;

    Color iconColor = Color(0xFFE17055);

    return Stack(
      children: [
        Center(
          child: Image.network(
            reelData["url"],
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(Icons.broken_image,
                    size: 50, color: Colors.grey[700]),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE17055),
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 10,
          bottom: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: isLiked ? Colors.red : iconColor,
                  size: 35,
                ),
                onPressed: _likeImage,
              ),
              Text(
                "${(reelData["likes"] as Map<String, dynamic>).keys.length}",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              SizedBox(height: 20),
              IconButton(
                icon: Icon(
                  Icons.chat_bubble,
                  color: iconColor,
                  size: 35,
                ),
                onPressed: toggleComments,
              ),
              Text(
                "${reelData["comments"].length}",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              SizedBox(height: 20),
              IconButton(
                icon: Icon(
                  Icons.flag,
                  color: iconColor,
                  size: 35,
                ),
                onPressed: () {
                  if (reelData["uid"] == currentUser.uid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("You cannot report your own post."),
                      ),
                    );
                  } else {
                    widget.onReport(reelData["uid"], reelData["imageId"]);
                  }
                },
              ),
            ],
          ),
        ),

        if (isCommentsVisible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus(); // Hide the keyboard
              },
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: toggleComments,
                      ),
                    ),
                    Expanded(
                      child: reelData["comments"].isEmpty
                          ? Center(
                        child: Text(
                          "No comments yet.",
                          style: TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      )
                          : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        reverse: false,
                        itemCount: reelData["comments"].length,
                        itemBuilder: (context, index) {
                          final comment = reelData["comments"][index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(0xFFE17055),
                                  child: Text(
                                    comment["user"] != null &&
                                        comment["user"].length > 1
                                        ? comment["user"][0]
                                        .toUpperCase()
                                        : 'A',
                                    style:
                                    TextStyle(color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                      Colors.white.withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                            color: Colors.white),
                                        children: [
                                          TextSpan(
                                            text:
                                            "${comment["user"] ?? "Anonymous"} ",
                                            style: TextStyle(
                                                fontWeight:
                                                FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: comment["text"] ?? "",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.8),
                      padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Add a comment...",
                                hintStyle:
                                TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide:
                                  BorderSide(color: Colors.transparent),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide:
                                  BorderSide(color: Colors.transparent),
                                ),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (value) {
                                String trimmedValue = value.trim();
                                if (trimmedValue.isNotEmpty) {
                                  _addComment(trimmedValue);
                                  commentController.clear();
                                  FocusScope.of(context)
                                      .unfocus();
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Color(0xFFE17055),
                            ),
                            onPressed: () {
                              String comment =
                              commentController.text.trim();
                              if (comment.isNotEmpty) {
                                _addComment(comment);
                                commentController.clear();
                                FocusScope.of(context)
                                    .unfocus();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ReelsPage extends StatefulWidget {
  @override
  _ReelsPageState createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef =
  FirebaseDatabase.instance.ref().child("users");
  final DatabaseReference _featureFlagsRef =
  FirebaseDatabase.instance.ref().child("featureFlags");

  User? currentUser;
  List<Map<String, dynamic>> reelsData = [];
  bool isLoading = true;
  PageController _pageController = PageController();
  Set<String> reportedImageIds = {};

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // A/B Sprint 5 Testing: 0 = Method A (Permanent Ads), 1 = Method B (Occasional Ads)
  int adsFeatureFlag = 0;

  Map<int, InlineAd> inlineBannerAds = {};

  final Map<int, String> _routes = {
    0: '/main',
    1: '/leaderboard',
    2: '/gallery',
    3: '/reels',
    4: '/powerzone',
  };

  DateTime? _pageEnterTime;
  bool _isLogged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
    _pageController.addListener(_pageListener);
    _pageEnterTime = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logUsageTime();
    _bannerAd?.dispose();
    inlineBannerAds.forEach((key, ad) {
      ad.bannerAd.dispose();
    });
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _loadReportedImages();
      await _loadReels();

      String userGroup = await _getUserGroup(currentUser!.uid);

      await _fetchAdsFeatureFlag(userGroup);

      if (adsFeatureFlag == 0) {
        _loadBannerAd();
      }
      setState(() {
        isLoading = false;
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<String> _getUserGroup(String uid) async {
    try {
      DatabaseReference userRef =
      FirebaseDatabase.instance.ref().child("users").child(uid);
      final snapshot = await userRef.child("group").get();
      if (snapshot.exists) {
        return snapshot.value.toString();
      } else {
        return "default";
      }
    } catch (e) {
      print("Error fetching user group: $e");
      return "default";
    }
  }

  Future<void> _fetchAdsFeatureFlag(String group) async {
    try {
      if (group == "default") {
        final snapshot = await _featureFlagsRef.child("ads").get();
        if (snapshot.exists) {
          setState(() {
            adsFeatureFlag = int.tryParse(snapshot.value.toString()) ?? 0;
          });
          print("Global Ads Feature Flag: $adsFeatureFlag");
        } else {
          await _featureFlagsRef.child("ads").set(0);
          setState(() {
            adsFeatureFlag = 0;
          });
          print("Global Ads Feature Flag initialized to 0");
        }
        await _logEvent('ad_variant', _removeNullValues({
          'variant': adsFeatureFlag == 0 ? 'Feature A' : 'Feature B',
        }));
      } else {
        DatabaseReference groupRef =
        FirebaseDatabase.instance.ref().child("userGroups").child(group).child("ads");
        final snapshot = await groupRef.get();
        if (snapshot.exists) {
          setState(() {
            adsFeatureFlag = int.tryParse(snapshot.value.toString()) ?? 0;
          });
          print("Group ($group) Ads Feature Flag: $adsFeatureFlag");
        } else {
          final globalSnapshot = await _featureFlagsRef.child("ads").get();
          if (globalSnapshot.exists) {
            setState(() {
              adsFeatureFlag = int.tryParse(globalSnapshot.value.toString()) ?? 0;
            });
            print("Fallback Global Ads Feature Flag: $adsFeatureFlag");
          } else {
            await _featureFlagsRef.child("ads").set(0);
            setState(() {
              adsFeatureFlag = 0;
            });
            print("Fallback Global Ads Feature Flag initialized to 0");
          }
        }
        await _logEvent('ad_variant', _removeNullValues({
          'variant': adsFeatureFlag == 0 ? 'Feature A' : 'Feature B',
          'group': group,
        }));
      }
    } catch (e) {
      print("Error fetching adsFeatureFlag: $e");
      setState(() {
        adsFeatureFlag = 0;
      });
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
                  "likes": Map<String, dynamic>.from(imageData["likes"] ?? {}),
                  "comments": formattedComments,
                });
              }
            });
          }
        });

        setState(() {
          reelsData = fetchedReels;
        });
      } else {
        setState(() {
          reelsData = [];
        });
      }
    } catch (error) {
      print("Failed to fetch reels data: $error");
      setState(() {
        reelsData = [];
      });
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId:
      'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          setState(() {
            _isBannerAdLoaded = true;
          });
          print("Banner Ad Loaded");
          await _logEvent(
              'ad_loaded', _removeNullValues({'variant': 'Feature A'}));
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print("Banner Ad Failed to Load: $error");
        },
      ),
    );

    _bannerAd!.load();
  }

  void _loadInlineBannerAd(int adIndex) {
    BannerAd inlineAd = BannerAd(
      adUnitId:
      'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.mediumRectangle,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          print("Inline Banner Ad Loaded at index $adIndex");
          setState(() {
            inlineBannerAds[adIndex]?.isLoaded = true;
          });
          await _logEvent('ad_loaded', _removeNullValues({
            'variant': 'Feature B',
            'adIndex': adIndex,
          }));
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print("Inline Banner Ad Failed to Load at index $adIndex: $error");
        },
        onAdClicked: (ad) async {
          await _logEvent('ad_clicked', _removeNullValues({
            'variant': 'Feature B',
            'adIndex': adIndex,
          }));
        },
      ),
    );
    inlineBannerAds[adIndex] = InlineAd(bannerAd: inlineAd);
    inlineAd.load();
  }

  Map<String, Object>? _removeNullValues(Map<String, Object?>? original) {
    if (original == null) return null;
    final filtered = <String, Object>{};
    original.forEach((key, value) {
      if (value != null) {
        filtered[key] = value;
      }
    });
    return filtered.isEmpty ? null : filtered;
  }

  void _pageListener() {
    // Currently unused. Placeholder for future enhancements if needed.
  }

  Future<void> _logEvent(
      String eventName, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
    } catch (e) {
      print("Error logging event: $e");
    }
  }

  Widget _buildBannerAdWidget() {
    if (!_isBannerAdLoaded) return SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
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
                Navigator.of(context).pop();
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
        BottomNavigationBarItem(
            icon: Icon(Icons.photo_album), label: "Gallery"),
        BottomNavigationBarItem(
            icon: Icon(Icons.video_library), label: "Reels"),
        BottomNavigationBarItem(
            icon: Icon(Icons.flash_on), label: "PowerZone"),
      ],
      onTap: (index) {
        if (_routes[index] == '/reels') return;

        Navigator.pushReplacementNamed(context, _routes[index]!);
        _logEvent('navigation',
            _removeNullValues({'destination': _routes[index]!}));
      },
    );
  }

  void _showReportOptions(String uid, String imageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Report Image",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE17055)),
                ),
                SizedBox(height: 10),
                ListTile(
                  leading:
                  Icon(Icons.fastfood, color: Color(0xFFE17055)),
                  title: Text("Not homecooked food"),
                  onTap: () {
                    _reportImage(uid, imageId, "Not homecooked food");
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading:
                  Icon(Icons.report, color: Color(0xFFE17055)),
                  title: Text("Inappropriate image"),
                  onTap: () {
                    _reportImage(uid, imageId, "Inappropriate image");
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reportImage(
      String uid, String imageId, String reason) async {
    if (currentUser == null) return;

    try {
      Map<String, dynamic>? reel = reelsData.firstWhere(
              (reel) => reel["uid"] == uid && reel["imageId"] == imageId,
          orElse: () => {});
      String imageUrl = reel["url"] ?? "";

      setState(() {
        reelsData.removeWhere(
                (reel) => reel["uid"] == uid && reel["imageId"] == imageId);
        reportedImageIds.add(imageId);
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList(
          'reportedImages_${currentUser?.uid}', reportedImageIds.toList());

      DatabaseReference reportedRef =
      FirebaseDatabase.instance.ref().child("reported").push();
      await reportedRef.set({
        "imageUrl": imageUrl,
        "reason": reason,
        "reportedAt": DateTime.now().toIso8601String(),
        "reportedBy": currentUser!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image reported successfully.")),
      );

      await _logEvent('image_reported', _removeNullValues({
        'uid': uid,
        'imageId': imageId,
        'reason': reason,
      }));
    } catch (e) {
      print("Error reporting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to report image. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logUsageTime() async {
    if (_isLogged || currentUser == null || _pageEnterTime == null) return;
    _isLogged = true;
    DateTime now = DateTime.now();
    Duration duration = now.difference(_pageEnterTime!);
    int timeSpentSeconds = duration.inSeconds;
    String timestamp = now.toIso8601String();
    String userEmail = currentUser!.email ?? "unknown";

    String sanitizedEmail = userEmail.replaceAll('.', ',');

    DatabaseReference usageLogsRef =
    FirebaseDatabase.instance.ref().child("usageLogs").child(sanitizedEmail);

    await usageLogsRef.push().set({
      "timeSpentSeconds": timeSpentSeconds,
      "timestamp": timestamp,
    });

    print(
        "Logged usage for $userEmail: $timeSpentSeconds seconds at $timestamp");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _logUsageTime();
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
      bottomNavigationBar: adsFeatureFlag == 0 && _isBannerAdLoaded
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBannerAdWidget(),
          _buildBottomNavigationBar(),
        ],
      )
          : _buildBottomNavigationBar(),
      backgroundColor: Colors.black,
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
          : PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: adsFeatureFlag == 1
            ? reelsData.length + (reelsData.length ~/ 5)
            : reelsData.length,
        itemBuilder: (context, index) {
          if (adsFeatureFlag == 1 && index % 6 == 5) {
            int adIndex = index ~/ 6;

            if (!inlineBannerAds.containsKey(adIndex)) {
              _loadInlineBannerAd(adIndex);
            }

            InlineAd? inlineAd = inlineBannerAds[adIndex];

            return AdReelCard(
              inlineAd: inlineAd,
            );
          } else {
            int reelIndex =
            adsFeatureFlag == 1 ? index - (index ~/ 6) : index;
            final reel = reelsData[reelIndex];
            return ReelCard(
              reel: reel,
              currentUser: currentUser!,
              onReport: _showReportOptions,
            );
          }
        },
      ),
    );
  }
}
