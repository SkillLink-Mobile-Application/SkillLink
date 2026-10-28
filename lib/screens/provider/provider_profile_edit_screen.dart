import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';
import 'provider_dashboard_screen.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);

class ProviderProfileEditScreen extends StatefulWidget {
  const ProviderProfileEditScreen({super.key});

  @override
  State<ProviderProfileEditScreen> createState() =>
      _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState
    extends State<ProviderProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final nicController = TextEditingController();
  final locationController = TextEditingController();
  final experienceController = TextEditingController();
  final descriptionController = TextEditingController();
  final certificateNameController = TextEditingController();
  final instituteController = TextEditingController();

  bool isLoading = false;
  bool termsAccepted = false;
  bool isLoadingProfile = true;

  String? selectedCategory;
  File? selectedProfileImage;
  String? profileImageUrl;
  PlatformFile? selectedCertificate;

  final List<String> serviceCategories = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Mason',
    'Mechanic',
    'AC Technician',
    'Computer Technician',
    'Phone Repair',
    'Painter',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    loadProviderProfile();
  }

  Future<void> loadProviderProfile() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (mounted) {
        setState(() => isLoadingProfile = false);
      }
      return;
    }

    try {
      final profile = await ApiService.getProviderProfile(email);

      if (!mounted) return;

      if (profile != null) {
        final user = profile['user'];

        nameController.text = user?['name']?.toString() ?? '';
        phoneController.text = user?['phone']?.toString() ?? '';
        nicController.text = profile['nicNumber']?.toString() ?? '';
        locationController.text = profile['location']?.toString() ?? '';
        experienceController.text =
            profile['experience']?.toString() ?? '';
        descriptionController.text =
            profile['description']?.toString() ?? '';
        certificateNameController.text =
            profile['certificateName']?.toString() ?? '';
        instituteController.text =
            profile['issuingInstitute']?.toString() ?? '';

        final category = profile['serviceCategory']?.toString();

        if (serviceCategories.contains(category)) {
          selectedCategory = category;
        }

        termsAccepted = profile['termsAccepted'] == true;

        final imagePath = profile['profileImage']?.toString();

        if (imagePath != null && imagePath.isNotEmpty) {
          profileImageUrl = '${ApiService.baseUrl}$imagePath';
        }
      }
    } catch (e) {
      debugPrint('Load provider profile error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingProfile = false);
      }
    }
  }

  Future<void> pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null && mounted) {
        setState(() {
          selectedProfileImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Profile image picker error: $e');

      if (mounted) {
        _showMessage('Could not select profile photo.');
      }
    }
  }

  Future<void> pickCertificate() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result.isEmpty || !mounted) return;

      setState(() {
        selectedCertificate = result.first;
      });
    } catch (e) {
      debugPrint('Certificate picker error: $e');

      if (mounted) {
        _showMessage('Could not select certificate document.');
      }
    }
  }

  Future<void> saveProfile() async {
    if (isLoading || isLoadingProfile) return;

    if (!_formKey.currentState!.validate()) return;

    if (!termsAccepted) {
      _showMessage(
        'Please accept the Badge Terms & Conditions to continue.',
      );
      return;
    }

    final email = Session.email;

    if (email.isEmpty) {
      _showMessage('User session not found. Please log in again.');
      return;
    }

    final experience = int.tryParse(
      experienceController.text.trim(),
    );

    if (experience == null || experience < 0) {
      _showMessage('Enter a valid number of experience years.');
      return;
    }

    if (selectedCategory == null) {
      _showMessage('Please select a service category.');
      return;
    }

    if (selectedCertificate != null &&
        certificateNameController.text.trim().isEmpty) {
      _showMessage('Enter the certificate or qualification name.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await ApiService.saveProviderProfile(
        email: email,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        nicNumber: nicController.text.trim(),
        location: locationController.text.trim(),
        experience: experience,
        description: descriptionController.text.trim(),
        serviceCategory: selectedCategory!,
        certificateName: certificateNameController.text.trim(),
        issuingInstitute: instituteController.text.trim(),
        termsAccepted: termsAccepted,
      );

      if (!mounted) return;

      if (!success) {
        _showMessage('Could not save profile. Please try again.');
        return;
      }

      // Upload profile image if the user selected one.
      if (selectedProfileImage != null) {
        final imageResult =
            await ApiService.uploadProviderProfileImage(
          email: email,
          image: selectedProfileImage!,
        );

        if (!mounted) return;

        if (imageResult == null) {
          _showMessage(
            'Profile saved, but photo upload failed. Please try again.',
          );
          return;
        }
      }

      if (!mounted) return;

      // Navigate to the dashboard only after successful submission.
      if (!mounted) return;

      final navigator = Navigator.of(context);

      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const ProviderDashboardScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Save provider profile error: $e');

      if (mounted) {
        _showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  InputDecoration _decoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: _kTextSecondary,
        fontSize: 14.5,
      ),
      floatingLabelStyle: const TextStyle(
        color: _kBlack,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: _kTextSecondary,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: _kBlack, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kYellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kDanger, width: 2),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _kYellow,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: _kBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _kTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        cursorColor: _kBlack,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _kBlack,
        ),
        decoration: _decoration(label, icon, hint: hint),
      ),
    );
  }

  Widget _termBlock(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _kBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: _kTextSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: Scaffold(
        backgroundColor: _kBackground,
        appBar: AppBar(
          backgroundColor: _kBlack,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: isLoading
                ? null
                : () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Complete Provider Profile',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: isLoadingProfile
            ? const Center(
                child: CircularProgressIndicator(color: _kBlack),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 6),
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _kYellow,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _kYellow.withValues(alpha: 0.35),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: const Color(0xFFFFF3C4),
                              backgroundImage: selectedProfileImage != null
                                  ? FileImage(selectedProfileImage!)
                                  : profileImageUrl != null
                                      ? NetworkImage(profileImageUrl!)
                                      : null,
                              child: selectedProfileImage == null &&
                                      profileImageUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 54,
                                      color: _kBlack,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: _kBlack,
                                foregroundColor: _kYellow,
                                disabledBackgroundColor:
                                    _kBlack.withValues(alpha: 0.5),
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              onPressed:
                                  isLoading ? null : pickProfileImage,
                              icon: const Icon(Icons.camera_alt),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: _kBlack,
                        ),
                        onPressed:
                            isLoading ? null : pickProfileImage,
                        child: const Text(
                          'Change Profile Photo (Optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: _kYellow,
                            decorationThickness: 2.5,
                          ),
                        ),
                      ),
                    ),
                    _sectionTitle(
                      'Personal Details',
                      'Enter your personal and contact information.',
                    ),
                    _field(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter your full name'
                              : null,
                    ),
                    _field(
                      controller: nicController,
                      label: 'NIC Number',
                      icon: Icons.badge_outlined,
                      hint: 'Enter your NIC number',
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter your NIC number'
                              : null,
                    ),
                    _field(
                      controller: phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter your phone number'
                              : null,
                    ),
                    _sectionTitle(
                      'Service Details',
                      'Tell customers what services you provide.',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        decoration: _decoration(
                          'Service Category',
                          Icons.handyman_outlined,
                        ),
                        items: serviceCategories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  selectedCategory = value;
                                });
                              },
                        validator: (v) =>
                            v == null ? 'Select a service category' : null,
                      ),
                    ),
                    _field(
                      controller: locationController,
                      label: 'Service Location',
                      icon: Icons.location_on_outlined,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter your service location'
                              : null,
                    ),
                    _field(
                      controller: experienceController,
                      label: 'Years of Experience',
                      icon: Icons.work_outline,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final years = int.tryParse(v?.trim() ?? '');
                        if (years == null || years < 0) {
                          return 'Enter a valid number (0 or more)';
                        }
                        return null;
                      },
                    ),
                    _field(
                      controller: descriptionController,
                      label: 'Service Description',
                      hint: 'Describe your skills and services',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter a service description'
                              : null,
                    ),
                    _sectionTitle(
                      'Qualification Documents (Optional)',
                      'Submitting relevant certificates is recommended '
                          'for Skilled Provider verification.',
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _kBorder),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Certificate / Qualification Document',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _kBlack,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Accepted formats: PDF, JPG, JPEG, PNG. '
                            'Maximum size: 10 MB.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: _kTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kBlack,
                              side: const BorderSide(
                                color: _kBlack,
                                width: 1.3,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed:
                                isLoading ? null : pickCertificate,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Choose Certificate'),
                          ),
                          if (selectedCertificate != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                4,
                                4,
                                4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7D6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _kYellow.withValues(alpha: 0.7),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    color: _kBlack,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedCertificate!.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _kBlack,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              selectedCertificate = null;
                                            });
                                          },
                                    icon: const Icon(
                                      Icons.close,
                                      color: _kBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _field(
                            controller: certificateNameController,
                            label: 'Certificate / Qualification Name',
                            icon: Icons.school_outlined,
                            validator: (v) {
                              if (selectedCertificate != null &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Enter the certificate name';
                              }
                              return null;
                            },
                          ),
                          _field(
                            controller: instituteController,
                            label: 'Issuing Institute (Optional)',
                            icon: Icons.account_balance_outlined,
                          ),
                        ],
                      ),
                    ),
                    _sectionTitle(
                      'Badge Terms & Conditions',
                      'Please read and accept before submitting.',
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _termBlock(
                            'Registered Provider Badge',
                            'Indicates completion of the platform’s required '
                                'registration and verification process. It does '
                                'not guarantee work quality or outcomes.',
                          ),
                          const SizedBox(height: 14),
                          _termBlock(
                            'Skilled Provider Badge',
                            'May be awarded after the submitted qualification '
                                'documents have been reviewed and verified by '
                                'the platform administrator.',
                          ),
                          const SizedBox(height: 14),
                          _termBlock(
                            'Additional Conditions',
                            '• Providing qualification documents is optional.\n'
                                '• Only verified qualifications qualify for the '
                                'Skilled Provider badge.\n'
                                '• Information and documents must be genuine.\n'
                                '• Badges may be removed if verification is invalid '
                                'or information is misleading.\n'
                                '• Identity and qualification documents must be '
                                'handled securely and not displayed publicly.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: termsAccepted,
                      activeColor: _kYellow,
                      checkColor: _kBlack,
                      side: const BorderSide(
                        color: _kBlack,
                        width: 1.6,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                termsAccepted = value ?? false;
                              });
                            },
                      title: const Text(
                        'I have read and agree to the Badge Terms & Conditions.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kYellow,
                          foregroundColor: _kBlack,
                          disabledBackgroundColor:
                              _kYellow.withValues(alpha: 0.65),
                          disabledForegroundColor: _kBlack,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: isLoading ? null : saveProfile,
                        icon: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: _kBlack,
                                ),
                              )
                            : const Icon(Icons.verified_user_outlined),
                        label: Text(
                          isLoading
                              ? 'Submitting...'
                              : 'Submit for Verification',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    nicController.dispose();
    locationController.dispose();
    experienceController.dispose();
    descriptionController.dispose();
    certificateNameController.dispose();
    instituteController.dispose();
    super.dispose();
  }
}