// FILE LOCATION: lib/widgets/influencer_release.dart
import 'dart:async';

import 'package:flutter/material.dart';

class InfluencerReleaseWidget extends StatefulWidget {
  final double coins;
  final String clientName;
  final int initialRemainingSeconds;

  /// Called when the widget is closed (X button) so the parent can show the
  /// rating screen.
  final VoidCallback onClose;

  const InfluencerReleaseWidget({
    super.key,
    required this.coins,
    required this.clientName,
    required this.initialRemainingSeconds,
    required this.onClose,
  });

  @override
  State<InfluencerReleaseWidget> createState() =>
      InfluencerReleaseWidgetState();
}

class InfluencerReleaseWidgetState extends State<InfluencerReleaseWidget>
    with TickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  bool _credited = false;
  bool _showingReleaseAnimation = false;

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
    // ✅ Always use 30 minutes (1800 seconds)
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
        _triggerCreditAnimation();
        return;
      }
      setState(() => _remaining--);
    });
  }

  /// Called externally (from the parent screen) when the client releases
  /// early — so the influencer widget reflects the instant credit with animation.
  void markCredited() {
    _timer?.cancel();
    if (mounted) {
      _triggerCreditAnimation();
    }
  }

  void _triggerCreditAnimation() {
    setState(() {
      _credited = true;
      _showingReleaseAnimation = true;
    });
    
    _releaseAnimController.reset();
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

  void _close() {
    _timer?.cancel();
    _slideController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = (_remaining / 60).ceil();

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              decoration: BoxDecoration(
                color: _credited ? const Color(0xFF00C853) : const Color(0xFFE91E63),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_credited),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _credited ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _credited ? 'Payment Released! 🎉' : 'Pending Release',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_credited)
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
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _showingReleaseAnimation 
                  ? _buildReleaseAnimation() 
                  : _buildPendingState(totalMinutes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingState(int totalMinutes) {
    return Column(
      children: [
        // ✅ No coin amount pill

        // Main message - no coin amounts
        Text(
          'Payment will be released if ${widget.clientName} does not release early',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1A1D2E),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Auto-releases in',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
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
          'Coins are held in escrow until the client releases or the timer ends.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Warning card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE53935).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFE53935),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '3 bad reviews from clients will lead to suspension of your account and loss of all earnings.',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFE53935).withOpacity(0.8),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _close,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Close & Rate Client',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
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
                    Icons.monetization_on_rounded,
                    color: Colors.amberAccent,
                    size: 42,
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
                      'Payment Credited! 🎉',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The payment has been added to your balance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1D2E),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _close,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Rate your experience',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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