// FILE LOCATION: lib/screens/influencer/video_call.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:videosdk/videosdk.dart';
import 'package:maskedparty/services/call_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'package:maskedparty/widgets/influencer_release.dart';
import 'package:maskedparty/screens/influencer/rating_screen.dart';
import 'package:maskedparty/widgets/client_release.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String clientName;

  final bool isInfluencer;

  const VideoCallScreen({
    super.key,
    required this.callId,
    this.clientName = 'Client',
    this.isInfluencer = true,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with TickerProviderStateMixin {
  final CallService _callService = CallService();

  String _countdownText = '--:--';
  Timer? _countdownPoller;
  Timer? _localTickTimer;
  bool _isConnecting = true;
  String? _connectError;
  bool _showRulesCard = true;
  String? _resolvedCallId;

  bool _hasEndedCall = false;
  bool _isEndingCall = false;
  bool _roomCleanedUp = false;

  Room? _room;
  Stream? _localVideoStream;
  Stream? _remoteVideoStream;
  final Map<String, Participant> _remoteParticipants = {};
  bool _micEnabled = true;
  bool _camEnabled = true;
  bool _speakerOn = true;
  bool _isLocalFullScreen = false;

  double? _pricePerMinute;
  double? _pricePerSecond;
  String _billingMode = 'standard';
  int _lastPaidDurationSeconds = 0;
  int _lastRemainingSeconds = 0;
  int? _actualDurationSeconds;
  int _elapsedSeconds = 0;
  DateTime? _callStartedAt;
  static const int _escrowAutoReleaseWindowSeconds = 1800;

  bool get _isPayg =>
      _billingMode == 'payg_minute' || _billingMode == 'payg_second';

  bool _showReleaseWidget = false;
  double _escrowCoins = 0;
  int _escrowRemainingSeconds = 0;
  bool _escrowReleased = false;

  final GlobalKey<InfluencerReleaseWidgetState> _influencerReleaseKey =
      GlobalKey<InfluencerReleaseWidgetState>();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _darkBg = Color(0xFF1A1A2E);
  static const Color _successGreen = Color(0xFF00C853);
  static const Color _dangerRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _connectToCall();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownPoller?.cancel();
    _localTickTimer?.cancel();
    _cleanupRoom();
    super.dispose();
  }

  void _cleanupRoom() {
    if (_roomCleanedUp) return;
    _roomCleanedUp = true;

    try {
      _room?.leave();
    } catch (e) {
      debugPrint('Error leaving room: $e');
    }
    _room = null;

    _localVideoStream = null;
    _remoteVideoStream = null;
    _remoteParticipants.clear();
  }

  Future<bool> _requestCallPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final granted = statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;

    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Camera and microphone permissions are required for calls',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    return granted;
  }

  Future<void> _connectToCall() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
      return;
    }

    final granted = await _requestCallPermissions();
    if (!granted) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectError = 'Camera and microphone permissions are required';
        });
      }
      return;
    }

    final result = await _callService.startCall(token, widget.callId);
    if (!mounted) return;

    if (result is! Map || result['success'] != true) {
      final message = result is Map ? result['message'] : null;
      setState(() {
        _isConnecting = false;
        _connectError = message ?? 'Failed to connect to call';
      });
      return;
    }

    final data = result['data'];
    final meetingId = data?['meeting_id']?.toString();
    final meetingToken =
        data?['meeting_token']?.toString() ?? data?['token']?.toString();
    _resolvedCallId = data?['call_id']?.toString() ?? widget.callId;
    _pricePerMinute = (data?['price_per_minute'] as num?)?.toDouble();
        _pricePerSecond = (data?['price_per_second'] as num?)?.toDouble();
        _billingMode = data?['billing_mode']?.toString() ?? 'standard';
    _lastPaidDurationSeconds =
        (data?['paid_duration_seconds'] as num?)?.toInt() ?? 0;
    _lastRemainingSeconds = _lastPaidDurationSeconds;

    if (meetingId == null || meetingToken == null) {
      setState(() {
        _isConnecting = false;
        _connectError = 'Call server did not return meeting credentials';
      });
      return;
    }

    _joinRoom(meetingId: meetingId, token: meetingToken);
    _startCountdownPolling(token);
  }

  void _joinRoom({required String meetingId, required String token}) {
    final room = VideoSDK.createRoom(
      roomId: meetingId,
      token: token,
      displayName: widget.isInfluencer ? 'Influencer' : 'Client',
      micEnabled: true,
      camEnabled: true,
      defaultCameraIndex: 1,
    );

    room.on(Events.roomJoined, () {
      if (!mounted) return;
      setState(() => _isConnecting = false);
      _attachLocalVideoListeners(room.localParticipant);
    });

    room.on(Events.participantJoined, (Participant participant) {
      if (!mounted) return;
      setState(() => _remoteParticipants[participant.id] = participant);
      _attachRemoteVideoListeners(participant);
    });

    room.on(Events.participantLeft, (String participantId) {
      if (!mounted) return;
      setState(() {
        _remoteParticipants.remove(participantId);
        _remoteVideoStream = null;
        _isLocalFullScreen = false;
      });
      _handleRemoteEndedCall(message: 'Client left — call ended');
    });

    room.on(Events.roomLeft, (String? reason) {
      if (!mounted) return;
      setState(() {
        _remoteParticipants.clear();
        _remoteVideoStream = null;
      });
    });

    _room = room;
    _roomCleanedUp = false;
    room.join();
  }

  void _handleRemoteEndedCall({required String message}) {
    if (_hasEndedCall) return;
    _hasEndedCall = true;

    _countdownPoller?.cancel();
    _cleanupRoom();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      _showEndCallSummary(actualDurationSeconds: _actualDurationSeconds);
    }
  }

  void _attachLocalVideoListeners(Participant localParticipant) {
    for (final s in localParticipant.streams.values) {
      if (s.kind == 'video') {
        if (mounted) setState(() => _localVideoStream = s);
        break;
      }
    }

    localParticipant.on(Events.streamEnabled, (Stream stream) {
      if (!mounted) return;
      if (stream.kind == 'video') setState(() => _localVideoStream = stream);
    });

    localParticipant.on(Events.streamDisabled, (Stream stream) {
      if (!mounted) return;
      if (stream.kind == 'video') setState(() => _localVideoStream = null);
    });
  }

  void _attachRemoteVideoListeners(Participant participant) {
    for (final s in participant.streams.values) {
      if (s.kind == 'video') {
        setState(() => _remoteVideoStream = s);
        break;
      }
    }

    participant.on(Events.streamEnabled, (Stream stream) {
      if (!mounted) return;
      if (stream.kind == 'video') setState(() => _remoteVideoStream = stream);
    });

    participant.on(Events.streamDisabled, (Stream stream) {
      if (!mounted) return;
      if (stream.kind == 'video') setState(() => _remoteVideoStream = null);
    });
  }

  void _startCountdownPolling(String token) {
    final id = _resolvedCallId ?? widget.callId;
    _callStartedAt ??= DateTime.now();

    if (_isPayg) {
      _localTickTimer?.cancel();
      _localTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _hasEndedCall) return;
        final started = _callStartedAt;
        if (started == null) return;
        final elapsed = DateTime.now().difference(started).inSeconds;
        if (elapsed != _elapsedSeconds) {
          setState(() {
            _elapsedSeconds = elapsed < 0 ? 0 : elapsed;
            _countdownText = _formatTime(_elapsedSeconds);
          });
        }
      });
    }

    _pollCountdownOnce(token, id);

    final pollEvery =
        _isPayg ? const Duration(seconds: 3) : const Duration(seconds: 10);
    _countdownPoller = Timer.periodic(pollEvery, (_) async {
      if (_hasEndedCall) return;
      await _pollCountdownOnce(token, id);
    });
  }

  Future<void> _pollCountdownOnce(String token, String id) async {
    final result = await _callService.getCountdown(token, id);
    if (!mounted || _hasEndedCall) return;

    if (result is Map && result['success'] == true) {
      final data = result['data'];
      final remaining = data?['remaining_seconds'];
      final paid = data?['paid_duration_seconds'];
      final status = data?['status']?.toString();
      final mode = data?['billing_mode']?.toString();
      if (mode != null && mode.isNotEmpty) {
        _billingMode = mode;
      }

      final actualDuration = data?['actual_duration_seconds'];
      if (actualDuration is num) {
        _actualDurationSeconds = actualDuration.toInt();
      }

      if (paid is num) {
        _lastPaidDurationSeconds = paid.toInt();
      }

      if (_isPayg) {
        final elapsedFromServer = data?['elapsed_seconds'];
        if (elapsedFromServer is num) {
          final e = elapsedFromServer.toInt();
          if (e >= 0 && (e - _elapsedSeconds).abs() > 2) {
            _elapsedSeconds = e;
            _callStartedAt = DateTime.now().subtract(Duration(seconds: e));
            setState(() => _countdownText = _formatTime(_elapsedSeconds));
          }
        } else if (_elapsedSeconds == 0 && remaining is num && paid is num) {
          // Bootstrap elapsed from paid - remaining once.
          final e = (paid.toInt() - remaining.toInt()).clamp(0, paid.toInt());
          _elapsedSeconds = e;
          _callStartedAt = DateTime.now().subtract(Duration(seconds: e));
          setState(() => _countdownText = _formatTime(_elapsedSeconds));
        }
      } else if (remaining is num) {
        _lastRemainingSeconds = remaining.toInt();
        setState(() => _countdownText = _formatTime(remaining.toInt()));
      }

      if (status == 'completed' && !_hasEndedCall) {
        _localTickTimer?.cancel();
        _handleRemoteEndedCall(message: 'Call has ended');
      }
    }
  }

  double _estimateEscrowCoins() {
    final elapsedSeconds = _actualDurationSeconds ??
        (_lastPaidDurationSeconds - _lastRemainingSeconds)
            .clamp(0, _lastPaidDurationSeconds);

    if (_billingMode == 'payg_second') {
      return (_pricePerSecond ?? 0) * elapsedSeconds;
    }
    final pricePerMinute = _pricePerMinute ?? 0;
    if (pricePerMinute <= 0) return 0;
    if (_billingMode == 'payg_minute') {
      final billedMinutes = elapsedSeconds <= 0 ? 0 : (elapsedSeconds / 60).ceil();
      return pricePerMinute * billedMinutes;
    }
    return ((pricePerMinute * elapsedSeconds) / 60).roundToDouble();
  }

  void _prepareEscrowDisplay() {
    if (!mounted) return;
    setState(() {
      _escrowCoins = _estimateEscrowCoins();
      _escrowRemainingSeconds = _escrowAutoReleaseWindowSeconds;
      _showReleaseWidget = true;
    });

    _startEscrowPolling();
  }

  void _startEscrowPolling() {
    _countdownPoller?.cancel();

    _countdownPoller = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || !_showReleaseWidget || _escrowReleased) {
        _countdownPoller?.cancel();
        return;
      }

      final token = await SessionManager.getToken();
      final callId = _resolvedCallId ?? widget.callId;
      if (token == null) return;

      try {
        final result = await _callService.getCountdown(token, callId);

        if (!mounted) return;

        if (result is Map && result['success'] == true) {
          final data = result['data'];
          if (data is Map) {
            final escrowStatus = data['escrow_status']?.toString() ?? '';

            if (escrowStatus == 'released') {
              _escrowReleased = true;
              _countdownPoller?.cancel();
              _influencerReleaseKey.currentState?.markCredited();
            }
          }
        }
      } catch (e) {
        // Silently ignore polling errors
      }
    });
  }

  void _onReleaseWidgetClosed() {
    _countdownPoller?.cancel();
    if (!mounted) return;
    setState(() => _showReleaseWidget = false);
    _navigateToRating();
  }

  void _navigateToRating() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          callId: _resolvedCallId ?? widget.callId,
          otherPartyName: widget.clientName,
          isInfluencer: widget.isInfluencer,
        ),
      ),
    );
  }

  Future<void> _showEndCallSummary({int? actualDurationSeconds}) async {
    if (!mounted) return;

    final callId = _resolvedCallId ?? widget.callId;
    final token = await SessionManager.getToken();

    Map<String, dynamic>? trackingData;
    if (token != null) {
      trackingData = await _callService.getCallTrackingDetails(token, callId);
    }

    final durationSecs = actualDurationSeconds ??
        trackingData?['duration_seconds'] as int? ??
        _lastPaidDurationSeconds;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.call_end_rounded, color: _primaryPink, size: 28),
            SizedBox(width: 12),
            Text(
              'Call Ended',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _darkBg,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryPink.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: _primaryPink),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${_formatDuration(durationSecs)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _darkBg,
                    ),
                  ),
                ],
              ),
            ),

            if (trackingData != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: _primaryPink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildEndedByText(trackingData),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _prepareEscrowDisplay();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _buildEndedByText(Map<String, dynamic> tracking) {
    final endedByRole = tracking['ended_by_role']?.toString() ?? '';
    final endedByName = tracking['ended_by_name']?.toString() ?? '';

    switch (endedByRole) {
      case 'system':
        return 'Call ended — time ran out';
      case 'client':
        return 'Call ended by $endedByName (Client)';
      case 'influencer':
        return 'Call ended by $endedByName (Influencer)';
      default:
        return 'Call ended';
    }
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '00:00';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0:00';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleMic() {
    if (_room == null) return;
    try {
      if (_micEnabled) {
        _room!.muteMic();
      } else {
        _room!.unmuteMic();
      }
      setState(() => _micEnabled = !_micEnabled);
    } catch (e) {
      debugPrint('Error toggling mic: $e');
    }
  }

  void _toggleCamera() {
    if (_room == null) return;
    try {
      if (_camEnabled) {
        _room!.disableCam();
      } else {
        _room!.enableCam();
      }
      setState(() => _camEnabled = !_camEnabled);
    } catch (e) {
      debugPrint('Error toggling camera: $e');
    }
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
  }

  void _swapVideos() {
    if (_localVideoStream != null && _remoteVideoStream != null) {
      setState(() => _isLocalFullScreen = !_isLocalFullScreen);
    }
  }

  Future<void> _endCall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.call_end_rounded, color: _dangerRed, size: 28),
            SizedBox(width: 12),
            Text(
              'End Call',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _darkBg,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to end this call?',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'End Call',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (_hasEndedCall) return;

    setState(() => _isEndingCall = true);

    _countdownPoller?.cancel();
    _cleanupRoom();

    final token = await SessionManager.getToken();
    final id = _resolvedCallId ?? widget.callId;

    if (token != null) {
      final endResult = await _callService.endCall(token, id);

      if (!mounted) return;
      setState(() => _isEndingCall = false);

      if (endResult is Map && endResult['success'] == true) {
        _hasEndedCall = true;
        final actual = endResult['data']?['actual_duration_seconds'];
        if (actual is num) _actualDurationSeconds = actual.toInt();

        await _showEndCallSummary(actualDurationSeconds: _actualDurationSeconds);
      } else {
        final message = endResult is Map
            ? endResult['message']?.toString()
            : 'Failed to end call';

        if (mounted) {
          final retry = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Error'),
              content: Text(message ?? 'Failed to end call. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );

          if (retry == true) {
            _endCall();
          }
        }
      }
    }
  }

  Widget _buildVideoView({required Stream? stream, required bool isCameraOn}) {
    if (stream == null || !mounted || _roomCleanedUp) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isCameraOn
                        ? Icons.person_rounded
                        : Icons.videocam_off_rounded,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCameraOn
                    ? 'Waiting for ${widget.clientName}...'
                    : 'Camera off',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    try {
      return RTCVideoView(
        stream.renderer as dynamic,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    } catch (e) {
      debugPrint('Error building video view: $e');
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54, size: 40),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    if (_showReleaseWidget) {
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
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Opacity(
                opacity: 0.35,
                child: IgnorePointer(
                  child: RatingScreen(
                    callId: _resolvedCallId ?? widget.callId,
                    otherPartyName: widget.clientName,
                    isInfluencer: widget.isInfluencer,
                  ),
                ),
              ),
              
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: widget.isInfluencer
                    ? InfluencerReleaseWidget(
                        key: _influencerReleaseKey,
                        coins: _escrowCoins,
                        clientName: widget.clientName,
                        initialRemainingSeconds: _escrowRemainingSeconds,
                        onClose: _onReleaseWidgetClosed,
                      )
                    : _buildClientReleaseWidget(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
    }

    if (_isConnecting) {
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
        backgroundColor: _darkBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primaryPink.withValues(alpha: 0.2),
                      _softPink.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryPink),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Connecting...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we establish the call',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
    }

    if (_connectError != null) {
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
        backgroundColor: _darkBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _connectError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 200,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryPink, _softPink],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryPink.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

    if (_isEndingCall) {
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
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _primaryPink),
              const SizedBox(height: 20),
              const Text(
                'Ending call...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      ),
    );
    }

    if (_roomCleanedUp) {
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
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'Call has ended',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ),
      ),
    );
    }

    final Stream? fullScreenStream =
        _isLocalFullScreen ? _localVideoStream : _remoteVideoStream;
    final Stream? previewStream =
        _isLocalFullScreen ? _remoteVideoStream : _localVideoStream;
    final bool isFullScreenCameraOn =
        _isLocalFullScreen ? _camEnabled : (_remoteVideoStream != null);
    final bool isPreviewCameraOn =
        _isLocalFullScreen ? (_remoteVideoStream != null) : _camEnabled;

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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _showReleaseWidget ? null : _swapVideos,
            child: _buildVideoView(
                stream: fullScreenStream,
                isCameraOn: isFullScreenCameraOn),
          ),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          if (!_showReleaseWidget)
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryPink, _softPink],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  widget.clientName.isNotEmpty
                                      ? widget.clientName[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.clientName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _successGreen.withValues(alpha: 0.25),
                                        _successGreen.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _successGreen.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: _successGreen,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _successGreen.withValues(alpha: 0.5),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _countdownText,
                                        style: const TextStyle(
                                          color: _successGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (previewStream != null ||
                            _localVideoStream != null ||
                            _remoteVideoStream != null)
                          GestureDetector(
                            onTap: _swapVideos,
                            child: Container(
                              width: 90,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14.5),
                                child: previewStream != null
                                    ? (!isPreviewCameraOn
                                        ? Container(
                                            color: Colors.grey[900],
                                            child: const Center(
                                              child: Icon(
                                                Icons.videocam_off,
                                                color: Colors.white54,
                                                size: 28,
                                              ),
                                            ),
                                          )
                                        : Builder(
                                            builder: (context) {
                                              if (_roomCleanedUp) {
                                                return Container(
                                                  color: Colors.grey[900],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.videocam_off,
                                                      color: Colors.white54,
                                                      size: 28,
                                                    ),
                                                  ),
                                                );
                                              }
                                              try {
                                                return RTCVideoView(
                                                  previewStream!.renderer as dynamic,
                                                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                                );
                                              } catch (e) {
                                                return Container(
                                                  color: Colors.grey[900],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.videocam_off,
                                                      color: Colors.white54,
                                                      size: 28,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ))
                                    : Container(
                                        color: Colors.grey[900],
                                        child: const Center(
                                          child: Icon(
                                            Icons.person_rounded,
                                            color: Colors.white54,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Column(
                      children: [
                        if (_showRulesCard) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.98),
                                  _primaryPink.withValues(alpha: 0.03),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _primaryPink.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'You are now connected.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _darkBg,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _showRulesCard = false),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Please remember:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildRuleItem('Respect platform rules.'),
                                const SizedBox(height: 3),
                                _buildRuleItem('No harassment.'),
                                const SizedBox(height: 3),
                                _buildRuleItem(
                                    'Poor ratings from 3 clients may lead to suspension.'),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_primaryPink, _softPink],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryPink.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => setState(() => _showRulesCard = false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Got it',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _darkBg.withValues(alpha: 0.9),
                                _darkBg.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildCallButton(
                                icon: _micEnabled
                                    ? Icons.mic_rounded
                                    : Icons.mic_off_rounded,
                                label: _micEnabled ? 'Mute' : 'Unmute',
                                backgroundColor: _micEnabled
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : _dangerRed,
                                onTap: _toggleMic,
                              ),
                              _buildCallButton(
                                icon: _camEnabled
                                    ? Icons.videocam_rounded
                                    : Icons.videocam_off_rounded,
                                label: 'Camera',
                                backgroundColor: _camEnabled
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : _dangerRed,
                                onTap: _toggleCamera,
                              ),
                              _buildCallButton(
                                icon: _speakerOn
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                label: 'Speaker',
                                backgroundColor: _speakerOn
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : _dangerRed,
                                onTap: _toggleSpeaker,
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: _endCall,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [_dangerRed, Color(0xFFFF5252)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _dangerRed.withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.call_end_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'End',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildClientReleaseWidget() {
    return _ClientReleaseShim(
      callId: _resolvedCallId ?? widget.callId,
      coins: _escrowCoins,
      influencerName: widget.clientName,
      initialRemainingSeconds: _escrowRemainingSeconds,
      onClose: _onReleaseWidgetClosed,
    );
  }

  Widget _buildRuleItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(color: Colors.black54, fontSize: 11),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _ClientReleaseShim extends StatelessWidget {
  final String callId;
  final double coins;
  final String influencerName;
  final int initialRemainingSeconds;
  final VoidCallback onClose;

  const _ClientReleaseShim({
    required this.callId,
    required this.coins,
    required this.influencerName,
    required this.initialRemainingSeconds,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ClientReleaseWidget(
      callId: callId,
      coins: coins,
      influencerName: influencerName,
      initialRemainingSeconds: initialRemainingSeconds,
      onClose: onClose,
    );
  }
}