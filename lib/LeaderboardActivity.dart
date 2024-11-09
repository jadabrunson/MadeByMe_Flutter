import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LeaderboardActivity extends StatefulWidget {
  @override
  _LeaderboardActivityState createState() => _LeaderboardActivityState();
}

class _LeaderboardActivityState extends State<LeaderboardActivity> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");

  List<Map<String, dynamic>> leaderboardData = [];
  String userPosition = "Your Position: Not ranked";

  @override
  void initState() {
    super.initState();
    fetchLeaderboardData();
  }

  Future<void> fetchLeaderboardData() async {
    final User? currentUser = _firebaseAuth.currentUser;
    String currentEmail = currentUser?.email ?? "";

    try {
      final event = await _usersRef.once();
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        List<Map<String, dynamic>> fetchedData = [];

        // Extract users' max streak counts and emails
        data.forEach((uid, userData) {
          if (userData["streaks"] != null) {
            String email = userData["email"] ?? "Unknown";
            int maxStreak = userData["streaks"]["maxStreak"] ?? 0;

            fetchedData.add({"email": email, "maxStreak": maxStreak});
          }
        });

        // Sort by max streak count in descending order
        fetchedData.sort((a, b) => b["maxStreak"].compareTo(a["maxStreak"]));

        // Determine user's rank
        int position = 1;
        bool userFound = false;
        for (var entry in fetchedData) {
          if (entry["email"] == currentEmail) {
            setState(() {
              userPosition = "Your Position: $position";
            });
            userFound = true;
            break;
          }
          position++;
        }
        if (!userFound) {
          setState(() {
            userPosition = "Your Position: Not ranked";
          });
        }

        setState(() {
          leaderboardData = fetchedData.sublist(0, fetchedData.length < 10 ? fetchedData.length : 10);
        });
      }
    } catch (error) {
      print("Failed to fetch leaderboard data: $error");
    }
  }

  // Utility function to get username from email
  String getUsernameFromEmail(String email) {
    return email.contains("@") ? email.split("@")[0] : email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7), // Warm Ivory
      appBar: AppBar(
        title: Text("Leaderboard"),
        backgroundColor: Color(0xFFE17055), // Burnt Orange
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              userPosition,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)), // Deep Brown
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final entry = leaderboardData[index];
                return ListTile(
                  title: Text(
                    "${index + 1}. ${getUsernameFromEmail(entry['email'])} - ${entry['maxStreak']} days",
                    style: TextStyle(fontSize: 16, color: Color(0xFF8D6E63)), // Soft Brown
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
