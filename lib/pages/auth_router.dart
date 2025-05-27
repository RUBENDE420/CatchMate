import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:catchmate/pages/home_page.dart';
import 'package:catchmate/pages/login_page.dart';

class AuthRouter extends StatelessWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomePage(); // Eingeloggt
        } else {
          return const LoginPage(); // Nicht eingeloggt
        }
      },
    );
  }
}
