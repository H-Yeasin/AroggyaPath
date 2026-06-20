import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arogya_path3/core/location/location.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import 'doctor_schedule_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUserProfile();
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    context.read<UserProvider>().clearUser();
    context.read<AuthProvider>().clearAuth();
    if (mounted)
      Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: colors.primaryContainer,
              backgroundImage: user?.profileImage != null
                  ? CachedNetworkImageProvider(user!.profileImage!)
                  : null,
              child: user?.profileImage == null
                  ? Icon(Icons.person, size: 50, color: colors.primary)
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Dr. ${user?.fullName ?? "Doctor"}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.heading)),
            const SizedBox(height: 4),
            Text(user?.email ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            if (user?.specialty != null) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: colors.statusAcceptedBg,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(user!.specialty!,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ),
            ],
            const SizedBox(height: 32),

            // Menu
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8)
                  ]),
              child: Column(children: [
                _buildMenuItem(
                    Icons.person_outline, 'Personal Info', 'Edit your profile',
                    onTap: () =>
                        Navigator.pushNamed(context, '/personal-info')),
                _buildDivider(),
                _buildMenuItem(
                    Icons.location_on,
                    'Practice Location',
                    user?.latitude != null && user?.longitude != null
                        ? 'Location set â€” tap to update'
                        : 'Set your clinic location on the map',
                    onTap: () async {
                  final u = user;
                  final initial = (u?.latitude != null && u?.longitude != null)
                      ? LatLng(u!.latitude!, u.longitude!)
                      : null;

                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LocationPickerScreen(initialPosition: initial),
                    ),
                  );

                  if (result != null && mounted) {
                    final provider = context.read<UserProvider>();
                    await provider.updateUserProfile(
                      latitude: result['latitude'] as double,
                      longitude: result['longitude'] as double,
                      address: result['address'] as String?,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Practice location updated!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }),
                _buildDivider(),
                _buildMenuItem(Icons.schedule, 'My Schedule',
                    'Set your weekly availability', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DoctorScheduleScreen()),
                  );
                }),
                _buildDivider(),
                _buildMenuItem(Icons.lock_outline, 'Change Password',
                    'Update your password',
                    onTap: () =>
                        Navigator.pushNamed(context, '/change-password')),
                _buildDivider(),
                _buildMenuItem(Icons.videocam, 'Video Call',
                    user?.isVideoCallAvailable == true ? 'Enabled' : 'Disabled',
                    onTap: () async {
                  final provider = context.read<UserProvider>();
                  await provider.updateVideoCallAvailability(
                      !(user?.isVideoCallAvailable ?? false));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(user?.isVideoCallAvailable == true
                              ? 'Video calls enabled'
                              : 'Video calls disabled')),
                    );
                  }
                }),
                _buildDivider(),
                _buildMenuItem(Icons.help_outline, 'Help & Support', 'FAQ',
                    onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support coming soon')),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 24),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle,
      {required VoidCallback onTap}) {
    final colors = AppTheme.of(context);
    return ListTile(
      leading: Icon(icon, color: colors.primary),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w600, color: colors.heading)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 72);
}
