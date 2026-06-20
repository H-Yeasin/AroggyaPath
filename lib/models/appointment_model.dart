// models/appointment_model.dart — Ported from DocMobi

import 'package:flutter/material.dart';

class AppointmentModel {
  final String id;
  final String doctorId;
  final String? doctorName;
  final String? doctorImage;
  final String? specialty;
  final String patientId;
  final String? patientName;
  final String? patientImage;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String status;
  final String? appointmentType;
  final String? symptoms;
  final String? notes;
  final String? reason;
  final DateTime? createdAt;
  final BookedForInfo? bookedFor;
  final List<String>? medicalDocuments;
  final String? paymentScreenshot;
  final bool paymentVerified;
  final String? completionRecordId;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    this.doctorName,
    this.doctorImage,
    this.specialty,
    required this.patientId,
    this.patientName,
    this.patientImage,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.appointmentType,
    this.symptoms,
    this.notes,
    this.reason,
    this.createdAt,
    this.bookedFor,
    this.medicalDocuments,
    this.paymentScreenshot,
    this.paymentVerified = false,
    this.completionRecordId,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final doctorData = json['doctor'];
    String doctorId = '';
    String? doctorName;
    String? doctorImage;
    String? specialty;

    if (doctorData != null) {
      if (doctorData is Map<String, dynamic>) {
        doctorId = doctorData['_id'] ?? doctorData['id'] ?? '';
        doctorName = doctorData['fullName'];
        specialty = doctorData['specialty'];
        final avatar = doctorData['avatar'];
        if (avatar != null && avatar is Map<String, dynamic>) {
          doctorImage = avatar['url'];
        }
      } else if (doctorData is String) {
        doctorId = doctorData;
      }
    }

    if (doctorId.isEmpty && json['doctorId'] != null) {
      doctorId = json['doctorId'].toString();
    }

    final patientData = json['patient'];
    String patientId = '';
    String? patientName;
    String? patientImage;

    if (patientData != null) {
      if (patientData is Map<String, dynamic>) {
        patientId = patientData['_id'] ?? patientData['id'] ?? '';
        patientName = patientData['fullName'];
        final avatar = patientData['avatar'];
        if (avatar != null && avatar is Map<String, dynamic>) {
          patientImage = avatar['url'];
        }
      } else if (patientData is String) {
        patientId = patientData;
      }
    }

    DateTime appointmentDate;
    try {
      appointmentDate = DateTime.parse(
        json['appointmentDate'] ?? json['date'] ?? DateTime.now().toString(),
      );
    } catch (e) {
      appointmentDate = DateTime.now();
      debugPrint('Date parse error: $e');
    }

