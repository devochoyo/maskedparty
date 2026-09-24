// FILE LOCATION: lib/widgets/client_release.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maskedparty/services/call_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class ClientReleaseWidget extends StatefulWidget {
  final String callId;
  final double coins;
  final String influencerName;
  final int initialRemainingSeconds;

  /// Called when the widget is closed (X button) so the parent can show the
  /// rating screen.
  final VoidCallback onClose;

  const ClientReleaseWidget({
    super.key,
    required this.callId,
    required this.coins,
    required this.influencerName,
    required this.initialRemainingSeconds,
    required this.onClose,
  });

  @override
  State<ClientReleaseWidget> createState() => _ClientReleaseWidgetState();
}

class _ClientReleaseWidgetState extends State<ClientReleaseWidget>
    with TickerProviderStateMixin {
  final CallService _callService = CallService();

  late int _remaining;
  Timer? _timer;
  bool _isReleasing = false;
  bool _released = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Release animation controllers
  late AnimationController _releaseAnimController;
  late Animation<double> _releaseScaleAnimation;
  late Animation<double> _releaseFadeAnimation;
  late Animation<double> _coinBounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // ✅ FIXED: Always use 30 minutes (1800 seconds)
    _remaining = 1800;

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    _releaseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _releaseScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _releaseAnimController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _releaseFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _releaseAnimController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );
    _coinBounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _releaseAnimController,
        curve: const Interval(0.3, 0.8, curve: Curves.bounceOut),
      ),
    );

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    _releaseAnimController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 0) {
        _timer?.cancel();
        _autoRelease();
        return;
      }
      setState(() => _remaining--);
    });
  }

  Future<void> _autoRelease() async {
    if (_released) return;

    final token = await SessionManager.getToken();
    if (token == null) return;

    try {
      final result = await _callService.releaseCoins(token, widget.callId);
      if (!mounted) return;

      if (result is Map && result['success'] == true) {
        setState(() => _released = true);
        _showReleaseAnimation();
      } else {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_released) _autoRelease();
        });
      }
    } catch (e) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_released) _autoRelease();
      });
    }
  }

  void _showReleaseAnimation() {
    _releaseAnimController.forward().then((_) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _close();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '00:00';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _releaseNow() async {
    if (_isReleasing || _released) return;
    setState(() => _isReleasing = true);

    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) setState(() => _isReleasing = false);
      return;
    }

    try {
      final result = await _callService.releaseCoins(token, widget.callId);
      if (!mounted) return;

      if (result is Map && result['success'] == true) {
        _timer?.cancel();
        setState(() {
          _released = true;
          _isReleasing = false;
        });
        _showReleaseAnimation();
      } else {
        setState(() => _isReleasing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result is Map
                    ? (result['message'] ?? 'Failed to release coins')
                    : 'Failed to release coins',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReleasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _close() {
    _timer?.cancel();
    _slideController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Call Ended',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_released)
                    GestureDetector(
                      onTap: _close,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _released ? _buildReleaseAnimation() : _buildPendingState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingState() {
    final totalMinutes = (_remaining / 60).ceil();
    
    return Column(
      children: [
        // ✅ REMOVED: Coin amount pill - no fake amounts
        const SizedBox(height: 8),

        // Main message - no coin amounts
        Text(
          'Payment will be released to ${widget.influencerName} in',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1A1D2E),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Countdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE91E63).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                _formatTime(_remaining),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                  letterSpacing: 2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '~$totalMinutes minutes remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Coins are held in escrow and auto-release when the timer ends.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Release Now button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isReleasing ? null : _releaseNow,
            icon: _isReleasing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.rocket_launch_rounded, size: 20),
            label: Text(
              _isReleasing ? 'Releasing...' : 'Release Now',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: const Color(0xFF00C853).withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseAnimation() {
    return AnimatedBuilder(
      animation: _releaseAnimController,
      builder: (context, child) {
        return Column(
          children: [
            Transform.scale(
              scale: _releaseScaleAnimation.value,
              child: Opacity(
                opacity: _releaseFadeAnimation.value,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Transform.scale(
              scale: _coinBounceAnimation.value,
              child: Opacity(
                opacity: _releaseFadeAnimation.value,
                child: Column(
                  children: [
                    // ✅ No coin amounts
                    const Text(
                      'Payment Released! 🎉',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.influencerName} has been credited.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFFE91E63),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Auto-closing in 5 seconds...',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFE91E63).withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}