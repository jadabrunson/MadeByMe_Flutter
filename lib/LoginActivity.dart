import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class LoginActivity extends StatefulWidget {
  @override
  _LoginActivityState createState() => _LoginActivityState();
}

class _LoginActivityState extends State<LoginActivity> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool _isSignUpMode = false; // Toggle between Sign In and Sign Up modes

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  Future<void> _checkUserLoggedIn() async {
    await Firebase.initializeApp(); // Ensure Firebase is initialized
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      // Navigate to main screen if already signed in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/main');
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode; // Toggle the mode
    });
  }

  Future<void> _loginUser() async {
    setState(() {
      isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please enter email and password.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      _showMessage("Login successful!");
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password. Please try again.";
      } else {
        errorMessage = "Login failed. Please try again.";
      }
      _showMessage(errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _registerUser() async {
    setState(() {
      isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please enter email and password.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Confirm registration success
      if (userCredential.user != null) {
        _showMessage("Registration successful. Please log in.");
        _toggleMode(); // Switch to Sign In mode after successful registration
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage = "The email address is already in use by another account.";
      } else if (e.code == 'weak-password') {
        errorMessage = "The password is too weak. Please choose a stronger password.";
      } else {
        errorMessage = "Registration failed. Please try again.";
      }
      _showMessage(errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF222831),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _isSignUpMode ? 'Sign up to get started' : 'Sign in to continue',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Color(0xFF393E46),
                  prefixIcon: Icon(Icons.email, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Color(0xFF393E46),
                  prefixIcon: Icon(Icons.lock, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 24),
              isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : ElevatedButton(
                onPressed: _isSignUpMode ? _registerUser : _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF673AB7),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _isSignUpMode ? 'Sign up' : 'Sign in',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _toggleMode,
                child: Text(
                  _isSignUpMode ? "Already have an account? Sign in" : "Don't have an account? Sign up",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
