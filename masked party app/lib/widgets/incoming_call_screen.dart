
// FILE LOCATION: lib/widgets/incoming_call_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class IncomingCallScreen extends StatefulWidget {
  final Map<String, dynamic> call;
  final bool isResponding;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final String? callerProfileImage;

  /// When non-null, overrides the "Incoming Call..." status text (e.g.
  /// "Call Ended") and disables the Accept/Reject buttons. Used when the
  /// call auto-times-out or is otherwise no longer actionable.
  final String? statusOverride;

  const IncomingCallScreen({
    super.key,
    required this.call,
    required this.isResponding,
    required this.onAccept,
    required this.onReject,
    this.callerProfileImage,
    this.statusOverride,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startIncomingRingtone();
  }

  @override
  void dispose() {
    _stopRingtone();
    super.dispose();
  }

  Future<void> _startIncomingRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('incoming.mp3'));
      if (mounted) {
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      // Silently fail if audio can't play
      debugPrint('Failed to play incoming ringtone: $e');
    }
  }

  Future<void> _stopRingtone() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        await _audioPlayer.dispose();
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      }
    } catch (e) {
      debugPrint('Failed to stop ringtone: $e');
    }
  }

  void _handleAccept() {
    _stopRingtone();
    widget.onAccept();
  }

  void _handleReject() {
    _stopRingtone();
    widget.onReject();
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.call['client_mystery_name'] ?? 'Unknown Caller';
    final callerImage = widget.callerProfileImage ?? widget.call['client_profile_photo'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final bool isTerminal = widget.statusOverride != null;
    final bool controlsDisabled = widget.isResponding || isTerminal;

    // Stop ringtone if call is terminal
    if (isTerminal && _isPlaying) {
      _stopRingtone();
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _stopRingtone();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Avatar with pink rings
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rings
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE91E63).withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE91E63).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE91E63).withOpacity(0.35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE91E63).withOpacity(0.08),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE91E63),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE91E63).withOpacity(0.18),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: (callerImage != null &&
                                          callerImage.toString().isNotEmpty)
                                      ? Image.network(
                                          callerImage.toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildPlaceholderAvatar(),
                                        )
                                      : _buildPlaceholderAvatar(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Soft outer pulse ring
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE91E63).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE91E63).withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Caller Name
              Text(
                callerName.toString(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 22 : 26,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D2E),
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 10),

              // Call Status (or override, e.g. "Call Ended")
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isTerminal ? Colors.grey[400] : const Color(0xFFE91E63),
                      shape: BoxShape.circle,
                      boxShadow: isTerminal
                          ? const []
                          : [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withOpacity(0.35),
                                blurRadius: 8,
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.statusOverride ?? 'Incoming Call...',
                    style: TextStyle(
                      fontSize: 14,
                      color: isTerminal ? Colors.grey[700] : Colors.grey[600],
                      fontWeight: isTerminal ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // Call type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE91E63).withOpacity(0.15),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      color: Color(0xFFE91E63),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Video Call',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE91E63),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              AnimatedOpacity(
                opacity: isTerminal ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reject Button
                    GestureDetector(
                      onTap: controlsDisabled ? null : _handleReject,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 60),
                    // Accept Button
                    GestureDetector(
                      onTap: controlsDisabled ? null : _handleAccept,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00C853),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C853).withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: widget.isResponding
                            ? const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.call_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Text
              GestureDetector(
                onTap: controlsDisabled ? null : _handleReject,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: const Color(0xFFFFF5F8),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 50,
          color: Color(0xFFE91E63),
        ),
      ),
    );
  }
}