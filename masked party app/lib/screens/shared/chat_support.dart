// FILE LOCATION: lib/screens/shared/chat_support.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../services/session_manager.dart';
import 'rate_support.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final SupportService _supportService = SupportService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _conversationId;
  String? _conversationStatus;
  String? _assignedAgentName;
  bool _needsSurvey = false;
  Timer? _poller;
  Set<int> _pendingMessageIds = {}; // Track messages being sent

  // True from the moment the user taps "Start New Conversation" until the
  // first message of that new conversation is actually sent successfully.
  // While true, _loadConversation() (including the background poller) is
  // skipped entirely — otherwise the poller would re-fetch the old, ended
  // conversation from the server and stomp the freshly-reset UI state
  // right back to "ended" before the user gets a chance to type.
  bool _startingNewConversation = false;

  // Set when the initial load finds the customer's most recent conversation
  // already `ended` and it still owes a satisfaction survey. We don't want
  // to make them look at (or be blocked by) that old, locked thread just to
  // reach the survey, so we jump straight to a fresh compose state and
  // surface a small "rate your last conversation" nudge instead, using this
  // id to link to it.
  int? _pendingSurveyConversationId;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _loadConversation(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation({bool silent = false}) async {
    // Skip while we're in the "starting a new conversation" transitional
    // state — see _startingNewConversation doc comment above.
    if (_startingNewConversation) return;

    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final result = await _supportService.getMyConversation(token);
    if (!mounted) return;

    // Re-check: the user may have tapped "Start New Conversation" while
    // this request was in flight. The check at the top of this method
    // only catches requests that hadn't started yet — a request already
    // in the air (e.g. from the 3s poller) would otherwise land here
    // *after* the reset and repopulate the UI with the old, ended
    // conversation. Bail out and let the reset state stand.
    if (_startingNewConversation) return;

    if (result['success'] == true) {
      final data = result['data'];
      if (data is Map) {
        // The API nests conversation fields under `data.conversation` and
        // keeps `messages` alongside it — read from there, not the top level.
        final conversation = data['conversation'];
        final messages = data['messages'] is List ? data['messages'] as List : <dynamic>[];

        // Remove confirmed messages from pending set
        if (silent && _pendingMessageIds.isNotEmpty) {
          for (final msg in messages) {
            if (msg is Map && msg['id'] != null) {
              final msgId = msg['id'];
              if (msgId is int) {
                _pendingMessageIds.remove(msgId);
              } else if (msgId is String) {
                _pendingMessageIds.remove(int.tryParse(msgId));
              }
            }
          }
        }

        setState(() {
          if (conversation is Map) {
            _conversationId = conversation['id'] is int
                ? conversation['id']
                : int.tryParse(conversation['id']?.toString() ?? '');
            _conversationStatus = conversation['status']?.toString();
            _assignedAgentName = conversation['agent_name']?.toString();
            _needsSurvey = conversation['needs_survey'] == true;
          } else {
            // No conversation yet — customer hasn't contacted support.
            _conversationId = null;
            _conversationStatus = null;
            _assignedAgentName = null;
            _needsSurvey = false;
          }
          _messages = messages;
          if (!silent) _isLoading = false;
        });

        _scrollToBottom();
      }
    } else if (!silent) {
      setState(() => _isLoading = false);
    }
  }

  // Resets the screen to a blank-slate "new conversation" state. The old
  // (ended) conversation stays intact on the server — contact.php only
  // reuses a ticket that's still `pending`/`active`, so the very next
  // message the customer sends will be attached to a brand-new ticket
  // automatically. We just need the UI to get out of the way and let them
  // type it.
  void _startNewConversation() {
    setState(() {
      _startingNewConversation = true;
      _conversationId = null;
      _conversationStatus = null;
      _assignedAgentName = null;
      _needsSurvey = false;
      _messages = [];
      _pendingMessageIds = {};
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final token = await SessionManager.getToken();
    if (token == null) return;

    // Create optimistic message
    final optimisticMsg = {
      'id': DateTime.now().millisecondsSinceEpoch, // temporary ID
      'message': text,
      'sender_type': 'customer',
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sending',
    };

    // Immediately add to messages list
    setState(() {
      _messages.add(optimisticMsg);
      _pendingMessageIds.add(optimisticMsg['id'] as int);
      _isSending = true;
    });
    _messageController.clear();

    // Scroll to bottom immediately
    _scrollToBottom();

    try {
      dynamic result;
      if (_conversationId == null) {
        result = await _supportService.contactSupport(token, text);
      } else {
        result = await _supportService.sendMessage(token, _conversationId!, text);
      }

      if (!mounted) return;
      setState(() => _isSending = false);

      if (result['success'] == true) {
        // The message went through — if this was the first message of a
        // freshly-started conversation, it's safe to let polling resume
        // and pick up the new ticket the backend just created.
        if (_startingNewConversation) {
          setState(() => _startingNewConversation = false);
        }
        // Refresh to get the actual message from server
        await _loadConversation(silent: true);
      } else {
        // Remove the optimistic message on failure. Deliberately leave
        // _startingNewConversation untouched here — if it was true, it
        // stays true, so the poller keeps ignoring stale server state
        // and the user can just retry the send from the same blank slate.
        setState(() {
          _messages.removeWhere((msg) => 
            msg is Map && msg['id'] == optimisticMsg['id']);
          _pendingMessageIds.remove(optimisticMsg['id'] as int);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send message'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          // Remove the optimistic message on error. Same reasoning as
          // above: _startingNewConversation is left as-is on failure.
          _messages.removeWhere((msg) => 
            msg is Map && msg['id'] == optimisticMsg['id']);
          _pendingMessageIds.remove(optimisticMsg['id'] as int);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  bool _isMine(dynamic msg) {
    final senderType = msg['sender_type']?.toString() ?? '';
    return senderType == 'customer' || senderType == 'client' || senderType == 'influencer';
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    // Once _startNewConversation() has been called, treat the screen as
    // fresh/not-ended even though the poller hasn't confirmed it yet.
    final isEnded = !_startingNewConversation && _conversationStatus == 'ended';

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
      backgroundColor: const Color(0xFFF0EDF2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1D2E), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Support',
              style: TextStyle(
                color: Color(0xFF1A1D2E),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_assignedAgentName != null)
              Text(
                _assignedAgentName!,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          if (msg is! Map) return const SizedBox.shrink();
                          final mine = _isMine(msg);
                          final text = msg['message']?.toString() ?? '';
                          final time = _formatTime(msg['created_at']?.toString());
                          final msgId = msg['id'];
                          final isPending = msgId != null && _pendingMessageIds.contains(
                            msgId is int ? msgId : int.tryParse(msgId.toString())
                          );
                          final status = msg['status']?.toString() ?? '';

                          return _MessageBubble(
                            mine: mine,
                            text: text,
                            time: time,
                            isPending: isPending,
                            status: status,
                            index: index,
                          );
                        },
                      ),
          ),
          if (isEnded) _buildEndedBar() else _buildInputBar(),
        ],
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFFE91E63),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Customer Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send us a message and we\'ll get back to you',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 6,
        top: 6,
        left: 10,
        right: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDF2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1D2E)),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: const Color(0xFFE91E63),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: _isSending ? null : _sendMessage,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(11),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shown instead of the input bar once the conversation has ended:
  // the typing field is fully blocked (not just disabled — it's replaced
  // with a locked, non-editable bar). A "Rate Customer Care" button is
  // shown when the customer hasn't submitted the survey yet, and a
  // "Start New Conversation" button is always shown so the customer isn't
  // stuck looking at a locked, ended thread.
  Widget _buildEndedBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDF2),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  'This conversation has ended',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_needsSurvey) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RateSupportScreen(
                        conversationId: _conversationId ?? 0,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.star_rounded, size: 18),
                label: const Text(
                  'Rate Customer Care',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: const Text(
                'Start New Conversation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE91E63),
                side: const BorderSide(color: Color(0xFFE91E63)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Message Bubble Widget ──────────────────────────────────
class _MessageBubble extends StatefulWidget {
  final bool mine;
  final String text;
  final String time;
  final bool isPending;
  final String status;
  final int index;

  const _MessageBubble({
    required this.mine,
    required this.text,
    required this.time,
    required this.isPending,
    required this.status,
    required this.index,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: Offset(
              widget.mine
                  ? 20 * (1 - _slideAnimation.value)
                  : -20 * (1 - _slideAnimation.value),
              0,
            ),
            child: Opacity(
              opacity: _animationController.value,
              child: child,
            ),
          ),
        );
      },
      child: Align(
        alignment: widget.mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.mine ? const Color(0xFFE91E63) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: widget.mine ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: widget.mine ? const Radius.circular(4) : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isPending ? 0.1 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
                style: TextStyle(
                  color: widget.mine ? Colors.white : const Color(0xFF1A1D2E),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (widget.time.isNotEmpty || widget.isPending) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.time.isNotEmpty)
                      Text(
                        widget.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.mine ? Colors.white.withOpacity(0.65) : Colors.grey,
                        ),
                      ),
                    if (widget.isPending) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.mine
                                ? Colors.white.withOpacity(0.65)
                                : Colors.grey[400]!,
                          ),
                        ),
                      ),
                    ] else if (widget.mine && widget.status == 'sent') ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}