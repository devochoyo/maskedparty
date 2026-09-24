// FILE LOCATION: lib/screens/auth/otp_verification.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/authentication_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String token;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.token = '',
    this.role = '',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final _authenticationService = AuthenticationService();
  bool _isLoading = false;
  bool _isResending = false;

  // OTP Controllers
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _resendTimer;
  int _secondsRemaining = 60;
  String _otpValue = '';

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _darkPink = Color(0xFFC2185B);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _successGreen = Color(0xFF00C853);

  @override
  void initState() {
    super.initState();
    _startResendCountdown();

    // Add listeners to handle paste on first field
    _otpControllers[0].addListener(() {
      final text = _otpControllers[0].text;
      if (text.length > 1) {
        _handlePastedCode(text);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _secondsRemaining = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _handlePastedCode(String pastedText) {
    // Extract only digits from pasted text
    final digitsOnly = pastedText.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length >= 6) {
      // Fill all boxes with the first 6 digits
      for (int i = 0; i < 6; i++) {
        if (i < digitsOnly.length) {
          _otpControllers[i].text = digitsOnly[i];
        }
      }
      // Focus last field
      _focusNodes[5].requestFocus();
      _updateOtpValue();
    } else if (digitsOnly.length > 1) {
      // Fill as many boxes as digits available
      for (int i = 0; i < digitsOnly.length; i++) {
        _otpControllers[i].text = digitsOnly[i];
      }
      // Focus next empty field
      _focusNodes[digitsOnly.length].requestFocus();
      _updateOtpValue();
    }
  }

  void _onOtpChanged(String value, int index) {
    // Handle paste in any field
    if (value.length > 1) {
      _handlePastedCode(value);
      return;
    }

    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    // Handle backspace
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    _updateOtpValue();
  }

  void _updateOtpValue() {
    _otpValue = _otpControllers.map((controller) => controller.text).join();
    setState(() {});
  }

  void _clearOtp() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _otpValue = '';
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: _SuccessDialog(
              onAnimationComplete: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  void _resendCode() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      final result = await _authenticationService.sendOtp(widget.email);

      if (!mounted) return;

      final success = result is Map && result['success'] == true;
      final message = result is Map
          ? (result['message'] ??
              (success ? 'Verification code resent.' : 'Failed to resend code.'))
          : 'Failed to resend code.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? _successGreen : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      if (success) {
        _startResendCountdown();
        _clearOtp();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to resend code. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _continue() async {
    if (_otpValue.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the complete 6-digit verification code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final result = await authService.verifyOtp(
        email: widget.email,
        code: _otpValue,
      );

      if (!mounted) return;

      if (result is Map && result['success'] == true) {
        // Show success dialog first
        _showSuccessDialog();

        // Wait for dialog animation to complete, then navigate
        await Future.delayed(const Duration(milliseconds: 2500));
        
        if (!mounted) return;
        
        await AuthService.checkAndNavigateProfile(
            context, widget.token, widget.role);
      } else {
        final message = result is Map
            ? result['message'] ?? 'Invalid verification code'
            : 'Invalid verification code';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification failed. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;

    // Calculate OTP box size dynamically
    final availableWidth = screenWidth - (horizontalPadding * 2);
    final totalSpacing = 8.0 * 5; // 5 gaps between 6 boxes (8px each)
    final boxWidth = ((availableWidth - totalSpacing) / 6).clamp(40.0, 56.0);
    final boxHeight = boxWidth * 1.2;

    final isSmallScreen = screenWidth < 360;
    final spacing = (availableWidth - (boxWidth * 6)) / 5;

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
      backgroundColor: _lightPink.withValues(alpha: 0.3),
      body: Stack(
        children: [
          // Full screen gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _primaryPink,
                    _softPink,
                    _lightPink.withValues(alpha: 0.8),
                    _lightPink.withValues(alpha: 0.3),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: 60,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                              splashColor: Colors.white.withValues(alpha: 0.2),
                              highlightColor: Colors.white.withValues(alpha: 0.1),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 40),
                        // Icon Container
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _darkPink.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.mark_email_unread_rounded,
                            color: _primaryPink,
                            size: isSmallScreen ? 36 : 44,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 32),
                        // Title
                        Text(
                          'Check Your Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Email Info Container
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _darkPink.withValues(alpha: 0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 14,
                                    color: _primaryPink,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.email,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: _textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'We sent a verification code to your email. Enter the code below to continue.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 13,
                                  color: _textMedium,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 28),
                        // OTP Input Boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            final isLast = index == 5;
                            return Container(
                              margin: EdgeInsets.only(right: isLast ? 0 : spacing),
                              width: boxWidth,
                              height: boxHeight,
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: index == 0 ? 6 : 1,
                                style: TextStyle(
                                  fontSize: boxWidth * 0.45,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) => _onOtpChanged(value, index),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: _otpControllers[index].text.isNotEmpty
                                      ? _primaryPink.withValues(alpha: 0.1)
                                      : Colors.white,
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(boxWidth * 0.25),
                                    borderSide: BorderSide(
                                      color: _focusNodes[index].hasFocus
                                          ? _primaryPink
                                          : Colors.white.withValues(alpha: 0.5),
                                      width: _focusNodes[index].hasFocus ? 2 : 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(boxWidth * 0.25),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(boxWidth * 0.25),
                                    borderSide: const BorderSide(
                                      color: _primaryPink,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        // Continue Button
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : const LinearGradient(
                                    colors: [_primaryPink, _darkPink],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            color: _isLoading
                                ? Colors.grey.withValues(alpha: 0.3)
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _isLoading
                                ? null
                                : [
                                    BoxShadow(
                                      color: _primaryPink.withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Resend Section
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Didn't receive the code? ",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            if (_secondsRemaining > 0)
                              Text(
                                'Resend in ${_secondsRemaining}s',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: _isResending ? null : _resendCode,
                                child: _isResending
                                    ? const SizedBox(
                                        height: 12,
                                        width: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Resend',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                              ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 30 : 40),
                      ],
                    ),
                  ),
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
}

// Animated Success Dialog Widget
class _SuccessDialog extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const _SuccessDialog({required this.onAnimationComplete});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for dialog appearance
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Rotation animation for checkmark
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeOutBack,
    );

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Pulse animation for icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Dialog scale in
    _scaleController.forward();

    // Wait a bit then start checkmark rotation
    await Future.delayed(const Duration(milliseconds: 400));
    _rotateController.forward();

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Fade in text
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();

    // Complete callback
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C853).withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Success Icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C853).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: RotationTransition(
                        turns: _rotateAnimation,
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Success Text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Column(
                    children: [
                      Text(
                        'Verification Successful',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1D2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your email has been verified successfully',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}