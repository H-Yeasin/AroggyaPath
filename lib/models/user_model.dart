// models/user_model.dart — Ported from DocMobi

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? profileImage;

  final String? bio;
  final String? specialty;
  final List<String>? specialties;
  final int? experienceYears;
  final String? medicalLicenseNumber;
  final String? visitingHoursText;

  final bool isVideoCallAvailable;
  final int points;

  final double? feesAmount;
  final String? feesCurrency;

  final List<Degree>? degrees;
  final List<DaySchedule>? weeklySchedule;

  final double? latitude;
  final double? longitude;

  Map<String, dynamic>? get fees => feesAmount != null
      ? {'amount': feesAmount, 'currency': feesCurrency}
      : null;

  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.profileImage,
    this.bio,
    this.specialty,
    this.specialties,
    this.experienceYears,
    this.medicalLicenseNumber,
    this.visitingHoursText,
    this.isVideoCallAvailable = false,
    this.points = 0,
    this.feesAmount,
    this.feesCurrency,
    this.degrees,
    this.weeklySchedule,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      dateOfBirth: json['dob'],
      gender: json['gender'],
      bloodGroup: json['bloodGroup'],
      address: json['address'],
      profileImage: json['avatar']?['url'] ?? json['profileImage'],
      bio: json['bio'],
      specialty: json['specialty'],
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : null,
      experienceYears: json['experienceYears'],
      medicalLicenseNumber: json['medicalLicenseNumber'],
      visitingHoursText: json['visitingHoursText'],
      isVideoCallAvailable:
          json['isVideoCallAvailable'] ??
          json['isVideoAvailable'] ??
          json['isAvailable'] ??
          (json['video']?['isAvailable'] ?? false),
      points: int.tryParse((json['points'] ?? 0).toString()) ?? 0,
      feesAmount: json['fees']?['amount']?.toDouble() ?? 0.0,
      feesCurrency: json['fees']?['currency'] ?? 'BDT',
      degrees: json['degrees'] != null
          ? (json['degrees'] as List).map((d) => Degree.fromJson(d)).toList()
          : null,
      weeklySchedule: json['weeklySchedule'] != null
          ? (json['weeklySchedule'] as List)
              .map((d) => DaySchedule.fromJson(d))
              .toList()
          : null,
      latitude:
          json['latitude']?.toDouble() ??
          (json['location'] != null
              ? double.tryParse(json['location']['lat'].toString())
              : null),
      longitude:
          json['longitude']?.toDouble() ??
          (json['location'] != null
              ? double.tryParse(json['location']['lng'].toString())
              : null),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phone': phone,
      'dob': dateOfBirth,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'profileImage': profileImage,
      'bio': bio,
      'specialty': specialty,
      'specialties': specialties,
      'experienceYears': experienceYears,
      'medicalLicenseNumber': medicalLicenseNumber,
      'visitingHoursText': visitingHoursText,
      'isVideoCallAvailable': isVideoCallAvailable,
      'points': points,
      'fees': {'amount': feesAmount, 'currency': feesCurrency},
      'degrees': degrees?.map((d) => d.toJson()).toList(),
      'weeklySchedule': weeklySchedule?.map((d) => d.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? profileImage,
    String? bio,
    String? specialty,
    List<String>? specialties,
    int? experienceYears,
    String? medicalLicenseNumber,
    String? visitingHoursText,
    bool? isVideoCallAvailable,
    int? points,
    double? feesAmount,
    String? feesCurrency,
    List<Degree>? degrees,
    List<DaySchedule>? weeklySchedule,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      specialty: specialty ?? this.specialty,
      specialties: specialties ?? this.specialties,
      experienceYears: experienceYears ?? this.experienceYears,
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
      visitingHoursText: visitingHoursText ?? this.visitingHoursText,
      isVideoCallAvailable: isVideoCallAvailable ?? this.isVideoCallAvailable,
      points: points ?? this.points,
      feesAmount: feesAmount ?? this.feesAmount,
      feesCurrency: feesCurrency ?? this.feesCurrency,
      degrees: degrees ?? this.degrees,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Degree {
  final String title;
  final String? institute;
  final int? year;

  Degree({required this.title, this.institute, this.year});

  factory Degree.fromJson(Map<String, dynamic> json) {
    return Degree(
      title: json['title'] ?? '',
      institute: json['institute'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'institute': institute, 'year': year};
  }
}

class DaySchedule {
  final String day;
  final bool isActive;
  final List<TimeSlot>? slots;

  DaySchedule({required this.day, required this.isActive, this.slots});

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day'] ?? '',
      isActive: json['isActive'] ?? false,
      slots: json['slots'] != null
          ? (json['slots'] as List).map((s) => TimeSlot.fromJson(s)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isActive': isActive,
      'slots': slots?.map((s) => s.toJson()).toList(),
    };
  }
}

class TimeSlot {
  final String start;
  final String end;

  TimeSlot({required this.start, required this.end});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(start: json['start'] ?? '', end: json['end'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'start': start, 'end': end};
  }
}
