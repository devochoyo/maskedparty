import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maskedparty/services/profile_service.dart';
import 'package:maskedparty/services/upload_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final UploadService _uploadService = UploadService();

  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _complexionController = TextEditingController();
  final _foodController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _aspirationController = TextEditingController();
  final _targetController = TextEditingController();

  String _maskStatus = 'masked';
  bool _willingToRemoveMask = false;
  String? _profilePhotoPath;
  String? _profilePhotoUrl;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isLoadingProfile = true;

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
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    try {
      final result = await _profileService.getProfile(token);
      
      debugPrint('📊 Loading existing profile: $result');
      
      if (mounted && result is Map && result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        
        if (data != null) {
          _bioController.text = data['biography']?.toString() ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _complexionController.text = data['complexion']?.toString() ?? '';
          _foodController.text = data['favourite_food']?.toString() ?? '';
          _hobbyController.text = data['hobby']?.toString() ?? '';
          _aspirationController.text = data['aspiration']?.toString() ?? '';
          _targetController.text = data['financial_target']?.toString() ?? '';
          
          final maskStatus = data['mask_status']?.toString();
          if (maskStatus != null && (maskStatus == 'masked' || maskStatus == 'unmasked')) {
            _maskStatus = maskStatus;
          }
          
          _willingToRemoveMask = data['willing_to_remove_mask'] == true || 
                                data['willing_to_remove_mask'] == 1;
          
          final photoUrl = data['profile_photo'];
          _profilePhotoUrl = photoUrl?.toString();
          
          setState(() => _isLoadingProfile = false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _ageController.dispose();
    _complexionController.dispose();
    _foodController.dispose();
    _hobbyController.dispose();
    _aspirationController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    setState(() => _isUploadingPhoto = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    try {
      debugPrint('📤 Uploading image: ${file.path}');
      
      final uploadResult = await _uploadService.uploadImage(token, file.path);
      
      debugPrint('📥 Upload response: $uploadResult');
      
      if (!mounted) return;

      if (uploadResult is Map && uploadResult['success'] == true) {
        final data = uploadResult['data'];
        String? url;
        
        if (data is Map) {
          url = data['url'] as String?;
        }
        
        if (url != null && url.isNotEmpty) {
          final updateResult = await _profileService.updateProfile(token, {'profile_photo': url});
          
          if (mounted && updateResult is Map && updateResult['success'] == true) {
            setState(() {
              _profilePhotoPath = file.path;
              _profilePhotoUrl = url;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile photo updated! ✅'),
                backgroundColor: _successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          } else {
            final message = updateResult is Map ? updateResult['message'] : null;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message ?? 'Failed to save photo'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          }
        }
      } else {
        final message = uploadResult is Map ? uploadResult['message'] : null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Upload failed'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
    
    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    final data = {
      'biography': _bioController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'complexion': _complexionController.text.trim(),
      'favourite_food': _foodController.text.trim(),
      'hobby': _hobbyController.text.trim(),
      'aspiration': _aspirationController.text.trim(),
      'financial_target': double.tryParse(_targetController.text.trim()) ?? 0,
      'mask_status': _maskStatus,
      'willing_to_remove_mask': _willingToRemoveMask,
    };

    debugPrint('📤 Updating profile: $data');

    try {
      final result = await _profileService.updateProfile(token, data);
      
      debugPrint('📥 Update response: $result');
      
      if (!mounted) return;
      
      if (result is Map && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated! 🎉'),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/influencerHome', (route) => false);
        }
      } else {
        final message = result is Map ? result['message'] : null;
        final errors = result is Map ? result['errors'] : null;
        
        String errorMsg = message ?? 'Failed to update profile';
        if (errors is Map && errors.isNotEmpty) {
          errorMsg = errors.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: CircularProgressIndicator(
            color: _primaryPink,
            strokeWidth: 3,
          ),
        ),
      );
    }

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
        automaticallyImplyLeading: false,
        title: Text(
          'Complete Profile',
          style: TextStyle(
            color: _textDark,
            fontSize: isSmallScreen ? 18 : 20,
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo with enhanced design
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingPhoto ? null : _pickProfilePhoto,
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryPink, _softPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 48 : 60),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryPink.withValues(alpha: 0.3),
                            blurRadius: isSmallScreen ? 15 : 20,
                            offset: Offset(0, isSmallScreen ? 6 : 8),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 2 : 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 44 : 56),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(isSmallScreen ? 42 : 52),
                              child: _profilePhotoPath != null
                                  ? Image.file(
                                      File(_profilePhotoPath!),
                                      height: isSmallScreen ? 80 : 104,
                                      width: isSmallScreen ? 80 : 104,
                                      fit: BoxFit.cover,
                                    )
                                  : _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                                      ? Image.network(
                                          _profilePhotoUrl!,
                                          height: isSmallScreen ? 80 : 104,
                                          width: isSmallScreen ? 80 : 104,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(isSmallScreen),
                                        )
                                      : _buildDefaultAvatar(isSmallScreen),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_primaryPink, _softPink],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryPink.withValues(alpha: 0.3),
                                      blurRadius: isSmallScreen ? 6 : 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _isUploadingPhoto
                                    ? SizedBox(
                                        height: isSmallScreen ? 12 : 16,
                                        width: isSmallScreen ? 12 : 16,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: isSmallScreen ? 14 : 18,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                Center(
                  child: Text(
                    'Tap to add profile photo',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 13,
                      color: _textMedium,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 18 : 24),

                // Form Fields with enhanced design
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 24),
                    border: Border.all(
                      color: _lightPink.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: isSmallScreen ? 8 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(Icons.cake_outlined, 'Age', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      _buildTextField(
                        controller: _ageController,
                        hint: 'Enter your age',
                        keyboardType: TextInputType.number,
                        isSmallScreen: isSmallScreen,
                        validator: (v) => (v == null || int.tryParse(v) == null || int.parse(v) <= 0)
                            ? 'Enter a valid age'
                            : null,
                      ),
                      SizedBox(height: isSmallScreen ? 18 : 24),

                      _buildFieldLabel(Icons.description_outlined, 'Biography', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      _buildTextField(
                        controller: _bioController,
                        hint: 'Tell clients about yourself...',
                        maxLines: 3,
                        isSmallScreen: isSmallScreen,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Biography is required' : null,
                      ),
                      SizedBox(height: isSmallScreen ? 18 : 24),

                      _buildFieldLabel(Icons.face_outlined, 'Complexion', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      _buildTextField(
                        controller: _complexionController,
                        hint: 'e.g. Fair, Olive, Dark',
                        isSmallScreen: isSmallScreen,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Complexion is required' : null,
                      ),
                      SizedBox(height: isSmallScreen ? 18 : 24),

                      _buildFieldLabel(Icons.restaurant_outlined, 'Favourite Food', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      _buildTextField(
                        controller: _foodController,
                        hint: 'e.g. Sushi',
                        isSmallScreen: isSmallScreen,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Favourite food is required' : null,
                      ),
                      SizedBox(height: isSmallScreen ? 18 : 24),

                      _buildFieldLabel(Icons.palette_outlined, 'Hobby', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      _buildTextField(
                        controller: _hobbyController,
                        hint: 'e.g. Painting',
                        isSmallScreen: isSmallScreen,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Hobby is required' : null,
                      ),
                      SizedBox(height: isSmallScreen ? 18 : 24),

                      _buildFieldLabel(Icons.emoji_objects_outlined, 'Aspiration', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      _buildTextField(
                        controller: _aspirationController,
                        hint: 'What are you working towards?',
                        isSmallScreen: isSmallScreen,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Aspiration is required' : null,
                      ),
                      SizedBox(height: isSmallScreen ? 18 : 24),

                      _buildFieldLabel(Icons.attach_money_rounded, 'Financial Target', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      _buildTextField(
                        controller: _targetController,
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixText: '\$ ',
                        isSmallScreen: isSmallScreen,
                        validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 14 : 20),

                // Mask Settings with enhanced design
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 24),
                    border: Border.all(
                      color: _lightPink.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: isSmallScreen ? 8 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(Icons.masks_rounded, 'Mask Status', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                          border: Border.all(
                            color: _lightPink.withValues(alpha: 0.4),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _maskStatus,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 6 : 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'masked', child: Text('🔒 Masked')),
                            DropdownMenuItem(value: 'unmasked', child: Text('🔓 Unmasked')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _maskStatus = value);
                          },
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Willing to remove mask for the right motivation?',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            color: _textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _willingToRemoveMask,
                        activeTrackColor: _primaryPink.withValues(alpha: 0.3),
                        activeColor: _primaryPink,
                        onChanged: (v) => setState(() => _willingToRemoveMask = v),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 28),

                // Submit Button with gradient
                Container(
                  width: double.infinity,
                  height: isSmallScreen ? 48 : 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryPink, _softPink],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryPink.withValues(alpha: 0.3),
                        blurRadius: isSmallScreen ? 10 : 15,
                        offset: Offset(0, isSmallScreen ? 4 : 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: isSmallScreen ? 18 : 22,
                            width: isSmallScreen ? 18 : 22,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Complete Profile',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 18 : 24),
              ],
            ),
          ),
        ),
      ),
    ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 80 : 104,
      width: isSmallScreen ? 80 : 104,
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
        size: isSmallScreen ? 38 : 50,
        color: _primaryPink.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildFieldLabel(IconData icon, String text, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryPink.withValues(alpha: 0.12),
                _softPink.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
            border: Border.all(
              color: _primaryPink.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Icon(icon, size: isSmallScreen ? 14 : 16, color: _primaryPink),
        ),
        SizedBox(width: isSmallScreen ? 8 : 10),
        Text(
          text,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: _textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isSmallScreen,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: isSmallScreen ? 13 : 15,
        color: _textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _textLight,
          fontSize: isSmallScreen ? 12 : 14,
          fontWeight: FontWeight.w400,
        ),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: _primaryPink,
          fontWeight: FontWeight.w600,
          fontSize: isSmallScreen ? 12 : 14,
        ),
        filled: true,
        fillColor: _bgColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 10 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          borderSide: BorderSide(
            color: _lightPink.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          borderSide: BorderSide(
            color: _lightPink.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          borderSide: const BorderSide(color: _primaryPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator,
    );
  }
}