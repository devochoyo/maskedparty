import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maskedparty/services/chat_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import '../shared/chat_detail.dart';

class InfluencerChatScreen extends StatefulWidget {
  const InfluencerChatScreen({super.key});

  @override
  State<InfluencerChatScreen> createState() => _InfluencerChatScreenState();
}

class _InfluencerChatScreenState extends State<InfluencerChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String _query = '';
  String? _error;
  Timer? _poller;

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
    _loadConversations();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    // Silent polling every 2 seconds
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _loadConversations(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!mounted) return;
    
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }
      
      final result = await _chatService.getConversations(token).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _error = null;
        if (result is Map && result['success'] == true) {
          final data = result['data'];
          if (data is List) {
            _conversations = data;
          } else if (data is Map && data['conversations'] is List) {
            _conversations = data['conversations'];
          } else if (data is Map && data['chats'] is List) {
            _conversations = data['chats'];
          } else {
            _conversations = [];
          }
        } else if (!silent) {
          _conversations = [];
          _error = (result is Map ? result['message'] : null) ?? 'Failed to load conversations';
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _isLoading = false;
          _conversations = [];
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<dynamic> get _filtered {
    if (_query.isEmpty) return _conversations;
    return _conversations.where((c) {
      final otherUser = c is Map ? c['other_user'] : null;
      final user = c is Map ? c['user'] : null;
      final name = (otherUser is Map ? otherUser['mystery_name'] : null)?.toString().toLowerCase() ??
                  (user is Map ? user['mystery_name'] : null)?.toString().toLowerCase() ?? '';
      return name.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
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
        title: Text(
          'Messages',
          style: TextStyle(
            color: _textDark,
            fontSize: isSmallScreen ? 20 : 24,
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
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 12 : 16,
              isSmallScreen ? 10 : 12,
              isSmallScreen ? 12 : 16,
              isSmallScreen ? 6 : 8,
            ),
            child: Container(
              height: isSmallScreen ? 42 : 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                border: Border.all(
                  color: _lightPink.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.04),
                    blurRadius: isSmallScreen ? 6 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  color: _textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                    color: _textLight,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _primaryPink.withValues(alpha: 0.5),
                    size: isSmallScreen ? 18 : 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: isSmallScreen ? 14 : 16,
                            color: _textLight,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8 : 10,
                  ),
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
                    ? _buildErrorState(isSmallScreen)
                    : _filtered.isEmpty
                        ? _buildEmptyState(isSmallScreen)
                        : RefreshIndicator(
                            onRefresh: () => _loadConversations(silent: false),
                            color: _primaryPink,
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 6 : 8,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final conv = _filtered[index];
                                if (conv is! Map) return const SizedBox.shrink();
                                
                                final otherUser = conv['other_user'] ?? conv['user'];
                                final name = otherUser is Map ? (otherUser['mystery_name']?.toString() ?? 'User') : 'User';
                                final photo = otherUser is Map ? otherUser['profile_photo']?.toString() : null;
                                final lastMessage = conv['last_message']?.toString() ?? '';
                                final time = conv['last_message_time']?.toString() ?? conv['last_message_at']?.toString() ?? '';
                                final unread = conv['unread_count'] ?? 0;
                                final unreadCount = (unread is num && unread > 0) ? unread.toInt() : 0;
                                final otherUserId = otherUser is Map ? (otherUser['id']?.toString() ?? '') : '';

                                return _buildChatTile(
                                  name: name,
                                  message: lastMessage,
                                  time: time,
                                  unreadCount: unreadCount,
                                  photoUrl: photo,
                                  isSmallScreen: isSmallScreen,
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
    required VoidCallback onTap,
    required bool isSmallScreen,
    String? photoUrl,
  }) {
    String displayTime = '';
    if (time.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(time);
        final now = DateTime.now();
        final difference = now.difference(dateTime);
        
        if (difference.inDays > 7) {
          displayTime = '${dateTime.day}/${dateTime.month}';
        } else if (difference.inDays > 0) {
          displayTime = '${difference.inDays}d';
        } else if (difference.inHours > 0) {
          displayTime = '${difference.inHours}h';
        } else if (difference.inMinutes > 0) {
          displayTime = '${difference.inMinutes}m';
        } else {
          displayTime = 'now';
        }
      } catch (e) {
        displayTime = time;
      }
    }

    final avatarSize = isSmallScreen ? 44.0 : 52.0;
    final borderRadius = isSmallScreen ? 14.0 : 18.0;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: _primaryPink.withValues(alpha: 0.05),
          highlightColor: _primaryPink.withValues(alpha: 0.03),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: unreadCount > 0
                    ? _primaryPink.withValues(alpha: 0.15)
                    : _lightPink.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: isSmallScreen ? 6 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with gradient border
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 1.5 : 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryPink, _softPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 13 : 16),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 1.5 : 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 11 : 14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 9 : 12),
                      child: (photoUrl != null && photoUrl.isNotEmpty)
                          ? Image.network(
                              photoUrl,
                              height: avatarSize,
                              width: avatarSize,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatarFallback(name, isSmallScreen),
                            )
                          : _avatarFallback(name, isSmallScreen),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 14),
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
                                fontSize: isSmallScreen ? 13 : 15,
                                fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                color: _textDark,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (displayTime.isNotEmpty) ...[
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Text(
                              displayTime,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9 : 11,
                                color: unreadCount > 0 ? _primaryPink : _textLight,
                                fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 3 : 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.isNotEmpty ? message : 'No messages yet',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
                                color: message.isNotEmpty ? _textMedium : _textLight,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: isSmallScreen ? 2 : 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryPink, _softPink],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryPink.withValues(alpha: 0.3),
                                    blurRadius: isSmallScreen ? 4 : 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 9 : 11,
                                  fontWeight: FontWeight.bold,
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

  Widget _avatarFallback(String name, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 44 : 52,
      width: isSmallScreen ? 44 : 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryPink.withValues(alpha: 0.1),
            _softPink.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: _primaryPink,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 20,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: isSmallScreen ? 32 : 40,
              ),
            ),
            SizedBox(height: isSmallScreen ? 14 : 18),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              _error!,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: _textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 18 : 24),
            ElevatedButton.icon(
              onPressed: () => _loadConversations(silent: false),
              icon: Icon(Icons.refresh_rounded, size: isSmallScreen ? 16 : 18),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 18 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 22 : 28),
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
                Icons.chat_bubble_outline_rounded,
                color: _primaryPink,
                size: isSmallScreen ? 32 : 40,
              ),
            ),
            SizedBox(height: isSmallScreen ? 14 : 18),
            Text(
              _conversations.isEmpty ? 'No conversations yet' : 'No matches',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              _conversations.isEmpty ? 'Start chatting with clients' : 'Try a different search',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: _textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}