// FILE LOCATION: lib/screens/shared/chat_detail.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maskedparty/services/chat_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isOnline = false;
  String? _myUserId;
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
  static const Color _onlineGreen = Color(0xFF00C853);

  @override
  void initState() {
    super.initState();
    _init();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = await SessionManager.getUser();
    _myUserId = user?['id']?.toString();
    await _loadMessages(silent: false);
  }

  Future<void> _loadMessages({bool silent = false}) async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final result = await _chatService.getMessages(token, widget.otherUserId);
    if (!mounted) return;

    if (result is Map && result['success'] == true) {
      final data = result['data'];
      List<dynamic> messages = [];
      if (data is List) { messages = data; }
      else if (data is Map) { messages = (data['messages'] ?? data['data'] ?? data['chats'] ?? data['items'] ?? []) as List<dynamic>; }
      
      final onlineStatus = data is Map ? data['online_status'] : null;
      
      setState(() {
        _messages = messages;
        if (onlineStatus != null) _isOnline = onlineStatus == 'online';
        if (!silent) _isLoading = false;
      });
      
      if (messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottomAnimated());
      }
    } else if (!silent) {
      setState(() => _isLoading = false);
    }
  }

  bool _hasNewMessages(List<dynamic> newMessages) {
    if (_messages.isEmpty) return newMessages.isNotEmpty;
    if (newMessages.isEmpty) return false;
    return newMessages.length > _messages.length;
  }

  void _scrollToBottomAnimated() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 0) return;
    
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final optimisticMessage = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'sender_id': _myUserId,
      'receiver_id': widget.otherUserId,
      'message': text,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
      'sending': true,
    };

    setState(() { _messages.add(optimisticMessage); _isSending = true; });
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottomAnimated());

    final result = await _chatService.sendMessage(token, widget.otherUserId, text);
    if (!mounted) return;

    setState(() => _isSending = false);

    if (result is Map && result['success'] == true) {
      final realMessage = {
        'id': result['data']?['message_id'] ?? optimisticMessage['id'],
        'sender_id': _myUserId, 'receiver_id': widget.otherUserId,
        'message': text, 'created_at': DateTime.now().toIso8601String(), 'is_read': false,
      };
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == optimisticMessage['id']);
        if (index != -1) _messages[index] = realMessage;
      });
      await _loadMessages(silent: true);
    } else {
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == optimisticMessage['id']);
        if (index != -1) _messages[index]['failed'] = true;
      });
      final message = result is Map ? result['message'] : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Failed to send message'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                setState(() => _messages.removeWhere((m) => m['id'] == optimisticMessage['id']));
                _messageController.text = text;
                _send();
              },
            ),
          ),
        );
      }
    }
  }

  bool _isMine(dynamic msg) {
    final senderId = msg['sender_id']?.toString();
    if (senderId == null || _myUserId == null) return false;
    return senderId == _myUserId;
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) { return ''; }
  }

  bool _isSameDay(String? d1, String? d2) {
    if (d1 == null || d2 == null) return true;
    try {
      final dt1 = DateTime.parse(d1), dt2 = DateTime.parse(d2);
      return dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day;
    } catch (e) { return true; }
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
        shadowColor: _primaryPink.withValues(alpha: 0.06),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textDark, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        leadingWidth: 48,
        titleSpacing: 0,
        title: Row(
          children: [
            // Profile picture with gradient border
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPink, _softPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.otherUserPhoto != null && widget.otherUserPhoto!.isNotEmpty
                      ? Image.network(
                          widget.otherUserPhoto!,
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isOnline ? _onlineGreen : _textLight,
                          shape: BoxShape.circle,
                          boxShadow: _isOnline
                              ? [
                                  BoxShadow(
                                    color: _onlineGreen.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isOnline ? 'Online' : 'Active',
                        style: TextStyle(
                          color: _isOnline ? _onlineGreen : _textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _primaryPink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.call_outlined, color: _primaryPink, size: 20),
              onPressed: () {},
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
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _primaryPink,
                      strokeWidth: 3,
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : GestureDetector(
                        onTap: () => _focusNode.unfocus(),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 4),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final mine = _isMine(msg);
                            final failed = msg['failed'] == true;
                            final sending = msg['sending'] == true;
                            final time = _formatTime(msg['created_at']?.toString());
                            final showDateSeparator = index == 0 || !_isSameDay(msg['created_at']?.toString(), index > 0 ? _messages[index - 1]['created_at']?.toString() : null);
                            
                            return Column(
                              children: [
                                if (showDateSeparator) _buildDateSeparator(msg['created_at']?.toString()),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutBack,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildMessageBubble(msg, mine, failed, sending, time),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryPink, _softPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSeparator(String? dateStr) {
    if (dateStr == null) return const SizedBox.shrink();
    String display = '';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        display = 'Today';
      } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) {
        display = 'Yesterday';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        display = '${months[dt.month - 1]} ${dt.day}${dt.year != now.year ? ', ${dt.year}' : ''}';
      }
    } catch (e) { return const SizedBox.shrink(); }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primaryPink.withValues(alpha: 0.08),
                _softPink.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _primaryPink.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Text(
            display,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: _textMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool mine, bool failed, bool sending, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: mine ? const EdgeInsets.only(left: 60) : const EdgeInsets.only(right: 60),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            gradient: failed
                ? null
                : mine
                    ? const LinearGradient(
                        colors: [_primaryPink, _softPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
            color: failed
                ? Colors.red.shade50
                : mine
                    ? null
                    : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: mine ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: mine ? const Radius.circular(4) : const Radius.circular(18),
            ),
            boxShadow: mine
                ? [
                    BoxShadow(
                      color: _primaryPink.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
            border: mine
                ? null
                : Border.all(
                    color: _lightPink.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
          ),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                msg['message'] ?? '',
                style: TextStyle(
                  color: failed
                      ? Colors.red.shade700
                      : mine
                          ? Colors.white
                          : _textDark,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: mine ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: mine
                          ? Colors.white.withValues(alpha: 0.7)
                          : _textLight,
                      height: 1,
                    ),
                  ),
                  if (mine && sending) ...[
                    const SizedBox(width: 3),
                    SizedBox(
                      height: 9,
                      width: 9,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  if (failed) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 11),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final hasText = _messageController.text.trim().isNotEmpty;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 6,
        top: 6,
        left: 10,
        right: 6,
      ),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 110),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _lightPink.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 14, color: _textDark),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: _textLight, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              gradient: hasText
                  ? const LinearGradient(
                      colors: [_primaryPink, _softPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasText ? null : Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
              boxShadow: hasText
                  ? [
                      BoxShadow(
                        color: _primaryPink.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: hasText ? _send : null,
                borderRadius: BorderRadius.circular(22),
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.send_rounded,
                      key: ValueKey(hasText),
                      color: hasText ? Colors.white : _textLight,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryPink, _softPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: _primaryPink.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(37),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: widget.otherUserPhoto != null && widget.otherUserPhoto!.isNotEmpty
                    ? Image.network(
                        widget.otherUserPhoto!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildEmptyAvatar(),
                      )
                    : _buildEmptyAvatar(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.otherUserName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send your first message to start\nthe conversation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _textMedium,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryPink, _softPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),
    );
  }
}