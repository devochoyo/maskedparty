// FILE LOCATION: lib/services/upload_service.dart
//
// Generic single-file uploads (e.g. chat attachments, or a profile photo
// that will then be attached via ProfileService.updateProfile's
// "profile_photo" field). These are distinct from the influencer-specific
// upload endpoints (gallery / verification), which live in
// InfluencerService because they carry different required field names and
// business rules.
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

/// FIX: ApiConfig.timeoutDuration is only 30s — sized for small JSON calls,
/// not multi-MB file uploads. Every method below previously used that 30s
/// timeout, so any image/video/document upload on a slow connection (or any
/// video at all) could be killed mid-transfer long before it had a chance
/// to finish. These give each upload type a size-appropriate budget instead,
/// the same pattern already used for the influencer verification upload.
const Duration kImageUploadTimeout = Duration(minutes: 1);
const Duration kDocumentUploadTimeout = Duration(minutes: 1);
const Duration kVideoUploadTimeout = Duration(minutes: 3);

class UploadService {
  /// Backend: api/upload/image.php — multipart field name MUST be "image"
  /// (the backend checks $_FILES["image"] specifically).
  Future<dynamic> uploadImage(String token, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'Selected image file could not be found.'};
      }

      final request = http.MultipartRequest(
        "POST",
        ApiConfig.uri(ApiEndpoints.uploadImage),
      );

      request.headers.addAll(ApiConfig.multipartHeaders(token));
      request.files.add(await http.MultipartFile.fromPath("image", filePath));

      final streamedResponse =
          await request.send().timeout(kImageUploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Backend: api/upload/video.php — multipart field name MUST be "video"
  /// (the backend checks $_FILES["video"] specifically).
  Future<dynamic> uploadVideo(String token, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'Recorded video file could not be found.'};
      }

      final request = http.MultipartRequest(
        "POST",
        ApiConfig.uri(ApiEndpoints.uploadVideo),
      );

      request.headers.addAll(ApiConfig.multipartHeaders(token));
      request.files.add(await http.MultipartFile.fromPath("video", filePath));

      final streamedResponse =
          await request.send().timeout(kVideoUploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Backend: api/upload/document.php — multipart field name MUST be
  /// "document" (the backend checks $_FILES["document"] specifically).
  Future<dynamic> uploadDocument(String token, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'Selected document file could not be found.'};
      }

      final request = http.MultipartRequest(
        "POST",
        ApiConfig.uri(ApiEndpoints.uploadDocument),
      );

      request.headers.addAll(ApiConfig.multipartHeaders(token));
      request.files
          .add(await http.MultipartFile.fromPath("document", filePath));

      final streamedResponse =
          await request.send().timeout(kDocumentUploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// FIX: new method for the dedicated profile-photo endpoint.
  /// Backend: api/profile/upload-photo.php — multipart field name MUST be
  /// "photo". Stores the file under uploads/profiles/ (not uploads/chat/...)
  /// and persists it to users.profile_photo directly, so the app no longer
  /// needs a separate ProfileService.updateProfile call just to attach the
  /// photo path (though calling it again with the same value afterwards is
  /// still harmless).
  Future<dynamic> uploadProfilePhoto(String token, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'Selected photo could not be found.'};
      }

      final request = http.MultipartRequest(
        "POST",
        ApiConfig.uri(ApiEndpoints.profileUploadPhoto),
      );

      request.headers.addAll(ApiConfig.multipartHeaders(token));
      request.files.add(await http.MultipartFile.fromPath("photo", filePath));

      final streamedResponse =
          await request.send().timeout(kImageUploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}