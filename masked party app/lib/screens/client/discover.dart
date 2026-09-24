// FILE LOCATION: lib/screens/client/discover.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:http/http.dart' as http;

import '../../services/api.dart';
import '../../services/api_endpoints.dart';
import '../../services/session_manager.dart';
import '../../widgets/influencer_preview_sheet.dart';
import '../auth/login.dart';
import '../auth/role_selection.dart';

/// Discover – list of influencers (dating-app style).
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<dynamic> _influencers = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoggedIn = false;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _bgColor = Color(0xFFF8F9FE);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _onlineGreen = Color(0xFF00C853);
  static const Color _ratingGold = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _isLoggedIn = await SessionManager.isLoggedIn();
    await _load(refresh: true);
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else if (!_hasMore) {
      return;
    }

    try {
      final search = _searchController.text.trim();
      final uri = ApiConfig.uri(ApiEndpoints.influencerList, queryParameters: {
        'page': _page.toString(),
        if (search.isNotEmpty) 'search': search,
      });

      final token = await SessionManager.getToken();
      final headers = (token != null && token.isNotEmpty)
          ? ApiConfig.authHeaders(token)
          : ApiConfig.headers();

      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.timeoutDuration);

      final result = ApiConfig.handleResponse(
        response,
        isAuthenticatedRequest: token != null && token.isNotEmpty,
      );

      if (!mounted) return;

      if (result is Map && result['success'] == true) {
        final data = result['data'];
        final list = (data is Map ? data['influencers'] : null) as List? ?? [];
        setState(() {
          if (refresh) {
            _influencers = list;
          } else {
            _influencers.addAll(list);
          }
          _hasMore = list.length >= 20;
          _page += 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = (result is Map ? result['message'] : null)?.toString() ??
              'Failed to load';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Network error';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _load();
    }
  }

  void _promptLogin() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
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
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: _primaryPink,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Join MaskedParty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Login or register to follow and call influencers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMedium,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPink, _softPink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  );
                },
                child: const Text(
                  'Register',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryPink,
                  side: const BorderSide(color: _primaryPink, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPreview(Map inf) {
    final id = inf['id'] as int?;
    if (id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => InfluencerPreviewSheet(
        influencerId: id,
        name: inf['mystery_name']?.toString() ?? '',
        photo: inf['profile_photo']?.toString(),
        country: inf['country_name']?.toString(),
        isLoggedIn: _isLoggedIn,
        onRequireAuth: _promptLogin,
      ),
    );
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
        title: const Text(
          'Discover',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _lightPink.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _load(refresh: true),
                style: const TextStyle(fontSize: 15, color: _textDark),
                decoration: InputDecoration(
                  hintText: 'Search influencers…',
                  hintStyle: TextStyle(color: _textLight, fontSize: 15),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _primaryPink.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: _textLight,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _load(refresh: true);
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _primaryPink,
        backgroundColor: Colors.white,
        onRefresh: () => _load(refresh: true),
        child: _buildBody(),
      ),
    ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _primaryPink,
          strokeWidth: 3,
        ),
      );
    }
    if (_error != null && _influencers.isEmpty) {
      return _buildErrorState();
    }
    if (_influencers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _influencers.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _influencers.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: _primaryPink.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            ),
          );
        }
        final inf = _influencers[index] as Map;
        return _InfluencerListTile(
          data: inf,
          onTap: () => _openPreview(inf),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14, color: _textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _load(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
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
              ),
              child: Icon(
                Icons.search_rounded,
                color: _primaryPink,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No influencers found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your search',
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

class _InfluencerListTile extends StatelessWidget {
  final Map data;
  final VoidCallback onTap;

  const _InfluencerListTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = data['profile_photo']?.toString();
    final name = data['mystery_name']?.toString() ?? 'Influencer';
    final country = data['country_name']?.toString() ?? '';
    final rating = data['average_rating'];
    final online = data['online_status'] == 'online' ||
        data['online_status'] == 1 ||
        data['online_status'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFFE91E63).withValues(alpha: 0.05),
          highlightColor: const Color(0xFFE91E63).withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFFFE4EC).withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular profile picture with online indicator
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: photo == null || photo.isEmpty
                            ? const LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFFFF6B8B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE91E63)
                                .withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: photo != null && photo.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photo,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFE91E63),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 32,
                                  color: Colors.grey[400],
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                    ),
                    if (online)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2.5,
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
                const SizedBox(width: 14),
                // Name and country
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1A1D2E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (country.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: const Color(0xFFE91E63)
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                country,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Rating on the right
                if (rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1D2E),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}