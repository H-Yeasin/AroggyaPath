import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/user_provider.dart';
import '../../shared/location_picker_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  File? _profileImage;
  final _picker = ImagePicker();

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _nameController.text = user.fullName ?? '';
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _bioController.text = user.bio ?? '';
      _latitude = user.latitude;
      _longitude = user.longitude;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _pickLocation() async {
    final initialPos = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : null;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPosition: initialPos),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'] as double;
        _longitude = result['longitude'] as double;
        _addressController.text = result['address'] as String? ?? '';
      });
    }
  }

  Future<void> _save() async {
    final provider = context.read<UserProvider>();
    final success = await provider.updateUserProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      bio: _bioController.text.trim(),
      profileImage: _profileImage,
      latitude: _latitude,
      longitude: _longitude,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    }
  }

  bool get _hasLocation => _latitude != null && _longitude != null;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title:
            Text('Personal Info', style: TextStyle(color: colors.heading)),
        actions: [
          TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: TextStyle(
                      color: colors.primary, fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Profile image
          GestureDetector(
            onTap: _pickImage,
            child: Center(
              child: Stack(children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: colors.primaryContainer,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (user?.profileImage != null
                          ? NetworkImage(user!.profileImage!)
                          : null) as ImageProvider?,
                  child: (_profileImage == null && user?.profileImage == null)
                      ? Icon(Icons.person, size: 50, color: colors.primary)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: colors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField('Full Name', _nameController),
          const SizedBox(height: 16),
          _buildTextField('Phone', _phoneController, TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(
              'Address', _addressController, TextInputType.streetAddress, 2),
          const SizedBox(height: 24),

          // ── Practice Location Section ──
          Text(
            'Practice Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set your exact practice location on the map so patients can find you nearby.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          if (_hasLocation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.check_circle, color: colors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location set',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _pickLocation,
                    child: const Text('Change'),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Set on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildTextField('Bio', _bioController, TextInputType.multiline, 3),
        ]),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      [TextInputType? keyboardType, int lines = 1]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
