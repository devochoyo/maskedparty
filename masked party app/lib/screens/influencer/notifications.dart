// FILE LOCATION: lib/screens/influencer/notifications.dart
import 'package:flutter/material.dart';
import 'package:maskedparty/services/notification_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class InfluencerNotificationsScreen extends StatefulWidget {
  const InfluencerNotificationsScreen({super.key});

  @override
  State<InfluencerNotificationsScreen> createState() => _InfluencerNotificationsScreenState();
}

class _InfluencerNotificationsScreenState extends State<InfluencerNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

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
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }
      
      final result = await _notificationService.getNotifications(token).timeout(
        const Duration(seconds: 15),
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (result is Map && result['success'] == true) {
          final data = result['data'] ?? {};
          if (data is Map) {
            _notifications = data['notifications'] ?? [];
            final uc = data['unread_count'];
            _unreadCount = (uc is num) ? uc.toInt() : 0;
          } else if (data is List) {
            _notifications = data;
            _unreadCount = 0;
          } else {
            _notifications = [];
            _unreadCount = 0;
          }
        } else {
          _notifications = [];
          _unreadCount = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _notifications = [];
        _unreadCount = 0;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    await _notificationService.markAsRead(token, id);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    final result = await _notificationService.markAllAsRead(token);
    if (mounted && result is Map && result['success'] != true) {
      final message = result['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Failed to mark notifications as read'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    _loadNotifications();
  }

  ({IconData icon, Color color}) _styleFor(String? type) {
    switch (type) {
      case 'call':
      case 'call_request':
        return (icon: Icons.phone_in_talk_rounded, color: _primaryPink);
      case 'verification':
        return (icon: Icons.verified_rounded, color: const Color(0xFF00BFA5));
      case 'withdrawal':
        return (icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF00BFA5));
      case 'review':
        return (icon: Icons.star_rounded, color: const Color(0xFFFFB300));
      case 'message':
      case 'chat':
        return (icon: Icons.mail_rounded, color: const Color(0xFF9C27B0));
      case 'profile':
        return (icon: Icons.person_rounded, color: const Color(0xFF2196F3));
      default:
        return (icon: Icons.notifications_rounded, color: _textLight);
    }
  }

  String _timeAgo(dynamic notif) {
    final date = notif is Map ? (notif['created_at']?.toString() ?? '') : '';
    if (date.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 7) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textDark, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: _textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: TextStyle(
                  color: _primaryPink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryPink.withValues(alpha: 0.12),
                    _softPink.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _primaryPink.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: _markAllAsRead,
                style: TextButton.styleFrom(
                  foregroundColor: _primaryPink,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _lightPink.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryPink,
                strokeWidth: 3,
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: _primaryPink,
                  backgroundColor: Colors.white,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      if (notif is! Map) return const SizedBox.shrink();
                      
                      final id = notif['id']?.toString() ?? '';
                      final title = notif['title']?.toString() ?? '';
                      final message = notif['message']?.toString() ?? '';
                      final isRead = notif['read'] == true || notif['is_read'] == true;
                      final type = notif['type']?.toString();
                      final style = _styleFor(type);
                      final timeAgo = _timeAgo(notif);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () => _markAsRead(id),
                            borderRadius: BorderRadius.circular(18),
                            splashColor: _primaryPink.withValues(alpha: 0.05),
                            highlightColor: _primaryPink.withValues(alpha: 0.03),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: isRead
                                    ? null
                                    : LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _lightPink.withValues(alpha: 0.5),
                                          Colors.white,
                                        ],
                                      ),
                                color: isRead ? _cardColor : null,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isRead
                                      ? _lightPink.withValues(alpha: 0.4)
                                      : _primaryPink.withValues(alpha: 0.3),
                                  width: isRead ? 1 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isRead
                                        ? Colors.black.withValues(alpha: 0.03)
                                        : _primaryPink.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon with gradient background
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          style.color.withValues(alpha: 0.12),
                                          style.color.withValues(alpha: 0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: style.color.withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      style.icon,
                                      color: style.color,
                                      size: 22,
                                    ),
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
                                                title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w700,
                                                  color: _textDark,
                                                  letterSpacing: 0.1,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (timeAgo.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                timeAgo,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: _textLight,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          message,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _textMedium,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Unread indicator
                                  if (!isRead) ...[
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [_primaryPink, _softPink],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryPink.withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                Icons.notifications_none_rounded,
                color: _primaryPink.withValues(alpha: 0.6),
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No notifications',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You\'re all caught up!',
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