import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/doctor_provider.dart';
import '../../models/doctor.dart';
import '../../database/database_helper.dart';

class AddEditDoctorScreen extends StatefulWidget {
  final Doctor? doctor; // optional named parameter for edit mode

  AddEditDoctorScreen({Key? key, this.doctor}) : super(key: key);

  @override
  _AddEditDoctorScreenState createState() => _AddEditDoctorScreenState();
}

class _AddEditDoctorScreenState extends State<AddEditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _specialties = '';
  String? _phone;
  String? _email;
  int? _yearsExperience;
  String? _bio;
  String? _imagePath;
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    if (d != null) {
      _name = d.name;
      _specialties = d.specialties;
      _phone = d.phone;
      _email = d.email;
      _yearsExperience = d.yearsExperience;
      _bio = d.bio;
      _imagePath = d.imagePath;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() => _imagePath = picked.path);
      }
    } catch (e) {
      // silent fail - could show snackbar if desired
    }
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

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);
    final db = DatabaseHelper();

    if (widget.doctor == null) {
      // create without relying on copyWith
      final newDoctor = Doctor(
        id: null,
        name: _name,
        specialties: _specialties,
        phone: _phone,
        email: _email,
        yearsExperience: _yearsExperience,
        bio: _bio,
        imagePath: _imagePath,
      );
      final insertedId = await db.insertDoctor(newDoctor);
      final savedDoctor = Doctor(
        id: insertedId,
        name: _name,
        specialties: _specialties,
        phone: _phone,
        email: _email,
        yearsExperience: _yearsExperience,
        bio: _bio,
        imagePath: _imagePath,
      );
      Provider.of<DoctorProvider>(
        context,
        listen: false,
      ).addDoctor(savedDoctor);
    } else {
      // update without relying on copyWith
      final updatedDoctor = Doctor(
        id: widget.doctor!.id,
        name: _name,
        specialties: _specialties,
        phone: _phone,
        email: _email,
        yearsExperience: _yearsExperience,
        bio: _bio,
        imagePath: _imagePath,
      );
      await db.updateDoctor(updatedDoctor);
      Provider.of<DoctorProvider>(
        context,
        listen: false,
      ).updateDoctor(updatedDoctor);
    }

    setState(() => _saving = false);
    Navigator.pop(context);
  }

  Future<void> _confirmAndDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete doctor?'),
        content: Text(
          'Are you sure you want to delete "${widget.doctor?.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.doctor?.id != null) {
      final db = DatabaseHelper();
      await db.deleteDoctor(widget.doctor!.id!);
      Provider.of<DoctorProvider>(
        context,
        listen: false,
      ).deleteDoctor(widget.doctor!.id!);
      Navigator.pop(context); // close editor
    }
  }

  Widget _buildAvatar() {
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty;
    ImageProvider? imageProvider;
    if (hasImage) {
      try {
        final uri = Uri.tryParse(_imagePath!);
        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
          imageProvider = NetworkImage(_imagePath!);
        } else {
          imageProvider = FileImage(File(_imagePath!));
        }
      } catch (_) {
        imageProvider = null;
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
                    (_name.isNotEmpty ? _name[0] : 'D').toUpperCase(),
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
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.doctor != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Doctor' : 'Add Doctor'),
        actions: [
          if (isEdit)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _saving ? null : _confirmAndDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // avatar preview with camera action
                  _buildAvatar(),
                  SizedBox(height: 12),
                  TextFormField(
                    initialValue: _name,
                    decoration: InputDecoration(labelText: 'Name'),
                    onSaved: (v) => _name = v?.trim() ?? '',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter name' : null,
                    onChanged: (v) => setState(() {}),
                  ),
                  TextFormField(
                    initialValue: _specialties,
                    decoration: InputDecoration(
                      labelText: 'Specialties',
                      hintText: 'e.g. Cardiology, Pediatrics',
                    ),
                    onSaved: (v) => _specialties = v?.trim() ?? '',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter specialties'
                        : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _phone,
                          decoration: InputDecoration(
                            labelText: 'Phone (optional)',
                          ),
                          keyboardType: TextInputType.phone,
                          onSaved: (v) => _phone = v?.trim(),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _email,
                          decoration: InputDecoration(
                            labelText: 'Email (optional)',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (v) => _email = v?.trim(),
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: _yearsExperience != null
                        ? '$_yearsExperience'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Years of Experience',
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (v) =>
                        _yearsExperience = int.tryParse((v ?? '').trim()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 0) return 'Enter valid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: _bio,
                    decoration: InputDecoration(labelText: 'Short bio'),
                    maxLines: 3,
                    onSaved: (v) => _bio = v?.trim(),
                  ),
                  // keep a visible readonly field showing image path (optional)
                  TextFormField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Image (from device)',
                      hintText: _imagePath ?? 'No image selected',
                    ),
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveForm,
                          icon: _saving ? SizedBox.shrink() : Icon(Icons.save),
                          label: Text(_saving ? 'Saving...' : 'Save'),
                        ),
                      ),
                      if (isEdit) SizedBox(width: 12),
                      if (isEdit)
                        OutlinedButton(
                          onPressed: _saving ? null : _confirmAndDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text('Delete'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
