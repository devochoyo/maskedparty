// FILE LOCATION: lib/screens/client/video_call.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:videosdk/videosdk.dart';
import 'package:maskedparty/services/call_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'package:maskedparty/widgets/client_release.dart';
import 'package:maskedparty/widgets/client_call_warning_dialog.dart';
import 'package:maskedparty/widgets/outgoing_call_screen.dart';
import 'package:maskedparty/widgets/connecting_screen.dart';
import 'rate_influencer.dart';

class VideoCallScreen extends StatefulWidget {
  final String requestId;
  final String? influencerId;
  final String? influencerName;
  final int initialMinutes;
  final String billingMode;

  const VideoCallScreen({
    super.key,
    required this.requestId,
    this.influencerId,
    this.influencerName,
    this.initialMinutes = 1,
    this.billingMode = 'standard',
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final CallService _callService = CallService();

  bool _isWaiting = true;
  bool _isInCall = false;
  bool _isConnecting = false;
  bool _isEndingCall = false;
  String? _waitStatusMessage;
  Timer? _statusPoller;
  Timer? _countdownPoller;

  // --- No-answer / terminal-status handling -------------------------------
  // How long we wait for the influencer to accept before giving up.
  static const Duration _noAnswerTimeout = Duration(seconds: 40);
  Timer? _noAnswerTimer;
  // Set when the call ends before connecting for any reason (rejected,
  // cancelled, expired, or timed out). Shown on OutgoingCallScreen briefly
  // before popping, instead of an instant snackbar + pop.
  String? _terminalStatusMessage;
  bool _isFinishingBeforeConnect = false;

  String? _callId;
  int _remainingSeconds = 0;
  int _totalDurationSeconds = 0;
  int? _actualDurationSeconds;
  bool _hasShownTimeUpWarning = false;
  bool _callEnded = false;
  bool _hasAppliedInitialExtend = false;

  /// Billing mode for this call (standard | payg_minute | payg_second).
  late String _billingMode;
  /// Elapsed seconds for Pay As You Go (counts up locally every second).
  int _elapsedSeconds = 0;
  Timer? _localTickTimer;
  DateTime? _callStartedAt;

  bool get _isPayg =>
      _billingMode == 'payg_minute' || _billingMode == 'payg_second';

  Room? _room;
  Stream? _localVideoStream;
  Stream? _remoteVideoStream;
  final Map<String, Participant> _remoteParticipants = {};
  bool _micEnabled = true;
  bool _camEnabled = true;
  bool _isLocalFullScreen = false;

  bool _showReleaseWidget = false;
  bool _showRateScreen = false;
  double _coinsForRelease = 0;

  @override
  void initState() {
    super.initState();
    _billingMode = widget.billingMode;
    _pollCallStatus();
    _noAnswerTimer = Timer(_noAnswerTimeout, _handleNoAnswerTimeout);
  }

  @override
  void dispose() {
    _statusPoller?.cancel();
    _countdownPoller?.cancel();
    _localTickTimer?.cancel();
    _noAnswerTimer?.cancel();
    try {
      _room?.leave();
    } catch (e) {
      debugPrint('Error leaving room: $e');
    }
    _room = null;
    super.dispose();
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
        const SnackBar(
          content: Text('Camera and microphone permissions are required for calls'),
        ),
      );
    }
    return granted;
  }

  /// Called when the influencer hasn't answered within [_noAnswerTimeout].
  /// Only acts if we're still in the waiting-for-answer stage.
  void _handleNoAnswerTimeout() {
    if (!mounted || !_isWaiting || _isFinishingBeforeConnect) return;
    _statusPoller?.cancel();
    _finishBeforeConnect('Not Answered');
  }

