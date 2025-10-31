// filepath: d:\Project\UNI\Ali App\doctake\lib\screens\patient\add_edit_patient_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/patient_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/patient.dart';
import '../../models/doctor.dart';
import '../../database/database_helper.dart';

class AddEditPatientScreen extends StatefulWidget {
  final Patient? patient;
  const AddEditPatientScreen({Key? key, this.patient}) : super(key: key);

  @override
  _AddEditPatientScreenState createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends State<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  int? _age;
  String? _diagnosis;
  int? _selectedDoctorId;
  String? _imagePath;
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    if (p != null) {
      _name = p.name;
      _age = p.age;
      _diagnosis = p.diagnosis;
      _selectedDoctorId = p.doctorId;
      _imagePath = p.imagePath;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) setState(() => _imagePath = picked.path);
    } catch (_) {}
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imagePath != null && _imagePath!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Image',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _imagePath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      final uri = Uri.tryParse(_imagePath!);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        imageProvider = NetworkImage(_imagePath!);
      } else {
        imageProvider = FileImage(File(_imagePath!));
      }
    }

    return GestureDetector(
      onTap: _showImageOptions,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    (_name.isNotEmpty ? _name[0] : 'P').toUpperCase(),
                    style: TextStyle(fontSize: 32, color: Colors.grey.shade700),
                  )
                : null,
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Material(
              elevation: 2,
              shape: CircleBorder(),
              color: Colors.white,
              child: InkWell(
                customBorder: CircleBorder(),
                onTap: _showImageOptions,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);
    final db = DatabaseHelper();

    if (widget.patient == null) {
      final newPatient = Patient(
        id: null,
        name: _name,
        age: _age,
        diagnosis: _diagnosis,
        imagePath: _imagePath,
        doctorId: _selectedDoctorId,
      );
      final insertedId = await db.insertPatient(newPatient);
      final saved = Patient(
        id: insertedId,
        name: _name,
        age: _age,
        diagnosis: _diagnosis,
        imagePath: _imagePath,
        doctorId: _selectedDoctorId,
      );
      Provider.of<PatientProvider>(context, listen: false).addPatient(saved);
    } else {
      final updated = Patient(
        id: widget.patient!.id,
        name: _name,
        age: _age,
        diagnosis: _diagnosis,
        imagePath: _imagePath,
        doctorId: _selectedDoctorId,
      );
      await db.updatePatient(updated);
      Provider.of<PatientProvider>(
        context,
        listen: false,
      ).updatePatient(updated);
    }

    setState(() => _saving = false);
    Navigator.pop(context);
  }

  Future<void> _confirmAndDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete patient?'),
        content: Text(
          'Are you sure you want to delete "${widget.patient?.name}"?',
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

    if (confirm == true && widget.patient?.id != null) {
      final db = DatabaseHelper();
      await db.deletePatient(widget.patient!.id!);
      Provider.of<PatientProvider>(
        context,
        listen: false,
      ).deletePatient(widget.patient!.id!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patient != null;
    final doctors = Provider.of<DoctorProvider>(context).doctors;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Patient' : 'Add Patient'),
        actions: [
          if (isEdit)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') _confirmAndDelete();
                if (v == 'edit') {} // no-op: already in edit screen
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
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onSaved: (v) => _name = v?.trim() ?? '',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter name' : null,
                    onChanged: (v) => setState(() {}),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _age != null ? '$_age' : null,
                          decoration: const InputDecoration(labelText: 'Age'),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => _age = int.tryParse(v ?? ''),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 0) return 'Enter valid age';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: _selectedDoctorId,
                          decoration: const InputDecoration(
                            labelText: 'Doctor (optional)',
                          ),
                          items:
                              [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Unassigned'),
                                ),
                              ]..addAll(
                                doctors
                                    .where((d) => d.id != null)
                                    .map(
                                      (doc) => DropdownMenuItem<int?>(
                                        value: doc.id,
                                        child: Text(doc.name),
                                      ),
                                    ),
                              ),
                          onChanged: (v) =>
                              setState(() => _selectedDoctorId = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _diagnosis,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis (optional)',
                    ),
                    maxLines: 3,
                    onSaved: (v) => _diagnosis = v?.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Image (from device)',
                      hintText: _imagePath ?? 'No image selected',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveForm,
                          icon: _saving
                              ? const SizedBox.shrink()
                              : const Icon(Icons.save),
                          label: Text(_saving ? 'Saving...' : 'Save'),
                        ),
                      ),
                      if (isEdit) const SizedBox(width: 12),
                      if (isEdit)
                        OutlinedButton(
                          onPressed: _saving ? null : _confirmAndDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageOptions,
        child: const Icon(Icons.camera_alt),
        tooltip: 'Pick image',
      ),
    );
  }
}
