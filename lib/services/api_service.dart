import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

import '../utils/session.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080';
  // ============================================================
  // TEST CONNECTION
  // ============================================================

  static Future<void> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/test'),
      );

      debugPrint(
        'Status Code: ${response.statusCode}',
      );

      debugPrint(
        'Response: ${response.body}',
      );
    } catch (e) {
      debugPrint(
        'API Connection Error: $e',
      );
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/users/register',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        }),
      );

      debugPrint(
        'Status Code: ${response.statusCode}',
      );

      debugPrint(
        'Response: ${response.body}',
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      debugPrint(
        'Registration Error: $e',
      );

      return false;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/users/login',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint(
        'Login Status Code: ${response.statusCode}',
      );

      debugPrint(
        'Login Response: ${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrint(
        'Login Error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // ADD ROLE
  // ============================================================

  static Future<bool> addRole({
    required String email,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/users/add-role'
          '?email=${Uri.encodeComponent(email)}'
          '&role=$role',
        ),
      );

      debugPrint(
        'Add Role Status Code: ${response.statusCode}',
      );

      debugPrint(
        'Add Role Response: ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Add Role Error: $e',
      );

      return false;
    }
  }

  // ============================================================
  // SAVE PROVIDER PROFILE
  // ============================================================

  static Future<bool> saveProviderProfile({
    required String email,
    required String name,
    required String phone,
    required String nicNumber,
    required String location,
    required int experience,
    required String description,
    required String serviceCategory,
    required String certificateName,
    required String issuingInstitute,
    required bool termsAccepted,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/provider-profile/save'
          '?email=${Uri.encodeComponent(email)}',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nicNumber': nicNumber,
          'location': location,
          'experience': experience,
          'description': description,
          'serviceCategory': serviceCategory,
          'certificateName': certificateName,
          'issuingInstitute': issuingInstitute,
          'termsAccepted': termsAccepted,
          'user': {
            'name': name,
            'phone': phone,
          },
        }),
      );

      debugPrint(
        'Provider Profile Status Code: ${response.statusCode}',
      );

      debugPrint(
        'Provider Profile Response: ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Provider Profile Error: $e');
      return false;
    }
  }

  // ============================================================
  // ADD SERVICE
  // ============================================================

  static Future<bool> addService({
    required String email,
    required String name,
    required String category,
    required String description,
    required double price,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/services/add'
          '?email=${Uri.encodeComponent(email)}',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'category': category,
          'description': description,
          'price': price,
        }),
      );

      debugPrint(
        'Add Service Status Code: '
        '${response.statusCode}',
      );

      debugPrint(
        'Add Service Response: '
        '${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Add Service Error: $e',
      );

      return false;
    }
  }

  // ============================================================
  // GET PROVIDER SERVICES
  // ============================================================

  static Future<List<dynamic>?> getProviderServices({
    required String email,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/services/provider/'
          '${Uri.encodeComponent(email)}',
        ),
      );

      debugPrint(
        'Get Services Status Code: '
        '${response.statusCode}',
      );

      debugPrint(
        'Get Services Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrint(
        'Get Services Error: $e',
      );

      return null;
    }
  }

  // ==================== GET PROVIDER AVAILABILITY ====================

  static Future<List<dynamic>> getProviderAvailability({
    required String email,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/provider-availability',
      ).replace(
        queryParameters: {
          'email': email,
        },
      );

      final response = await http.get(uri);

      debugPrint(
        'Provider Availability Status: ${response.statusCode}',
      );
      debugPrint(
        'Provider Availability Response: ${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint('Get Provider Availability Error: $e');
      return [];
    }
  }

  

  // ============================================================
  // ADD PROVIDER AVAILABILITY
  // ============================================================

  static Future<bool> addProviderAvailability({
    required String email,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/provider-availability',
      ).replace(
        queryParameters: {
          'email': email,
          'dayOfWeek': dayOfWeek,
          'startTime': startTime,
          'endTime': endTime,
        },
      );

      final response = await http.post(uri);

      debugPrint('Add Availability Status: ${response.statusCode}');
      debugPrint('Add Availability Response: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Add Availability Error: $e');
      return false;
    }
  }

  // ============================================================
  // UPDATE PROVIDER AVAILABILITY ON/OFF
  // ============================================================

  static Future<bool> updateProviderAvailability({
    required int id,
    required String email,
    required bool available,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/provider-availability/$id/availability',
      ).replace(
        queryParameters: {
          'email': email,
          'available': available.toString(),
        },
      );

      final response = await http.put(uri);

      debugPrint('Update Availability Status: ${response.statusCode}');
      debugPrint('Update Availability Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Availability Error: $e');
      return false;
    }
  }


  
  static Future<bool> addDateProviderAvailability({
    required String email,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/provider-availability/date',
      ).replace(queryParameters: {
        'email': email,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
      });

      final response = await http.post(uri);
      debugPrint('Add Date Availability: ${response.statusCode}');
      debugPrint(response.body);

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      debugPrint('Add Date Availability Error: $e');
      return false;
    }
  }

  static Future<bool> editProviderAvailability({
    required int id,
    required String email,
    required String startTime,
    required String endTime,
    String? date,
    String? dayOfWeek,
  }) async {
    try {
      final params = <String, String>{
        'email': email,
        'startTime': startTime,
        'endTime': endTime,
      };

      if (date != null) params['date'] = date;
      if (dayOfWeek != null) params['dayOfWeek'] = dayOfWeek;

      final uri = Uri.parse(
        '$baseUrl/api/provider-availability/$id',
      ).replace(queryParameters: params);

      final response = await http.put(uri);
      debugPrint('Edit Availability: ${response.statusCode}');
      debugPrint(response.body);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Edit Availability Error: $e');
      return false;
    }
  }

  static Future<bool> deleteProviderAvailability({
    required int id,
    required String email,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/provider-availability/$id',
      ).replace(queryParameters: {'email': email});

      final response = await http.delete(uri);
      debugPrint('Delete Availability: ${response.statusCode}');
      debugPrint(response.body);

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete Availability Error: $e');
      return false;
    }
  }


  // ============================================================
  // UPDATE SERVICE
  // ============================================================

  static Future<bool> updateService({
    required int id,
    required String email,
    required String name,
    required String category,
    required String description,
    required double price,
  }) async {
    debugPrint(
      '==============================',
    );

    debugPrint(
      'UPDATE SERVICE START',
    );

    try {
      final uri = Uri(
        scheme: 'http',
        host: '10.0.2.2',
        port: 8080,
        path: '/api/services/update/$id',
        queryParameters: {
          'email': email,
        },
      );

      debugPrint(
        'URI: $uri',
      );

      final body = jsonEncode({
        'name': name,
        'category': category,
        'description': description,
        'price': price,
      });

      debugPrint(
        'BODY: $body',
      );

      debugPrint(
        'SENDING PUT REQUEST...',
      );

      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type':
                  'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: 10),
          );

      debugPrint(
        'RESPONSE RECEIVED!',
      );

      debugPrint(
        'STATUS: ${response.statusCode}',
      );

      debugPrint(
        'BODY: ${response.body}',
      );

      return response.statusCode == 200;
    } on TimeoutException catch (e) {
      debugPrint(
        '!!!!!!!! TIMEOUT !!!!!!!!',
      );

      debugPrint(
        e.toString(),
      );

      return false;
    } catch (e, stackTrace) {
      debugPrint(
        '!!!!!!!! UPDATE ERROR !!!!!!!!',
      );

      debugPrint(
        e.toString(),
      );

      debugPrint(
        stackTrace.toString(),
      );

      return false;
    }
  }

  // ============================================================
  // DELETE SERVICE
  // ============================================================

  static Future<bool> deleteService({
    required int id,
    required String email,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '$baseUrl/api/services/delete/$id'
          '?email=${Uri.encodeComponent(email)}',
        ),
      );

      debugPrint(
        'Delete Service Status Code: '
        '${response.statusCode}',
      );

      debugPrint(
        'Delete Service Response: '
        '${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Delete Service Error: $e',
      );

      return false;
    }
  }

  // ============================================================
  // GET PROVIDERS
  // ============================================================

  static Future<List<dynamic>> getProviders() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/users/providers',
        ),
      );

      debugPrint(
        'Get Providers Status Code: '
        '${response.statusCode}',
      );

      debugPrint(
        'Get Providers Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint(
        'Get Providers Error: $e',
      );

      return [];
    }
  }

  // ============================================================
  // GET SERVICES BY CATEGORY
  // ============================================================

  static Future<List<dynamic>> getServicesByCategory(
    String category,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/services/category/'
          '${Uri.encodeComponent(category)}',
        ),
      );

      debugPrint(
        'Get Services By Category Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Get Services By Category Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint(
        'Get Services By Category Error: $e',
      );

      return [];
    }
  }

  // ============================================================
  // GET PROVIDER PROFILE
  // ============================================================

  static Future<Map<String, dynamic>?>
      getProviderProfile(
    String email,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/provider-profile/'
          '${Uri.encodeComponent(email)}',
        ),
      );

      debugPrint(
        'Get Provider Profile Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Get Provider Profile Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrint(
        'Get Provider Profile Error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // GET CUSTOMER REQUESTS
  // ============================================================

  static Future<List<dynamic>> getCustomerRequests({
    required String email,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/service-requests/customer'
          '?email=${Uri.encodeComponent(email)}',
        ),
      );

      debugPrint(
        'Get Customer Requests Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Get Customer Requests Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint(
        'Get Customer Requests Error: '
        '$e',
      );

      return [];
    }
  }

  
  // ============================================================
  // CREATE SERVICE REQUEST
  // Supports SCHEDULED and ON_DEMAND requests
  // Supports optional photo uploads
  // Converts selected photos to JPEG before uploading
  // ============================================================

  static Future<Map<String, dynamic>?> createServiceRequest({
    required String customerEmail,
    required String providerEmail,
    required int serviceId,
    required String serviceType,
    String? requestedDate,
    String? requestedTime,
    required String address,
    required String description,
    double? latitude,
    double? longitude,
    List<File> photos = const [],
  }) async {
    try {
      final Map<String, String> fields = {
        'customerEmail': customerEmail,
        'providerEmail': providerEmail,
        'serviceId': serviceId.toString(),
        'serviceType': serviceType,
        'address': address,
        'description': description,
      };

      // Date and time are required only for scheduled requests.
      if (serviceType == 'SCHEDULED') {
        if (requestedDate == null || requestedTime == null) {
          debugPrint('Scheduled requests require a date and time.');
          return null;
        }

        fields['requestedDate'] = requestedDate;
        fields['requestedTime'] = requestedTime;
      }

      // Add GPS coordinates if available.
      if (latitude != null && longitude != null) {
        fields['latitude'] = latitude.toString();
        fields['longitude'] = longitude.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/api/service-requests/create',
      );

      final request = http.MultipartRequest('POST', uri);

      request.fields.addAll(fields);

      // Convert selected photos to JPEG and attach them.
      if (photos.isNotEmpty) {
        final tempDirectory = await getTemporaryDirectory();

        int photoIndex = 0;

        for (final photo in photos.take(4)) {
          if (!await photo.exists()) {
            debugPrint('Photo does not exist: ${photo.path}');
            continue;
          }

          photoIndex++;

          final jpegPath =
              '${tempDirectory.path}/skilllink_${DateTime.now().microsecondsSinceEpoch}_$photoIndex.jpg';

          final compressedImage =
              await FlutterImageCompress.compressAndGetFile(
            photo.absolute.path,
            jpegPath,
            format: CompressFormat.jpeg,
            quality: 85,
          );

          if (compressedImage == null) {
            debugPrint('Failed to convert photo: ${photo.path}');
            return null;
          }

          final jpegFile = File(compressedImage.path);

          if (!await jpegFile.exists()) {
            debugPrint('Converted JPEG file does not exist.');
            continue;
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              'photos',
              jpegFile.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );

          debugPrint('JPEG photo added: ${jpegFile.path}');
        }
      }

      debugPrint(
        'Submitting service request with '
        '${request.files.length} photos',
      );

      // Send request.
      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'Create Service Request Status: ${response.statusCode}',
      );

      debugPrint(
        'Create Service Request Response: ${response.body}',
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('Create Service Request Error: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  
  // ============================================================
  // GET PROVIDER REQUESTS
  // ============================================================

  static Future<List<dynamic>> getProviderRequests({
    required String email,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/service-requests/provider'
          '?email=${Uri.encodeComponent(email)}',
        ),
      );

      debugPrint(
        'Get Provider Requests Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Get Provider Requests Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint(
        'Get Provider Requests Error: '
        '$e',
      );

      return [];
    }
  }

  // ============================================================
  // UPDATE SERVICE REQUEST STATUS
  // ============================================================

  static Future<bool> updateServiceRequestStatus({
    required int requestId,
    required String email,
    required String status,
    String? reason,
  }) async {
    try {
      final queryParameters = {
        'email': email,
        'status': status,
      };

      if (status == 'REJECTED') {
        if (reason == null || reason.trim().isEmpty) {
          debugPrint('Rejection reason is required.');
          return false;
        }

        queryParameters['reason'] = reason.trim();
      }

      final uri = Uri.parse(
        '$baseUrl/api/service-requests/update-status/$requestId',
      ).replace(queryParameters: queryParameters);

      final response = await http.put(uri);

      debugPrint('Update Status Code: ${response.statusCode}');
      debugPrint('Update Status Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Status Error: $e');
      return false;
    }
  }

  // ============================================================
  // PROVIDER PROPOSES / RESCHEDULES DATE AND TIME
  // ============================================================

  static Future<bool> proposeServiceRequestTime({
    required int requestId,
    required String email,
    required String proposedDate,
    required String proposedTime,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/service-requests/propose-time/$requestId',
      ).replace(
        queryParameters: {
          'email': email,
          'proposedDate': proposedDate,
          'proposedTime': proposedTime,
        },
      );

      final response = await http.put(uri);

      debugPrint('Propose Time Code: ${response.statusCode}');
      debugPrint('Propose Time Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Propose Time Error: $e');
      return false;
    }
  }

  // ============================================================
  // CUSTOMER CONFIRMS PROPOSED TIME
  // ============================================================

  static Future<bool> confirmServiceRequestTime({
    required int requestId,
    required String email,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/service-requests/confirm-time/$requestId',
      ).replace(
        queryParameters: {
          'email': email,
        },
      );

      final response = await http.put(uri);

      debugPrint('Confirm Time Code: ${response.statusCode}');
      debugPrint('Confirm Time Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Confirm Time Error: $e');
      return false;
    }
  }

  // ============================================================
  // CUSTOMER DECLINES PROPOSED TIME
  // ============================================================

  static Future<bool> declineServiceRequestTime({
    required int requestId,
    required String email,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/service-requests/decline-time/$requestId',
      ).replace(
        queryParameters: {
          'email': email,
        },
      );

      final response = await http.put(uri);

      debugPrint('Decline Time Code: ${response.statusCode}');
      debugPrint('Decline Time Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Decline Time Error: $e');
      return false;
    }
  }

  // ============================================================
  // CUSTOMER PROPOSES A NEW DATE AND TIME
  // ============================================================

  static Future<bool> customerProposeServiceRequestTime({
    required int requestId,
    required String email,
    required String proposedDate,
    required String proposedTime,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/service-requests/customer-propose-time/$requestId',
      ).replace(
        queryParameters: {
          'email': email,
          'proposedDate': proposedDate,
          'proposedTime': proposedTime,
        },
      );

      final response = await http.put(uri);

      debugPrint('Customer Propose Time Code: ${response.statusCode}');
      debugPrint('Customer Propose Time Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Customer Propose Time Error: $e');
      return false;
    }
  }

  // ============================================================
  // GET PROVIDER BOOKINGS
  // ============================================================

  static Future<List<dynamic>>
      getProviderBookings({
    required String email,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/service-requests/'
          'provider/bookings'
          '?email=${Uri.encodeComponent(email)}',
        ),
      );

      debugPrint(
        'Get Provider Bookings Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Get Provider Bookings Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint(
        'Get Provider Bookings Error: '
        '$e',
      );

      return [];
    }
  }

  // ============================================================
  // ADD REVIEW
  // ============================================================

  static Future<bool> addReview({
    required String customerEmail,
    required int serviceRequestId,
    required int rating,
    required String comment,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/reviews/add',
      ).replace(
        queryParameters: {
          'customerEmail': customerEmail,
          'serviceRequestId':
              serviceRequestId.toString(),
          'rating': rating.toString(),
          'comment': comment,
        },
      );

      final response = await http.post(uri);

      debugPrint(
        'Add Review Status Code: '
        '${response.statusCode}',
      );

      debugPrint(
        'Add Review Response: '
        '${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Add Review Error: '
        '$e',
      );

      return false;
    }
  }

  static Future<bool> hasReview(
  int serviceRequestId,
) async {
  try {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/reviews/check'
        '?serviceRequestId=$serviceRequestId',
      ),
    );

    debugPrint(
      'Check Review Status: ${response.statusCode}',
    );

    debugPrint(
      'Check Review Response: ${response.body}',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) == true;
    }

    return false;
  } catch (e) {
    debugPrint(
      'Check Review Error: $e',
    );

    return false;
  }
}

  // ============================================================
  // GET PROVIDER REVIEWS
  // ============================================================

  static Future<List<dynamic>>
      getProviderReviews(
    String email,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/reviews/provider'
        '?email=${Uri.encodeComponent(email)}',
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to load provider reviews',
      );
    }
  }

  // ============================================================
  // UPLOAD PROVIDER PROFILE IMAGE
  // ============================================================

  static Future<String?>
      uploadProviderProfileImage({
    required String email,
    required File image,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/api/provider-profile/'
          'upload-image',
        ),
      );

      request.fields['email'] = email;

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
        ),
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'Upload Profile Image Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Upload Profile Image Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return response.body;
      }

      return null;
    } catch (e) {
      debugPrint(
        'Upload Profile Image Error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // GET USER PROFILE
  // ============================================================

  static Future<Map<String, dynamic>?>
      getUserProfile({
    required String email,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/users/profile'
          '?email=${Uri.encodeComponent(email)}',
        ),
      );

      debugPrint(
        'Get User Profile Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Get User Profile Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrint(
        'Get User Profile Error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // UPDATE USER PROFILE
  // ============================================================

  static Future<bool> updateUserProfile({
    required String email,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/api/users/profile'
          '?email=${Uri.encodeComponent(email)}',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
        }),
      );

      debugPrint(
        'Update User Profile Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Update User Profile Response: '
        '${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Update User Profile Error: $e',
      );

      return false;
    }
  }

  // ============================================================
  // UPLOAD CUSTOMER PROFILE IMAGE
  // ============================================================

  static Future<String?>
      uploadCustomerProfileImage({
    required String email,
    required File image,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/api/customer-profile/'
          'upload-image',
        ),
      );

      request.fields['email'] = email;

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
        ),
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'Upload Customer Profile Image Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Upload Customer Profile Image Response: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        return response.body;
      }

      return null;
    } catch (e) {
      debugPrint(
        'Upload Customer Profile Image Error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/api/users/change-password',
        ),
        headers: {
          'Content-Type': 'application/json',

          // JWT TOKEN
          'Authorization':
              'Bearer ${Session.token}',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      debugPrint(
        'Change Password Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Change Password Response: '
        '${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Change Password Error: $e',
      );

      return false;
    }
  }

  // ==================== Send Chat Message ====================

  static Future<Map<String, dynamic>?> sendChatMessage({
    required String receiverEmail,
    required String message,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/chat/send',
      ).replace(
        queryParameters: {
          'receiverEmail': receiverEmail,
          'message': message,
        },
      );

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      debugPrint(
        'Send Chat Status: ${response.statusCode}',
      );

      debugPrint(
        'Send Chat Response: ${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrint(
        'Send Chat Error: $e',
      );

      return null;
    }
  }

  // ==================== Get Conversation ====================

  static Future<List<dynamic>> getChatConversation({
    required String otherUserEmail,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/chat/conversation',
      ).replace(
        queryParameters: {
          'otherUserEmail': otherUserEmail,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      debugPrint(
        'Get Chat Status: ${response.statusCode}',
      );

      debugPrint(
        'Get Chat Response: ${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint(
        'Get Chat Error: $e',
      );

      return [];
    }
  }

  // ==================== Get Notifications ====================

  static Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: {
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      debugPrint(
        'Get Notifications Status: ${response.statusCode}',
      );

      debugPrint(
        'Get Notifications Response: ${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      debugPrint(
        'Get Notifications Error: $e',
      );

      return [];
    }
  }

  // ==================== Get Unread Notification Count ====================

  static Future<int> getUnreadNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/notifications/unread-count',
        ),
        headers: {
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      debugPrint(
        'Unread Notification Status: ${response.statusCode}',
      );

      debugPrint(
        'Unread Notification Response: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return int.tryParse(
              data['count'].toString(),
            ) ??
            0;
      }

      return 0;
    } catch (e) {
      debugPrint(
        'Unread Notification Error: $e',
      );

      return 0;
    }
  }

  // ==================== Mark Notification as Read ====================

  static Future<bool> markNotificationAsRead(
    int notificationId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/api/notifications/$notificationId/read',
        ),
        headers: {
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      debugPrint(
        'Mark Notification Read Status: ${response.statusCode}',
      );

      debugPrint(
        'Mark Notification Read Response: ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Mark Notification Read Error: $e',
      );

      return false;
    }
  }

  // ==================== Mark All Notifications as Read ====================

  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/api/notifications/mark-all-read',
        ),
        headers: {
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      debugPrint(
        'Mark All Notifications Read Status: ${response.statusCode}',
      );

      debugPrint(
        'Mark All Notifications Read Response: ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Mark All Notifications Read Error: $e',
      );

      return false;
    }
  }
    // ==================== Save FCM Token ====================

  static Future<bool> saveFcmToken(
    String fcmToken,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/api/users/fcm-token',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Session.token}',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
        }),
      );

      debugPrint(
        'Save FCM Token Status: '
        '${response.statusCode}',
      );

      debugPrint(
        'Save FCM Token Response: '
        '${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Save FCM Token Error: $e',
      );

      return false;
    }
  }
  // ==================== Delete One Notification ====================

  static Future<bool> deleteNotification(
    int notificationId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '$baseUrl/api/notifications/$notificationId',
        ),
        headers: {
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      debugPrint(
        'Delete Notification Status: ${response.statusCode}',
      );

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete Notification Error: $e');
      return false;
    }
  }

  // ==================== Clear All Notifications ====================

  static Future<bool> clearAllNotifications() async {
    try {
      final response = await http.delete(
        Uri.parse(
          '$baseUrl/api/notifications/clear-all',
        ),
        headers: {
          'Authorization': 'Bearer ${Session.token}',
        },
      );

      debugPrint(
        'Clear All Notifications Status: ${response.statusCode}',
      );

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (e) {
      debugPrint('Clear All Notifications Error: $e');
      return false;
    }
  }

    // ============================================================
  // PROVIDER ACCEPTS CUSTOMER-PROPOSED TIME
  // ============================================================

  static Future<bool> acceptCustomerProposedTime({
    required int requestId,
    required String email,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/service-requests/accept-customer-time/$requestId',
      ).replace(
        queryParameters: {
          'email': email,
        },
      );

      final response = await http.put(uri);

      debugPrint(
        'Accept Customer Time Status: ${response.statusCode}',
      );

      debugPrint(
        'Accept Customer Time Response: ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Accept Customer Time Error: $e');
      return false;
    }
  }

  // ============================================================
  // PROVIDER DECLINES CUSTOMER-PROPOSED TIME
  // ============================================================

  static Future<bool> declineCustomerProposedTime({
    required int requestId,
    required String email,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/service-requests/decline-customer-time/$requestId',
      ).replace(
        queryParameters: {
          'email': email,
        },
      );

      final response = await http.put(uri);

      debugPrint(
        'Decline Customer Time Status: ${response.statusCode}',
      );

      debugPrint(
        'Decline Customer Time Response: ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Decline Customer Time Error: $e');
      return false;
    }
  }

}