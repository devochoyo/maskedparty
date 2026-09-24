// FILE LOCATION: lib/widgets/influencer_preview_sheet.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '../services/api.dart';
import '../services/api_endpoints.dart';
import '../services/follow_service.dart';
import '../services/session_manager.dart';
import '../screens/client/influencer_details.dart';

/// Bottom sheet shown when tapping an influencer avatar / card.
/// Shows photo, country, follower count, follow button, gallery carousel,
/// and Call Now.
class InfluencerPreviewSheet extends StatefulWidget {
  final int influencerId;
  final String name;
  final String? photo;
  final String? country;
  final bool isLoggedIn;
  final VoidCallback onRequireAuth;

  const InfluencerPreviewSheet({
    super.key,
    required this.influencerId,
    required this.name,
    this.photo,
    this.country,
    required this.isLoggedIn,
    required this.onRequireAuth,
  });

  @override
  State<InfluencerPreviewSheet> createState() => _InfluencerPreviewSheetState();
}

class _InfluencerPreviewSheetState extends State<InfluencerPreviewSheet> {
  bool _loading = true;
  Map<String, dynamic>? _details;
  int _followerCount = 0;
  bool _isFollowing = false;
  bool _followBusy = false;

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _bgColor = Color(0xFFF8F9FE);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await SessionManager.getToken();
      final headers = (token != null && token.isNotEmpty)
          ? ApiConfig.authHeaders(token)
          : ApiConfig.headers();

      final detailsResp = await http
          .get(
            ApiConfig.uri(ApiEndpoints.influencerDetails, queryParameters: {
              'id': widget.influencerId.toString(),
            }),
            headers: headers,
          )
          .timeout(ApiConfig.timeoutDuration);

      final detailsResult = ApiConfig.handleResponse(
        detailsResp,
        isAuthenticatedRequest: token != null && token.isNotEmpty,
      );

      final statusResult = await FollowService.status(widget.influencerId);

      if (!mounted) return;

      setState(() {
        if (detailsResult is Map && detailsResult['success'] == true) {
          _details = detailsResult['data'] is Map
              ? Map<String, dynamic>.from(detailsResult['data'])
              : null;
        }
        if (statusResult['success'] == true && statusResult['data'] is Map) {
          final d = statusResult['data'] as Map;
          _followerCount = (d['follower_count'] as num?)?.toInt() ?? 0;
          _isFollowing = d['is_following'] == true;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (!widget.isLoggedIn) {
      Navigator.pop(context);
      widget.onRequireAuth();
      return;
    }
    if (_followBusy) return;
    setState(() => _followBusy = true);

    final result = _isFollowing
        ? await FollowService.unfollow(widget.influencerId)
        : await FollowService.follow(widget.influencerId);

    if (!mounted) return;
    setState(() => _followBusy = false);

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _isFollowing = data is Map ? data['following'] == true : !_isFollowing;
        if (data is Map && data['follower_count'] != null) {
          _followerCount = (data['follower_count'] as num).toInt();
        } else {
          _followerCount += _isFollowing ? 1 : -1;
        }
      });
    } else if (result['requires_auth'] == true) {
      Navigator.pop(context);
      widget.onRequireAuth();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _callNow() {
    if (!widget.isLoggedIn) {
      Navigator.pop(context);
      widget.onRequireAuth();
      return;
    }
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InfluencerDetailsScreen(
          influencerId: widget.influencerId.toString(),
        ),
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = _details?['profile_photo']?.toString() ?? widget.photo;
    final name = _details?['mystery_name']?.toString() ?? widget.name;
    final country =
        _details?['country_name']?.toString() ?? widget.country ?? '';
    final gallery = (_details?['gallery'] as List?) ?? [];
    final bio = _details?['biography']?.toString();
    final whatOffer = _details?['what_offer']?.toString().trim();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _primaryPink))
              : ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _lightPink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Avatar - tap to view fullscreen
                    Center(
                      child: GestureDetector(
                        onTap: photo != null && photo.isNotEmpty
                            ? () => _showFullImage(photo)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryPink, _softPink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: photo != null
                                ? CachedNetworkImageProvider(photo)
                                : null,
                            child: photo == null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: _primaryPink.withValues(alpha: 0.3),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Center(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (country.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: _primaryPink.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              country,
                              style: const TextStyle(
                                color: _textMedium,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        '$_followerCount followers',
                        style: const TextStyle(
                          color: _textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _textMedium,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                    // What I will offer on the video call
                    if (whatOffer != null && whatOffer.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'What I will offer on the video call',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _lightPink.withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          whatOffer,
                          style: const TextStyle(
                            color: _textMedium,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Follow button
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? _lightPink
                                    : _primaryPink,
                                foregroundColor: _isFollowing
                                    ? _primaryPink
                                    : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _followBusy ? null : _toggleFollow,
                              child: _followBusy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (_isFollowing) ...[
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz,
                              color: _textLight,
                            ),
                            onSelected: (v) {
                              if (v == 'unfollow') _toggleFollow();
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'unfollow',
                                child: Text('Unfollow'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Call Now button
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryPink,
                          side: const BorderSide(color: _primaryPink, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: _callNow,
                        icon: const Icon(Icons.videocam_rounded, size: 20),
                        label: const Text(
                          'Call Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    // Gallery carousel
                    if (gallery.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'Gallery',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: gallery.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final item = gallery[i];
                            final url = item is Map
                                ? item['url']?.toString()
                                : item?.toString();
                            if (url == null) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () => _showFullImage(url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: _lightPink),
                                  errorWidget: (_, __, ___) => Container(
                                    color: _lightPink,
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: _textLight,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}