// ...existing code...
import 'package:flutter/material.dart';
import '../models/doctor.dart';

class DoctorProvider with ChangeNotifier {
  final List<Doctor> _doctors = [];

  List<Doctor> get doctors => [..._doctors];

  void setDoctors(List<Doctor> doctors) {
    _doctors
      ..clear()
      ..addAll(doctors);
    notifyListeners();
  }

  void addDoctor(Doctor doctor) {
    _doctors.add(doctor);
    notifyListeners();
  }

  void updateDoctor(Doctor doctor) {
    final idx = _doctors.indexWhere((d) => d.id == doctor.id);
    if (idx != -1) {
      _doctors[idx] = doctor;
      notifyListeners();
    }
  }

  void deleteDoctor(int id) {
    _doctors.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  Doctor? getById(int id) {
    final idx = _doctors.indexWhere((d) => d.id == id);
    return idx == -1 ? null : _doctors[idx];
  }
}
// ...existing code...