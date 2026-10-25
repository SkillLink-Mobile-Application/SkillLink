import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/session.dart';
import 'provider_dashboard_screen.dart';

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

  InputDecoration _decoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
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
        decoration: _decoration(label, icon, hint: hint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: isLoading
                ? null
                : () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Complete Provider Profile'),
        ),
        body: isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
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
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton.filled(
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
                        onPressed:
                            isLoading ? null : pickProfileImage,
                        child: const Text(
                          'Change Profile Photo (Optional)',
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Certificate / Qualification Document',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Accepted formats: PDF, JPG, JPEG, PNG. '
                            'Maximum size: 10 MB.',
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                isLoading ? null : pickCertificate,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Choose Certificate'),
                          ),
                          if (selectedCertificate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.description_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedCertificate!.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registered Provider Badge',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Indicates completion of the platform’s required '
                            'registration and verification process. It does '
                            'not guarantee work quality or outcomes.',
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Skilled Provider Badge',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'May be awarded after the submitted qualification '
                            'documents have been reviewed and verified by '
                            'the platform administrator.',
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Additional Conditions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
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
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: termsAccepted,
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
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : saveProfile,
                        icon: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
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