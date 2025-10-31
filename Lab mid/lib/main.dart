// ...existing code...
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/patient_provider.dart';
import 'screens/home_screen.dart';
import 'database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
      ],
      child: MaterialApp(
        title: 'Healthcare Dashboard',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final db = DatabaseHelper();
    final doctors = await db.getDoctors();
    final patients = await db.getPatients();

    // populate providers
    Provider.of<DoctorProvider>(context, listen: false).setDoctors(doctors);
    Provider.of<PatientProvider>(context, listen: false).setPatients(patients);

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return HomeScreen();
  }
}
