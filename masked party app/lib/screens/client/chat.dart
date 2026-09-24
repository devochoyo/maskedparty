// FILE LOCATION: lib/screens/client/chat.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maskedparty/services/chat_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import '../shared/chat_detail.dart';
import '../auth/login.dart';
import '../auth/role_selection.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String _query = '';
  String? _error;
  Timer? _poller;
  bool _isGuest = false;

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _bgColor = Color(0xFFF8F9FE);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _onlineGreen = Color(0xFF00C853);

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _loadConversations(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!mounted) return;
    
    if (!silent) {
      setState(() { _isLoading = true; _error = null; });
    }
    
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _isGuest = true;
            _isLoading = false;
            _conversations = [];
          });
        }
        return;
      }
      if (mounted) setState(() => _isGuest = false);
      
      final result = await _chatService.getConversations(token).timeout(const Duration(seconds: 15));
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _error = null;
        if (result is Map && result['success'] == true) {
          final data = result['data'];
          if (data is List) { _conversations = data; }
          else if (data is Map && data['conversations'] is List) { _conversations = data['conversations']; }
          else if (data is Map && data['chats'] is List) { _conversations = data['chats']; }
          else { _conversations = []; }
        } else if (!silent) {
          _conversations = [];
          _error = (result is Map ? result['message'] : null) ?? 'Failed to load conversations';
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() { _isLoading = false; _conversations = []; _error = e.toString().replaceFirst('Exception: ', ''); });
      }
    }
  }

  List<dynamic> get _filtered {
    if (_query.isEmpty) return _conversations;
    return _conversations.where((c) {
      final user = c is Map ? c['user'] : null;
      final name = user is Map ? (user['mystery_name']?.toString().toLowerCase() ?? '') : '';
      return name.contains(_query);
    }).toList();
  }

  String _formatLastSeen(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inDays > 7) return '${dateTime.day}/${dateTime.month}';
      if (difference.inDays > 0) return '${difference.inDays}d';
      if (difference.inHours > 0) return '${difference.inHours}h';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m';
      return 'now';
    } catch (e) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    if (_isGuest) {
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
            'Chats',
            style: TextStyle(
              color: _textDark,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced icon with gradient circle
                Container(
                  width: 100,
                  height: 100,
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
                      color: _primaryPink.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 50,
                    color: _primaryPink.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login to view your chats',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to message influencers',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textMedium,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                // Register button with gradient - NOW GOES TO ROLE SELECTION
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
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                      );
                      if (mounted) _loadConversations();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
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
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      if (mounted) _loadConversations();
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
    }
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
          'Chats',
          style: TextStyle(
            color: _textDark,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _lightPink.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar with enhanced design
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                style: const TextStyle(fontSize: 15, color: _textDark),
                decoration: InputDecoration(
                  hintText: 'Search conversations',
                  hintStyle: TextStyle(color: _textLight, fontSize: 15),
                  prefixIcon: Icon(Icons.search_rounded, color: _primaryPink.withValues(alpha: 0.5), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 16, color: _textLight),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _primaryPink,
                      strokeWidth: 3,
                    ),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _filtered.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => _loadConversations(silent: false),
                            color: _primaryPink,
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final conv = _filtered[index];
                                if (conv is! Map) return const SizedBox.shrink();
                                
                                final user = conv['user'];
                                final name = user is Map ? (user['mystery_name']?.toString() ?? 'User') : 'User';
                                final photo = user is Map ? user['profile_photo']?.toString() : null;
                                final lastMessage = conv['last_message']?.toString() ?? '';
                                final time = conv['last_message_time']?.toString() ?? conv['last_message_at']?.toString() ?? '';
                                final unread = conv['unread_count'] ?? 0;
                                final unreadCount = (unread is num && unread > 0) ? unread.toInt() : 0;
                                final otherUserId = user is Map ? (user['id']?.toString() ?? '') : '';
                                final isOnline = user is Map && user['online_status'] == 'online';

                                return _buildChatTile(
                                  name: name,
                                  message: lastMessage,
                                  time: time,
                                  unreadCount: unreadCount,
                                  photoUrl: photo,
                                  isOnline: isOnline,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatDetailScreen(
                                          conversationId: conv['id']?.toString() ?? otherUserId,
                                          otherUserId: otherUserId,
                                          otherUserName: name,
                                          otherUserPhoto: photo,
                                        ),
                                      ),
                                    ).then((_) => _loadConversations(silent: true));
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildChatTile({
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required bool isOnline,
    required VoidCallback onTap,
    String? photoUrl,
  }) {
    final displayTime = _formatLastSeen(time);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: _primaryPink.withValues(alpha: 0.08),
          highlightColor: _primaryPink.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: unreadCount > 0
                    ? _primaryPink.withValues(alpha: 0.15)
                    : Colors.transparent,
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
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: photoUrl == null || photoUrl.isEmpty
                            ? const LinearGradient(
                                colors: [_primaryPink, _softPink],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        image: (photoUrl != null && photoUrl.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryPink.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _onlineGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _cardColor,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _onlineGreen.withValues(alpha: 0.3),
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
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                color: _textDark,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (displayTime.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              displayTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadCount > 0 ? _primaryPink : _textLight,
                                fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.isNotEmpty ? message : 'No messages yet',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: unreadCount > 0 ? _textDark : _textMedium,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryPink, _softPink],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryPink.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ],
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 32),
            ),
            const SizedBox(height: 18),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _textMedium),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => _loadConversations(silent: false),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                gradient: const LinearGradient(
                  colors: [_primaryPink, _softPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 22),
            Text(
              _conversations.isEmpty ? 'No conversations yet' : 'No matches',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _conversations.isEmpty ? 'Start chatting with influencers\nthey\'ll appear here' : 'Try a different search',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: _textMedium,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}