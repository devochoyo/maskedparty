// FILE LOCATION: lib/screens/client/edit_profile.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maskedparty/services/profile_service.dart';
import 'package:maskedparty/services/upload_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final UploadService _uploadService = UploadService();
  final ImagePicker _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();

  dynamic _currentProfile;
  String? _profilePhotoUrl;
  File? _pickedPhoto;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

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

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    setState(() => _isLoading = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }
    final result = await _profileService.getProfile(token);
    if (!mounted) return;
    if (result is Map && result['success'] == true) {
      setState(() {
        _isLoading = false;
        _currentProfile = result['data'];
        _nameController.text = _currentProfile['mystery_name']?.toString() ?? '';
        _emailController.text = _currentProfile['email']?.toString() ?? '';
        _countryController.text = _currentProfile['country_name']?.toString() ?? '';
        _profilePhotoUrl = _currentProfile['profile_photo']?.toString();
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _pickedPhoto = File(picked.path);
      _isUploadingPhoto = true;
    });

    final token = await SessionManager.getToken();
    if (token == null) return;

    // FIX: was calling uploadImage() (api/upload/image.php), which stores
    // files under uploads/chat/images/ — meant for chat attachments, not
    // avatars. uploadProfilePhoto() hits the dedicated profile endpoint
    // that stores under uploads/profiles/ and saves it to the DB directly.
    final uploadResult =
        await _uploadService.uploadProfilePhoto(token, picked.path);
    if (!mounted) return;

    setState(() => _isUploadingPhoto = false);

    if (uploadResult is Map && uploadResult['success'] == true) {
      final url = uploadResult['data']?['url']?.toString();
      if (url != null) {
        setState(() => _profilePhotoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo uploaded successfully'),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to upload photo'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mystery Name is required'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    final data = <String, dynamic>{
      'mystery_name': _nameController.text.trim(),
      if (_profilePhotoUrl != null) 'profile_photo': _profilePhotoUrl,
    };

    final result = await _profileService.updateProfile(token, data);
    if (mounted) {
      setState(() => _isSaving = false);
      if (result is Map && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      } else {
        final message = result is Map ? result['message'] : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Update failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textDark, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: _textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _lightPink.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryPink,
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Photo Section with enhanced design
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _lightPink.withValues(alpha: 0.3),
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _lightPink.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryPink.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Photo with enhanced gradient border
                        GestureDetector(
                          onTap: _isUploadingPhoto ? null : _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primaryPink, _softPink],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryPink.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(56),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(52),
                                    child: _pickedPhoto != null
                                        ? Image.file(
                                            _pickedPhoto!,
                                            height: 104,
                                            width: 104,
                                            fit: BoxFit.cover,
                                          )
                                        : (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
                                            ? Image.network(
                                                _profilePhotoUrl!,
                                                height: 104,
                                                width: 104,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(104),
                                              )
                                            : _buildPhotoPlaceholder(104),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [_primaryPink, _softPink],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryPink.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: _isUploadingPhoto
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to change photo',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textMedium,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Fields with enhanced design
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _lightPink.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mystery Name
                        _buildFieldLabel('Mystery Name', Icons.person_outline),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 15,
                            color: _textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _buildInputDecoration(
                            hint: 'Enter your display name',
                            icon: Icons.edit_outlined,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email
                        _buildFieldLabel('Email Address', Icons.email_outlined),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          enabled: false,
                          style: TextStyle(
                            fontSize: 15,
                            color: _textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _buildInputDecoration(
                            hint: 'Email address',
                            icon: Icons.lock_outlined,
                            enabled: false,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: _textLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Email cannot be changed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Country
                        _buildFieldLabel('Country', Icons.location_on_outlined),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _countryController,
                          enabled: false,
                          style: TextStyle(
                            fontSize: 15,
                            color: _textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _buildInputDecoration(
                            hint: 'Country',
                            icon: Icons.lock_outlined,
                            enabled: false,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: _textLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Detected automatically',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Button with gradient
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
                      onPressed: _isSaving ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
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
                                Icon(Icons.check_rounded, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lightPink.withValues(alpha: 0.5),
            Colors.white,
          ],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 48,
        color: _primaryPink.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildFieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
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
            border: Border.all(
              color: _primaryPink.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 16, color: _primaryPink),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _textLight, fontSize: 14, fontWeight: FontWeight.w400),
      prefixIcon: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryPink.withValues(alpha: 0.1),
                    _softPink.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: enabled ? null : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: enabled
              ? Border.all(
                  color: _primaryPink.withValues(alpha: 0.15),
                  width: 1,
                )
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _primaryPink : _textLight,
        ),
      ),
      filled: true,
      fillColor: enabled ? _bgColor : Colors.grey.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lightPink.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lightPink.withValues(alpha: 0.4)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryPink, width: 2),
      ),
    );
  }
}