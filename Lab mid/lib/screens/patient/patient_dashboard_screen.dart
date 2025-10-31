import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/patient_card.dart';
import 'add_edit_patient_screen.dart';
import 'patient_detail_screen.dart';
import '../../database/database_helper.dart';
import '../../models/patient.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({Key? key}) : super(key: key);

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete patient?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patients = Provider.of<PatientProvider>(context).patients;

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Dashboard')),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (ctx, i) {
          final Patient patient = patients[i];
          final pid = patient.id;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ListTile(
              onTap: pid != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetailScreen(patientId: pid),
                      ),
                    )
                  : null,
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Text(
                  (patient.name.isNotEmpty ? patient.name[0] : 'U')
                      .toUpperCase(),
                ),
              ),
              title: Text(patient.name),
              subtitle: Text('Age: ${patient.age ?? "N/A"}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditPatientScreen(patient: patient),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirmed = await _confirmDelete(
                      context,
                      patient.name,
                    );
                    if (confirmed == true && pid != null) {
                      final db = DatabaseHelper();
                      await db.deletePatient(pid);
                      Provider.of<PatientProvider>(
                        context,
                        listen: false,
                      ).deletePatient(pid);
                      if (ScaffoldMessenger.maybeOf(context) != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient deleted')),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditPatientScreen()),
        ),
      ),
    );
  }
}
