// ...existing code...
class Patient {
  final int? id;
  final String name;
  final int? age;
  final String? diagnosis;
  final String? imagePath;
  final int? doctorId;

  Patient({
    this.id,
    required this.name,
    this.age,
    this.diagnosis,
    this.imagePath,
    this.doctorId,
  });

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] is int
          ? map['id'] as int
          : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
      name: map['name'] as String? ?? '',
      age: map['age'] is int
          ? map['age'] as int
          : (map['age'] != null ? int.tryParse(map['age'].toString()) : null),
      diagnosis: map['diagnosis'] as String?,
      imagePath: map['imagePath'] as String?,
      doctorId: map['doctorId'] is int
          ? map['doctorId'] as int
          : (map['doctorId'] != null
                ? int.tryParse(map['doctorId'].toString())
                : null),
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'age': age,
      'diagnosis': diagnosis,
      'imagePath': imagePath,
      'doctorId': doctorId,
    };
    if (id != null) m['id'] = id;
    return m;
  }
}
