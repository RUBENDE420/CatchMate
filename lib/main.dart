import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:catchmate/pages/auth_router.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CatchMateApp());
}

class CatchMateApp extends StatelessWidget {
  const CatchMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CatchMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AuthRouter(),
    );
  }
}
