// FILE LOCATION: lib/screens/client/rate_influencer.dart
import 'package:flutter/material.dart';
import 'package:maskedparty/services/call_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'package:maskedparty/screens/shared/chat_support.dart';
import 'bottom_navigation.dart';

class RateInfluencerScreen extends StatefulWidget {
  final String callId;
  final String influencerId;
  final String influencerName;
  
  const RateInfluencerScreen({
    super.key,
    required this.callId,
    required this.influencerId,
    this.influencerName = '',
  });

  @override
  State<RateInfluencerScreen> createState() => _RateInfluencerScreenState();
}

class _RateInfluencerScreenState extends State<RateInfluencerScreen> {
  final CallService _callService = CallService();
  final _formKey = GlobalKey<FormState>();

  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _reviewTouched = false;

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _darkPink = Color(0xFFC2185B);
  static const Color _bgColor = Color(0xFFF8F9FE);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _ratingGold = Color(0xFFFFB300);
  static const Color _successGreen = Color(0xFF00C853);
  static const Color _dangerRed = Color(0xFFE53935);

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    if (widget.callId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Missing call reference — cannot submit review'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _callService.submitRating(
        token: token,
        callId: widget.callId,
        rating: _rating,
        experienceText: _reviewController.text.trim(),
      );

      if (!mounted) return;

      if (result is Map && result['success'] == true) {
        try {
          await _callService.releaseEscrow(token, widget.callId);
        } catch (escrowError) {
          debugPrint('Escrow release error (non-critical): $escrowError');
        }
        
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
      } else {
        setState(() => _isSubmitting = false);
        
        String errorMessage = 'Failed to submit review';
        if (result is Map) {
          if (result['message'] != null && result['message'].toString().isNotEmpty) {
            errorMessage = result['message'].toString();
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _skipReview() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ClientBottomNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final displayName = widget.influencerName.isEmpty ? 'Influencer' : widget.influencerName;

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
      body: _submitted ? _buildDoneState() : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: _buildRatingForm(displayName),
      ),
    ),
      ),
    );
  }

  Widget _buildRatingForm(String displayName) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                splashColor: _primaryPink.withValues(alpha: 0.05),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _lightPink.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: _textDark,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Avatar with gradient border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryPink, _softPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryPink.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: _lightPink,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _primaryPink,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            displayName,
            style: const TextStyle(
              color: _textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How was your experience?',
            style: TextStyle(
              color: _textMedium,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 40),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: AnimatedScale(
                    scale: star <= _rating ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: star <= _rating ? _ratingGold : _textLight.withValues(alpha: 0.4),
                      size: star <= _rating ? 46 : 38,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Star label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: (_rating <= 2 ? _dangerRed : _successGreen).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _starLabel(_rating),
              style: TextStyle(
                color: _rating <= 2 ? _dangerRed : _successGreen,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Review text box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _lightPink.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryPink.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextFormField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 300,
              style: const TextStyle(
                color: _textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Share your experience *',
                hintStyle: TextStyle(
                  color: _textLight,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _primaryPink,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _dangerRed,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _dangerRed,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterStyle: const TextStyle(
                  color: _textLight,
                  fontSize: 11,
                ),
                errorStyle: const TextStyle(
                  color: _dangerRed,
                  fontSize: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please share your experience before submitting';
                }
                if (value.trim().length < 3) {
                  return 'Review must be at least 3 characters';
                }
                return null;
              },
              onChanged: (_) {
                if (_reviewTouched) {
                  _formKey.currentState?.validate();
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _dangerRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _dangerRed.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: _dangerRed,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bad ratings or experiences from 3 different clients leads to a ban.',
                    style: TextStyle(
                      color: _dangerRed.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Submit button with gradient
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: _isSubmitting
                  ? null
                  : const LinearGradient(
                      colors: [_primaryPink, _darkPink],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              color: _isSubmitting ? Colors.grey.withValues(alpha: 0.3) : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isSubmitting
                  ? null
                  : [
                      BoxShadow(
                        color: _primaryPink.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Skip
          TextButton(
            onPressed: _skipReview,
            child: Text(
              'Skip',
              style: TextStyle(
                color: _textMedium,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDoneState() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryPink, _softPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryPink.withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Thanks for your review!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your feedback helps improve the community.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textMedium,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Contact Support Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatSupportScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent_rounded, size: 20),
                  label: const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryPink,
                    side: const BorderSide(color: _primaryPink, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Back to Home with gradient
              Container(
                width: double.infinity,
                height: 56,
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
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _skipReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
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
    );
  }

  String _starLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}