import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dating_app/view/HomePage.dart';
import 'package:dating_app/view/LoginPage.dart';
import 'package:dating_app/view/ProfilePage.dart';
import 'package:dating_app/view/RegistrationPage.dart';
import 'package:dating_app/view/SwipePage.dart';
import 'package:dating_app/view/ProfileSetupPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(DatingApp());
}

class DatingApp extends StatelessWidget {
  const DatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dating App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      routes: {
        '/swipe': (context) => SwipePage(),
        '/profile': (context) => ProfilePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/profileSetup': (context) => ProfileSetupPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
