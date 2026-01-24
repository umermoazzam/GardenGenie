import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/detection_screen.dart'; // Ensure correct path

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plantio',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      // Adding routes for cleaner navigation
      routes: {
        '/plant-disease-detector': (context) => const PlantDetectionScreen(),
      },
    );
  }
}