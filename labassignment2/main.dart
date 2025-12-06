import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';

// ---------------------------------------------------------
// MODEL: GameResult
// ---------------------------------------------------------
class GameResult {
  int? id;
  int guess;
  String status;
  String timestamp;

  GameResult({
    this.id,
    required this.guess,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guess': guess,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      id: map['id'],
      guess: map['guess'],
      status: map['status'],
      timestamp: map['timestamp'],
    );
  }
}

// ---------------------------------------------------------
// DATABASE HELPER
// ---------------------------------------------------------
class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initializeDB();
    return _db!;
  }

  Future<Database> initializeDB() async {
    String path = join(await getDatabasesPath(), 'results.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
        CREATE TABLE results (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          guess INTEGER,
          status TEXT,
          timestamp TEXT
        )
        """);
      },
    );
  }

  Future<int> insertResult(GameResult result) async {
    final database = await db;
    return await database.insert("results", result.toMap());
  }

  Future<List<GameResult>> getResults() async {
    final database = await db;
    final data = await database.query("results", orderBy: "id DESC");
    return data.map((e) => GameResult.fromMap(e)).toList();
  }

  Future<void> deleteAll() async {
    final database = await db;
    await database.delete("results");
  }
}

// ---------------------------------------------------------
// MAIN APP
// ---------------------------------------------------------
void main() {
  runApp(NumberGuessingApp());
}

class NumberGuessingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Number Guessing Game",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

// ---------------------------------------------------------
// HOME SCREEN
// ---------------------------------------------------------
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController guessController = TextEditingController();
  int randomNumber = Random().nextInt(100) + 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Number Guessing Game")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Guess the secret number (1 to 100)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            TextField(
              controller: guessController,
              decoration: InputDecoration(
                labelText: "Enter your guess",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (guessController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter a number")));
                  return;
                }

                int guess = int.parse(guessController.text);
                String status = "";

                if (guess == randomNumber) {
                  status = "Correct!";
                } else if (guess > randomNumber) {
                  status = "Too High!";
                } else {
                  status = "Too Low!";
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(
                      guess: guess,
                      answer: randomNumber,
                      status: status,
                    ),
                  ),
                );
              },
              child: Text("Submit Guess"),
            ),

            SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => HistoryScreen()));
              },
              child: Text("View History"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// RESULT SCREEN
// ---------------------------------------------------------
class ResultScreen extends StatelessWidget {
  final int guess;
  final int answer;
  final String status;

  ResultScreen({
    required this.guess,
    required this.answer,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    DBHelper().insertResult(
      GameResult(
        guess: guess,
        status: status,
        timestamp: DateTime.now().toString(),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text("Result")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Your Guess: $guess", style: TextStyle(fontSize: 24)),
            Text("Result: $status",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text("Correct Number: $answer", style: TextStyle(fontSize: 22)),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // go back
              },
              child: Text("Play Again"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// HISTORY SCREEN
// ---------------------------------------------------------
class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GameResult> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  void loadHistory() async {
    history = await DBHelper().getResults();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("History"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              await DBHelper().deleteAll();
              loadHistory();
            },
          ),
        ],
      ),
      body: history.isEmpty
          ? Center(child: Text("No history found"))
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return ListTile(
            title: Text("Guess: ${item.guess}"),
            subtitle: Text("Result: ${item.status}\n${item.timestamp}"),
          );
        },
      ),
    );
  }
}
