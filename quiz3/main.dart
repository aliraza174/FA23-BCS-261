import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// -------------------------------------------------------------
// SQLITE HELPER
// -------------------------------------------------------------
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      p.join(await getDatabasesPath(), "guess.db"),
      version: 1,
      onCreate: (db, version) {
        return db.execute(
            "CREATE TABLE results("
                "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                "guess INTEGER, "
                "result TEXT, "
                "time TEXT)"
        );
      },
    );

    return _db!;
  }

  Future<void> insertResult(int guess, String result) async {
    final db = await database;

    await db.insert("results", {
      "guess": guess,
      "result": result,
      "time": DateTime.now().toString(),
    });
  }

  Future<List<Map<String, dynamic>>> getResults() async {
    final db = await database;

    return db.query("results", orderBy: "id DESC");
  }
}

// -------------------------------------------------------------
// MAIN
// -------------------------------------------------------------
void main() {
  runApp(GuessApp());
}

// -------------------------------------------------------------
// APP ROOT
// -------------------------------------------------------------
class GuessApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Number Guessing Game",
      home: HomeScreen(),
    );
  }
}

// -------------------------------------------------------------
// HOME SCREEN
// -------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController controller = TextEditingController();
  int randomNumber = Random().nextInt(50) + 1;

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void checkGuess() async {
    if (controller.text.isEmpty) {
      showMsg("Enter a number!");
      return;
    }

    int guess = int.tryParse(controller.text) ?? -1;

    if (guess < 1) {
      showMsg("Invalid number!");
      return;
    }

    String result;

    if (guess == randomNumber) {
      result = "Correct!";
    } else if (guess > randomNumber) {
      result = "Too High!";
    } else {
      result = "Too Low!";
    }

    // Save result
    await DBHelper().insertResult(guess, result);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result),
      ),
    );

    setState(() {
      randomNumber = Random().nextInt(50) + 1;
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guess The Number"),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryScreen()),
              );
            },
          )
        ],
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Guess a number between 1 and 50",
                style: TextStyle(fontSize: 20),
              ),

              SizedBox(height: 20),

              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter number",
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: checkGuess,
                child: Text("Guess"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// RESULT SCREEN
// -------------------------------------------------------------
class ResultScreen extends StatelessWidget {
  final String result;

  ResultScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Result")),
      body: Center(
        child: Text(
          result,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// HISTORY SCREEN
// -------------------------------------------------------------
class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    data = await DBHelper().getResults();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Guess History")),
      body: data.isEmpty
          ? Center(child: Text("No history yet"))
          : ListView.builder(
        itemCount: data.length,
        itemBuilder: (_, i) {
          return Card(
            child: ListTile(
              title: Text("Guess: ${data[i]['guess']}"),
              subtitle: Text(
                "${data[i]['result']}  •  ${data[i]['time']}",
              ),
            ),
          );
        },
      ),
    );
  }
}
