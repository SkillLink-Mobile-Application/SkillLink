import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kSuccess = Color(0xFF1B7A3C);

//----------------RateProviderScreen----------------//
class RateProviderScreen extends StatefulWidget {
    final int serviceRequestId;
    final String providerName;

    const RateProviderScreen({
      super.key,
      required this.serviceRequestId,
      required this.providerName,
    });

    @override
    State<RateProviderScreen> createState() =>
        _RateProviderScreenState();
  }

  class _RateProviderScreenState
      extends State<RateProviderScreen> {
    int selectedRating = 0;

    final TextEditingController commentController =
        TextEditingController();

    bool isSubmitting = false;

    @override
    void dispose() {
      commentController.dispose();
      super.dispose();
    }

    Future<void> submitReview() async {
      final email = Session.email;

      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User session not found. Please login again.',
            ),
          ),
        );
        return;
      }

      if (selectedRating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a rating.',
            ),
          ),
        );
        return;
      }

      if (commentController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a comment.',
            ),
          ),
        );
        return;
      }

      setState(() {
        isSubmitting = true;
      });

      final success = await ApiService.addReview(
        customerEmail: email,
        serviceRequestId:
            widget.serviceRequestId,
        rating: selectedRating,
        comment: commentController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Review submitted successfully.',
            ),
            backgroundColor: _kSuccess,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to submit review.',
            ),
          ),
        );
      }
    }

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
            'Rate Provider',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

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
                child: const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFFFF3C4),
                  child: Icon(
                    Icons.person_rounded,
                    size: 44,
                    color: _kBlack,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                widget.providerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: _kBlack,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'How was your experience?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _kTextSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Rating card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _kBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) {
                          final starNumber = index + 1;

                          return IconButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                selectedRating =
                                    starNumber;
                              });
                            },
                            icon: Icon(
                              starNumber <=
                                      selectedRating
                                  ? Icons.star_rounded
                                  : Icons
                                      .star_border_rounded,
                              size: 46,
                              color: starNumber <=
                                      selectedRating
                                  ? _kYellow
                                  : const Color(0xFFCFCFC8),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selectedRating == 0
                            ? const Color(0xFFF1F1EC)
                            : _kBlack,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        selectedRating == 0
                            ? 'Select a rating'
                            : '$selectedRating / 5',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: selectedRating == 0
                              ? _kTextSecondary
                              : _kYellow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _kYellow,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Your Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kBlack,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: commentController,
                maxLines: 5,
                cursorColor: _kBlack,
                textInputAction:
                    TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 15,
                  color: _kBlack,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Write your experience...',
                  hintStyle: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 14.5,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _kBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _kBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _kYellow,
                      width: 2,
                    ),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      isSubmitting
                          ? null
                          : submitReview,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: _kBlack,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                        ),
                  label: Text(
                    isSubmitting
                        ? 'Submitting...'
                        : 'Submit Review',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: _kYellow,
                    foregroundColor: _kBlack,
                    disabledBackgroundColor:
                        _kYellow.withValues(alpha: 0.65),
                    disabledForegroundColor: _kBlack,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }