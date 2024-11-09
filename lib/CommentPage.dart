import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CommentPage extends StatefulWidget {
  final String uid;
  final String imageId;

  CommentPage({required this.uid, required this.imageId});

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    DatabaseReference commentsRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(widget.uid)
        .child("images")
        .child(widget.imageId)
        .child("comments");

    final snapshot = await commentsRef.get();
    if (snapshot.exists) {
      setState(() {
        comments = (snapshot.value as Map).entries
            .map((e) => {"user": e.value["user"], "text": e.value["text"], "timestamp": e.value["timestamp"]})
            .toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    User? currentUser = _auth.currentUser;
    String timestamp = DateTime.now().toIso8601String();
    DatabaseReference commentsRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(widget.uid)
        .child("images")
        .child(widget.imageId)
        .child("comments")
        .push();

    await commentsRef.set({
      "user": currentUser!.uid,
      "text": _commentController.text,
      "timestamp": timestamp,
    });

    _commentController.clear();
    _loadComments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comments"),
        backgroundColor: Color(0xFFE17055),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE17055)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(comment["user"][0].toUpperCase())),
                  title: Text(comment["text"]),
                  subtitle: Text(comment["timestamp"]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(hintText: "Add a comment..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFFE17055)),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
