import 'package:flutter/material.dart';
import 'dart:math';

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  // Variable to hold the current dice number (1-6)
  int diceNumber = 1;
  
  // Random number generator
  final Random random = Random();

  // Method to roll the dice
  void rollDice() {
    setState(() {
      // Generate random number between 1 and 6
      diceNumber = random.nextInt(6) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Dice Roller',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              'Tap the dice to roll!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Dice Image (Tap to roll)
            GestureDetector(
              onTap: rollDice,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/dice$diceNumber.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Current dice number display
            Text(
              'Current: $diceNumber',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Roll Button (alternative way to roll)
            ElevatedButton(
              onPressed: rollDice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text('Roll Dice'),
            ),
          ],
        ),
      ),
    );
  }
}