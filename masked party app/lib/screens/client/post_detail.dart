// FILE LOCATION: lib/screens/client/post_detail.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/post_service.dart';
import '../../widgets/influencer_preview_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final bool isLoggedIn;
  final VoidCallback onRequireAuth;
  final bool openKeyboard;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.isLoggedIn,
    required this.onRequireAuth,
    this.openKeyboard = false,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? _post;
  List<dynamic> _comments = [];
  bool _loading = true;
  bool _sending = false;
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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
    if (widget.openKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final postResult = await PostService.getPost(widget.postId);
    final commentsResult =
        await PostService.listComments(postId: widget.postId);

    if (!mounted) return;
    setState(() {
      if (postResult['success'] == true && postResult['data'] is Map) {
        _post = Map<String, dynamic>.from(
            (postResult['data'] as Map)['post'] as Map? ?? {});
      }
      if (commentsResult['success'] == true && commentsResult['data'] is Map) {
        _comments =
            (commentsResult['data'] as Map)['comments'] as List? ?? [];
      }
      _loading = false;
    });
  }

  Future<void> _toggleLike() async {
    if (!widget.isLoggedIn) {
      widget.onRequireAuth();
      return;
    }
    if (_post == null) return;
    final liked = _post!['liked_by_me'] == true;
    setState(() {
      _post!['liked_by_me'] = !liked;
      _post!['like_count'] =
          ((_post!['like_count'] as int?) ?? 0) + (liked ? -1 : 1);
    });
    final result = liked
        ? await PostService.unlikePost(widget.postId)
        : await PostService.likePost(widget.postId);
    if (result['success'] != true && mounted) {
      setState(() {
        _post!['liked_by_me'] = liked;
        _post!['like_count'] =
            ((_post!['like_count'] as int?) ?? 0) + (liked ? 1 : -1);
      });
    }
  }

  Future<void> _sendComment() async {
    if (!widget.isLoggedIn) {
      widget.onRequireAuth();
      return;
    }
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result =
        await PostService.addComment(postId: widget.postId, comment: text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result['success'] == true) {
      _commentCtrl.clear();
      final c = result['data']?['comment'];
      if (c != null) {
        setState(() {
          _comments.add(c);
          _post!['comment_count'] =
              ((_post!['comment_count'] as int?) ?? 0) + 1;
        });
      } else {
        _load();
      }
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
        iconTheme: const IconThemeData(color: _textDark),
        title: const Text(
          'Post',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
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
          : _post == null
              ? const Center(child: Text('Post not found'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          // Header with gradient avatar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: _lightPink.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => InfluencerPreviewSheet(
                                        influencerId: _post!['influencer_id'] as int,
                                        name: _post!['influencer_name']?.toString() ?? '',
                                        photo: _post!['influencer_photo']?.toString(),
                                        country: _post!['influencer_country']?.toString(),
                                        isLoggedIn: widget.isLoggedIn,
                                        onRequireAuth: widget.onRequireAuth,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryPink, _softPink],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.white,
                                      backgroundImage: _post!['influencer_photo'] != null
                                          ? CachedNetworkImageProvider(
                                              _post!['influencer_photo'].toString())
                                          : null,
                                      child: _post!['influencer_photo'] == null
                                          ? Icon(
                                              Icons.person_rounded,
                                              color: _primaryPink.withValues(alpha: 0.4),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _post!['influencer_name']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: _textDark,
                                        ),
                                      ),
                                      if (_post!['influencer_country'] != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              size: 13,
                                              color: _primaryPink.withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              _post!['influencer_country'].toString(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: _textMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Images
                          ...((_post!['images'] as List?) ?? []).map((img) {
                            final url = img is Map ? img['url']?.toString() : null;
                            if (url == null) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryPink.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (_, __) => Container(
                                    height: 300,
                                    color: _lightPink,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _primaryPink,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    height: 300,
                                    color: _lightPink,
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: _primaryPink.withValues(alpha: 0.4),
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Actions
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: _post!['liked_by_me'] == true
                                        ? _primaryPink.withValues(alpha: 0.1)
                                        : _lightPink.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _post!['liked_by_me'] == true
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: _post!['liked_by_me'] == true
                                          ? _primaryPink
                                          : _textMedium,
                                      size: 26,
                                    ),
                                    onPressed: _toggleLike,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_post!['like_count'] ?? 0}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _post!['liked_by_me'] == true
                                        ? _primaryPink
                                        : _textDark,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: _textMedium,
                                  size: 22,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_post!['comment_count'] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Caption
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              _post!['caption']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _textDark,
                              ),
                            ),
                          ),
                          if (_post!['body'] != null && _post!['body'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _lightPink.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _lightPink.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _post!['body'].toString(),
                                style: const TextStyle(
                                  color: _textMedium,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: _lightPink.withValues(alpha: 0.3),
                          ),
                          // Comments header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _primaryPink.withValues(alpha: 0.12),
                                        _softPink.withValues(alpha: 0.06),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 14,
                                    color: _primaryPink,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Comments',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: _textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Comments list
                          ..._comments.map((c) {
                            final m = c as Map;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _lightPink.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      gradient: m['user_photo'] == null
                                          ? const LinearGradient(
                                              colors: [_primaryPink, _softPink],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white,
                                      backgroundImage: m['user_photo'] != null
                                          ? CachedNetworkImageProvider(
                                              m['user_photo'].toString())
                                          : null,
                                      child: m['user_photo'] == null
                                          ? const Icon(
                                              Icons.person_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['user_name']?.toString() ?? 'User',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: _textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          m['comment']?.toString() ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _textMedium,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    // Comment input
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: _lightPink.withValues(alpha: 0.4),
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryPink.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _lightPink.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: _lightPink.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _commentCtrl,
                                  focusNode: _focusNode,
                                  style: const TextStyle(fontSize: 14, color: _textDark),
                                  decoration: InputDecoration(
                                    hintText: 'Add a comment…',
                                    hintStyle: TextStyle(color: _textLight, fontSize: 14),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryPink, _softPink],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryPink.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _sending ? null : _sendComment,
                                icon: _sending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    ),
      ),
    );
  }
}