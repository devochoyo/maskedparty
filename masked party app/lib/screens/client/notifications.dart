// FILE LOCATION: lib/screens/client/notifications.dart
import 'package:flutter/material.dart';
import 'package:maskedparty/services/notification_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;

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
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
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
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (result is Map && result['success'] == true) {
          final data = result['data'];
          if (data is Map && data['notifications'] is List) {
            _notifications = data['notifications'];
          } else if (data is List) {
            _notifications = data;
          } else {
            _notifications = [];
          }
          _error = null;
        } else {
          _notifications = [];
          _error = (result is Map ? result['message'] : null) ?? 'Failed to load notifications';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _notifications = [];
        _error = e.toString().replaceFirst('Exception: ', '');
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
    await _notificationService.markAllAsRead(token);
    _loadNotifications();
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'payment':
        return Icons.account_balance_wallet_rounded;
      case 'call':
        return Icons.phone_in_talk_rounded;
      case 'message':
        return Icons.mail_rounded;
      case 'profile':
        return Icons.person_rounded;
      case 'offer':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String? type) {
    switch (type) {
      case 'payment':
        return const Color(0xFF00BFA5);
      case 'call':
        return _primaryPink;
      case 'message':
        return const Color(0xFF9C27B0);
      case 'profile':
        return const Color(0xFF2196F3);
      case 'offer':
        return const Color(0xFFFF9800);
      default:
        return _primaryPink;
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
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: _textDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_notifications.any((n) => n is Map && n['is_read'] == false))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _markAllAsRead,
                style: TextButton.styleFrom(
                  foregroundColor: _primaryPink,
                ),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 13,
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
          : _error != null
              ? _buildErrorState()
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(_notifications[index]);
                        },
                      ),
                    ),
    ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notif) {
    if (notif is! Map) return const SizedBox.shrink();

    final id = notif['id']?.toString() ?? '';
    final type = notif['type']?.toString();
    final title = notif['title']?.toString() ?? 'Notification';
    final subtitle = notif['message']?.toString() ?? '';
    final isUnread = notif['is_read'] == false;
    final timeAgo = _timeAgo(notif);
    final color = _colorFor(type);

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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnread ? Colors.white : _bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isUnread
                    ? _primaryPink.withValues(alpha: 0.2)
                    : _lightPink.withValues(alpha: 0.3),
                width: isUnread ? 1.5 : 1,
              ),
              boxShadow: isUnread
                  ? [
                      BoxShadow(
                        color: _primaryPink.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconFor(type),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                color: _textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeAgo.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              timeAgo,
                              style: const TextStyle(
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
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textMedium,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: _primaryPink,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryPink.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
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
              onPressed: _loadNotifications,
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
                color: _primaryPink.withValues(alpha: 0.08),
                shape: BoxShape.circle,
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