import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:arogya_path3/providers/auth_provider.dart';
import 'package:arogya_path3/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  final String initialRole;
  const SignupScreen({super.key, this.initialRole = 'patient'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Doctor-specific
  final _licenseCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  String? _specialty;

  String _role = 'patient';
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _isLoading = false;

  List<String> _specialties = [];
  bool _loadingCategories = true;
  bool _referralEnabled = false;
  bool _loadingReferral = true;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
    if (_role == 'doctor') {
      _fetchCategories();
      _fetchReferralSetting();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiService.getAllCategories();
      if (res['success'] == true && res['data'] != null) {
        final list = res['data'] as List;
        setState(() {
          _specialties = list
              .map((c) => c['speciality_name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
          _loadingCategories = false;
        });
      } else {
        setState(() => _loadingCategories = false);
      }
    } catch (_) {
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _fetchReferralSetting() async {
    try {
      final res = await ApiService.getReferralSetting();
      if (res['success'] == true) {
        setState(() {
          _referralEnabled = res['data']?['referralSystemEnabled'] ?? false;
          _loadingReferral = false;
        });
      } else {
        setState(() => _loadingReferral = false);
      }
    } catch (_) {
      setState(() => _loadingReferral = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      _snack('You must agree to the Terms of Service', true);
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _snack('Passwords do not match', true);
      return;
    }

    if (_role == 'doctor') {
      if (_licenseCtrl.text.trim().isEmpty) {
        _snack('Medical license is required', true);
        return;
      }
      if (_specialty == null || _specialty!.isEmpty) {
        _snack('Please select a specialty', true);
        return;
      }
      if (_experienceCtrl.text.trim().isEmpty) {
        _snack('Years of experience is required', true);
        return;
      }
      if (_referralEnabled && _referralCtrl.text.trim().isEmpty) {
        _snack('Referral code is required', true);
        return;
      }
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _role,
      medicalLicenseNumber: _role == 'doctor' ? _licenseCtrl.text.trim() : null,
      specialty: _role == 'doctor' ? _specialty : null,
      experienceYears: _role == 'doctor' ? _experienceCtrl.text.trim() : null,
      referralCode: _role == 'doctor' ? _referralCtrl.text.trim() : null,
    );
    setState(() => _isLoading = false);

    if (ok && mounted) {
      _snack('Registration successful! Please log in.', false);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else if (mounted && auth.error != null) {
      _snack(auth.error!, true);
    }
  }

  void _snack(String msg, bool err) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showEula() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.gavel, color: AppColors.patientPrimary),
          SizedBox(width: 10),
          Text('Terms of Service',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: const SingleChildScrollView(
          child: Text(
            'By accepting, you agree to our Terms of Service and EULA.\n\n'
            'Safety Policy:\n'
            'â€¢ Zero tolerance for objectionable content\n'
            'â€¢ No defamatory, obscene, or illegal content\n'
            'â€¢ Violators ejected within 24 hours\n\n'
            'You can report or block users at any time.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _agreed = false);
              },
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _agreed = true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patientPrimary),
            child: const Text('Accept',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _licenseCtrl.dispose();
    _referralCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final isDoctor = _role == 'doctor';
    final accent =
        isDoctor ? AppColors.doctorPrimary : AppColors.patientPrimary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.heading),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isDoctor ? 'Register as Doctor' : 'Register as Patient',
          style: const TextStyle(
              color: AppColors.heading,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Role Toggle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _role = 'patient'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isDoctor ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: !isDoctor
                            ? [
                                BoxShadow(
                                    color: AppColors.patientPrimary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]
                            : [],
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person,
                                size: 18,
                                color: !isDoctor ? Colors.white : Colors.grey),
                            const SizedBox(width: 6),
                            Text('Patient',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: !isDoctor
                                        ? Colors.white
                                        : Colors.grey)),
                          ]),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _role = 'doctor');
                      if (_specialties.isEmpty) _fetchCategories();
                      if (_loadingReferral && !_referralEnabled)
                        _fetchReferralSetting();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDoctor
                            ? AppColors.doctorPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isDoctor
                            ? [
                                BoxShadow(
                                    color: AppColors.doctorPrimary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]
                            : [],
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medical_services,
                                size: 18,
                                color: isDoctor ? Colors.white : Colors.grey),
                            const SizedBox(width: 6),
                            Text('Doctor',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDoctor ? Colors.white : Colors.grey)),
                          ]),
                    ),
                  ),
                ),
              ]),
            ),

            // â”€â”€ Common fields â”€â”€
            _label('Full Name *'),
            const SizedBox(height: 6),
            _field(_nameCtrl, 'Enter your full name', Icons.person_outline,
                v: (v) => (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 16),

            _label('Email *'),
            const SizedBox(height: 6),
            _field(_emailCtrl, 'you@example.com', Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
                v: (v) => (v == null || !v.contains('@'))
                    ? 'Valid email required'
                    : null),
            const SizedBox(height: 16),

            _label('Phone (optional)'),
            const SizedBox(height: 6),
            _field(_phoneCtrl, 'Phone number', Icons.call,
                keyboard: TextInputType.phone),
            const SizedBox(height: 16),

            // â”€â”€ Doctor-specific fields â”€â”€
            if (isDoctor) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusAcceptedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.doctorPrimary.withValues(alpha: 0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline,
                      color: AppColors.doctorPrimary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('Doctor verification details',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.doctorGreenDark,
                              fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 16),

              // Medical License
              _label('Medical License Number *'),
              const SizedBox(height: 6),
              _field(_licenseCtrl, 'Enter license number', Icons.badge_outlined,
                  v: (v) => (v == null || v.isEmpty) ? 'Required' : null),
              const SizedBox(height: 16),

              // Specialty dropdown
              _label('Medical Specialty *'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _loadingCategories
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _specialty,
                          hint: const Text('Select specialty',
                              style: TextStyle(color: Colors.grey)),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.doctorPrimary),
                          items: _specialties
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _specialty = v),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Experience
              _label('Years of Experience *'),
              const SizedBox(height: 6),
              _field(_experienceCtrl, 'e.g. 5', Icons.work_outline,
                  keyboard: TextInputType.number,
                  v: (v) => (v == null || v.isEmpty) ? 'Required' : null),
              const SizedBox(height: 16),

              // Referral code (if enabled)
              if (_loadingReferral)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_referralEnabled) ...[
                _label('Referral Code *'),
                const SizedBox(height: 6),
                _field(_referralCtrl, 'Enter referral code',
                    Icons.discount_outlined,
                    v: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                const SizedBox(height: 16),
              ],
            ],

            // â”€â”€ Password â”€â”€
            _label('Password *'),
            const SizedBox(height: 6),
            _field(_passwordCtrl, 'Min. 6 characters', Icons.lock_outlined,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20, color: Colors.grey),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ), v: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            }),
            const SizedBox(height: 16),

            _label('Confirm Password *'),
            const SizedBox(height: 6),
            _field(_confirmCtrl, 'Re-enter password', Icons.lock_outlined,
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: Colors.grey),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ), v: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            }),
            const SizedBox(height: 20),

            // EULA
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreed,
                  activeColor: accent,
                  onChanged: (v) {
                    if (v == true)
                      _showEula();
                    else
                      setState(() => _agreed = false);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _agreed ? setState(() => _agreed = false) : _showEula(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                        children: [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.patientPrimary)),
                          TextSpan(text: ' and confirm '),
                          TextSpan(
                              text: 'zero tolerance',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          TextSpan(text: ' for objectionable content.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Register button
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: Text(
                      'Create ${isDoctor ? "Doctor" : "Patient"} Account',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 16),

            // Login link
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Log in',
                    style: TextStyle(color: AppColors.bodyText)),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  // â”€â”€ Helpers â”€â”€
  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.heading));
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? v,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: v,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.patientPrimary, size: 20),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.patientPrimary)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }
}
