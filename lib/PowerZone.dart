import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PowerZone extends StatefulWidget {
  @override
  _PowerZoneState createState() => _PowerZoneState();
}

class _PowerZoneState extends State<PowerZone> {
  RewardedAd? _rewardedAd; // Replace BannerAd with RewardedAd
  bool _isRewardedAdLoaded = false; // Track if the Rewarded Ad is loaded
  int _currentIndex = 4; // Set the initial index to PowerZone
  double groupProgress = 0.0; // Initialize group progress at 0
  int userContribution = 0; // Initialize user contribution at 0
  final int targetMeals = 6; // Set target meals for 100% progress
  final DatabaseReference _challengeRef =
  FirebaseDatabase.instance.ref().child("weeklyChallenge");
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  bool _adRemoved = false;
  final mockProduct = ProductDetails(
    id: 'remove_ads',
    title: 'Remove Ads',
    description: 'Remove all ads from the app',
    price: '\$5.00', // Mock price
    rawPrice: 5.00,
    currencyCode: 'USD',
  );
  List<ProductDetails> _products = [];
  bool _purchasePending = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  static const Set<String> _productIds = {'remove_ads'};

  // Define the test Rewarded Ad Unit ID
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // Test Rewarded Ad Unit ID

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _loadRewardedAd(); // Prepare the Rewarded Ad on initialization
    _initializeData();
  }

  void _initializeInAppPurchases() async {
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);

    if (response.error == null && response.productDetails.isNotEmpty) {
      setState(() {
        _products.add(mockProduct);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load products")));
    }
  }
  void _buyProduct(ProductDetails product) {
    print("Simulating purchase for product: ${product.id}");
    setState(() {
      _adRemoved = true; // Simulate removing ads
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Purchase successful: ${product.title}")),
    );
  }

  // Handle purchase updates
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Purchase Successful! Ads Removed")),
        );
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Purchase Failed")),
        );
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }

    setState(() {
      _purchasePending = false;
    });
  }

  // Load a Rewarded Ad for testing
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId, // Use the correct test Rewarded Ad Unit ID
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          });
          print('Rewarded Ad Loaded successfully');
          _setRewardedAdCallbacks(); // Set callbacks for the loaded ad
        },
        onAdFailedToLoad: (error) {
          print('RewardedAd failed to load: $error');
          setState(() {
            _isRewardedAdLoaded = false;
          });
        },
      ),
    );
  }

  // Set callbacks for the Rewarded Ad
  void _setRewardedAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('Rewarded Ad dismissed');
        ad.dispose();
        setState(() {
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
        });
        _loadRewardedAd(); // Load a new ad for future use
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Rewarded Ad failed to show: $error');
        ad.dispose();
        setState(() {
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
        });
        _loadRewardedAd(); // Load a new ad for future use
      },
    );
  }

  // Initialize challenge data from Firebase
  Future<void> _initializeData() async {
    await _initializeGroupProgress();
    await _loadUserContribution();
  }

  // Initialize or load group progress
  Future<void> _initializeGroupProgress() async {
    try {
      final contributionsSnapshot =
      await _challengeRef.child("contributions").get();
      if (contributionsSnapshot.exists) {
        int totalContributions = contributionsSnapshot.children
            .map((snapshot) =>
        snapshot.child("userContribution").value as int? ?? 0)
            .fold(0, (sum, value) => sum + value);

        setState(() {
          // Calculate progress based on target meals
          groupProgress = (totalContributions / targetMeals).clamp(0.0, 1.0);
        });
        print("Initial groupProgress loaded: ${groupProgress * 100}%");
      } else {
        // If groupProgress doesn't exist, initialize it to 0
        setState(() {
          groupProgress = 0.0;
        });
        print("Initialized groupProgress to 0");
      }
    } catch (e) {
      print("Error initializing groupProgress: $e");
    }
  }

  // Load initial user contribution
  Future<void> _loadUserContribution() async {
    if (currentUser != null) {
      try {
        final userContributionSnapshot = await _challengeRef
            .child("contributions")
            .child(currentUser!.uid)
            .child("userContribution")
            .get();

        if (userContributionSnapshot.exists) {
          setState(() {
            userContribution = userContributionSnapshot.value as int;
          });
          print("Initial userContribution loaded: $userContribution");
        }
      } catch (e) {
        print("Error loading initial user contribution: $e");
      }
    }
  }

  // Show the Rewarded Ad when user clicks the button
  void _displayRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          _freezeStreak(); // Call streak freeze after earning the reward
        },
      );
      // After showing the ad, set the ad to null and load a new one
      setState(() {
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
      });
      _loadRewardedAd(); // Load a new ad for future use
    } else {
      print('Rewarded Ad is not loaded yet.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text("Ad is not ready yet. Please try again later.")),
      );
    }
  }

  // Logic to freeze the streak for the day
  void _freezeStreak() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Your streak has been frozen for today!")),
    );
    // You can also update Firebase or local state here as needed
  }

  // Logout functionality
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navigate to the login screen after logout
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Handle errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error signing out. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Confirmation dialog for logout
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
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose(); // Dispose of the Rewarded Ad when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _products.add(mockProduct);
    return Scaffold(
      appBar: AppBar(
        title: Text('PowerZone'),
        backgroundColor: Color(0xFFE17055),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Welcome to the PowerZone!",
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // Weekly Group Challenge Section
            _buildWeeklyChallengeCard(),

            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isRewardedAdLoaded ? _displayRewardedAd : null,
              child: Text("Watch Ad to Freeze Streak"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE17055),
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _buyProduct(_products[0]);
              },
              child: Text("Remove Ads - ${_products[0].price}"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5D4037),
                foregroundColor: Colors.white,
              ),
            ),
            if (!_isRewardedAdLoaded)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Loading ad... please wait.",
                  style: TextStyle(color: Color(0xFF8D6E63)),
                ),
              ),

            // Optionally, you can show a placeholder or additional UI elements here
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Build the Weekly Challenge Card
  Widget _buildWeeklyChallengeCard() {
    return Card(
      color: Color(0xFFF6E6CC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Weekly Challenge: Vegan Recipes!",
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Sponsored by Fresh Mart - Complete to earn a 10% grocery discount!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8D6E63)),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: groupProgress,
              minHeight: 12,
              backgroundColor: Color(0xFFEEE5D5),
              color: Color(0xFFE17055),
            ),
            SizedBox(height: 10),
            Text(
              "Group Progress: ${(groupProgress * 100).toInt()}%",
              style: TextStyle(
                  color: Color(0xFF8D6E63), fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),
            Text(
              "Your Contribution: $userContribution meals",
              style: TextStyle(color: Color(0xFF5D4037)),
            ),
          ],
        ),
      ),
    );
  }
  // Bottom Navigation Bar with navigation logic
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Color(0xFFF6E6CC),
      selectedItemColor: Color(0xFFE17055),
      unselectedItemColor: Color(0xFF8D6E63),
      currentIndex: _currentIndex,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard), label: "Leaderboard"),
        BottomNavigationBarItem(icon: Icon(Icons.photo_album), label: "Gallery"),
        BottomNavigationBarItem(
            icon: Icon(Icons.video_library), label: "Reels"),
        BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: "PowerZone"),
      ],
      onTap: (index) {
        if (index == _currentIndex) return; // Do nothing if tapped on the current page

        setState(() {
          _currentIndex = index;
        });

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/main');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/leaderboard');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/gallery');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/reels');
            break;
          case 4:
          // Current page, no navigation needed
            break;
        }
      },
    );
  }
}