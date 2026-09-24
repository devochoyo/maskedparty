// FILE LOCATION: lib/services/post_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';
import 'session_manager.dart';

class PostService {
  /// Public home feed. Works for guests and logged-in users.
  /// When logged in, each post includes `liked_by_me`.
  static Future<Map<String, dynamic>> listPosts({int page = 1}) async {
    final token = await SessionManager.getToken();
    final uri = ApiConfig.uri(
      ApiEndpoints.postList,
      queryParameters: {'page': page.toString()},
    );

    final headers = (token != null && token.isNotEmpty)
        ? ApiConfig.authHeaders(token)
        : ApiConfig.headers();

    final response = await http
        .get(uri, headers: headers)
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(
      response,
      isAuthenticatedRequest: token != null && token.isNotEmpty,
    );
  }

  /// Full single post (caption + full body + images).
  static Future<Map<String, dynamic>> getPost(int postId) async {
    final token = await SessionManager.getToken();
    final uri = ApiConfig.uri(
      ApiEndpoints.postGet,
      queryParameters: {'id': postId.toString()},
    );

    final headers = (token != null && token.isNotEmpty)
        ? ApiConfig.authHeaders(token)
        : ApiConfig.headers();

    final response = await http
        .get(uri, headers: headers)
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(
      response,
      isAuthenticatedRequest: token != null && token.isNotEmpty,
    );
  }

  /// Influencer creates a post. Supports 0..n images.
  static Future<Map<String, dynamic>> createPost({
    required String caption,
    String? body,
    List<File>? images,
  }) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Please login again.'};
    }

    final uri = ApiConfig.uri(ApiEndpoints.postCreate);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(ApiConfig.multipartHeaders(token));
    request.fields['caption'] = caption;
    if (body != null && body.trim().isNotEmpty) {
      request.fields['body'] = body.trim();
    }

    if (images != null) {
      for (final file in images) {
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        final multipart = http.MultipartFile(
          'images[]',
          stream,
          length,
          filename: file.path.split(Platform.pathSeparator).last,
        );
        request.files.add(multipart);
      }
    }

    final streamed = await request.send().timeout(ApiConfig.timeoutDuration);
    final response = await http.Response.fromStream(streamed);
    return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
  }

  static Future<Map<String, dynamic>> likePost(int postId) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Please login to like posts.'};
    }

    final response = await http
        .post(
          ApiConfig.uri(ApiEndpoints.postLike),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'post_id': postId}),
        )
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
  }

  static Future<Map<String, dynamic>> unlikePost(int postId) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Please login again.'};
    }

    final response = await http
        .post(
          ApiConfig.uri(ApiEndpoints.postUnlike),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'post_id': postId}),
        )
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
  }

  static Future<Map<String, dynamic>> addComment({
    required int postId,
    required String comment,
  }) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Please login to comment.'};
    }

    final response = await http
        .post(
          ApiConfig.uri(ApiEndpoints.postComment),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode({'post_id': postId, 'comment': comment}),
        )
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
  }

  static Future<Map<String, dynamic>> listComments({
    required int postId,
    int page = 1,
  }) async {
    final uri = ApiConfig.uri(
      ApiEndpoints.postComments,
      queryParameters: {
        'post_id': postId.toString(),
        'page': page.toString(),
      },
    );

    final response = await http
        .get(uri, headers: ApiConfig.headers())
        .timeout(ApiConfig.timeoutDuration);

    return ApiConfig.handleResponse(response, isAuthenticatedRequest: false);
  }
}
