import 'dart:io' show File;

import 'api/api_appointment_service.dart';
import 'api/api_auth_service.dart';
import 'api/api_chat_service.dart';
import 'api/api_client.dart';
import 'api/api_dependent_service.dart';
import 'api/api_doctor_service.dart';
import 'api/api_upload_service.dart';
import 'api/api_user_service.dart';

class ApiService {
  static Future<void> init() => ApiClient.init();

  static Future<void> syncUserSession() => ApiAuthService.syncUserSession();

  static Future<void> saveToken(String token) => ApiClient.saveToken(token);

  static Future<void> clearToken() => ApiClient.clearToken();

  static bool get isLoggedIn => ApiClient.isLoggedIn;

  static String? get token => ApiClient.token;

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
    int retries = 2,
    Duration delay = const Duration(seconds: 1),
  }) {
    return ApiClient.get(
      endpoint,
      requiresAuth: requiresAuth,
      retries: retries,
      delay: delay,
    );
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return ApiClient.post(endpoint, body, requiresAuth: requiresAuth);
  }

  static Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    Map<String, String> fields = const {},
    Map<String, List<File>> files = const {},
    bool requiresAuth = true,
  }) {
    return ApiClient.postMultipart(
      endpoint,
      fields: fields,
      files: files,
      requiresAuth: requiresAuth,
    );
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return ApiClient.put(endpoint, body, requiresAuth: requiresAuth);
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return ApiClient.patch(endpoint, body, requiresAuth: requiresAuth);
  }

  static Future<Map<String, dynamic>> patchMultipart(
    String endpoint, {
    Map<String, String> fields = const {},
    Map<String, List<File>> files = const {},
    bool requiresAuth = true,
  }) {
    return ApiClient.patchMultipart(
      endpoint,
      fields: fields,
      files: files,
      requiresAuth: requiresAuth,
    );
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) {
    return ApiClient.delete(endpoint, requiresAuth: requiresAuth);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return ApiAuthService.login(email: email, password: password);
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? medicalLicenseNumber,
    String? specialty,
    String? experienceYears,
    String? referralCode,
  }) {
    return ApiAuthService.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      medicalLicenseNumber: medicalLicenseNumber,
      specialty: specialty,
      experienceYears: experienceYears,
      referralCode: referralCode,
    );
  }

  static Future<Map<String, dynamic>> logout() => ApiAuthService.logout();

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) {
    return ApiAuthService.forgotPassword(email: email);
  }

  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) {
    return ApiAuthService.verifyOTP(email: email, otp: otp);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return ApiAuthService.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  static Future<Map<String, dynamic>> getUserProfile({String? userId}) {
    return ApiUserEndpointService.getUserProfile(userId: userId);
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required Map<String, dynamic> data,
  }) {
    return ApiUserEndpointService.updateUserProfile(data: data);
  }

  static Future<Map<String, dynamic>> getAllDoctors({
    int page = 1,
    int limit = 20,
    String? specialty,
  }) {
    return ApiDoctorEndpointService.getAllDoctors(
      page: page,
      limit: limit,
      specialty: specialty,
    );
  }

  static Future<Map<String, dynamic>> getDoctorDetails({
    required String doctorId,
  }) {
    return ApiDoctorEndpointService.getDoctorDetails(doctorId: doctorId);
  }

  static Future<Map<String, dynamic>> searchDoctors({
    required String query,
    int page = 1,
    int limit = 20,
  }) {
    return ApiDoctorEndpointService.searchDoctors(
      query: query,
      page: page,
      limit: limit,
    );
  }

  static Future<Map<String, dynamic>> getAllCategories() {
    return ApiDoctorEndpointService.getAllCategories();
  }

  static Future<Map<String, dynamic>> getReferralSetting() {
    return ApiDoctorEndpointService.getReferralSetting();
  }

  static Future<Map<String, dynamic>> getAppointments() {
    return ApiAppointmentEndpointService.getAppointments();
  }

  static Future<Map<String, dynamic>> createAppointment({
    required Map<String, dynamic> appointmentData,
  }) {
    return ApiAppointmentEndpointService.createAppointment(
      appointmentData: appointmentData,
    );
  }

  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) {
    return ApiAppointmentEndpointService.updateAppointmentStatus(
      appointmentId: appointmentId,
      status: status,
    );
  }

  static Future<Map<String, dynamic>> cancelAppointment({
    required String appointmentId,
  }) {
    return ApiAppointmentEndpointService.cancelAppointment(
      appointmentId: appointmentId,
    );
  }

  static Future<Map<String, dynamic>> getDependents() {
    return ApiDependentEndpointService.getDependents();
  }

  static Future<Map<String, dynamic>> addDependent({
    required Map<String, dynamic> dependentData,
  }) {
    return ApiDependentEndpointService.addDependent(
      dependentData: dependentData,
    );
  }

  static Future<Map<String, dynamic>> updateDependent({
    required String dependentId,
    required Map<String, dynamic> data,
  }) {
    return ApiDependentEndpointService.updateDependent(
      dependentId: dependentId,
      data: data,
    );
  }

  static Future<Map<String, dynamic>> deleteDependent({
    required String dependentId,
  }) {
    return ApiDependentEndpointService.deleteDependent(
      dependentId: dependentId,
    );
  }

  static Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fieldName,
  }) {
    return ApiUploadService.uploadFile(
      filePath: filePath,
      fieldName: fieldName,
    );
  }

  static Future<Map<String, dynamic>> getAgoraToken({
    required String channelName,
    String? account,
  }) {
    return ApiChatService.getAgoraToken(
      channelName: channelName,
      account: account,
    );
  }

  static Future<Map<String, dynamic>> initiateCall({
    required String chatId,
    required String receiverId,
    required bool isVideo,
  }) {
    return ApiChatService.initiateCall(
      chatId: chatId,
      receiverId: receiverId,
      isVideo: isVideo,
    );
  }

  static Future<Map<String, dynamic>> acceptCall({
    required String chatId,
    required String fromUserId,
  }) {
    return ApiChatService.acceptCall(chatId: chatId, fromUserId: fromUserId);
  }

  static Future<Map<String, dynamic>> rejectCall({
    required String chatId,
    required String toUserId,
  }) {
    return ApiChatService.rejectCall(chatId: chatId, toUserId: toUserId);
  }

  static Future<Map<String, dynamic>> endCall({
    required String chatId,
    required String toUserId,
    String? uuid,
  }) {
    return ApiChatService.endCall(
      chatId: chatId,
      toUserId: toUserId,
      uuid: uuid,
    );
  }

  static int min(int a, int b) => a < b ? a : b;
}
