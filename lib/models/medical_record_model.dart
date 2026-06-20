class MedicalRecordFile {
  final String publicId;
  final String url;
  final String mimeType;
  final String fileName;

  const MedicalRecordFile({
    required this.publicId,
    required this.url,
    this.mimeType = '',
    this.fileName = '',
  });

  factory MedicalRecordFile.fromJson(Map<String, dynamic> json) {
    return MedicalRecordFile(
      publicId: json['public_id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
    );
  }
}

class MedicalRecordModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String appointmentId;
  final String appointmentType;
  final String appointmentTime;
  final String recordType;
  final String title;
  final String description;
  final List<MedicalRecordFile> files;
  final List<String> tags;
  final DateTime recordDate;
  final String source;
  final DateTime? createdAt;

  const MedicalRecordModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.appointmentId,
    required this.appointmentType,
    required this.appointmentTime,
    required this.recordType,
    required this.title,
    required this.description,
    required this.files,
    required this.tags,
    required this.recordDate,
    required this.source,
    this.createdAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'];
    final patient = json['patient'];
    final appointment = json['appointment'];

    DateTime parseDate(dynamic value) {
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return MedicalRecordModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: patient is Map
          ? patient['_id']?.toString() ?? ''
          : json['patient']?.toString() ?? '',
      doctorId: doctor is Map
          ? doctor['_id']?.toString() ?? ''
          : json['doctor']?.toString() ?? '',
      doctorName: doctor is Map ? doctor['fullName']?.toString() ?? '' : '',
      specialty: doctor is Map ? doctor['specialty']?.toString() ?? '' : '',
      appointmentId: appointment is Map
          ? appointment['_id']?.toString() ?? ''
          : json['appointment']?.toString() ?? '',
      appointmentType:
          appointment is Map ? appointment['appointmentType']?.toString() ?? '' : '',
      appointmentTime:
          appointment is Map ? appointment['time']?.toString() ?? '' : '',
      recordType: json['recordType']?.toString() ?? 'other',
      title: json['title']?.toString() ?? 'Medical record',
      description: json['description']?.toString() ?? '',
      files: (json['files'] is List)
          ? (json['files'] as List)
              .whereType<Map<String, dynamic>>()
              .map(MedicalRecordFile.fromJson)
              .where((file) => file.url.isNotEmpty)
              .toList()
          : const [],
      tags: (json['tags'] is List)
          ? (json['tags'] as List).map((tag) => tag.toString()).toList()
          : const [],
      recordDate: parseDate(json['recordDate']),
      source: json['source']?.toString() ?? 'appointment',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  String get typeLabel {
    switch (recordType) {
      case 'prescription':
        return 'Prescription';
      case 'summary':
        return 'Summary';
      case 'lab_report':
        return 'Lab Report';
      case 'follow_up':
        return 'Follow-up';
      default:
        return 'Other';
    }
  }

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${recordDate.day} ${months[recordDate.month - 1]}, ${recordDate.year}';
  }

  String get shareText {
    final links = files.map((file) => file.url).join('\n');
    final sourceLine =
        source == 'manual_upload' ? 'Patient upload' : 'Dr. $doctorName';
    return '$title\n$typeLabel\n$sourceLine\n$formattedDate\n\n$links';
  }
}
