import 'package:flutter/material.dart';

/// Centralized semantic color constants.
/// Use [AppColors.patientPrimary] / [AppColors.doctorPrimary] in auth screens.
/// Use [AppTheme.of(context)] in logged-in screens.
class AppColors {
  AppColors._();

  // ── Patient palette (blue family) ──
  static const patientPrimary = Color(0xFF1664CD);
  static const patientPrimaryDark = Color(0xFF0D47A1);
  static const patientPrimaryLight = Color(0xFF0D53C1);
  static const patientPrimaryContainer = Color(0xFFE3F2FD);
  static const patientGradientStart = Color(0xFFE3F2FD);
  static const patientGradientMid = Color(0xFFF5F8FF);

  // ── Doctor palette (green family) ──
  static const doctorPrimary = Color(0xFF4CAF50);
  static const doctorPrimaryDark = Color(0xFF2E7D32);
  static const doctorPrimaryLight = Color(0xFF388E3C);
  static const doctorPrimaryContainer = Color(0xFFE8F5E9);
  static const doctorGradientStart = Color(0xFFE8F5E9);
  static const doctorGradientMid = Color(0xFFF1F8E9);

  // ── Role-independent colors ──
  static const heading = Color(0xFF1B2C49);
  static const bodyText = Color(0xFF4B5563);
  static const background = Color(0xFFF5F8FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFF);
  static const gradientEnd = Color(0xFFFFFFFF);
  static const disabled = Color(0xFF9E9E9E);
  static const error = Color(0xFFF44336);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const info = Color(0xFF2196F3);

  // Status badge backgrounds
  static const statusPendingBg = Color(0xFFFFF3E0);
  static const statusAcceptedBg = Color(0xFFE8F5E9);
  static const statusCompletedBg = Color(0xFFE3F2FD);
  static const statusCancelledBg = Color(0xFFFFEBEE);

  // Doctor-specific
  static const doctorGreenDark = Color(0xFF2E7D32);
  static const doctorGreenText = Color(0xFF33691E);

  // Chat (role-independent purple)
  static const chatPrimary = Color(0xFF6C5CE7);
  static const chatSecondary = Color(0xFF8E7CFE);

  // Call screens
  static const callDark = Color(0xFF1E3C72);
  static const callAccent = Color(0xFF2A5298);

  // Legacy purple (for arogyascreens)
  static const legacyPurple = Color(0xFF665ACF);
  static const legacyGrey = Color(0xFFA2A8B4);
  static const legacyBlack = Color(0xFF2F2F32);
}

/// ThemeExtension registered in main.dart.
/// Provides role-appropriate colors via `Theme.of(context).extension<AroggyaColors>()!`.
class AroggyaColors extends ThemeExtension<AroggyaColors> {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primaryContainer;
  final Color gradientStart;
  final Color gradientMid;
  final Color gradientEnd;
  final Color heading;
  final Color bodyText;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color disabled;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;
  final Color statusPendingBg;
  final Color statusAcceptedBg;
  final Color statusCompletedBg;
  final Color statusCancelledBg;
  final Color doctorGreenDark;
  final Color doctorGreenText;
  final Color chatPrimary;
  final Color chatSecondary;
  final Color callDark;
  final Color callAccent;
  final Color legacyPurple;
  final Color legacyGrey;
  final Color legacyBlack;

  const AroggyaColors._({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryContainer,
    required this.gradientStart,
    required this.gradientMid,
    required this.gradientEnd,
    required this.heading,
    required this.bodyText,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.disabled,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.statusPendingBg,
    required this.statusAcceptedBg,
    required this.statusCompletedBg,
    required this.statusCancelledBg,
    required this.doctorGreenDark,
    required this.doctorGreenText,
    required this.chatPrimary,
    required this.chatSecondary,
    required this.callDark,
    required this.callAccent,
    required this.legacyPurple,
    required this.legacyGrey,
    required this.legacyBlack,
  });

  factory AroggyaColors.patient() => AroggyaColors._(
        primary: AppColors.patientPrimary,
        primaryDark: AppColors.patientPrimaryDark,
        primaryLight: AppColors.patientPrimaryLight,
        primaryContainer: AppColors.patientPrimaryContainer,
        gradientStart: AppColors.patientGradientStart,
        gradientMid: AppColors.patientGradientMid,
        gradientEnd: AppColors.gradientEnd,
        heading: AppColors.heading,
        bodyText: AppColors.bodyText,
        background: AppColors.background,
        surface: AppColors.surface,
        surfaceAlt: AppColors.surfaceAlt,
        disabled: AppColors.disabled,
        error: AppColors.error,
        success: AppColors.success,
        warning: AppColors.warning,
        info: AppColors.info,
        statusPendingBg: AppColors.statusPendingBg,
        statusAcceptedBg: AppColors.statusAcceptedBg,
        statusCompletedBg: AppColors.statusCompletedBg,
        statusCancelledBg: AppColors.statusCancelledBg,
        doctorGreenDark: AppColors.doctorGreenDark,
        doctorGreenText: AppColors.doctorGreenText,
        chatPrimary: AppColors.chatPrimary,
        chatSecondary: AppColors.chatSecondary,
        callDark: AppColors.callDark,
        callAccent: AppColors.callAccent,
        legacyPurple: AppColors.legacyPurple,
        legacyGrey: AppColors.legacyGrey,
        legacyBlack: AppColors.legacyBlack,
      );

