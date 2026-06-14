// models/dependent_model.dart — Ported from DocMobi

import 'package:flutter/material.dart';

class DependentModel {
  final String id;
  final String fullName;
  final String? relationship;
  final String? gender;
  final DateTime? dob;
  final String? phone;
  final String? notes;
  final bool? isActive;

  DependentModel({
    required this.id,
    required this.fullName,
    this.relationship,
    this.gender,
    this.dob,
    this.phone,
    this.notes,
    this.isActive,
  });

  factory DependentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDob;
    if (json['dob'] != null) {
      try {
        parsedDob = DateTime.parse(json['dob']);
      } catch (e) {
        debugPrint('Error parsing dob: $e');
      }
    }

    return DependentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      relationship: json['relationship']?.toString(),
      gender: json['gender']?.toString(),
      dob: parsedDob,
      phone: json['phone']?.toString(),
      notes: json['notes']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      if (relationship != null) 'relationship': relationship,
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': dob!.toIso8601String(),
      if (phone != null) 'phone': phone,
      if (notes != null) 'notes': notes,
      'isActive': isActive ?? true,
    };
  }

  String? get age {
    if (dob == null) return null;

    final now = DateTime.now();
    int years = now.year - dob!.year;

    if (now.month < dob!.month ||
        (now.month == dob!.month && now.day < dob!.day)) {
      years--;
    }

    if (years == 0) {
      final months = now.month - dob!.month + (12 * (now.year - dob!.year));
      return months == 1 ? '1 month' : '$months months';
    }

    return years == 1 ? '1 year' : '$years years';
  }

  String get displayName {
    if (relationship != null && relationship!.isNotEmpty) {
      return '$fullName ($relationship)';
    }
    return fullName;
  }

  DependentModel copyWith({
    String? id,
    String? fullName,
    String? relationship,
    String? gender,
    DateTime? dob,
    String? phone,
    String? notes,
    bool? isActive,
  }) {
    return DependentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}
