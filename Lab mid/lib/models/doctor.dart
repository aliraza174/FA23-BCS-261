// ...existing code...
class Doctor {
  final int? id;
  final String name;
  final String specialties; // stored as TEXT (comma-separated or free text)
  final String? phone;
  final String? email;

  // new fields
  final int? yearsExperience;
  final String? bio;
  final String? imagePath;

  Doctor({
    this.id,
    required this.name,
    required this.specialties,
    this.phone,
    this.email,
    this.yearsExperience,
    this.bio,
    this.imagePath,
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] is int
          ? map['id'] as int
          : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
      name: map['name'] as String? ?? '',
      specialties: map['specialties'] as String? ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      yearsExperience: map['yearsExperience'] is int
          ? map['yearsExperience'] as int
          : (map['yearsExperience'] != null
                ? int.tryParse(map['yearsExperience'].toString())
                : null),
      bio: map['bio'] as String?,
      imagePath: map['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'specialties': specialties,
      'phone': phone,
      'email': email,
      'yearsExperience': yearsExperience,
      'bio': bio,
      'imagePath': imagePath,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  // copyWith used by edit/save flows
  Doctor copyWith({
    int? id,
    String? name,
    String? specialties,
    String? phone,
    String? email,
    int? yearsExperience,
    String? bio,
    String? imagePath,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialties: specialties ?? this.specialties,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      bio: bio ?? this.bio,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
