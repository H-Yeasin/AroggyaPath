import 'dart:io';

import 'package:arogya_path3/core/utils/api_config.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';

class MedicalRecordService {
  Future<Map<String, dynamic>> getMyMedicalRecords({
    String? recordType,
    String? search,
  }) async {
    try {
      final params = <String>[];
      if (recordType != null && recordType != 'all') {
        params.add('recordType=$recordType');
      }
      if (search != null && search.trim().isNotEmpty) {
        params.add('search=${Uri.encodeQueryComponent(search.trim())}');
      }

      final endpoint = params.isEmpty
          ? ApiConfig.medicalRecords
          : '${ApiConfig.medicalRecords}?${params.join('&')}';

      return await ApiService.get(endpoint, requiresAuth: true);
    } catch (e) {
      debugPrint('Get Medical Records Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch medical records: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getMedicalRecordById(String id) async {
    try {
      return await ApiService.get(
        '${ApiConfig.medicalRecords}/$id',
        requiresAuth: true,
      );
    } catch (e) {
      debugPrint('Get Medical Record Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch medical record: $e',
      };
    }
  }

  Future<Map<String, dynamic>> uploadManualRecord({
    required String recordType,
    required String title,
    required List<File> files,
    String? description,
    DateTime? recordDate,
    List<String> tags = const [],
  }) async {
    try {
      return await ApiService.postMultipart(
        ApiConfig.medicalRecords,
        fields: {
          'recordType': recordType,
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (recordDate != null)
            'recordDate': recordDate.toIso8601String().split('T')[0],
          if (tags.isNotEmpty) 'tags': tags.join(','),
        },
        files: {'files': files},
        requiresAuth: true,
      );
    } catch (e) {
      debugPrint('Upload Medical Record Error: $e');
      return {
        'success': false,
        'message': 'Failed to upload medical record: $e',
      };
    }
  }
}
