// FILE LOCATION: lib/services/influencer_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api.dart';
import 'api_endpoints.dart';

/// Timeout budget for the verification upload's network send, used instead
/// of [ApiConfig.timeoutDuration] (which is 30s — sized for small JSON
/// requests, not a file upload). The caller (VerificationScreen) also
/// applies its own outer timeout for the whole flow, kept in sync with this.
const Duration kVerificationUploadTimeout = Duration(seconds: 90);

class InfluencerService {
  /// The influencer's OWN gallery (for management: view/delete). For a
  /// public profile's gallery, see ClientService.getInfluencerDetails,
  /// which returns gallery as part of influencer/details.php.
  /// Backend: api/influencer/gallery.php — GET — role: influencer
  Future<dynamic> getGallery(String token) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.influencerGallery),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Backend: api/influencer/delete-gallery-image.php — role: influencer
  /// body: {image_id}
  Future<dynamic> deleteGalleryImage(String token, String imageId) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.influencerDeleteGalleryImage),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({"image_id": imageId}),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Backend: api/influencer/complete-profile.php — role: influencer.
  /// Required keys in [data]: biography, age, complexion, favourite_food,
  /// hobby, aspiration, financial_target, mask_status,
  /// willing_to_remove_mask. On success flips profile_completed to true.
  Future<dynamic> completeProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.influencerCompleteProfile),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode(data),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Uploads one or more gallery images/videos.
  ///
  /// Backend: api/influencer/upload-gallery.php — role: influencer —
  /// multipart field name MUST be "gallery_images" (repeated for each
  /// file). The backend enforces a maximum of 10 gallery items per
  /// influencer and reports per-file failures in `data.upload_errors`.
  Future<dynamic> uploadGallery(String token, List<String> filePaths) async {
    try {
      final request = http.MultipartRequest(
        "POST",
        ApiConfig.uri(ApiEndpoints.influencerUploadGallery),
      );

      request.headers.addAll(ApiConfig.multipartHeaders(token));

      for (final path in filePaths) {
        request.files.add(
          await http.MultipartFile.fromPath("gallery_images", path),
        );
      }

      final streamedResponse =
          await request.send().timeout(ApiConfig.timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Submits the influencer's verification documents.
  ///
  /// Backend: api/influencer/verification.php — role: influencer.
  /// Required multipart file fields (ALL THREE are required — the backend
  /// returns a validation error if any is missing):
  ///   - "government_id"      (photo ID)                — REQUIRED
  ///   - "selfie"              (selfie photo)             — REQUIRED
  ///   - "verification_video"  (short verification clip)  — REQUIRED
  Future<dynamic> submitVerification(
    String token, {
    required String governmentIdPath,
    required String selfiePath,
    required String verificationVideoPath,
  }) {
    return submitVerificationWithProgress(
      token,
      governmentIdPath: governmentIdPath,
      selfiePath: selfiePath,
      verificationVideoPath: verificationVideoPath,
    );
  }

  /// Submits verification documents WITH real upload progress tracking.
  ///
  /// Uses a normal [http.MultipartRequest.send] — the same code path as
  /// [UploadService.uploadVideo], which is known to reach PHP.
  Future<dynamic> submitVerificationWithProgress(
    String token, {
    required String governmentIdPath,
    required String selfiePath,
    required String verificationVideoPath,
    void Function(int sent, int total)? onProgress,
  }) async {
    http.Client? client;
    try {
      final uri = ApiConfig.uri(ApiEndpoints.influencerVerification);

      final govPath = _normalizePath(governmentIdPath);
      final selfieNorm = _normalizePath(selfiePath);
      final videoPath = _normalizePath(verificationVideoPath);

      final govId = File(govPath);
      final selfie = File(selfieNorm);
      final video = File(videoPath);

      if (!await govId.exists()) {
        return {
          'success': false,
          'message': 'Your government ID file is missing. Please re-upload it.',
        };
      }
      if (!await selfie.exists()) {
        return {
          'success': false,
          'message': 'Your selfie photo is missing. Please take it again.',
        };
      }
      if (!await video.exists()) {
        return {
          'success': false,
          'message':
              'Your verification video is missing. Please record it again.',
        };
      }

      final govLen = await govId.length();
      final selfieLen = await selfie.length();
      final videoLen = await video.length();

      if (govLen == 0 || selfieLen == 0 || videoLen == 0) {
        return {
          'success': false,
          'message':
              'One of your files is empty. Please recapture the missing document and try again.',
        };
      }

      final fileBytesTotal = govLen + selfieLen + videoLen;

      developer.log(
        'verification POST $uri '
        'gov=${_kb(govLen)} selfie=${_kb(selfieLen)} video=${_kb(videoLen)} '
        'videoName=${_uploadFilename(videoPath, 'verification_video.mp4')}',
        name: 'InfluencerService',
      );

      int fileBytesSent = 0;
      void bump(int chunk) {
        fileBytesSent += chunk;
        final total = fileBytesTotal <= 0 ? 1 : fileBytesTotal;
        onProgress?.call(fileBytesSent.clamp(0, total), total);
      }

      final request = http.MultipartRequest("POST", uri);
      request.headers.addAll(ApiConfig.multipartHeaders(token));

      request.files.add(
        await _trackedMultipartFile(
          field: "government_id",
          path: govPath,
          length: govLen,
          fallbackName: "government_id.jpg",
          fallbackType: MediaType("image", "jpeg"),
          onChunk: bump,
        ),
      );
      request.files.add(
        await _trackedMultipartFile(
          field: "selfie",
          path: selfieNorm,
          length: selfieLen,
          fallbackName: "selfie.jpg",
          fallbackType: MediaType("image", "jpeg"),
          onChunk: bump,
        ),
      );
      request.files.add(
        await _trackedMultipartFile(
          field: "verification_video",
          path: videoPath,
          length: videoLen,
          fallbackName: "verification_video.mp4",
          fallbackType: MediaType("video", "mp4"),
          onChunk: bump,
        ),
      );

      client = http.Client();
      final streamedResponse = await client
          .send(request)
          .timeout(kVerificationUploadTimeout);
      final response = await http.Response.fromStream(streamedResponse)
          .timeout(const Duration(seconds: 30));

      developer.log(
        'verification response HTTP ${response.statusCode} '
        'body=${response.body.length}b',
        name: 'InfluencerService',
      );

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e, st) {
      developer.log(
        'verification failed: $e',
        name: 'InfluencerService',
        stackTrace: st,
      );
      return ApiConfig.handleError(e);
    } finally {
      client?.close();
    }
  }

  /// Manually toggles the influencer's own visibility.
  ///
  /// Backend: api/influencer/online-status.php — role: influencer —
  /// body: {status} where status is one of "online" | "offline" |
  /// "unavailable" (a plain string — NOT a boolean). "busy" is set
  /// automatically by the call lifecycle and cannot be set here; the
  /// backend rejects any attempt to change status while on an active call
  /// (HTTP 409).
  Future<dynamic> updateOnlineStatus(String token, String status) async {
    try {
      final response = await http
          .post(
            ApiConfig.uri(ApiEndpoints.influencerOnlineStatus),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              "status": status,
            }),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }

  /// Backend: api/influencer/earnings.php — GET — role: influencer.
  /// Returns today/this_week/this_month/lifetime earnings, current
  /// wallet + escrow balance, and call counts.
  Future<dynamic> getEarnings(String token) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.influencerEarnings),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}

Future<http.MultipartFile> _trackedMultipartFile({
  required String field,
  required String path,
  required int length,
  required String fallbackName,
  required MediaType fallbackType,
  required void Function(int chunkBytes) onChunk,
}) async {
  final filename = _uploadFilename(path, fallbackName);
  final type = _uploadMediaType(filename, fallbackType);

  return http.MultipartFile(
    field,
    File(path).openRead().map((chunk) {
      onChunk(chunk.length);
      return chunk;
    }),
    length,
    filename: filename,
    contentType: type,
  );
}

String _normalizePath(String path) {
  var p = path.trim();
  if (p.startsWith('file://')) {
    try {
      p = Uri.parse(p).toFilePath();
    } catch (_) {}
  }
  return p;
}

String _uploadFilename(String path, String fallback) {
  final p = _normalizePath(path);
  final base = p.replaceAll('\\', '/').split('/').last;
  if (base.contains('.') && !base.startsWith('.') && base.length > 3) {
    return base;
  }
  return fallback;
}

MediaType _uploadMediaType(String filename, MediaType fallback) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  }
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
    return MediaType('image', 'heic');
  }
  if (lower.endsWith('.mp4')) return MediaType('video', 'mp4');
  if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
  if (lower.endsWith('.webm')) return MediaType('video', 'webm');
  if (lower.endsWith('.m4v')) return MediaType('video', 'x-m4v');
  if (lower.endsWith('.3gp')) return MediaType('video', '3gpp');
  return fallback;
}

String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(1)}KB';