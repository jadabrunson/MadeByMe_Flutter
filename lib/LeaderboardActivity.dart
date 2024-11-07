/**
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
    String currentUserUID = currentUser?.uid ?? "";
    String currentEmail = currentUser?.email ?? "";

    _usersRef.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        List<Map<String, dynamic>> fetchedData = [];

        data.forEach((key, value) {
          String email = value["email"] ?? "";
          int score = value["score"] ?? 0;
          String username = getUsernameFromEmail(email);

          fetchedData.add({"username": username, "score": score});
        });

        // Sort by score in descending order
        fetchedData.sort((a, b) => b["score"].compareTo(a["score"]));
        setState(() {
          leaderboardData = fetchedData.sublist(0, fetchedData.length < 10 ? fetchedData.length : 10);
        });

        // Determine user's rank
        int position = 1;
        bool userFound = false;
        for (var entry in fetchedData) {
          if (entry["username"] == getUsernameFromEmail(currentEmail)) {
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
      }
    }).catchError((error) {
      print("Failed to fetch leaderboard data: $error");
    });
  }

  String getUsernameFromEmail(String email) {
    return email.contains("@") ? email.split("@")[0] : email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leaderboard"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              userPosition,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final entry = leaderboardData[index];
                return ListTile(
                  title: Text(
                    "${index + 1}. ${entry['username']} - ${entry['score']} points",
                    style: TextStyle(fontSize: 16),
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

    */

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
    String currentUID = currentUser?.uid ?? "";
    String currentEmail = currentUser?.email ?? "";

    _usersRef.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        List<Map<String, dynamic>> fetchedData = [];

        // Extract users' streak counts and emails
        data.forEach((uid, userData) {
          if (userData["streaks"] != null) {
            String email = userData["email"] ?? "Unknown";
            int streakCount = userData["streaks"]["streakCount"] ?? 0;

            fetchedData.add({"email": email, "streakCount": streakCount});
          }
        });

        // Sort by streak count in descending order
        fetchedData.sort((a, b) => b["streakCount"].compareTo(a["streakCount"]));

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
    }).catchError((error) {
      print("Failed to fetch leaderboard data: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leaderboard"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              userPosition,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final entry = leaderboardData[index];
                return ListTile(
                  title: Text(
                    "${index + 1}. ${entry['email']} - ${entry['streakCount']} days",
                    style: TextStyle(fontSize: 16),
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

