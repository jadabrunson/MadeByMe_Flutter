import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class PowerZone extends StatefulWidget {
  @override
  _PowerZoneState createState() => _PowerZoneState();
}

class _PowerZoneState extends State<PowerZone> {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  int _currentIndex = 4; // Set the initial index to PowerZone (assuming it's the 5th tab)

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  // Load the rewarded ad
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Google's official test ad unit ID for Rewarded Ads
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
          print('Rewarded Ad Loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('RewardedAd failed to load: $error');
          setState(() {
            _isAdLoaded = false;
          });
        },
      ),
    );
  }

  // Show the rewarded ad
  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        print('User earned reward: ${reward.amount} ${reward.type}');
        _freezeStreak();
      });

      // Dispose of the ad after showing and load a new one for next time
      _rewardedAd = null;
      _loadRewardedAd();
    } else {
      print('RewardedAd not ready');
    }
  }

  // Logic to freeze the streak for the day
  void _freezeStreak() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Your streak has been frozen for today!")),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PowerZone'),
        backgroundColor: Color(0xFFE17055),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Text(
              "Need to take a break but don’t want to lose your streak? Watch an ad to freeze it for a day.",
              style: TextStyle(
                color: Color(0xFF8D6E63),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isAdLoaded ? _showRewardedAd : null,
              child: Text("Watch Ad to Freeze Streak"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE17055),
                foregroundColor: Colors.white,
              ),
            ),
            if (!_isAdLoaded)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Loading ad... please wait.",
                  style: TextStyle(color: Color(0xFF8D6E63)),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFFF6E6CC),
        selectedItemColor: Color(0xFFE17055),
        unselectedItemColor: Color(0xFF8D6E63),
        currentIndex: _currentIndex, // Dynamically set the currentIndex
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
            icon: Icon(Icons.flash_on), // Lightning bolt icon for PowerZone
            label: "PowerZone", // PowerZone tab label
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update currentIndex when tapping on tabs
          });

          if (index == 0) {
            Navigator.pushNamed(context, '/main');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/leaderboard');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/gallery');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/reels');
          } else if (index == 4) {
            // No navigation needed for PowerZone since it's already the current screen
          }
        },
      ),
    );
  }
}