  /// Shows [label] on the OutgoingCallScreen for a moment, then pops.
  /// Used for reject / cancel / expired / not-answered cases — anything
  /// that ends the call before it actually connects.
  void _finishBeforeConnect(String label) {
    if (_isFinishingBeforeConnect) return;
    _isFinishingBeforeConnect = true;
    _noAnswerTimer?.cancel();
    _statusPoller?.cancel();

    if (!mounted) return;
    setState(() => _terminalStatusMessage = label);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _pollCallStatus() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    _statusPoller = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final result = await _callService.startCall(token, widget.requestId);
      if (!mounted) return;

      if (result is Map && result['success'] == true) {
        timer.cancel();
        _noAnswerTimer?.cancel();
        final data = result['data'];
        _callId = data?['call_id']?.toString();

        final modeFromServer = data?['billing_mode']?.toString();
        if (modeFromServer != null && modeFromServer.isNotEmpty) {
          _billingMode = modeFromServer;
        }

        final paidDuration = data?['paid_duration_seconds'];
        if (paidDuration is num && paidDuration > 0) {
          _remainingSeconds = paidDuration.toInt();
          _totalDurationSeconds = paidDuration.toInt();
        } else {
          final remaining = data?['remaining_seconds'];
          if (remaining is num && remaining > 0) {
            _remainingSeconds = remaining.toInt();
            _totalDurationSeconds = remaining.toInt();
          }
        }

        final coins = data?['coins'];
        if (coins is num) {
          _coinsForRelease = coins is num ? coins.toDouble() : double.tryParse('$coins') ?? _coinsForRelease;
        }

        setState(() => _isWaiting = false);
        _showPrivacyDialog(data);
      } else {
        final message = result is Map ? result['message']?.toString() : null;
        final lower = message?.toLowerCase() ?? '';
        final looksTerminal = message != null &&
            (lower.contains('reject') ||
                lower.contains('cancel') ||
                lower.contains('expired'));

        if (looksTerminal) {
          timer.cancel();
          String label = 'Call Ended';
          if (lower.contains('reject')) {
            label = 'Call Rejected';
          } else if (lower.contains('cancel')) {
            label = 'Call Cancelled';
          } else if (lower.contains('expired')) {
            label = 'Call Expired';
          }
          _finishBeforeConnect(label);
        } else {
          setState(() => _waitStatusMessage = message);
        }
      }
    });
  }

  void _showPrivacyDialog(dynamic startData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ClientCallWarningDialog(),
    ).then((accepted) {
      if (accepted == true) {
        _joinFromStartData(startData);
      } else {
        if (mounted) Navigator.pop(context);
      }
    });
  }

  Future<void> _joinFromStartData(dynamic data) async {
    setState(() => _isConnecting = true);

    final granted = await _requestCallPermissions();
    if (!granted) {
      setState(() => _isConnecting = false);
      return;
    }

    final meetingId = data?['meeting_id']?.toString();
    final meetingToken =
        data?['meeting_token']?.toString() ?? data?['token']?.toString();

    if (meetingId == null || meetingToken == null) {
      setState(() => _isConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call server did not return meeting credentials')),
        );
      }
      return;
    }

    await _applyInitialDurationIfNeeded();

    _joinRoom(meetingId: meetingId, token: meetingToken);
    _startCountdownPolling();
  }

  Future<void> _applyInitialDurationIfNeeded() async {
    if (_hasAppliedInitialExtend || _callId == null) return;
    if (widget.billingMode != 'standard' || widget.initialMinutes <= 1) return;

    _hasAppliedInitialExtend = true;
    final extraMinutes = widget.initialMinutes - 1;

    final token = await SessionManager.getToken();
    if (token == null) return;

    try {
      final result = await _callService.extendCall(token, _callId!, extraMinutes);
      if (!mounted) return;

      if (result is Map && result['success'] == true) {
        final newRemaining = result['data']?['remaining_seconds'];
        final newPaidDuration = result['data']?['paid_duration_seconds'];

        if (newRemaining is num) {
          setState(() => _remainingSeconds = newRemaining.toInt());
        }
        if (newPaidDuration is num) {
          _totalDurationSeconds = newPaidDuration.toInt();
        }

        final coins = result['data']?['coins'];
        if (coins is num) {
          _coinsForRelease = coins is num ? coins.toDouble() : double.tryParse('$coins') ?? _coinsForRelease;
        }

        debugPrint(
          'Initial duration applied: ${widget.initialMinutes} min '
          '(extended by $extraMinutes). Remaining: $_remainingSeconds s',
        );
      } else {
        final message = result is Map ? result['message'] : null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message ??
                    'Could not purchase ${widget.initialMinutes} minutes — starting with 1 minute',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to apply initial duration: $e');
    }
  }

  void _startCountdownPolling() {
    _countdownPoller?.cancel();
    _localTickTimer?.cancel();
    if (_callId == null) return;

    _callStartedAt ??= DateTime.now();
    if (_isPayg) {
      // Smooth local elapsed clock for Pay As You Go (no jumping remaining).
      _localTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _callEnded) return;
        final started = _callStartedAt;
        if (started == null) return;
        final elapsed = DateTime.now().difference(started).inSeconds;
        if (elapsed != _elapsedSeconds) {
          setState(() => _elapsedSeconds = elapsed < 0 ? 0 : elapsed);
        }
      });
    }

    _pollCountdownOnce();

    // Server poll: standard uses remaining; PAYG uses it only for
    // top-up / insufficient-balance / call-ended signals.
    final pollEvery = _isPayg ? const Duration(seconds: 3) : const Duration(seconds: 5);
    _countdownPoller = Timer.periodic(pollEvery, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _pollCountdownOnce();
    });
  }

  Future<void> _pollCountdownOnce() async {
    if (_callId == null || _callEnded) return;
    final token = await SessionManager.getToken();
    if (token == null) return;

    try {
      final result = await _callService.getCountdown(token, _callId!);
      if (!mounted || _callEnded) return;

      if (result is Map && result['success'] == true) {
        final data = result['data'];
        final remaining = data?['remaining_seconds'];
        final paidDuration = data?['paid_duration_seconds'];
        final status = data?['status']?.toString();
        final insufficient = data?['insufficient_balance'] == true;

        final actualDuration = data?['actual_duration_seconds'];
        if (actualDuration is num) {
          _actualDurationSeconds = actualDuration.toInt();
        }

        if (paidDuration is num && paidDuration > 0) {
          _totalDurationSeconds = paidDuration.toInt();
        }

        final coins = data?['coins'];
        if (coins is num) {
          _coinsForRelease =
              coins is num ? coins.toDouble() : double.tryParse('$coins') ?? _coinsForRelease;
        }

        // Call already settled on server (timeout / insufficient / remote end).
        if (status == 'completed' || insufficient) {
          _countdownPoller?.cancel();
          _localTickTimer?.cancel();
          if (_isInCall && !_callEnded) {
            if (insufficient) {
              _handleInsufficientBalance();
            } else {
              _handleCallTimeUp();
            }
          }
          return;
        }

        if (_isPayg) {
          // Keep elapsed in sync if server provides it; otherwise local tick owns the display.
          final elapsedFromServer = data?['elapsed_seconds'];
          if (elapsedFromServer is num) {
            final e = elapsedFromServer.toInt();
            if (e >= 0 && (e - _elapsedSeconds).abs() > 2) {
              setState(() => _elapsedSeconds = e);
              _callStartedAt = DateTime.now().subtract(Duration(seconds: e));
            }
          }
          // Do not drive UI from remaining_seconds on PAYG — it jumps on every escrow top-up.
          return;
        }

        // --- Standard (fixed package) countdown ---
        if (remaining is num) {
          final newRemaining = remaining.toInt();
          if (newRemaining >= 0) {
            setState(() => _remainingSeconds = newRemaining);

            final warningThreshold = _warningThresholdSeconds();

            if (_remainingSeconds <= warningThreshold &&
                _remainingSeconds > 0 &&
                !_hasShownTimeUpWarning) {
              _hasShownTimeUpWarning = true;
              _showTimeWarning();
            }

            if (_remainingSeconds <= 0 && _isInCall && !_callEnded) {
              _countdownPoller?.cancel();
              _handleCallTimeUp();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error polling countdown: $e');
    }
  }

  int _warningThresholdSeconds() {
    if (_totalDurationSeconds <= 60) return 15;
    if (_totalDurationSeconds <= 180) return 30;
    return 60;
  }

  void _showTimeWarning() {
    if (!mounted || _callEnded || _isPayg) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Call Ending Soon'),
        content: Text(
          'Your call will end in about ${_formatTime(_remainingSeconds)}. '
          'Would you like to extend?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endCall();
            },
            child: const Text('End Call'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _extendCall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Extend Call'),
          ),
        ],
      ),
    );
  }

  void _handleInsufficientBalance() {
    if (!mounted || _callEnded) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Out of Coins'),
        content: const Text(
          'Your call has ended because there are not enough coins left to continue Pay As You Go billing.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endCall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleCallTimeUp() {
    if (!mounted || _callEnded) return;
    // Pay As You Go never needs a manual "extend" flow — billing is automatic
    // until balance runs out (handled via insufficient_balance above).
    if (_isPayg) {
      _endCall();
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Time's Up!"),
        content: const Text(
          'Your paid call time has ended. You can extend the call or end it.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endCall();
            },
            child: const Text('End Call'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _extendCall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Extend Call'),
          ),
        ],
      ),
    );
  }

  void _joinRoom({required String meetingId, required String token}) {
    final room = VideoSDK.createRoom(
      roomId: meetingId,
      token: token,
      displayName: 'Client',
      micEnabled: true,
      camEnabled: true,
      defaultCameraIndex: 1,
    );

    room.on(Events.roomJoined, () {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isInCall = true;
      });
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
      _handleRemoteEndedCall(message: 'Influencer left — call ended');
    });

    room.on(Events.roomLeft, (String? reason) {
      if (!mounted) return;
      setState(() {
        _isInCall = false;
        _remoteParticipants.clear();
        _remoteVideoStream = null;
      });
    });

    _room = room;
    room.join();
  }

  void _handleRemoteEndedCall({required String message}) {
    if (_callEnded) return;
    _callEnded = true;
    _countdownPoller?.cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      _showPostCallFlow();
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

  void _swapVideos() {
    if (_localVideoStream != null && _remoteVideoStream != null) {
      setState(() => _isLocalFullScreen = !_isLocalFullScreen);
    }
  }

  Future<void> _extendCall() async {
    if (_callId == null || _isPayg) return; // PAYG is billed automatically
    final token = await SessionManager.getToken();
    if (token == null) return;

    final additionalMinutes = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Extend Call'),
        children: [5, 10, 15]
            .map((m) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, m),
                  child: Text('+$m minutes'),
                ))
            .toList(),
      ),
    );

    if (additionalMinutes == null) return;

    final result =
        await _callService.extendCall(token, _callId!, additionalMinutes);
    if (!mounted) return;

    if (result is Map && result['success'] == true) {
      _hasShownTimeUpWarning = false;
      final newRemaining = result['data']?['remaining_seconds'];
      final newPaidDuration = result['data']?['paid_duration_seconds'];
      if (newRemaining is num) {
        setState(() => _remainingSeconds = newRemaining.toInt());
      }
      if (newPaidDuration is num) {
        _totalDurationSeconds = newPaidDuration.toInt();
      }

      final coins = result['data']?['coins'];
      if (coins is num) {
        _coinsForRelease = coins is num ? coins.toDouble() : double.tryParse('$coins') ?? _coinsForRelease;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Call extended by $additionalMinutes minutes'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final message = result is Map ? result['message'] : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Failed to extend call — check your coin balance'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _endCall() async {
    if (_callEnded) return;
    if (_isEndingCall) return;
    
    setState(() => _isEndingCall = true);
    _countdownPoller?.cancel();
    _localTickTimer?.cancel();
    final token = await SessionManager.getToken();
    try {
      _room?.leave();
    } catch (e) {
      debugPrint('Error leaving room: $e');
    }
    _room = null;
    
    if (token != null && _callId != null) {
      final endResult = await _callService.endCall(token, _callId!);
      
      if (!mounted) return;
      setState(() => _isEndingCall = false);

      if (endResult is Map && endResult['success'] == true) {
        _callEnded = true;
        final actual = endResult['data']?['actual_duration_seconds'];
        if (actual is num) _actualDurationSeconds = actual.toInt();

        final coins = endResult['data']?['coins'];
        if (coins is num) {
          _coinsForRelease = coins is num ? coins.toDouble() : double.tryParse('$coins') ?? _coinsForRelease;
        }
        
        _showPostCallFlow();
      } else {
        final message = endResult is Map 
            ? endResult['message']?.toString() 
            : 'Failed to end call';
        
        if (mounted) {
          final retry = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Error'),
              content: Text(message ?? 'Failed to end call. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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

  void _showPostCallFlow() {
    setState(() {
      _showReleaseWidget = true;
      _showRateScreen = true;
    });
  }

  void _onReleaseWidgetClosed() {
    setState(() {
      _showReleaseWidget = false;
    });
  }

  void _finishCall() {
    _countdownPoller?.cancel();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RateInfluencerScreen(
            callId: _callId ?? '',
            influencerId: widget.influencerId ?? '',
            influencerName: widget.influencerName ?? '',
          ),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '--:--';
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

  Widget _buildVideoView({required Stream? stream, required bool isCameraOn}) {
    if (stream == null || !mounted) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_rounded, color: Colors.white54, size: 40),
              SizedBox(height: 16),
              Text(
                "Waiting for the other participant's video...",
                style: TextStyle(color: Colors.white70),
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
    if (_showRateScreen) {
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
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            AnimatedOpacity(
              opacity: _showReleaseWidget ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                ignoring: _showReleaseWidget,
                child: RateInfluencerScreen(
                  callId: _callId ?? '',
                  influencerId: widget.influencerId ?? '',
                  influencerName: widget.influencerName ?? '',
                ),
              ),
            ),
            
            if (_showReleaseWidget)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.2,
                left: 0,
                right: 0,
                child: ClientReleaseWidget(
                  callId: _callId ?? '',
                  coins: _coinsForRelease,
                  influencerName: widget.influencerName ?? 'Influencer',
                  initialRemainingSeconds: 1800,
                  onClose: _onReleaseWidgetClosed,
                ),
              ),
          ],
        ),
      ),
      ),
    );
    }

    if (_isWaiting) {
      return OutgoingCallScreen(
        influencerName: widget.influencerName ?? 'Influencer',
        influencerImage: null,
        statusMessage:
            _terminalStatusMessage ?? _waitStatusMessage ?? 'Calling...',
        onCancel: _isFinishingBeforeConnect
            ? () {}
            : () {
                _statusPoller?.cancel();
                _noAnswerTimer?.cancel();
                Navigator.pop(context);
              },
      );
    }

    if (_isConnecting) {
      return const ConnectingScreen();
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
              const CircularProgressIndicator(color: Color(0xFFE91E63)),
              const SizedBox(height: 20),
              const Text('Ending call...',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
      ),
      ),
    );
    }

    if (!_isInCall) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Call setup in progress...',
            style: TextStyle(color: Colors.white70),
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
            onTap: _swapVideos,
            child: _buildVideoView(
              stream: fullScreenStream,
              isCameraOn: isFullScreenCameraOn,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.person, color: Colors.white70, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.influencerName ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isPayg
                                    ? _formatTime(_elapsedSeconds)
                                    : _formatTime(_remainingSeconds),
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Extend only applies to fixed-duration (standard) calls.
                      if (!_isPayg)
                        GestureDetector(
                          onTap: _extendCall,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Extend Call',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _billingMode == 'payg_second' ? 'Pay/sec' : 'Pay/min',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    children: [
                      if (previewStream != null)
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: _swapVideos,
                            child: Container(
                              width: 90,
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.5),
                                child: !isPreviewCameraOn
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
                                          try {
                                            return RTCVideoView(
                                              previewStream!.renderer as dynamic,
                                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                            );
                                          } catch (e) {
                                            debugPrint('Error building preview video: $e');
                                            return Container(
                                              color: Colors.grey[900],
                                              child: const Center(
                                                child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCallButton(
                            icon: _micEnabled ? Icons.mic : Icons.mic_off,
                            label: _micEnabled ? 'Mute' : 'Unmute',
                            backgroundColor: _micEnabled
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xFFE53935),
                            onTap: _toggleMic,
                          ),
                          _buildCallButton(
                            icon: _camEnabled ? Icons.videocam : Icons.videocam_off,
                            label: 'Camera',
                            backgroundColor: _camEnabled
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xFFE53935),
                            onTap: _toggleCamera,
                          ),
                          _buildCallButton(
                            icon: Icons.call_end,
                            label: 'End Call',
                            backgroundColor: const Color(0xFFE53935),
                            onTap: _endCall,
                          ),
                        ],
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}