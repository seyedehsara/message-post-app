import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tabbed_home_screen.dart'; 

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final provider = GoogleAuthProvider();

      // Use the built-in popup sign-in method for web
      await FirebaseAuth.instance.signInWithPopup(provider);

      // Navigate to the new tabbed home screen after login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TabbedHomeScreen()),
      );
    } catch (e) {
      print("Google sign-in error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => signInWithGoogle(context),
          child: const Text("Sign in with Google"),
        ),
      ),
    );
  }
}
