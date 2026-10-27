import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

class CustomerEditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;

  const CustomerEditProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  State<CustomerEditProfileScreen> createState() =>
      _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState
    extends State<CustomerEditProfileScreen> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  bool isSaving = false;
  bool isPickingImage = false;

  File? selectedImage;

  final ImagePicker imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.name);

    emailController =
        TextEditingController(text: widget.email);

    phoneController =
        TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  // ================= PICK PROFILE IMAGE =================

  Future<void> pickProfileImage() async {
    if (isPickingImage) return;

    setState(() {
      isPickingImage = true;
    });

    try {
      final XFile? image =
          await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        selectedImage = File(image.path);
      });
    } catch (e) {
      debugPrint(
        'Image Picker Error: $e',
      );

      if (!mounted) return;

      showMessage(
        'Unable to select image. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isPickingImage = false;
        });
      }
    }
  }

  // ================= SAVE PROFILE =================

  Future<void> saveProfile() async {
    final name =
        nameController.text.trim();

    final phone =
        phoneController.text.trim();

    // Validate name
    if (name.isEmpty) {
      showMessage(
        'Please enter your full name',
      );
      return;
    }

    // Validate phone
    if (phone.isEmpty) {
      showMessage(
        'Please enter your phone number',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // ================= UPDATE PROFILE DETAILS =================

      final profileUpdated =
          await ApiService.updateUserProfile(
        email: widget.email,
        name: name,
        phone: phone,
      );

      if (!profileUpdated) {
        if (!mounted) return;

        showMessage(
          'Failed to update profile details',
        );

        return;
      }

      // ================= UPLOAD PROFILE IMAGE =================

      if (selectedImage != null) {
        final imagePath =
            await ApiService.uploadCustomerProfileImage(
          email: widget.email,
          image: selectedImage!,
        );

        if (imagePath == null) {
          if (!mounted) return;

          showMessage(
            'Profile details saved, but image upload failed',
          );

          return;
        }
      }

      // ================= SUCCESS =================

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      debugPrint(
        'Save Profile Error: $e',
      );

      if (!mounted) return;

      showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ================= MESSAGE =================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ================= UI HELPERS =================

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    Color fill = Colors.white,
    bool readOnly = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _kTextSecondary,
        fontSize: 14.5,
      ),
      prefixIcon: Icon(
        icon,
        color: readOnly ? _kTextSecondary : _kBlack,
        size: 22,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: fill,
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
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _kBlack,
      ),
    );
  }

  static const TextStyle _inputStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: _kBlack,
  );

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // ================= PROFILE HEADER =================

              Center(
                child: Column(
                  children: [

                    Stack(
                      children: [

                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: _kYellow,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor:
                                const Color(0xFFFFF3C4),
                            backgroundImage:
                                selectedImage != null
                                    ? FileImage(
                                        selectedImage!,
                                      )
                                    : null,
                            child:
                                selectedImage == null
                                    ? const Icon(
                                        Icons
                                            .person_rounded,
                                        size: 60,
                                        color: _kBlack,
                                      )
                                    : null,
                          ),
                        ),

                        Positioned(
                          right: 0,
                          bottom: 0,
                          child:
                              GestureDetector(
                            onTap:
                                isPickingImage
                                    ? null
                                    : pickProfileImage,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration:
                                  BoxDecoration(
                                color: _kBlack,
                                shape:
                                    BoxShape.circle,
                                border:
                                    Border.all(
                                  color:
                                      Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons
                                    .camera_alt_rounded,
                                color: _kYellow,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    const Text(
                      'Profile Photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                        color: _kBlack,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      'Tap the camera icon to change your photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ================= PERSONAL INFORMATION =================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(color: _kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _kYellow,
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w800,
                            color: _kBlack,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'Update your personal details below.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _kTextSecondary,
                      ),
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ================= FULL NAME =================

                    _fieldLabel('Full Name'),

                    const SizedBox(
                      height: 8,
                    ),

                    TextField(
                      controller:
                          nameController,
                      cursorColor: _kBlack,
                      style: _inputStyle,
                      textCapitalization:
                          TextCapitalization
                              .words,
                      decoration:
                          _fieldDecoration(
                        hint:
                            'Enter your full name',
                        icon: Icons
                            .person_outline_rounded,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ================= EMAIL =================

                    _fieldLabel('Email Address'),

                    const SizedBox(
                      height: 8,
                    ),

                    TextField(
                      controller:
                          emailController,
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _kTextSecondary,
                      ),
                      decoration:
                          _fieldDecoration(
                        hint: 'Email address',
                        icon: Icons.email_outlined,
                        suffix: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: _kTextSecondary,
                        ),
                        fill: const Color(0xFFF1F1EC),
                        readOnly: true,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Email address cannot be changed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ================= PHONE =================

                    _fieldLabel('Phone Number'),

                    const SizedBox(
                      height: 8,
                    ),

                    TextField(
                      controller:
                          phoneController,
                      cursorColor: _kBlack,
                      style: _inputStyle,
                      keyboardType:
                          TextInputType.phone,
                      decoration:
                          _fieldDecoration(
                        hint:
                            'Enter your phone number',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // ================= SAVE BUTTON =================

              SizedBox(
                width:
                    double.infinity,
                height: 56,
                child:
                    ElevatedButton(
                  onPressed:
                      isSaving
                          ? null
                          : saveProfile,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: _kYellow,
                    foregroundColor: _kBlack,
                    disabledBackgroundColor:
                        _kYellow.withValues(
                      alpha: 0.65,
                    ),
                    disabledForegroundColor:
                        _kBlack,
                    elevation: 0,
                    shadowColor:
                        Colors.transparent,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(16),
                    ),
                  ),
                  child:
                      isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.5,
                                color: _kBlack,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  Icons
                                      .save_rounded,
                                  size: 20,
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  'Save Changes',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}