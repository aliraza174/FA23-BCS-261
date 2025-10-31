// ...existing code...
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/doctor.dart';
import '../database/database_helper.dart';
import '../providers/doctor_provider.dart';
import '../screens/doctor/add_edit_doctor_screen.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final hasImage = doctor.imagePath != null && doctor.imagePath!.isNotEmpty;
    final hasScheme =
        hasImage && (Uri.tryParse(doctor.imagePath!)?.hasScheme ?? false);

    Widget avatar = CircleAvatar(
      radius: 28,
      backgroundColor: Colors.grey[200],
      backgroundImage: hasImage
          ? (hasScheme
                ? Image.network(doctor.imagePath!).image
                : FileImage(File(doctor.imagePath!)) as ImageProvider)
          : null,
      child: !hasImage
          ? Icon(Icons.person, size: 28, color: Colors.grey[700])
          : null,
    );

    final specialties = (doctor.specialties ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            avatar,
            SizedBox(width: 12),
            // main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // name + small subtitle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doctor.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // experience badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${doctor.yearsExperience ?? 0} yrs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  // specialties chips / wrap
                  if (specialties.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: specialties.take(4).map((s) {
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          label: Text(s, style: TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                  SizedBox(height: 8),
                  // contact row
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          doctor.phone ?? 'No phone',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.email, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          doctor.email ?? 'No email',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // three dots menu centered vertically
            Container(
              width: 44,
              alignment: Alignment.center,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                tooltip: 'Options',
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditDoctorScreen(doctor: doctor),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Delete doctor?'),
                        content: Text(
                          'Are you sure you want to delete "${doctor.name}"? Assigned patients will be unassigned.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (doctor.id == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cannot delete doctor without id'),
                          ),
                        );
                        return;
                      }
                      final db = DatabaseHelper();
                      await db.deleteDoctor(doctor.id!);
                      Provider.of<DoctorProvider>(
                        context,
                        listen: false,
                      ).deleteDoctor(doctor.id!);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Doctor deleted')));
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