  factory AroggyaColors.doctor() => AroggyaColors._(
        primary: AppColors.doctorPrimary,
        primaryDark: AppColors.doctorPrimaryDark,
        primaryLight: AppColors.doctorPrimaryLight,
        primaryContainer: AppColors.doctorPrimaryContainer,
        gradientStart: AppColors.doctorGradientStart,
        gradientMid: AppColors.doctorGradientMid,
        gradientEnd: AppColors.gradientEnd,
        heading: AppColors.heading,
        bodyText: AppColors.bodyText,
        background: AppColors.background,
        surface: AppColors.surface,
        surfaceAlt: AppColors.surfaceAlt,
        disabled: AppColors.disabled,
        error: AppColors.error,
        success: AppColors.success,
        warning: AppColors.warning,
        info: AppColors.info,
        statusPendingBg: AppColors.statusPendingBg,
        statusAcceptedBg: AppColors.statusAcceptedBg,
        statusCompletedBg: AppColors.statusCompletedBg,
        statusCancelledBg: AppColors.statusCancelledBg,
        doctorGreenDark: AppColors.doctorGreenDark,
        doctorGreenText: AppColors.doctorGreenText,
        chatPrimary: AppColors.chatPrimary,
        chatSecondary: AppColors.chatSecondary,
        callDark: AppColors.callDark,
        callAccent: AppColors.callAccent,
        legacyPurple: AppColors.legacyPurple,
        legacyGrey: AppColors.legacyGrey,
        legacyBlack: AppColors.legacyBlack,
      );

  @override
  AroggyaColors copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? primaryContainer,
    Color? gradientStart,
    Color? gradientMid,
    Color? gradientEnd,
    Color? heading,
    Color? bodyText,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? disabled,
    Color? error,
    Color? success,
    Color? warning,
    Color? info,
    Color? statusPendingBg,
    Color? statusAcceptedBg,
    Color? statusCompletedBg,
    Color? statusCancelledBg,
    Color? doctorGreenDark,
    Color? doctorGreenText,
    Color? chatPrimary,
    Color? chatSecondary,
    Color? callDark,
    Color? callAccent,
    Color? legacyPurple,
    Color? legacyGrey,
    Color? legacyBlack,
  }) {
    return AroggyaColors._(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientMid: gradientMid ?? this.gradientMid,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      heading: heading ?? this.heading,
      bodyText: bodyText ?? this.bodyText,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      disabled: disabled ?? this.disabled,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      statusPendingBg: statusPendingBg ?? this.statusPendingBg,
      statusAcceptedBg: statusAcceptedBg ?? this.statusAcceptedBg,
      statusCompletedBg: statusCompletedBg ?? this.statusCompletedBg,
      statusCancelledBg: statusCancelledBg ?? this.statusCancelledBg,
      doctorGreenDark: doctorGreenDark ?? this.doctorGreenDark,
      doctorGreenText: doctorGreenText ?? this.doctorGreenText,
      chatPrimary: chatPrimary ?? this.chatPrimary,
      chatSecondary: chatSecondary ?? this.chatSecondary,
      callDark: callDark ?? this.callDark,
      callAccent: callAccent ?? this.callAccent,
      legacyPurple: legacyPurple ?? this.legacyPurple,
      legacyGrey: legacyGrey ?? this.legacyGrey,
      legacyBlack: legacyBlack ?? this.legacyBlack,
    );
  }

  @override
  AroggyaColors lerp(ThemeExtension<AroggyaColors>? other, double t) {
    if (other is! AroggyaColors) return this;
    return t < 0.5 ? this : other;
  }
}

/// Convenience helper for accessing theme colors.
class AppTheme {
  /// Returns the role-appropriate palette.
  static AroggyaColors of(BuildContext context) {
    return Theme.of(context).extension<AroggyaColors>()!;
  }

  // Quick accessors for the most commonly used colors
  static Color primary(BuildContext c) => of(c).primary;
  static Color primaryDark(BuildContext c) => of(c).primaryDark;
  static Color primaryLight(BuildContext c) => of(c).primaryLight;
  static Color primaryContainer(BuildContext c) => of(c).primaryContainer;
  static Color heading(BuildContext c) => of(c).heading;
  static Color bodyText(BuildContext c) => of(c).bodyText;
  static Color background(BuildContext c) => of(c).background;
  static Color surface(BuildContext c) => of(c).surface;
  static Color error(BuildContext c) => of(c).error;
  static Color success(BuildContext c) => of(c).success;
  static Color warning(BuildContext c) => of(c).warning;
  static Color info(BuildContext c) => of(c).info;
}
