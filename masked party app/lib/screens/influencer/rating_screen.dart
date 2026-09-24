// FILE LOCATION: lib/screens/influencer/rating_screen.dart
// (used by both influencer and client — isInfluencer flag controls copy)
import 'package:flutter/material.dart';
import 'package:maskedparty/services/call_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import '../shared/chat_support.dart';
import 'bottom_navigation.dart';
import '../client/bottom_navigation.dart';


class RatingScreen extends StatefulWidget {
  final String callId;
  final String otherPartyName;

  /// true  → influencer rating the client
  /// false → client rating the influencer
  final bool isInfluencer;

  const RatingScreen({
    super.key,
    required this.callId,
    required this.otherPartyName,
    required this.isInfluencer,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();

  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _bgColor = Color(0xFFF8F9FE);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _successGreen = Color(0xFF00C853);
  static const Color _dangerRed = Color(0xFFE53935);
  static const Color _ratingGold = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a star rating'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // NOTE: the backend's /api/review/create.php is client-only — there is
    // no endpoint for an influencer to rate a client. Until that exists,
    // an influencer's rating is captured in the UI but not sent anywhere.
    // Swap this branch out once a real influencer-side endpoint exists.
    if (widget.isInfluencer) {
      await Future.delayed(const Duration(milliseconds: 400)); // feels like a submit
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
      return;
    }

    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final result = await _callService.submitRating(
      token: token,
      callId: widget.callId,
      rating: _selectedRating,
      experienceText: _reviewController.text.trim(),
    );

    if (!mounted) return;

    if (result is Map && result['success'] == true) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result is Map
              ? (result['message'] ?? 'Failed to submit rating')
              : 'Failed to submit rating'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _finish() {
    // Navigate to the appropriate bottom navigation wrapper
    if (widget.isInfluencer) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const InfluencerBottomNavigation()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ClientBottomNavigation()),
        (route) => false,
      );
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _submitted 
            ? _buildDoneState() 
            : SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: _buildRatingForm(),
                ),
              ),
      ),
    ),
      ),
    );
  }

  Widget _buildRatingForm() {
    final isLowRating = _selectedRating > 0 && _selectedRating <= 2;
    final titleText = widget.isInfluencer
        ? 'Rate ${widget.otherPartyName}'
        : 'Rate your experience';
    final subtitleText = widget.isInfluencer
        ? 'How was your call with ${widget.otherPartyName}?'
        : 'How was your call with ${widget.otherPartyName}?';

    return Column(
      children: [
        const SizedBox(height: 20),

        // Back Button with enhanced design
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              splashColor: _primaryPink.withValues(alpha: 0.05),
              highlightColor: _primaryPink.withValues(alpha: 0.03),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _lightPink.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryPink.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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

        const SizedBox(height: 24),

        // Avatar with enhanced design
        Container(
          height: 88,
          width: 88,
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
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.otherPartyName.isNotEmpty
                  ? widget.otherPartyName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          titleText,
          style: const TextStyle(
            color: _textDark,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitleText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textMedium,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),

        // Stars with enhanced design
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = star),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: AnimatedScale(
                  scale: star <= _selectedRating ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    star <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: star <= _selectedRating
                        ? _ratingGold
                        : _textLight.withValues(alpha: 0.4),
                    size: star <= _selectedRating ? 48 : 40,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Star label with enhanced design
        if (_selectedRating > 0)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(_selectedRating),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: (_selectedRating <= 2 ? _dangerRed : _successGreen)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_selectedRating <= 2 ? _dangerRed : _successGreen)
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _starLabel(_selectedRating),
                style: TextStyle(
                  color: _selectedRating <= 2 ? _dangerRed : _successGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

        const SizedBox(height: 32),

        // Warning for low rating (influencer side) with enhanced design
        if (widget.isInfluencer && isLowRating) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _dangerRed.withValues(alpha: 0.06),
                  _dangerRed.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _dangerRed.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: _dangerRed,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '3 bad reviews from clients may lead to suspension of your account and loss of all earnings.',
                    style: TextStyle(
                      color: _dangerRed.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Review text box with enhanced design
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _lightPink.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _reviewController,
            maxLines: 4,
            maxLength: 300,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Leave a comment (optional)...',
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
              contentPadding: const EdgeInsets.all(16),
              counterStyle: TextStyle(
                color: _textLight,
                fontSize: 11,
              ),
            ),
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
                    colors: [_primaryPink, _softPink],
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
            onPressed: _isSubmitting ? null : _submitRating,
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
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Rating',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Skip button with enhanced design
        TextButton(
          onPressed: _finish,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Skip',
            style: TextStyle(
              color: _textMedium,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
              // Success icon with enhanced design
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
                'Thanks for your feedback!',
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
                'Your rating helps keep the community safe and enjoyable for everyone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textMedium,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Contact Support Button with enhanced design
              SizedBox(
                width: double.infinity,
                height: 54,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryPink,
                    side: const BorderSide(color: _primaryPink, width: 2),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Back to Home with gradient
              Container(
                width: double.infinity,
                height: 54,
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
                  onPressed: _finish,
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
                      letterSpacing: 0.3,
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