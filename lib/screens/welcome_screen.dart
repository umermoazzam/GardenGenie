import 'package:flutter/material.dart';

void main() {
  runApp(const PlantioApp());
}

class PlantioApp extends StatelessWidget {
  const PlantioApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/welcome.png', // <-- apni local image ka path
          fit: BoxFit.cover,           // poora screen cover kare
        ),
      ),
    );
  }
}
