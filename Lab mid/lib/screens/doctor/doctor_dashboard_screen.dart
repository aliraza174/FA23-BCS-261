// ...existing code...
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/doctor_card.dart';
import 'add_edit_doctor_screen.dart';
import 'doctor_detail_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final doctors = Provider.of<DoctorProvider>(context).doctors;

    return Scaffold(
      appBar: AppBar(title: Text('Doctor Dashboard')),
      body: ListView.builder(
        itemCount: doctors.length,
        itemBuilder: (ctx, i) {
          final doc = doctors[i];
          return GestureDetector(
            onTap: doc.id != null
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorDetailScreen(doctorId: doc.id!),
                    ),
                  )
                : null,
            child: DoctorCard(doctor: doc),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditDoctorScreen()),
        ),
      ),
    );
  }
}
// ...existing code...