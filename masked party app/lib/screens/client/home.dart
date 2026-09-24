// FILE LOCATION: lib/screens/client/home.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/post_service.dart';
import '../../services/follow_service.dart';
import '../../services/session_manager.dart';
import '../../services/wallet_service.dart';
import 'buy_coins.dart';
import 'notifications.dart';
import 'influencer_details.dart';
import '../auth/login.dart';
import '../auth/role_selection.dart';
import 'post_detail.dart';
import '../../widgets/influencer_preview_sheet.dart';

/// Client Home – public post feed (dating-app style cards).
/// Works for both guests and logged-in users.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final WalletService _walletService = WalletService();

  List<dynamic> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  double _coinBalance = 0;
  bool _isLoggedIn = false;

  final ScrollController _scrollController = ScrollController();

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _bgColor = Color(0xFFF8F9FE);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _goldColor = Color(0xFFFF9800);
  static const Color _goldLight = Color(0xFFFFF3E0);
  static const Color _goldDark = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _isLoggedIn = await SessionManager.isLoggedIn();
    if (_isLoggedIn) {
      _loadBalance();
    }
    await _loadPosts(refresh: true);
  }

  Future<void> _loadBalance() async {
  try {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return;
    final result = await _walletService.getBalance(token);
    if (result is Map && result['success'] == true) {
      final data = result['data'];
      if (data is Map) {
        setState(() {
          _coinBalance = double.tryParse(
                (data['current_balance'] ??
                        data['available_balance'] ??
                        data['balance'] ??
                        data['coins'] ??
                        0)
                    .toString()) ??
              0;
        });
      }
    }
  } catch (_) {}
}
  Future<void> _loadPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await PostService.listPosts(page: _page);
      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        final list = (data is Map ? data['posts'] : null) as List? ?? [];
        setState(() {
          if (refresh) {
            _posts = list;
          } else {
            _posts.addAll(list);
          }
          _hasMore = list.length >= 15;
          _page += 1;
          _isLoading = false;
          _isLoadingMore = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _error = result['message']?.toString() ?? 'Failed to load posts';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPosts();
    }
  }

  Future<void> _toggleLike(int index) async {
    if (!_isLoggedIn) {
      _promptLogin();
      return;
    }
    final post = Map<String, dynamic>.from(_posts[index] as Map);
    final postId = post['id'] as int;
    final liked = post['liked_by_me'] == true;

    setState(() {
      post['liked_by_me'] = !liked;
      post['like_count'] =
          ((post['like_count'] as int?) ?? 0) + (liked ? -1 : 1);
      _posts[index] = post;
    });

    final result = liked
        ? await PostService.unlikePost(postId)
        : await PostService.likePost(postId);

    if (result['success'] != true && mounted) {
      // revert
      setState(() {
        post['liked_by_me'] = liked;
        post['like_count'] =
            ((post['like_count'] as int?) ?? 0) + (liked ? 1 : -1);
        _posts[index] = post;
      });
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
              'Login or register to like, comment, follow and call influencers.',
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
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  );
                  if (mounted) _bootstrap();
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
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (mounted) _bootstrap();
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

  void _openInfluencerPreview(Map post) {
    final influencerId = post['influencer_id'] as int?;
    if (influencerId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InfluencerPreviewSheet(
        influencerId: influencerId,
        name: post['influencer_name']?.toString() ?? '',
        photo: post['influencer_photo']?.toString(),
        country: post['influencer_country']?.toString(),
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
        titleSpacing: 16,
        title: Row(
          children: [
            // Coin balance (left)
            GestureDetector(
              onTap: () {
                if (!_isLoggedIn) {
                  _promptLogin();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuyCoinsScreen()),
                ).then((_) => _loadBalance());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _goldLight,
                      _goldLight.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _goldColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _goldColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: _goldColor,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isLoggedIn ? _coinBalance.toStringAsFixed(0) : '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'MaskedParty',
              style: TextStyle(
                color: _primaryPink,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            // Notifications
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: _textDark,
                size: 24,
              ),
              onPressed: () {
                if (!_isLoggedIn) {
                  _promptLogin();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
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
      body: RefreshIndicator(
        color: _primaryPink,
        backgroundColor: Colors.white,
        onRefresh: () => _loadPosts(refresh: true),
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
    if (_error != null && _posts.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Colors.red.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _error!,
              style: const TextStyle(color: _textMedium, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _loadPosts(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_posts.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(24),
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
              Icons.photo_library_outlined,
              size: 56,
              color: _primaryPink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No posts yet',
              style: TextStyle(
                color: _textDark,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Influencers will share updates here',
              style: TextStyle(color: _textLight, fontSize: 14),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _posts.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: _primaryPink.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            ),
          );
        }
        return _PostCard(
          post: _posts[index] as Map,
          onLike: () => _toggleLike(index),
          onOpenProfile: () => _openInfluencerPreview(_posts[index] as Map),
          onOpenPost: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  postId: (_posts[index] as Map)['id'] as int,
                  isLoggedIn: _isLoggedIn,
                  onRequireAuth: _promptLogin,
                ),
              ),
            ).then((_) => _loadPosts(refresh: true));
          },
          onComment: () {
            if (!_isLoggedIn) {
              _promptLogin();
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  postId: (_posts[index] as Map)['id'] as int,
                  isLoggedIn: _isLoggedIn,
                  onRequireAuth: _promptLogin,
                  openKeyboard: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Post Card (dating-app style) ───────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final Map post;
  final VoidCallback onLike;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenPost;
  final VoidCallback onComment;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onOpenProfile,
    required this.onOpenPost,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final images = (post['images'] as List?) ?? [];
    final firstImage = images.isNotEmpty ? images[0]['url']?.toString() : null;
    final liked = post['liked_by_me'] == true;
    final likeCount = post['like_count'] ?? 0;
    final commentCount = post['comment_count'] ?? 0;
    final caption = post['caption']?.toString() ?? '';
    final bodyPreview = post['body_preview']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFE4EC).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name with enhanced design
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onOpenProfile,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF6B8B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: post['influencer_photo'] != null
                            ? CachedNetworkImageProvider(
                                post['influencer_photo'].toString())
                            : null,
                        child: post['influencer_photo'] == null
                            ? const Icon(
                                Icons.person_rounded,
                                color: Colors.grey,
                                size: 24,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpenProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['influencer_name']?.toString() ?? 'Influencer',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A1D2E),
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (post['influencer_country'] != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: const Color(0xFFE91E63).withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                post['influencer_country'].toString(),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image with enhanced design
          if (firstImage != null)
            GestureDetector(
              onTap: onOpenPost,
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: firstImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[100],
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

          // Actions with enhanced design
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: liked ? const Color(0xFFE91E63) : Colors.grey[600],
                    size: 28,
                  ),
                  onPressed: onLike,
                ),
                Text(
                  '$likeCount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: liked ? const Color(0xFFE91E63) : const Color(0xFF4B5563),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                  onPressed: onComment,
                ),
                Text(
                  '$commentCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Caption + body preview with enhanced design
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: GestureDetector(
              onTap: onOpenPost,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1D2E),
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (bodyPreview != null && bodyPreview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      bodyPreview,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'See more',
                      style: TextStyle(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}