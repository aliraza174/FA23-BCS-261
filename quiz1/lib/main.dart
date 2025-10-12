import 'package:flutter/material.dart';
import 'dice_screen.dart';

void main() {
  runApp(const DiceApp());
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Roller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins', // Using custom font
      ),
      home: const DiceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}