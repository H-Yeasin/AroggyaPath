import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Production URL — update after deploying thekingBackend
  /// Render/Railway deployment URL goes here
  static const String prodUrl = 'https://api.aroggyapath.com';

  /// Development URLs
  static const String localhostUrl = 'http://localhost:5000';
  static const String androidEmulatorUrl = 'http://10.0.2.2:5000';

  /// Your computer's local IP (for physical device testing on same WiFi)
  /// Find using: ipconfig (Windows) or ifconfig (Mac/Linux)
  /// Example: 'http://192.168.0.105:5000'
  static const String localNetworkUrl = 'http://192.168.0.XXX:5000';

  static const DevMode _currentMode = DevMode.localhost;

  /// Get base URL based on environment and platform
  static String get baseUrl {
    if (kReleaseMode || _currentMode == DevMode.production) {
      return prodUrl;
    }

    if (_currentMode == DevMode.network) {
      return localNetworkUrl;
    }

    // Default to localhost/emulator
    if (Platform.isAndroid) {
      return androidEmulatorUrl;
    } else {
      return localhostUrl;
    }
  }

  /// Get Socket URL (WebSocket protocol)
  static String get socketUrl => baseUrl;

  // ========== Auth Endpoints ==========
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String logout = '/api/v1/auth/logout';
  static const String forgotPassword = '/api/v1/auth/forget';
  static const String resetPassword = '/api/v1/auth/reset-password';
  static const String verifyOTP = '/api/v1/auth/verify-otp';
  static const String refreshToken = '/api/v1/auth/refresh-token';
  static const String changePassword = '/api/v1/user/password';

  // User Endpoints
  static const String profile = '/api/v1/user/profile';
  static const String userProfile = '/api/v1/user/profile';
  static const String updateProfile = '/api/v1/user/profile';
  static const String getUserById = '/api/v1/user';
  static const String deleteUser = '/api/v1/user';
  static const String deleteAccount = '/api/v1/user/delete-account';

  // Appointment Endpoints
  static const String appointments = '/api/v1/appointment';
  static const String createAppointment = '/api/v1/appointment';
  static const String getAppointmentById = '/api/v1/appointment';
  static const String updateAppointment = '/api/v1/appointment';
  static const String deleteAppointment = '/api/v1/appointment';
  static const String cancelAppointment = '/api/v1/appointment';
  static const String patientAppointments = '/api/v1/appointment/patient';
  static const String doctorAppointments = '/api/v1/appointment/doctor';
  static const String upcomingAppointments = '/api/v1/appointment/upcoming';
  static const String pastAppointments = '/api/v1/appointment/past';

  // Medical Record Endpoints
  static const String medicalRecords = '/api/v1/medical-records';

  // Doctor Endpoints
  static const String doctors = '/api/v1/user/role/doctor';
  static const String doctorById = '/api/v1/user';
  static const String searchDoctors = '/api/v1/user/role/doctor';
  static const String nearbyDoctors = '/api/v1/user/role/doctor/nearby';
  static const String doctorsBySpecialty = '/api/v1/user/role/doctor/specialty';
  static const String topRatedDoctors = '/api/v1/user/role/doctor/top-rated';

  // Category Endpoints
  static const String categories = '/api/v1/category';
  static const String categoryById = '/api/v1/category';
  static const String createCategory = '/api/v1/category/create';
  static const String updateCategory = '/api/v1/category';
  static const String deleteCategory = '/api/v1/category';

  // Notification Endpoints
  static const String notifications = '/api/v1/notification';
  static const String markAsRead = '/api/v1/notification';
  static const String markAllAsRead = '/api/v1/notification/read-all';
  static const String deleteNotification = '/api/v1/notification';
  static const String unreadCount = '/api/v1/notification/unread-count';

  // Doctor Review Endpoints
  static const String reviews = '/api/v1/doctor-review';
  static const String createReview = '/api/v1/doctor-review/create';
  static const String doctorReviews = '/api/v1/doctor-review/doctor';
  static const String updateReview = '/api/v1/doctor-review';
  static const String deleteReview = '/api/v1/doctor-review';
  static const String myReviews = '/api/v1/doctor-review/my-reviews';

  // Post Endpoints
  static const String posts = '/api/v1/posts';
  static const String createPost = '/api/v1/posts';
  static const String getPostById = '/api/v1/posts';
  static const String updatePost = '/api/v1/posts';
  static const String deletePost = '/api/v1/posts';
  static const String likePost = '/api/v1/posts';
  static const String commentOnPost = '/api/v1/posts';
  static const String myPosts = '/api/v1/posts/my-posts';
  static const String userPosts = '/api/v1/posts/user';

  // Chat Endpoints
  static const String chats = '/api/v1/chat';
  static const String messages = '/api/v1/chat/messages';
  static const String sendMessage = '/api/v1/chat/send';
  static const String createChat = '/api/v1/chat/create';
  static const String getChatById = '/api/v1/chat';
  static const String deleteChatMessage = '/api/v1/chat/message';
  static const String markChatAsRead = '/api/v1/chat';

  // Reel Endpoints
  static const String reels = '/api/v1/reels';
  static const String createReel = '/api/v1/reels';
  static const String getReelById = '/api/v1/reels';
  static const String updateReel = '/api/v1/reels';
  static const String deleteReel = '/api/v1/reels';
  static const String likeReel = '/api/v1/reels';
  static const String commentOnReel = '/api/v1/reels';

  // Referral Code Endpoints
  static const String referralCode = '/api/v1/referral';
  static const String applyReferral = '/api/v1/referral/apply';
  static const String myReferrals = '/api/v1/referral/my-referrals';
  static const String referralStats = '/api/v1/referral/stats';

  // System Settings Endpoints
  static const String systemSettings = '/api/v1/system-setting';
  static const String getSettingByKey = '/api/v1/system-setting';
  static const String updateSystemSetting = '/api/v1/system-setting';

  // Payment Endpoints
  static const String payments = '/api/v1/payment';
  static const String createPayment = '/api/v1/payment/create';
  static const String verifyPayment = '/api/v1/payment/verify';
  static const String paymentHistory = '/api/v1/payment/history';

  // Upload Endpoints
  static const String uploadImage = '/api/v1/upload/image';
  static const String uploadFile = '/api/v1/upload/file';
  static const String uploadVideo = '/api/v1/upload/video';

  // Dependent Endpoints
  static const String dependents = '/api/v1/user/me/dependents';

  // Block / Report Endpoints (UGC Safety)
  static const String blockUser = '/api/v1/user/block';
  static const String blockedUsers = '/api/v1/user/blocked';
  static const String reportContent = '/api/v1/report';

  // ═══════════════════════════════════════════════════════════════
  // 🔧 HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  static String getFullUrl(String endpoint) => '$baseUrl$endpoint';
  static String getAppointmentByIdUrl(String id) => '$appointments/$id';
  static String getDoctorByIdUrl(String id) => '$doctorById/$id';
  static String getUserByIdUrl(String id) => '$getUserById/$id';
  static String getCancelAppointmentUrl(String id) =>
      '$appointments/$id/status';
  static String getCategoryByIdUrl(String id) => '$categoryById/$id';
  static String getPostByIdUrl(String id) => '$getPostById/$id';
  static String getReelByIdUrl(String id) => '$getReelById/$id';
  static String getDoctorReviewsUrl(String doctorId) =>
      '$doctorReviews/$doctorId';
  static String getMarkAsReadUrl(String notificationId) =>
      '$markAsRead/$notificationId/read';
  static String getChatByIdUrl(String chatId) => '$chats/$chatId';
  static String getDependentByIdUrl(String id) => '$dependents/$id';

  // ═══════════════════════════════════════════════════════════════
  // 📊 DEBUG & STATUS
  // ═══════════════════════════════════════════════════════════════

  /// Print current configuration
  static void debugPrintConfig() {
    debugPrint('');
    debugPrint('╔═══════════════════════════════════════════════════════╗');
    debugPrint('║         AROGGYAPATH API CONFIGURATION                ║');
    debugPrint('╚═══════════════════════════════════════════════════════╝');
    debugPrint('');
    debugPrint(' Current Settings:');
    debugPrint('   • Platform: ${Platform.operatingSystem}');
    debugPrint('   • Mode: ${_currentMode.name.toUpperCase()}');
    debugPrint('   • Base URL: $baseUrl');
    debugPrint('   • Socket URL: $socketUrl');
    debugPrint('   • Production: ${isProduction ? "YES ✅" : "NO ❌"}');
    debugPrint('');
    debugPrint(' Available URLs:');
    debugPrint('   • Production: $prodUrl');
    debugPrint('   • Localhost: $localhostUrl');
    debugPrint('   • Android Emulator: $androidEmulatorUrl');
    debugPrint('   • Local Network: $localNetworkUrl');
    debugPrint('');
    debugPrint('╚═══════════════════════════════════════════════════════╝');
    debugPrint('');
  }

  /// Check if using production
  static bool get isProduction => baseUrl == prodUrl;

  /// Check if using local development
  static bool get isDevelopment =>
      baseUrl.contains('localhost') ||
      baseUrl.contains('10.0.2.2') ||
      baseUrl.contains('192.168');
}

enum DevMode {
  production,
  localhost,
  network,
}
