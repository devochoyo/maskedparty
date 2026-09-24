// FILE LOCATION: lib/screens/auth/client_register.dart
import 'package:flutter/material.dart';

import '/services/auth_service.dart';
import '/services/countries.dart';
import 'login.dart';
import '../shared/privacy.dart';
import 'otp_verification.dart';

class ClientRegister extends StatefulWidget {
  const ClientRegister({super.key});

  @override
  State<ClientRegister> createState() => _ClientRegisterState();
}

class _ClientRegisterState extends State<ClientRegister> {
  final _formKey = GlobalKey<FormState>();
  final _mysteryNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countryController = TextEditingController(text: 'Loading country...');

  bool _isLoading = false;
  bool _isDetectingCountry = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedPrivacyPolicy = false;

  // Age confirmation: null = not answered, true = 18+, false = under 18
  bool? _isAdult;

  final AuthService _authService = AuthService();

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
    _detectCountry();
  }

  Future<void> _detectCountry() async {
    final country = await CountryService.detectCountry();
    if (mounted) {
      setState(() {
        _countryController.text = country ?? '';
        _isDetectingCountry = false;
      });
    }
  }

  @override
  void dispose() {
    _mysteryNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showNotEligibleDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: _lightPink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.block_rounded,
              color: _primaryPink,
              size: 34,
            ),
          ),
          title: const Text(
            'Not Eligible',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          content: const Text(
            'Sorry, you are not eligible to use this application.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: _textMedium,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Frontend-only age check. Returns true only when the user confirmed 18+.
  bool _checkAgeEligibility() {
    if (_isAdult == null) {
      _showWarningSnackBar('Please confirm whether you are 18 years or above.');
      return false;
    }
    if (_isAdult == false) {
      _showNotEligibleDialog();
      return false;
    }
    return true;
  }

  void _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_checkAgeEligibility()) return;

    if (!_acceptedPrivacyPolicy) {
      _showWarningSnackBar('You must agree to the Privacy Policy to continue.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.register(
        role: 'client',
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        mysteryName: _mysteryNameController.text.trim(),
        countryName: _countryController.text.trim(),
      );

      if (result == null || result is String || (result is Map && result['success'] == false)) {
        final message = result is Map ? result['message'] : null;
        throw Exception(message ?? 'Registration failed');
      }

      if (mounted) {
        final data = result is Map ? result['data'] : null;
        final otpSent = data is Map ? data['otp_sent'] : null;
        final token = data is Map ? data['token'] : null;

        if (otpSent == true && token != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                email: _emailController.text.trim(),
                token: token,
                role: 'client',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registration successful! Please login.'),
              backgroundColor: _successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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

  // ---------------------------------------------------------------------------
  // Reusable UI helpers
  // ---------------------------------------------------------------------------

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textDark,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildPrefixIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryPink.withValues(alpha: 0.12),
            _softPink.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: _primaryPink,
        size: 18,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _textLight,
        fontSize: 14,
      ),
      prefixIcon: _buildPrefixIcon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _lightPink.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _lightPink.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _primaryPink,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  /// A single Yes/No option button, styled to match the form.
  Widget _buildChoiceButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primaryPink.withValues(alpha: 0.15),
                      _softPink.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            color: isSelected ? null : _lightPink.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _primaryPink : _lightPink.withValues(alpha: 0.4),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: _primaryPink,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("Are you 18 years and above?"),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildChoiceButton(
              label: 'Yes',
              isSelected: _isAdult == true,
              onTap: () => setState(() => _isAdult = true),
            ),
            const SizedBox(width: 12),
            _buildChoiceButton(
              label: 'No',
              isSelected: _isAdult == false,
              onTap: () => setState(() => _isAdult = false),
            ),
          ],
        ),
      ],
    );
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
              Positioned(
                bottom: 100,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        // Back button
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

                        const SizedBox(height: 20),

                        // Logo
                        Container(
                          height: 80,
                          width: 80,
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
                          child: const Icon(
                            Icons.masks_rounded,
                            color: _primaryPink,
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "Join MaskedParty as a Client",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Registration form card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _darkPink.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mystery Name
                                _buildFieldLabel("Mystery Name"),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _mysteryNameController,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: _textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: "Choose your Mystery name",
                                    icon: Icons.masks_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Mystery name is required";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Email
                                _buildFieldLabel("Email Address"),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: _textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: "Enter your email",
                                    icon: Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Email is required";
                                    }
                                    if (!value.contains('@')) {
                                      return "Valid email required";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Password
                                _buildFieldLabel("Password"),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: _textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: "Minimum 8 characters",
                                    icon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: _textLight,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Password is required";
                                    }
                                    if (value.length < 8) {
                                      return "Minimum 8 characters";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Confirm Password
                                _buildFieldLabel("Confirm Password"),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: _textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: "Confirm your password",
                                    icon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: _textLight,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirm = !_obscureConfirm;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please confirm your password";
                                    }
                                    if (value != _passwordController.text) {
                                      return "Passwords do not match";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Country
                                _buildFieldLabel("Country"),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _countryController,
                                  enabled: !_isDetectingCountry,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: _textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: "Country",
                                    icon: Icons.location_on_outlined,
                                    suffixIcon: _isDetectingCountry
                                        ? const Padding(
                                            padding: EdgeInsets.all(14),
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _primaryPink,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_circle_rounded,
                                            color: _successGreen,
                                            size: 20,
                                          ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Country is required";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Age confirmation (18+)
                                _buildAgeQuestion(),

                                const SizedBox(height: 24),

                                // Privacy Policy Agreement
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _acceptedPrivacyPolicy,
                                        activeColor: _primaryPink,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (value) {
                                          setState(() {
                                            _acceptedPrivacyPolicy = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const PrivacyPolicyScreen(),
                                            ),
                                          );
                                        },
                                        child: RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                              color: _textMedium,
                                              fontSize: 13,
                                            ),
                                            children: [
                                              TextSpan(text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Privacy Policy & Terms',
                                                style: TextStyle(
                                                  color: _primaryPink,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: TextDecoration.none,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 25),

                                // Register Button
                                Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: (_isLoading || !_acceptedPrivacyPolicy)
                                        ? null
                                        : const LinearGradient(
                                            colors: [_primaryPink, _darkPink],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                    color: (_isLoading || !_acceptedPrivacyPolicy)
                                        ? Colors.grey.withValues(alpha: 0.3)
                                        : null,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: (_isLoading || !_acceptedPrivacyPolicy)
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
                                    onPressed: (_isLoading || !_acceptedPrivacyPolicy) ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor: _textLight,
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
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Create Account",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login link
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _darkPink.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: _textDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                ),
                                child: const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: _primaryPink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
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