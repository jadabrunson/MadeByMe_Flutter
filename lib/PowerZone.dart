import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PowerZone extends material.StatefulWidget {
  @override
  _PowerZoneState createState() => _PowerZoneState();
}

class _PowerZoneState extends material.State<PowerZone> {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  int _currentIndex = 4;
  double groupProgress = 0.0;
  int userContribution = 0;
  final int targetMeals = 6;
  double amount = 5.0;
  Map<String, dynamic>? intentPaymentData;
  final DatabaseReference _challengeRef =
  FirebaseDatabase.instance.ref().child("weeklyChallenge");
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;

  // Stripe secret key (Replace with your Stripe secret key)
  final String secretKey = "sk_test_51..."; // Replace with your actual secret key

  // Ad Unit ID
  final String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test Ad Unit ID

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _loadRewardedAd();
    _initializeData();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> showPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text("Payment successful!")),
      );
    } on StripeException catch (error) {
      if (kDebugMode) {
        print(error);
      }
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text("Payment cancelled.")),
      );
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text("Payment failed.")),
      );
    }
  }

  Future<void> paymentSheetInitialization(double amountToCharge, String currency) async {
    try {
      final paymentIntent = await _createPaymentIntent(amountToCharge, currency);
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent["client_secret"],
          merchantDisplayName: "MadeByMe",
        ),
      );
      showPaymentSheet();
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text("Payment sheet initialization failed.")),
      );
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(double amount, String currency) async {
    try {
      final body = {
        "amount": (amount * 100).toInt().toString(), // Convert to cents
        "currency": currency,
        "payment_method_types[]": "card",
      };
      final response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        headers: {
          "Authorization": "Bearer $secretKey",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );
      return jsonDecode(response.body);
    } catch (error) {
      throw Exception("Failed to create payment intent: $error");
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          setState(() {
            _isRewardedAdLoaded = false;
          });
        },
      ),
    );
  }

  Future<void> _initializeData() async {
    await _initializeGroupProgress();
    await _loadUserContribution();
  }

  Future<void> _initializeGroupProgress() async {
    try {
      final snapshot = await _challengeRef.child("contributions").get();
      if (snapshot.exists) {
        int totalContributions = snapshot.children
            .map((child) => child.child("userContribution").value as int? ?? 0)
            .fold(0, (sum, value) => sum + value);

        setState(() {
          groupProgress = (totalContributions / targetMeals).clamp(0.0, 1.0);
        });
      } else {
        setState(() {
          groupProgress = 0.0;
        });
      }
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
    }
  }

  Future<void> _loadUserContribution() async {
    if (currentUser != null) {
      try {
        final snapshot = await _challengeRef
            .child("contributions")
            .child(currentUser!.uid)
            .child("userContribution")
            .get();
        if (snapshot.exists) {
          setState(() {
            userContribution = snapshot.value as int;
          });
        }
      } catch (error) {
        if (kDebugMode) {
          print(error);
        }
      }
    }
  }

  void _displayRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          material.ScaffoldMessenger.of(context).showSnackBar(
            material.SnackBar(content: material.Text("Streak frozen for today!")),
          );
        },
      );
      setState(() {
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
      });
      _loadRewardedAd();
    } else {
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text("Ad not ready. Try again later.")),
      );
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      appBar: material.AppBar(
        title: material.Text("PowerZone"),
        backgroundColor: material.Color(0xFFE17055),
      ),
      body: material.SingleChildScrollView(
        padding: const material.EdgeInsets.all(16.0),
        child: material.Column(
          children: [
            material.Text(
              "Welcome to the PowerZone!",
              style: material.TextStyle(
                fontSize: 24,
                fontWeight: material.FontWeight.bold,
                color: material.Color(0xFF5D4037),
              ),
            ),
            material.SizedBox(height: 20),
            _buildWeeklyChallengeCard(),
            material.SizedBox(height: 30),
            material.ElevatedButton(
              onPressed: _isRewardedAdLoaded ? _displayRewardedAd : null,
              child: material.Text("Watch Ad to Freeze Streak"),
            ),
            material.ElevatedButton(
              onPressed: () => paymentSheetInitialization(amount, "USD"),
              child: material.Text("Remove Ads (\$5.00)"),
              style: material.ElevatedButton.styleFrom(
                backgroundColor: material.Color(0xFF5D4037),
                foregroundColor: material.Colors.white,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  material.Widget _buildWeeklyChallengeCard() {
    return material.Card(
      color: material.Color(0xFFF6E6CC),
      shape: material.RoundedRectangleBorder(borderRadius: material.BorderRadius.circular(12)),
      elevation: 4,
      child: material.Padding(
        padding: const material.EdgeInsets.all(16.0),
        child: material.Column(
          children: [
            material.Text(
              "Weekly Challenge: Vegan Recipes!",
              style: material.TextStyle(
                color: material.Color(0xFF5D4037),
                fontSize: 20,
                fontWeight: material.FontWeight.bold,
              ),
            ),
            material.SizedBox(height: 10),
            material.Text(
              "Sponsored by Fresh Mart - Complete to earn a 10% grocery discount!",
              textAlign: material.TextAlign.center,
              style: material.TextStyle(color: material.Color(0xFF8D6E63)),
            ),
            material.SizedBox(height: 20),
            material.LinearProgressIndicator(
              value: groupProgress,
              minHeight: 12,
              backgroundColor: material.Color(0xFFEEE5D5),
              color: material.Color(0xFFE17055),
            ),
            material.SizedBox(height: 10),
            material.Text(
              "Group Progress: ${(groupProgress * 100).toInt()}%",
              style: material.TextStyle(
                  color: material.Color(0xFF8D6E63), fontWeight: material.FontWeight.w500),
            ),
            material.SizedBox(height: 10),
            material.Text(
              "Your Contribution: $userContribution meals",
              style: material.TextStyle(color: material.Color(0xFF5D4037)),
            ),
          ],
        ),
      ),
    );
  }

  material.Widget _buildBottomNavigationBar() {
    return material.BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: material.Color(0xFFE17055),
      unselectedItemColor: material.Color(0xFF8D6E63),
      items: [
        material.BottomNavigationBarItem(icon: material.Icon(material.Icons.home), label: "Home"),
        material.BottomNavigationBarItem(icon: material.Icon(material.Icons.leaderboard), label: "Leaderboard"),
        material.BottomNavigationBarItem(icon: material.Icon(material.Icons.photo_album), label: "Gallery"),
        material.BottomNavigationBarItem(icon: material.Icon(material.Icons.video_library), label: "Reels"),
        material.BottomNavigationBarItem(icon: material.Icon(material.Icons.flash_on), label: "PowerZone"),
      ],
    );
  }
}
