import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/medical_record_model.dart';
import '../services/medical_record_service.dart';

class MedicalRecordProvider with ChangeNotifier {
  final MedicalRecordService _service = MedicalRecordService();

  List<MedicalRecordModel> _records = [];
  bool _isLoading = false;
  String? _error;
  String _selectedType = 'all';
  String _search = '';

  List<MedicalRecordModel> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedType => _selectedType;
  String get search => _search;

  Future<bool> fetchRecords({String? recordType, String? search}) async {
    _isLoading = true;
    _error = null;
    if (recordType != null) _selectedType = recordType;
    if (search != null) _search = search;
    notifyListeners();

    try {
      final response = await _service.getMyMedicalRecords(
        recordType: _selectedType,
        search: _search,
      );

      if (response['success'] == true && response['data'] is List) {
        _records = (response['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(MedicalRecordModel.fromJson)
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['message'] ?? 'Failed to fetch medical records';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Fetch Medical Records Error: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadManualRecord({
    required String recordType,
    required String title,
    required List<File> files,
    String? description,
    DateTime? recordDate,
    List<String> tags = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.uploadManualRecord(
        recordType: recordType,
        title: title,
        files: files,
        description: description,
        recordDate: recordDate,
        tags: tags,
      );

      if (response['success'] == true) {
        await fetchRecords();
        return true;
      }

      _error = response['message'] ?? 'Failed to upload medical record';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Upload Manual Medical Record Error: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearRecords() {
    _records = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
