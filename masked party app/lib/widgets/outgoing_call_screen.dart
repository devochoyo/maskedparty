// FILE LOCATION: lib/widgets/outgoing_call_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String influencerName;
  final String? influencerImage;
  final String statusMessage;
  final VoidCallback onCancel;

  const OutgoingCallScreen({
    super.key,
    required this.influencerName,
    this.influencerImage,
    this.statusMessage = 'Calling...',
    required this.onCancel,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startOutgoingRingtone();
  }

  @override
  void dispose() {
    _stopRingtone();
    super.dispose();
  }

  Future<void> _startOutgoingRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('outgoing.mp3'));
      if (mounted) {
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      // Silently fail if audio can't play
      debugPrint('Failed to play outgoing ringtone: $e');
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

  void _handleCancel() {
    _stopRingtone();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

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
                                  child: (widget.influencerImage != null && widget.influencerImage!.isNotEmpty)
                                      ? Image.network(
                                          widget.influencerImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
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

              // Name
              Text(
                widget.influencerName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 22 : 26,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D2E),
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 10),

              // Call Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withOpacity(0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
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

              // Cancel Button
              GestureDetector(
                onTap: _handleCancel,
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

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _handleCancel,
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
