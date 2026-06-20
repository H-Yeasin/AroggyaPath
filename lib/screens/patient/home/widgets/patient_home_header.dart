import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../models/user_model.dart';

class PatientHomeHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onProfileTap;
  final VoidCallback onSearchTap;

  const PatientHomeHeader({
    super.key,
    required this.user,
    required this.onProfileTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.primaryContainer,
                    child: ClipOval(
                      child: user?.profileImage != null
                          ? CachedNetworkImage(
                              imageUrl: user!.profileImage!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Icon(
                                Icons.person,
                                size: 30,
                                color: colors.primary,
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.person,
                                size: 30,
                                color: colors.primary,
                              ),
                            )
                          : Icon(Icons.person, size: 30, color: colors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Welcome to AroggyaPath',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.heading,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user?.address ?? 'Location not set',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.search, size: 28, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
