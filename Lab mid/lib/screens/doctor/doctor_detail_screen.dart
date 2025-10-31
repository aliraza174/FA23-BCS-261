import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/doctor_provider.dart';
import '../../providers/patient_provider.dart';
import '../../database/database_helper.dart';
import '../../models/doctor.dart';
import 'add_edit_doctor_screen.dart';
import '../patient/patient_detail_screen.dart';

/// Redesigned, simpler and stable Doctor detail UI.
/// - Replaces complex Sliver layout with a scrollable, responsive layout
/// - Keeps full-screen image preview, edit & delete flows
/// - Clear contact/about cards and a stable patient list
class DoctorDetailScreen extends StatefulWidget {
  final int doctorId;
  const DoctorDetailScreen({Key? key, required this.doctorId})
    : super(key: key);

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  ImageProvider? _getImageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return NetworkImage(path);
    }
    try {
      final f = File(path);
      if (f.existsSync()) return FileImage(f);
    } catch (_) {}
    return null;
  }

  void _showFullImage(BuildContext context, String? path) {
    final img = _getImageProvider(path);
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

  Future<void> _deleteDoctor(BuildContext context, int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete doctor'),
        content: Text('Delete "$name" permanently? This cannot be undone.'),
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

    if (confirm == true) {
      final db = DatabaseHelper();
      await db.deleteDoctor(id);
      Provider.of<DoctorProvider>(context, listen: false).deleteDoctor(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Doctor deleted')));
        Navigator.of(context).pop();
      }
    }
  }

  Widget _patientTile(BuildContext c, dynamic p) {
    final avatar = (p.imagePath != null && p.imagePath!.isNotEmpty)
        ? _getImageProvider(p.imagePath)
        : null;
    return ListTile(
      onTap: () {
        if (p.id != null) {
          Navigator.push(
            c,
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(patientId: p.id!),
            ),
          );
        }
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[200],
        backgroundImage: avatar,
        child: avatar == null ? Text((p.name ?? 'U')[0].toUpperCase()) : null,
      ),
      title: Text(p.name ?? 'Unknown'),
      subtitle: Text('Age: ${p.age ?? 'N/A'}'),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = Provider.of<DoctorProvider>(
      context,
    ).getById(widget.doctorId);
    final patients = Provider.of<PatientProvider>(
      context,
    ).getByDoctor(widget.doctorId);

    if (doctor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doctor')),
        body: const Center(child: Text('Doctor not found')),
      );
    }

    final img = _getImageProvider(doctor.imagePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(doctor.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditDoctorScreen(doctor: doctor),
                ),
              );
            },
            tooltip: 'Edit',
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete')
                _deleteDoctor(context, doctor.id!, doctor.name);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top image / hero
            GestureDetector(
              onTap: () => _showFullImage(context, doctor.imagePath),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  image: img != null
                      ? DecorationImage(image: img, fit: BoxFit.cover)
                      : null,
                ),
                child: img == null
                    ? Center(
                        child: Text(
                          doctor.name.isNotEmpty
                              ? doctor.name[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            fontSize: 56,
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
            ),

            // Avatar overlapping
            Transform.translate(
              offset: const Offset(0, -36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      backgroundImage: img,
                      child: img == null
                          ? Text(
                              doctor.name.isNotEmpty
                                  ? doctor.name[0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                fontSize: 36,
                                color: Colors.teal,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & specialties
                  Center(
                    child: Column(
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          doctor.specialties,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Chip(
                              label: Text('${doctor.yearsExperience ?? 0} yrs'),
                              backgroundColor: Colors.teal.shade50,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text('${patients.length} patients'),
                              backgroundColor: Colors.teal.shade50,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contact card: full width
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              Flexible(child: Text(doctor.phone ?? 'N/A')),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 16,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              Flexible(child: Text(doctor.email ?? 'N/A')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Patients card: now full width like Contact
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Patients',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${patients.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextButton.icon(
                                onPressed: null,
                                icon: Icon(Icons.person_add),
                                label: Text('Assign'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // About section (already full width) - ensure same styling
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            doctor.bio ?? 'No bio provided',
                            style: const TextStyle(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Patients header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assigned Patients',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // if you have a dedicated add patient screen, navigate there.
                          // For now, reuse edit doctor to keep flow simple.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddEditDoctorScreen(doctor: doctor),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Patients list
                  if (patients.isEmpty)
                    Center(
                      child: Column(
                        children: const [
                          SizedBox(height: 24),
                          Icon(Icons.person_off, size: 72, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No patients assigned',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: patients.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (ctx, i) => _patientTile(ctx, patients[i]),
                    ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),

      // Primary floating action to edit; delete available in appbar menu
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditDoctorScreen(doctor: doctor),
          ),
        ),
        icon: const Icon(Icons.edit),
        label: const Text('Edit'),
      ),
    );
  }
}