    DateTime? createdAt;
    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt']);
      }
    } catch (e) {
      debugPrint('CreatedAt parse error: $e');
    }

    List<String>? medicalDocuments;
    if (json['medicalDocuments'] != null && json['medicalDocuments'] is List) {
      medicalDocuments = (json['medicalDocuments'] as List)
          .map((doc) {
            String docStr = doc.toString();
            if (docStr.contains('https://res.cloudinary.com')) {
              final match = RegExp(
                r'https://res\.cloudinary\.com[^\s,}]+',
              ).firstMatch(docStr);
              if (match != null) return match.group(0)!;
            }
            if (docStr.contains('public_id')) {
              final match = RegExp(
                r'"public_id"\s*:\s*"([^"]+)"',
              ).firstMatch(docStr);
              if (match != null) return match.group(1)!;
            }
            return docStr;
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }

    String? paymentScreenshot;
    if (json['paymentScreenshot'] != null) {
      String psStr = json['paymentScreenshot'].toString();
      if (psStr.contains('https://res.cloudinary.com')) {
        final match = RegExp(
          r'https://res\.cloudinary\.com[^\s,}]+',
        ).firstMatch(psStr);
        if (match != null) paymentScreenshot = match.group(0)!;
      } else {
        paymentScreenshot = psStr;
      }
    }

    final completionRecord = json['completionRecord'];
    final completionRecordId = completionRecord is Map<String, dynamic>
        ? completionRecord['_id']?.toString()
        : completionRecord?.toString();

    return AppointmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      doctorId: doctorId,
      doctorName: doctorName,
      doctorImage: doctorImage,
      specialty: specialty,
      patientId: patientId,
      patientName: patientName,
      patientImage: patientImage,
      appointmentDate: appointmentDate,
      appointmentTime: json['time'] ?? json['appointmentTime'] ?? '',
      status: json['status'] ?? 'pending',
      appointmentType: json['appointmentType']?.toString().toLowerCase(),
      symptoms: json['symptoms'],
      notes: json['notes'],
      reason: json['reason'],
      createdAt: createdAt,
      bookedFor: json['bookedFor'] != null
          ? BookedForInfo.fromJson(json['bookedFor'])
          : null,
      medicalDocuments: medicalDocuments,
      paymentScreenshot: paymentScreenshot,
      paymentVerified: json['paymentVerified'] == true,
      completionRecordId: completionRecordId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'doctor': {
        '_id': doctorId,
        'fullName': doctorName,
        'specialty': specialty,
        if (doctorImage != null) 'avatar': {'url': doctorImage},
      },
      'patient': {
        '_id': patientId,
        'fullName': patientName,
        if (patientImage != null) 'avatar': {'url': patientImage},
      },
      'appointmentDate': appointmentDate.toIso8601String(),
      'time': appointmentTime,
      'appointmentTime': appointmentTime,
      'status': status,
      if (appointmentType != null) 'appointmentType': appointmentType,
      if (symptoms != null) 'symptoms': symptoms,
      if (notes != null) 'notes': notes,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (bookedFor != null) 'bookedFor': bookedFor!.toJson(),
      if (medicalDocuments != null) 'medicalDocuments': medicalDocuments,
      if (paymentScreenshot != null) 'paymentScreenshot': paymentScreenshot,
      'paymentVerified': paymentVerified,
      if (completionRecordId != null) 'completionRecord': completionRecordId,
    };
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return 'green';
      case 'pending':
        return 'orange';
      case 'completed':
        return 'blue';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${appointmentDate.day} ${months[appointmentDate.month - 1]}, ${appointmentDate.year}';
  }

  bool get isVideoCall => appointmentType?.toLowerCase() == 'video';

  String get patientStatusLabel {
    final normalizedStatus = status.toLowerCase();
    if (isVideoCall && normalizedStatus == 'pending') {
      return 'Payment Verification Pending';
    }
    if (isVideoCall && normalizedStatus == 'accepted') {
      return 'Booking Successful';
    }
    if (normalizedStatus == 'accepted') return 'Confirmed';
    return status.toUpperCase();
  }

  String get appointmentTypeLabel => isVideoCall ? 'Video Call' : 'Physical Visit';

  AppointmentModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? doctorImage,
    String? specialty,
    String? patientId,
    String? patientName,
    String? patientImage,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? status,
    String? appointmentType,
    String? symptoms,
    String? notes,
    String? reason,
    DateTime? createdAt,
    BookedForInfo? bookedFor,
    List<String>? medicalDocuments,
    String? paymentScreenshot,
    bool? paymentVerified,
    String? completionRecordId,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorImage: doctorImage ?? this.doctorImage,
      specialty: specialty ?? this.specialty,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientImage: patientImage ?? this.patientImage,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      appointmentType: appointmentType ?? this.appointmentType,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      bookedFor: bookedFor ?? this.bookedFor,
      medicalDocuments: medicalDocuments ?? this.medicalDocuments,
      paymentScreenshot: paymentScreenshot ?? this.paymentScreenshot,
      paymentVerified: paymentVerified ?? this.paymentVerified,
      completionRecordId: completionRecordId ?? this.completionRecordId,
    );
  }
}

class BookedForInfo {
  final String type;
  final String? dependentId;
  final String? dependentName;
  final String? relationship;

  BookedForInfo({
    required this.type,
    this.dependentId,
    this.dependentName,
    this.relationship,
  });

  String get bookingLabel {
    if (type == 'dependent') {
      if (dependentName != null &&
          dependentName!.isNotEmpty &&
          relationship != null &&
          relationship!.isNotEmpty) {
        return "$dependentName ($relationship)";
      }
      if (relationship != null && relationship!.isNotEmpty) return relationship!;
      if (dependentName != null && dependentName!.isNotEmpty) return dependentName!;
      return "Dependent";
    }
    return 'Self';
  }

  factory BookedForInfo.fromJson(Map<String, dynamic> json) {
    return BookedForInfo(
      type: json['type']?.toString() ?? 'self',
      dependentId: json['dependentId']?.toString(),
      dependentName: json['dependentName']?.toString(),
      relationship: json['relationship']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (dependentId != null) 'dependentId': dependentId,
      if (dependentName != null) 'dependentName': dependentName,
      if (relationship != null) 'relationship': relationship,
    };
  }
}
