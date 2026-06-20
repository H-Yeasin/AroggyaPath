import 'package:arogya_path3/core/constants/app_constants.dart';
import 'package:arogya_path3/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'emergency_banner.dart';
import 'emergency_contacts_grid.dart';
import 'emergency_section_header.dart';
import 'symptoms_row.dart';

class EmergencyHelpScreen extends StatefulWidget {
  const EmergencyHelpScreen({super.key});

  @override
  State<EmergencyHelpScreen> createState() => _EmergencyHelpScreenState();
}

class _EmergencyHelpScreenState extends State<EmergencyHelpScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showElevatedAppBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > 60 && !_showElevatedAppBar) {
      setState(() => _showElevatedAppBar = true);
    } else if (offset <= 60 && _showElevatedAppBar) {
      setState(() => _showElevatedAppBar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 130,
            backgroundColor:
                _showElevatedAppBar ? Colors.white : const Color(0xFFF8F9FC),
            surfaceTintColor: Colors.transparent,
            elevation: _showElevatedAppBar ? 2 : 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _showElevatedAppBar ? black : Colors.transparent,
              ),
              child: const Text('Emergency Help'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: purple.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: purple.withValues(alpha: 0.1),
                        backgroundImage: user?.profileImage != null
                            ? NetworkImage(user!.profileImage!)
                            : null,
                        child: user?.profileImage == null
                            ? const Icon(Icons.person, color: purple, size: 28)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Emergency Call Banner
              EmergencyBanner(onCall: _callEmergency),
              const SizedBox(height: 28),

              //Health Tips Section
              const EmergencySectionHeader(
                icon: Icons.health_and_safety_outlined,
                title: '',
              ),
              const SizedBox(height: 14),
              const SymptomsRow(),
              const SizedBox(height: 28),

              //Emergency Contacts Section
              const EmergencySectionHeader(
                icon: Icons.contact_emergency_outlined,
                title: '',
              ),
              const SizedBox(height: 14),
              const EmergencyContactsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callEmergency(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('')),
        );
      }
    }
  }

}
