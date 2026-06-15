import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/const.dart';
import '../models/emergency_contacts.dart';
import '../models/symptom.dart';
import '../providers/user_provider.dart';
import 'emergency_contact_details_screen.dart';

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
            backgroundColor: _showElevatedAppBar
                ? Colors.white
                : const Color(0xFFF8F9FC),
            surfaceTintColor: Colors.transparent,
            elevation: _showElevatedAppBar ? 2 : 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: black,
                size: 20,
              ),
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
                            'জরুরি সহায়তা',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'জরুরি ফোন নম্বর ও স্বাস্থ্য পরামর্শ',
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
              // ── Emergency Call Banner ──
              _buildEmergencyBanner(),
              const SizedBox(height: 28),

              // ── Health Tips Section ──
              _buildSectionHeader(
                icon: Icons.health_and_safety_outlined,
                title: 'সুস্বাস্থ্যের জন্য',
              ),
              const SizedBox(height: 14),
              _buildSymptomsRow(),
              const SizedBox(height: 28),

              // ── Emergency Contacts Section ──
              _buildSectionHeader(
                icon: Icons.contact_emergency_outlined,
                title: 'জরুরি ফোন নম্বর: মনে রাখুন, সহায়তা নিন',
              ),
              const SizedBox(height: 14),
              _buildEmergencyContactsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Emergency Call Banner
  // ────────────────────────────────────────────────────────────

  Widget _buildEmergencyBanner() {
    return GestureDetector(
      onTap: () => _callEmergency('999'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF3B3B),
              const Color(0xFFE53935),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B3B).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pulse icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'জাতীয় জরুরি সেবা',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'যেকোনো জরুরি পরিস্থিতিতে — পুলিশ, ফায়ার সার্ভিস, অ্যাম্বুলেন্স',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.call, color: Color(0xFFE53935), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'এখনই কল করুন — ৯৯৯',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          SnackBar(content: Text('কল করতে ব্যর্থ: $e')),
        );
      }
    }
  }

  // ────────────────────────────────────────────────────────────
  // Section Header
  // ────────────────────────────────────────────────────────────

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: purple),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: black,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // Symptoms Row
  // ────────────────────────────────────────────────────────────

  Widget _buildSymptomsRow() {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: symptoms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage(symptoms[index].image),
                ),
                const SizedBox(width: 8),
                Text(
                  symptoms[index].label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: black,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Emergency Contacts Grid
  // ────────────────────────────────────────────────────────────

  Widget _buildEmergencyContactsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: emergencyContacts.length,
      itemBuilder: (context, index) {
        final contact = emergencyContacts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmergencyContactDetailsScreen(doctor: contact),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar with colored ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(contact.color),
                        Color(contact.color).withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(contact.color).withValues(alpha: 0.3),
                    backgroundImage: NetworkImage(contact.image),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  contact.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    contact.specialist,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: purple,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
