import 'package:flutter/material.dart';
import '../models/patient.dart';

class PatientProvider with ChangeNotifier {
  final List<Patient> _patients = [];

  List<Patient> get patients => [..._patients];

  void setPatients(List<Patient> patients) {
    _patients
      ..clear()
      ..addAll(patients);
    notifyListeners();
  }

  void addPatient(Patient patient) {
    _patients.add(patient);
    notifyListeners();
  }

  void updatePatient(Patient patient) {
    final idx = _patients.indexWhere((p) => p.id == patient.id);
    if (idx != -1) {
      _patients[idx] = patient;
      notifyListeners();
    }
  }

  void deletePatient(int id) {
    _patients.removeWhere((pat) => pat.id == id);
    notifyListeners();
  }

  Patient? getById(int id) {
    final idx = _patients.indexWhere((p) => p.id == id);
    return idx == -1 ? null : _patients[idx];
  }

  List<Patient> getByDoctor(int? doctorId) {
    return _patients.where((p) => p.doctorId == doctorId).toList();
  }
}
