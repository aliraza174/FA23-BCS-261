import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/form_screen.dart';


Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
await Supabase.initialize(
url: 'https://bwycbocvqinflczteech.supabase.co',
anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3eWNib2N2cWluZmxjenRlZWNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2OTUwNTgsImV4cCI6MjA4MTI3MTA1OH0.eDAGdXjyK6F-Qenn9ypD2Xzh7rHWRZme7R-zykKJ3Ys',
);
runApp(const MyApp());
}


class MyApp extends StatelessWidget {
const MyApp({super.key});
@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Submission Form',
theme: ThemeData(primarySwatch: Colors.indigo),
home: const FormScreen(),
);
}
}