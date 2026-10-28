import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

class ReviewsScreen extends StatefulWidget {
  final String providerEmail;

  const ReviewsScreen({
    super.key,
    required this.providerEmail,
  });

  @override
  State<ReviewsScreen> createState() =>
      _ReviewsScreenState();
}

class _ReviewsScreenState
    extends State<ReviewsScreen> {

  List<dynamic> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  Future<void> loadReviews() async {
    try {
      final result =
          await ApiService.getProviderReviews(
        widget.providerEmail,
      );

      if (!mounted) return;

      setState(() {
        reviews = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to load reviews.',
          ),
        ),
      );
    }
  }

  Widget buildStars(int rating) {
    return Row(
      children: List.generate(
        5,
        (index) {
          return Icon(
            index < rating
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: index < rating
                ? _kYellow
                : const Color(0xFFCFCFC8),
            size: 22,
          );
        },
      ),
    );
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
          'Reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _kBlack,
              ),
            )
          : reviews.isEmpty
              ? RefreshIndicator(
                  color: _kBlack,
                  backgroundColor: _kYellow,
                  onRefresh: loadReviews,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 150),
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: _kYellow.withValues(
                              alpha: 0.18,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.rate_review_outlined,
                            size: 42,
                            color: _kBlack,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'No reviews yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _kTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _kBlack,
                  backgroundColor: _kYellow,
                  onRefresh: loadReviews,
                  child: ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final review =
                          reviews[index];

                      final customer =
                          review['customer'];

                      final customerName =
                          customer?['name']
                                  ?.toString() ??
                              'Customer';

                      final rating =
                          int.tryParse(
                                review['rating']
                                    .toString(),
                              ) ??
                              0;

                      final comment =
                          review['comment']
                                  ?.toString() ??
                              '';

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(22),
                          border:
                              Border.all(color: _kBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration:
                                        const BoxDecoration(
                                      color: _kYellow,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: _kBlack,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child: Text(
                                      customerName,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: _kBlack,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kBlack,
                                      borderRadius:
                                          BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 15,
                                          color: _kYellow,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$rating.0',
                                          style:
                                              const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight:
                                                FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              buildStars(rating),

                              const SizedBox(height: 10),

                              if (comment.isNotEmpty)
                                Text(
                                  comment,
                                  style:
                                      const TextStyle(
                                    fontSize: 15,
                                    height: 1.45,
                                    color: _kTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}