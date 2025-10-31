import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../database/database_helper.dart';
import 'add_edit_patient_screen.dart';
import '../doctor/doctor_detail_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final int patientId;

  const PatientDetailScreen({Key? key, required this.patientId})
    : super(key: key);

  ImageProvider? _imageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https'))
      return NetworkImage(path);
    try {
      final f = File(path);
      if (f.existsSync()) return FileImage(f);
    } catch (_) {}
    return null;
  }

  void _showFullImage(BuildContext context, String? path) {
    final img = _imageProvider(path);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: img != null
              ? InteractiveViewer(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 700),
                    decoration: BoxDecoration(
                      image: DecorationImage(image: img, fit: BoxFit.contain),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('No image available'),
                ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete patient?'),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
        ),
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
    final patient = Provider.of<PatientProvider>(context).getById(patientId);
    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Details')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    final doctor = (patient.doctorId != null)
        ? Provider.of<DoctorProvider>(
            context,
            listen: false,
          ).getById(patient.doctorId!)
        : null;

    final img = _imageProvider(patient.imagePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(patient.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditPatientScreen(patient: patient),
                  ),
                );
              } else if (v == 'delete') {
                final ok = await _confirmDelete(context, patient.name);
                if (ok == true && patient.id != null) {
                  final db = DatabaseHelper();
                  await db.deletePatient(patient.id!);
                  Provider.of<PatientProvider>(
                    context,
                    listen: false,
                  ).deletePatient(patient.id!);
                  // use context.mounted because this is a StatelessWidget and
                  // the async callback may run after navigation changes
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Patient deleted')),
                    );
                    Navigator.of(context).pop();
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // top card with image + basic info
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullImage(context, patient.imagePath),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: img,
                        child: img == null
                            ? Text(
                                (patient.name.isNotEmpty
                                        ? patient.name[0]
                                        : 'P')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.black54,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Age: ${patient.age ?? "N/A"}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(label: Text('ID: ${patient.id ?? '-'}')),
                              if (patient.doctorId != null)
                                Chip(label: const Text('Assigned')),
                              if (patient.diagnosis != null &&
                                  patient.diagnosis!.isNotEmpty)
                                Chip(label: const Text('Has diagnosis')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // diagnosis / notes - full width card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnosis & Notes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      patient.diagnosis ?? 'No diagnosis or notes provided',
                      style: const TextStyle(height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // assigned doctor - full width card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assigned Doctor',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            doctor?.name ?? 'Unassigned',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            doctor?.specialties ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (doctor != null)
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DoctorDetailScreen(doctorId: doctor.id!),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // actions row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditPatientScreen(patient: patient),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () async {
                      final ok = await _confirmDelete(context, patient.name);
                      if (ok == true && patient.id != null) {
                        final db = DatabaseHelper();
                        await db.deletePatient(patient.id!);
                        Provider.of<PatientProvider>(
                          context,
                          listen: false,
                        ).deletePatient(patient.id!);
                        if (Navigator.of(context).canPop())
                          Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
