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

        data.forEach((uid, userData) {
          if (userData["streaks"] != null) {
            String email = userData["email"] ?? "Unknown";
            int maxStreak = userData["streaks"]["maxStreak"] ?? 0;

            fetchedData.add({"email": email, "maxStreak": maxStreak});
          }
        });

        fetchedData.sort((a, b) => b["maxStreak"].compareTo(a["maxStreak"]));

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
          leaderboardData = fetchedData.sublist(
              0, fetchedData.length < 10 ? fetchedData.length : 10);
        });
      }
    } catch (error) {
      print("Failed to fetch leaderboard data: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load leaderboard. Please try again later."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String getUsernameFromEmail(String email) {
    return email.contains("@") ? email.split("@")[0] : email;
  }

  Future<void> _logout() async {
    try {
      await _firebaseAuth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error signing out. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      print("Error during sign out: $e");
    }
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
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text("Leaderboard"),
        backgroundColor: Color(0xFFE17055),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Text(
              userPosition,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 80.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF6E6CC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: leaderboardData.map((entry) {
                      int index = leaderboardData.indexOf(entry);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 15.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF8E7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFE17055)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFFE17055),
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              "${getUsernameFromEmail(entry['email'])}",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF5D4037),
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              "${entry['maxStreak']} days",
                              style: TextStyle(
                                  fontSize: 16, color: Color(0xFF8D6E63)),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Color(0xFFF6E6CC),
      selectedItemColor: Color(0xFFE17055),
      unselectedItemColor: Color(0xFF8D6E63),
      currentIndex: 1,
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
          icon: Icon(Icons.flash_on),
          label: "PowerZone",
        ),
      ],
      onTap: (index) {
        if (index == 1) return;

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/main');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/gallery');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/reels');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/powerzone');
            break;
          default:
            break;
        }
      },
    );
  }
}
