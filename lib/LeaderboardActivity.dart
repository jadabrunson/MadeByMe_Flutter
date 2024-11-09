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

  Future<void> _signOut() async {
    await _firebaseAuth.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7), // Warm Ivory
      appBar: AppBar(
        title: Text("Leaderboard"),
        backgroundColor: Color(0xFFE17055), // Burnt Orange
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Text(
              userPosition,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037), // Deep Brown
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 80.0), // Space above the bottom navigation bar
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF6E6CC), // Light Almond
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: leaderboardData.map((entry) {
                      int index = leaderboardData.indexOf(entry);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF8E7), // Warm Ivory
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFE17055)), // Burnt Orange border
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFFE17055), // Burnt Orange
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              "${getUsernameFromEmail(entry['email'])}",
                              style: TextStyle(fontSize: 18, color: Color(0xFF5D4037), fontWeight: FontWeight.w500), // Deep Brown
                            ),
                            subtitle: Text(
                              "${entry['maxStreak']} days",
                              style: TextStyle(fontSize: 16, color: Color(0xFF8D6E63)), // Soft Brown
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFFF6E6CC), // Light Almond
        selectedItemColor: Color(0xFFE17055), // Burnt Orange
        unselectedItemColor: Color(0xFF8D6E63), // Soft Brown
        currentIndex: 1, // Set the current index to 1 for the leaderboard page
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
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/main'); // Navigate to Home page
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/gallery'); // Navigate to Gallery page
          }
        },
      ),
    );
  }
}
