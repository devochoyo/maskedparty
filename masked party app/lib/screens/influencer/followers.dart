// FILE LOCATION: lib/screens/influencer/followers.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/follow_service.dart';
import '../../services/session_manager.dart';

class InfluencerFollowersScreen extends StatefulWidget {
  const InfluencerFollowersScreen({super.key});

  @override
  State<InfluencerFollowersScreen> createState() =>
      _InfluencerFollowersScreenState();
}

class _InfluencerFollowersScreenState extends State<InfluencerFollowersScreen> {
  List<dynamic> _followers = [];
  bool _loading = true;
  int _total = 0;
  int? _myId;

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _bgColor = Color(0xFFF8F9FE);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await SessionManager.getUser();
    final id = user?['id'];
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    _myId = id is int ? id : int.tryParse(id.toString());
    if (_myId == null) {
      setState(() => _loading = false);
      return;
    }

    final result = await FollowService.listFollowers(influencerId: _myId!);
    if (!mounted) return;
    setState(() {
      if (result['success'] == true && result['data'] is Map) {
        final data = result['data'] as Map;
        _followers = data['followers'] as List? ?? [];
        _total = (data['follower_count'] as num?)?.toInt() ?? _followers.length;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: isSmallScreen
            ? const TextScaler.linear(0.92)
            : MediaQuery.of(context).textScaler,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          visualDensity: isSmallScreen
              ? VisualDensity.compact
              : Theme.of(context).visualDensity,
        ),
        child: Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const Text(
              'Followers',
              style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryPink.withValues(alpha: 0.12),
                    _softPink.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _primaryPink.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '$_total',
                style: const TextStyle(
                  color: _primaryPink,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _lightPink.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryPink,
                strokeWidth: 3,
              ),
            )
          : _followers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: _primaryPink,
                  backgroundColor: Colors.white,
                  onRefresh: _load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _followers.length,
                    itemBuilder: (context, i) {
                      final f = _followers[i] as Map;
                      return _buildFollowerCard(f);
                    },
                  ),
                ),
    ),
      ),
    );
  }

  Widget _buildFollowerCard(Map f) {
    final photo = f['profile_photo']?.toString();
    final name = f['mystery_name']?.toString() ?? 'User';
    final country = f['country_name']?.toString();
    final isOnline = f['online_status'] == 'online' ||
        f['online_status'] == 1 ||
        f['online_status'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            // Optional: Navigate to follower profile
          },
          borderRadius: BorderRadius.circular(18),
          splashColor: _primaryPink.withValues(alpha: 0.05),
          highlightColor: _primaryPink.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _lightPink.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with gradient border
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryPink, _softPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: photo != null && photo.isNotEmpty
                                ? CachedNetworkImageProvider(photo)
                                : null,
                            child: photo == null || photo.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: Colors.grey,
                                    size: 24,
                                  )
                                : null,
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C853)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name and country
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: _textDark,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (country != null && country.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: _primaryPink.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                country,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textMedium,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow indicator
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primaryPink.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: _textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryPink.withValues(alpha: 0.1),
                    _softPink.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _primaryPink.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: _primaryPink.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No followers yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your followers will appear here',
              style: TextStyle(
                fontSize: 14,
                color: _textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}